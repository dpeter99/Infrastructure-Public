set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']
set script-interpreter := ['bash', '-euo', 'pipefail']
set default-list
set default-script

deploy_key := justfile_dir() + '/deploy.key'
webhook_token_file := justfile_dir() + '/flux-webhook-token.txt'

template: render

[private]
render:
    rm -r ./.out
    PYTHONDONTWRITEBYTECODE=1 uv run --locked --no-dev makejinja

mod? talos ".out/talos"
mod? bootstrap ".out/bootstrap"


[private]
log lvl msg *args:
    gum log -t rfc3339 -s -l "{{ lvl }}" "{{ msg }}" {{ args }}    


[doc('Initialize configuration files (cluster.toml, age key, deploy key, webhook token)')]
init:
    [ -f "{{ deploy_key }}" ]         || ssh-keygen -t ed25519 -C "deploy-key" -f "{{ deploy_key }}" -q -P ""
    [ -f "{{ webhook_token_file }}" ] || openssl rand -hex 16 > "{{ webhook_token_file }}"