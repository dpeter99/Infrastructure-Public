
Contains kubernetes workloads and configurations for the cluster infrastructure.

## Workloads

### base
Contains helm repositories for installing stuff

### core
Contains the core infrastructure workloads
- `cert-manager`: Manages certificates like let's encrypt
- `ciliium`: The core networking of the cluster
- `longhorn`: The storage solution for the cluster
- `metrics-server`: Provides metrics for the cluster horizontal pod autoscaler
- `nginx-proxy`: The ingress controller for the cluster

### monitoring
Contains the monitoring workloads
- `grafana`: The monitoring dashboard
- `prometheus`: The monitoring engine where all the metrics are sent to

### security
Contains the security workloads
- `external-secrets`: For loading secrets from external sources
- `onepassword-connect`: For loading secrets from 1password

### system
Contains the system workloads
- `node-feature-discovery`: Discovers the features of the nodes like CPU, GPU, Memory, etc.
- `reloader`: Reloads the deployments when the secrets/configs change