set quiet
set shell := ['bash', '-euo', 'pipefail', '-c']
set script-interpreter := ['bash', '-euo', 'pipefail']
set default-list
set default-script


[doc('List all nodes and their current state')]
[group('talos')]
nodes:
    topf nodes