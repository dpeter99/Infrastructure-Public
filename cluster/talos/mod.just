set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']
set script-interpreter := ['bash', '-euo', 'pipefail']
set default-list
set default-script


[doc('List all nodes and their current state')]
[group('talos')]
nodes:
    topf nodes

[doc('Apply Talos config to all nodes (shows a diff and asks first)')]
[group('talos')]
apply:
    topf apply

[doc('Show pending config changes without applying them')]
[group('talos')]
diff:
    topf apply --dry-run


[doc('Render Talos machine configs to ./rendered')]
[group('talos')]
render:
    topf render --output ./rendered