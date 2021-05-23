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
    

##Backup and restore

###What do you need to backup?
* Resource configuration needs to be saved in version control ofc
* etcd has a builtin snapshot solution