export TALOS_CLUSTER_NAME=aper_cluster
export MAIN_NODE=10.1.2.1
talosctl gen config $TALOS_CLUSTER_NAME https://$MAIN_NODE:6443 -o ./
talosctl config merge ./talosconfig
