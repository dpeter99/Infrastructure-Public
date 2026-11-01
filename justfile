set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']
set script-interpreter := ['bash', '-euo', 'pipefail']
set default-list
set default-script

webhook_token_file := justfile_dir() + '/flux-webhook-token.txt'
# sops-encrypted (keys visible) secret values rendered into the cluster-secrets Secret.
secrets_file := justfile_dir() + '/cluster.secrets.sops.yaml'
out_dir := justfile_dir() + '/.out'
manifests_dir := out_dir + '/kubernetes'
# flux reads registry logins from here; podman is told to write to the same file.
docker_config := env('DOCKER_CONFIG', env('HOME') + '/.docker') + '/config.json'

template: render encrypt

[private]
render:
    [ -f "{{ secrets_file }}" ] || just log fatal "Missing {{ secrets_file }}, run: just init"
    just log info "Rendering content"
    rm -rf ./.out
    PYTHONDONTWRITEBYTECODE=1 uv run --locked --no-dev makejinja

mod? talos ".out/talos"
mod? bootstrap ".out/bootstrap"


[private]
log lvl msg *args:
    gum log -t rfc3339 -s -l "{{ lvl }}" "{{ msg }}" {{ args }}


[doc('Initialize configuration files (webhook token, cluster secrets)')]
init: gen_age_secret
    [ -f "{{ webhook_token_file }}" ] || openssl rand -hex 16 > "{{ webhook_token_file }}"
    if [ ! -f "{{ secrets_file }}" ]; then
        just log info "Creating encrypted secrets file" file "{{ secrets_file }}"
        printf '%s\n' \
            '# Secret cluster values. Edit with `just secrets`.' \
            '# Referenced as #{ secrets.<key> }# in cluster/bootstrap/cluster-secrets.yaml.j2.' \
            'domain: example.com' \
            'internal_domain: internal.example.com' \
        | sops encrypt --input-type yaml --output-type yaml \
            --filename-override "{{ secrets_file }}" /dev/stdin > "{{ secrets_file }}"
    fi

[private]
gen_age_secret:
    if [ ! -f age.key ]; then
        just log info "Generating age key"
        age-keygen -pq -o ./age.key
    else 
        just log info "Age key exists"
    fi



[doc('Edit the encrypted cluster secrets (domain, ...)')]
secrets:
    sops "{{ secrets_file }}"


[doc('Log in to the OCI registry with credentials from 1Password (op)')]
login:
    url="$(yq -p toml -o yaml '.artifact.url' cluster.toml)"
    registry="${url#oci://}"; registry="${registry%%/*}"
    username="$(op read "$(yq -p toml -o yaml '.artifact.op_username' cluster.toml)")"
    just log info "Logging in" registry "$registry" user "$username"
    mkdir -p "$(dirname "{{ docker_config }}")"
    op read "$(yq -p toml -o yaml '.artifact.op_token' cluster.toml)" \
        | podman login "$registry" --username "$username" --password-stdin --authfile "{{ docker_config }}"


# Templates may render *.sops.yaml in plaintext (e.g. from cluster.secrets.sops.yaml);
# encrypt them in place with the creation rules from $SOPS_CONFIG. Files that are
# already encrypted (copied through unchanged) are left alone.
[doc('Encrypt every plaintext *.sops.yaml under .out')]
encrypt:
    while IFS= read -r -d '' file; do
        if yq --exit-status '.sops.mac' "$file" > /dev/null 2>&1; then
            continue
        fi
        just log info "Encrypting" file "${file#{{ out_dir }}/}"
        sops encrypt --in-place "$file"
    done < <(find "{{ out_dir }}" -name '*.sops.yaml' -print0)


# Only Flux running in the cluster may decrypt secrets, so refuse to publish
# anything that looks like key material or an unencrypted sops file.
[doc('Check that .out contains no decrypted sops files and the manifests no key material')]
verify:
    if grep -rqE 'AGE-SECRET-KEY-|PRIVATE KEY-----' "{{ manifests_dir }}"; then
        just log fatal "Private key material found in {{ manifests_dir }}"
    fi
    while IFS= read -r -d '' file; do
        if ! yq --exit-status '.sops.mac' "$file" > /dev/null 2>&1; then
            just log fatal "sops file is not encrypted" file "$file"
        fi
    done < <(find "{{ out_dir }}" -name '*.sops.yaml' -print0)
    just log info "No decrypted sops files in {{ out_dir }}"


[doc('Render the manifests and push them as an OCI artifact for Flux to reconcile')]
push: template verify
    url="$(yq -p toml -o yaml '.artifact.url' cluster.toml)"
    sha="$(git rev-parse --short HEAD)"
    [ -f "{{ docker_config }}" ] || { just log fatal "Not logged in to the registry, run: just login"; }

    # Push under the git sha for traceability, then move `latest` (which
    # flux-instance tracks) to the same artifact.
    just log info "Pushing manifests" artifact "$url:$sha"
    
    flux push artifact "$url:$sha" \
        --path "{{ manifests_dir }}" \
        --source "$(git remote get-url origin 2>/dev/null || echo "local")" \
        --revision "$(git branch --show-current)@sha1:$(git rev-parse HEAD)"
    just log info "Tagging as latest" artifact "$url:$sha"
    flux tag artifact "$url:$sha" --tag latest
