set no-exit-message
set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']
set script-interpreter := ['bash', '-euo', 'pipefail']
set default-list
set default-script

[doc('Bootstrap the Talos cluster')]
[group('bootstrap')]
talos: talos-secret talos-apply talos-talosconfig talos-kubeconfig

# Run `just push` first: once flux-instance is up it reconciles the OCI
# artifact and takes over the helmfile-installed releases.
[doc('Bootstrap the core apps')]
[group('bootstrap')]
apps: apps-namespaces apps-secrets apps-crds apps-helm


[private]
[script]
[working-directory('../talos')]
talos-secret:
    just log info "Generating secrets" stage "{{ recipe_name() }}"
    topf secrets --confirm=false > /dev/null


[private]
[working-directory('../talos')]
talos-apply:
    just log info "Applying talos config and bootstrapping" stage "{{ recipe_name() }}"
    topf apply --auto-bootstrap --confirm=false

[private]
[working-directory('../talos')]
talos-talosconfig:
    just log info "Generating talosconfig" stage "{{ recipe_name() }}"
    topf talosconfig > "{{ justfile_dir() }}/talosconfig"

# topf issues short-lived admin certs by default; 8760h keeps the
# kubeconfig usable long-term.
[private]
[working-directory('../talos')]
talos-kubeconfig:
    just log info "Fetching kubeconfig" stage "{{ recipe_name() }}"
    topf kubeconfig --validity 8760h > "{{ justfile_dir() }}/kubeconfig"



# Namespaces are owned by Flux (kubernetes/apps/<ns>/namespace.yaml); they
# are pre-created here so the bootstrap secrets and helm releases have a home.
[private]
apps-namespaces:
    just log info "Applying namespaces for apps" stage "{{ recipe_name() }}"
    for ns in \
        "kube-system" \
        "flux-system"
    do
        if kubectl create namespace "$ns" --dry-run=client -o yaml \
                | kubectl apply --server-side --filename - &>/dev/null; then
            just log info "Namespace applied" namespace "$ns"
        else
            just log fatal "Failed to apply namespace" namespace "$ns"
        fi
    done


# sops-age is the only place the age private key ever lands outside this
# machine; Flux decrypts *.sops.yaml in-cluster with it.
[private]
apps-secrets:
    just log info "Applying secrets for apps" stage "{{ recipe_name() }}"
    for secret in \
        "{{ source_directory() }}/sops-age.yaml" \
        "{{ source_directory() }}/registry-credentials.yaml" \
        "{{ source_directory() }}/cluster-secrets.yaml"
    do
        if cat "$secret" \
                | kubectl --namespace flux-system apply --server-side --filename - &>/dev/null; then
            just log info "Secret applied" resource "$secret"
        else
            just log fatal "Failed to apply secret" resource "$secret"
        fi
    done



[private]
apps-crds:
    just log info "Applying CRDs" stage "{{ recipe_name() }}"
    if ! helmfile --file "{{ source_directory() }}/helmfile/crds.yaml" template --quiet | yq eval-all --exit-status 'select(.kind == "CustomResourceDefinition")' | kubectl apply --server-side --force-conflicts --filename -; then
        just log fatal "Failed to apply crds"
    fi


[private]
apps-helm:
    just log info "Syncing helmfile" stage "{{ recipe_name() }}"
    if ! helmfile --file "{{ source_directory() }}/helmfile/apps.yaml" sync --hide-notes; then
        just log fatal "Failed to sync helmfile"
    fi


