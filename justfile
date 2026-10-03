set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']
set script-interpreter := ['bash', '-euo', 'pipefail']
set default-list
set default-script

#[group('bootstrap')]
#mod bootstrap

template: render

[private]
render:
    rm -r ./.out
    PYTHONDONTWRITEBYTECODE=1 uv run --locked --no-dev makejinja &> /dev/null

mod? talos ".out/talos"
mod? bootstrap ".out/bootstrap"


[private]
log lvl msg *args:
    gum log -t rfc3339 -s -l "{{ lvl }}" "{{ msg }}" {{ args }}    


