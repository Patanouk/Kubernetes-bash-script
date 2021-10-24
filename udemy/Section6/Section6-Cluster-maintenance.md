#Section 6
##OS upgrades
Assuming you need to upgrade your nodes, or apply patches

If the node goes down, kubernetes waits `eviction-pod-timeout` before recreating the pods

Safest options
1. `kubectl drain node-1`
2. Wait for the drain
3. Reboot `ndoe-1`, apply patches
4. `kubectl uncordon node-1`

You can also use `kubectl cordon node-1`. This does not remove the workloads from the pods, but new pods are not scheduled on that node

##Kubernetes version

Similar as lots of other : Major.minor.patch

##Upgrade kubernetes version

If managed Kubernetes, just click on the button in your cloud provider UI  

The different kubernetes components can be at most the version of the `api-server`
* `api-server` : 1.10 = X
    * 1.9 < `controller-manager` and `kube-scheduler` < 1.10 (**[ X - 1, X ]**)
    * 1.8 < `kubelet` and `kube-proxy` < 1.10 (**[ X - 2, X]**)
    * 1.9 < `kubectl` < 1.11 (**[ X - 1, X + 1]**)
    
Kubernetes only supports the last 3 minor versions

Upgrade steps: 
* Upgrade the master node first 
    * Workloads on the worker nodes will continue to work
* Upgrade the worker nodes
    1. Upgrade them all by one
    2. Upgrade them one by one
    3. Add new nodes with new version and shutdown old ones
    
---
Commands to upgrade
Assuming all components are at 1.11.0

1. Upgrade master nodes components
* `apt-get upgrade -y kubeadm=1.12.0-00`
* `kubeadm upgrade plan`
* `kubeadm upgrade apply v1.12.0`
* `k get nodes` <- version of the kubelet is not the version of the api-server
* `ssh master-node`
* `apt-get upgrade -y kubelet=1.12.0-00`
* `systemctl restart kubelet`
* `k get nodes` <- kubelet in the controlplane node is now at 1.12

2. Upgrade worker nodes (Repeat for each nodes)

* `kubectl drain node01`
* `ssh node01`
* `apt-get upgrade -y kubeadm=1.12.0-00`
* `apt-get upgrade -y kubelet=1.12.0-00`
* `kubeadm upgrade node config --kubelet-version 1.12.0-00`
* `systemctl restart kubelet`
* `kubectl uncordon node01`


##Backup and restore

###What do you need to backup?
* Resource configuration needs to be saved in version control ofc
* etcd has a builtin snapshot solution