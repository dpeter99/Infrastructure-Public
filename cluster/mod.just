set no-exit-message
set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']
set script-interpreter := ['bash', '-euo', 'pipefail']
set default-list
set default-script
set working-directory := '..'

template: render

[private]
render:
    rm -r ./.out
    PYTHONDONTWRITEBYTECODE=1 uv run --locked --no-dev makejinja