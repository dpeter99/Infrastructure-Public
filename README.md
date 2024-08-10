<div align="center">

<img src="https://raw.githubusercontent.com/onedr0p/home-ops/main/docs/src/assets/logo.png" align="center" width="144px" height="144px"/>

### My Home Operations Repository :octocat:

_... managed with Flux 🤖

</div>

This is the public copy of my Kubernetes cluster configuration. 
I use this repository to manage my home infrastructure and workloads,
like [Home Assistant](https://www.home-assistant.io/).


### :wrench:&nbsp; Tools

| Tool                                                               | Purpose                                                             |
|--------------------------------------------------------------------|---------------------------------------------------------------------|
| [flux](https://toolkit.fluxcd.io/)                                 | Operator that manages your k8s cluster based on your Git repository |


## 💻 Nodes
| Node                          | Hostname     | RAM  | Storage                                            | Function    | Operating System    |
|-------------------------------|--------------|------|----------------------------------------------------|-------------|---------------------|
| Dell Optiplex Micro 5050      | APER_NODE_01 | 16GB | 2TB HDD + 500GB SSD (Boot)                         | Kube Worker | Talos 1.8.0-alpha.1 |
| Dell Optiplex Micro 5050      | APER_NODE_01 | 16GB | 2TB HDD + 500GB SSD (Boot)                         | Kube Worker | Talos 1.8.0-alpha.1 |

## Storage
No dedicated NAS or storage server. Instead, I use the two 2tb disks in the nodes

## Network

| Vendor  | Model       | Function                             |
|---------|-------------|--------------------------------------|
| ASUS    | RT-AC66U B1 | Running FreshTomoato as the firmware |
| TP-LINK |             | Managed 6 port switch                |

## ☁️ Cloud Dependencies

While most of my infrastructure and workloads are self-hosted I do rely upon the cloud for certain key parts of my setup. This saves me from having to worry about two things. (1) Dealing with chicken/egg scenarios and (2) services I critically need whether my cluster is online or not.

The alternative solution to these two problems would be to host a Kubernetes cluster in the cloud and deploy applications like [HCVault](https://www.vaultproject.io/), [Vaultwarden](https://github.com/dani-garcia/vaultwarden), [ntfy](https://ntfy.sh/), and [Gatus](https://gatus.io/). However, maintaining another cluster and monitoring another group of workloads is a lot more time and effort than I am willing to put in.

| Service                                                               | Use                                                                | Cost                |
|-----------------------------------------------------------------------|--------------------------------------------------------------------|---------------------|
| [Cloudflare](https://www.cloudflare.com/)                             | Domain(s)                                                          | Free                |
| [GCP](https://cloud.google.com/)                                      | Voice interactions with Home Assistant over Google Assistant       | Free                |
| [GitHub](https://github.com/)                                         | Hosting this repository and continuous integration/deployments     | Free                |
| [1Password](https://1password.eu)                                     | External Secrets and secret management                             | Free for the moment |

## Stargazers

[![Star History Chart](https://api.star-history.com/svg?repos=dpeter99/Infrastructure-Public&type=Date)](https://star-history.com/#dpeter99/Infrastructure-Public&Date)


