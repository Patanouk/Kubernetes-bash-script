#Section 3
## 1 - Manual Scheduling

How do we schedule pod manually?

Every pod has a `nodeName` field. Generally added later by kubernetes  
The scheduler goes through the pods and checks for the ones which don't have that property  

So, without a scheduler, the easiest way is to specify the `nodeName` property  
* `nodeName` can only be set at creation
* Can create a `Binding` object otherwise, to bind a pod to a node

## 2 - Labels and Selectors
### labels
* `labels` are just strings added to the kubernetes items
* `selectors` can be used to filter objects based on labels

To filter the pods :  
* `kubectl get pods -l=function=backend`
* `kubectl get pods --selector function=backend`  

Internally, kubernetes uses label to link objects together  
For example, when creating a ReplicaSet : 
* `labels` under metadata are labels for the ReplicaSet object
* `labels` under template section are the labels of the pods
* `selector -> matchLabels` are then used to by the ReplicaSet to discover the pods

###Annotations
Cannot be used for selecting
Used for a lot of stuff, for example prometheus auto-discovery of scraping endpoints

See [pod-label](pod-label-definition.yaml)

## 3 - Taints and Tolerations

`Taint` are labels-like added to the node  
By default, none of the pods can go on a tainted node. You need to add `tolerations` to make sure the node is populated

Command:
* `kubectl taint nodes node-name key=value:taint-effect`
* `taint-effect`
    * `NoSchedule` -> Pods are not scheduled on the node
    * `PreferNoSchedule`-> Try to avoid scheduling pod, but not guaranteed
    * `NoExecute` -> New pods are not scheduled on the node, and existing pods will be evicted
    
Example
* `kubectl taint nodes node1 app=blue:NoSchedule`

Can also be added in yaml files  

!!!Taint only restrict which pods can be run on which node. It doesn't force the scheduling of certain pods on certain nodes!!!

Special case of the master node  
No pods are scheduled on master node by default  
The master node has a special taint which prevents pods to be scheduled here  

See [pod-tolerations](pod-tolerations-definition.yaml)

## 4 - Nodes Selectors

Assuming multiples nodes with different sizes  
See [pod-nodeselector](pod-nodeselector-definition.yaml)

Can be added as a section in a yaml file  
The node selectors sections specify a label which has to match the labels on the nodes

To label nodes: 
* `kubectl label nodes node-name key=value`
* `kubectl label nodes node1 size=large`  

Nice, but only match single label  
How do we do
* Pod on medium or large node?
* Pod not on small node?

## 5 - Node Affinity

The goal is to ensure some pods are scheduled on some nodes

See [pod-nodeaffinity.yaml](pod-nodeaffinity-definition.yaml). Lots of options  

See `NodeAffinityTypes` for the possible behaviors  
* `DuringScheduling` -> Considered when placing the pods on the node
    * `required` -> Has to be placed on node matching the selectors. If no matching nodes, pod is not scheduled
    * `preferred` -> If no matching nodes, pod will still be scheduled on any available nodes
* `DuringExecution` -> Considered after pods are running, when we make changes to the nodes
    * `Ignored` -> Changing the nodes labels doesn't evict currently running pods
    

## 6 - Node affinity vs Taints and tolerations

3 nodes and 3 pods, each in 3 different colors. Also, other nodes in cluster with other colors  

* `Taints and tolerations`
    * Add taint with the color on each nodes
    * Add toleration with the color on each pod
    * We're sure each node can only accept pods with the associated taint
    * !!!However, we're not sure each color pod is put on each color node!!!
* `Node Affinity`
    * Label each node with their respective color
    * Add NodeSelector on each pod with the color
    * That ensures that each pod is scheduled on a node with the specific color
    * !!!However, other pods can still be scheduled on color pods, even if they don't have nodeSelector!!!
    
Hence, we need **BOTH** `taints and tolerations` and `Node Affinity` to ensure only specific pods are scheduled on specific nodes

## 6 - Resources and limits

Each node has `CPU`, `MEM`, `DISK`  
Pod can specify resources they want to acquire 
The scheduler uses these limits to schedule the pods on a node with enough resources

* `CPU`
    * 1 CPU is equal to 1 AWS vCPU, 1 Hyperthread, 1 GPC Core...
    * Can be expressed in milliCPU
* `Memory`
    * 1G -> 1 GigaByte (1000 M) = 1 000 000 000 bytes
    * 1Gi -> 1024 Mi = 1 073 741 824 bytes
    
By default, Docker doesn't have any memory and resources limits  
If not specified in yaml file, the pod has no resource limits either  

!!!You can create a `LimitRange` object!!! to specify default limit values for your containers

Of course, can be specifed in the yaml file  
See [pod-resources.yaml](pod-resources-definition.yaml)  

####What happens if try to exceed resources?
* `CPU` -> Container is throttled
* `Memory` -> Pod is killed if exceed memory  

Behaves like that because memory cannot be reclaimed 

## 7 - Daemon Sets

Daemon sets are like replica sets, in the sense it helps you to deploy your pods on multiple nodes  

However, `Deamon Sets` ensure that one copy of each pod is running on each node
* If a node is deleted, the copy is deleted
* If a node is added, a new copy is automatically added on that node
* Each node gets one copy of the pod specified in the daemon set  

See [daemon-set yaml](deamonset-definition.yaml)

####Use cases
* `kube-proxy` -> Has to present on every node of the kubernetes cluster
* `weave-net` -> Networking agent, needs a copy on every node

####Under the hood
Uses `NodeAffinity` to schedule a pod per node

## 8 - Static Pods

What happens if we have a single node without a Kubernetes master (e.g. single kubelet on a node)?

You can configure the kubelet to read the pod definition files from a specific directory on the server  
The kubelet periodically checks the directory, reads the file and creates the nodes  
If the application crashes, the kubelet recreates the pod. Same if file is changed  
If file removed, kubelet deletes pod  

!!!Can only create pods, no ReplicaSet, Deployments...!!!  
The kubelet only works on a pod level

####Options
* `--pod-manifest-path`=/etc/Kubernetes/manifests
* Via config file
  * `--config=kubeconfig.yaml`
  * Can then check inside `kubeconfig.yaml` for `staticPodPath` option
    
####Seeing the containers
~~kubectl~~ -> Not supported, as it normally does api calls to the `kubeapi-server`
`docker ps` -> Will list the containers running  

#### How to create both?

You can create `Pods` both ways out of the box
* Via the kubectl -> http request to kubeapi-server -> http request to kubelet  
* Via the static pods method defined above  

The kubeapi-server is also aware of the static pods (via directory) created by the kubelet  
However, it's read-only, e.g. the kubeapi-server cannot modify the static pods

####How to recognize static pods
They have the name of the node as suffix of the pod name 
Example: etc-controlplane
* `etcd` -> pod name
* `controlplane` -> node name

####Why do we neeed this?

Useful to setup kubernetes cluster  
1. Install kubelet on all the master nodes
2. Pass all the yaml files for the controlplane components to the kubelet
3. The kubelet download and install the images. That way, no need to worry about setting up things manually, downloading etc...
4. If a service crash, will be restarted by the kubelet. Easier than setup restart policy for a bunch of different services

