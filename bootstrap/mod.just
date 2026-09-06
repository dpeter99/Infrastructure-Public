set no-exit-message
set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']
set script-interpreter := ['bash', '-euo', 'pipefail']
set default-list
set default-script

mod age_setup

[doc('Bootstrap the Talos cluster')]
[group('bootstrap')]
init: talos-secret talos-apply talos-talosconfig talos-kubeconfig

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
    topf talosconfig > talosconfig    

# topf issues short-lived admin certs by default; 8760h keeps the
# kubeconfig usable long-term.
[private]
[working-directory('../talos')]
talos-kubeconfig:
    just log info "Fetching kubeconfig" stage "{{ recipe_name() }}"
    topf kubeconfig --validity 8760h > "{{ justfile_dir() }}/kubeconfig"    