#Section 2
## 2 - Cluster Architecture

* `Worker Nodes` : Hosts applications as Containers
    * `Kubelet` : Present on every worker node. Receives instruction from the `kube-apiserver` and destroyes or create containers. `Kubelet` also sends reports to the `kube-apiserver`
    * `kube-proxy` : Present on every worker node. Enable communication between services within the custer

<br>

* `Master Node` : Manage, plan schedule and monitor the `Worker Nodes`
    * `ETCD Cluster` : A HA database storing info in a key value store. Stores info about which container on which node, loading time of container etc...
    * `kube-scheduler` : Identifies which node should get a container based on resources, number of existing pods, pods affinity etc...
    * `Controllers`
        * `Node-Controller` : Responsible to onboard new nodes in cluster, handling when node goes down
        * `Replication-Controller` : Making sure the correct number of pods are running at all time
    * `Kube-apiserver` : Orchestrate all operations within the cluster. Also opens the API to the outside for management
    * `Container Runtime` : Generally Docker. Has to be on every node (including master). Master Nodes components can be containers 
    
## 3 - ETCD

###Intro 
* ETCD is a distributed reliable key-value store
    * Can be downloaded via github releases
* Stores information about the cluster state : Secrets, Pods, Configs.
* All `kubectl get` commands are pinging the `etcd cluster`
* All updates are stored in `ETCD`. Changes are considered to be complete if `ETCD` has stored the change  

###Setup : 
* From scratch : Need to setup `ETCD` yourself
    * `--advertise-client-urls` : url where you can ping the `ETCD`
* `Kubeadm` : Takes care of the installation for you. Can check `etcd-master` in `kube-system` namespace

### ETCD in HA
`--initial-cluster` : Need to set the list of `ETCD` addresses

## 4 - Kube-apiserver
###Intro

Endpoint where all the kubectl are going
  * `kubectl get nodes` -> Sends a POST request to apiserver, validates it, retrieves data from etcd cluster
  * You can also make a post request directly to the api server, e.g. not using the `kubect` CLI
  
Responsible for:
  * Authenticating user
  * Validating the POST requests
  * Retrieving data
  * Updating ETCD -> `kube-apiserver` is the only component updating `ETCD`
  * Scheduler
  * Kubelet

If running via kubeadm / minikube / managed kubernetes, the `apiserver` is deployed as a pod in `kube-system` namespace

## 5 - Kube controller manager

Continuously watch the status of the system and takes action to correct the state

Example : `Node Controller` -> Checks the status of the node
* Node Monitor Period (5s) = heartbeat
* Node Monitor Grace Period (40s) = Node marked as unreachable if unresponsive for that time
* POD eviction timeout (5m) = Pod evicted if node unreachable for that time

Example : `Replication controller` -> Checks the status of the pods. Create another ones if one of the pod is unavailable

Tons of other controllers as well. They're all packaged in the `kube-controller-manager`

If running via kubeadm / minikube / managed kubernetes, the `controller manager` is installed as a pod in `kube-system` namespace
Can also search for the process on the master node if have access

## 6 - Kube scheduler

Responsible for deciding which pods goes on which node
!!!Not responsible for actually placing the pods on the node. This is done by the `kubelet`, present on each POD!!!

The scheduler goes through 2 phases to decide on a node for a POD
1. `Filter Nodes` : Filter out the nodes not fitting the POD profile. Not enough memory / CPU for example
2. `Rank Nodes` : Ranks the remaining nodes on a [1, 10] scale. For example score based on the number of free memory after placing the POD

Same as before, deployed as a pod in `kube-system` namespace

## 7 - Kubelet

Component present on each `worker node`. Responsible for authenticating with the master node. Single point of contact on each worker node

* The `kubelet` on the worker node registers the node with the kubernetes cluster
* When it receives an instruction to place a POD, it asks the container runtime (`Docker`) to pull the image
* The kubelet keeps monitoring the status of the POD and the container, and sends regular report to the kube-apiserver

Installation
* Not installed by default with `kubeadm` -> Need to install it manually on each worker node

## 8 - Kube-proxy

Within a kubernetes cluster, each POD can talk to other pods. Done by deploying a `pod network` solution within the cluster  
A `pod network` is an internal virtual network that spans across all the nodes in the cluster to which all the pods connect to  

Usual things with services. You don't ping `pods` with ip adresses. You create a service instead  
The `service` cannot join the `pod netowrk` because it's not an actual component. It's just a virtual component living in Kubernetes memory

So how is `service` accessible from all the nodes? -> Done with the `kube-proxy`  
* `kube-proxy` is a process which runs on every node in the kubernetes cluster
* The `kube-proxy` looks for the creation of new services and creates appropriate rules on each node so that network traffic is correctly forwarded
  * Can be done with `Iptables` rules. Create rules forwarding traffic heading to the Ip of the service to the Ip of the actual POD
  * See bullet point above. Then no need to know Ip of the pod, only need to know Ip of the service. If the pod goes down and is recreated elsewhere, I guess the `kube-proxy` updates the Iptable rule
  
Installation
* Download from google kubernetes release page
* Also deployed in `kube-system` namespace as a `daemonset`

## 9 - PODS

A POD is a single instance of an application. Smallest object which can be created in Kubernetes  
`PODS` are your scaling unit. If you need more applications to handle traffic, you create new `PODS`. Can be deployed on multiple nodes  

`PODS` can be multi-containers
* The containers within the same `POD` can refer to each other as localhost since they share the same network space
* They can share same storage as well  

`kubectl run nginx --image nginx` -> Run a pod named nginx with a single docker nginx container running

## 10 - PODS with Yaml

Needed fields for yaml
* `apiVersion` : version of the kubernetes api you're trying to use
* `kind` : kind of resource
* `metadata` : name, labels, annotations...
* `spec` : Different for each resource type. Check docs for the list of possible values

See [Pod yaml file](pod-definition.yaml)

`kubectl create -f pod-definition.yaml` -> Create the `pod` (or more generally the resources) defined in the yaml file
`kubectl get pods -o wide` -> Also shows on which node the pod is running

## 11 - ReplicaSets

Replication Controller (old way) vs ReplicaSets (new way)
* Responsible for bringing back up failed pods
* Responsible for load balancing and scaling. Multiple pods can belong to the same replica set

See [Replication Controller yaml file](rc-definition.yaml)  
See [Replicaset yaml file](replicaset-definition.yaml)  

Differents behavior for selector : 
* `Replication controller` : Assumes the selector is same as the labels provided in the pod definition file
* `Replica Set` : the selector needs to be filled manually  

Why do we need labels and selectors?  

The `replica set` is a process used to monitor the pods, and spin them up if necessary  
The labels can be used as a filter so that the `replica set` know which pods to monitor  
The `replica set` doesn't creates new pods if pods already exists. !!!Still need templates section though, so the `replicaset` knows how to create a pod if one goes down!!!  

How do we scale the replica set?

* Modify the yaml file and run `kubectl apply` <- Better since you can check the file in version control
* `kubectl scale --replicas 6 -f replicaset-definition.yaml` !!!Doesn't change the file!!!

## 12 - Deployments

Deployment = POD + replicaset

* Can have rolling update, rolling restart etc...

See [Deployment yaml file](deployment-definition.yml)

`kubectl get pods` -> See it created pods
`kubectl get replicaset` -> See it created replicaset
`kubectl get deployment` -> See it created a deployment

## 13 - Namespaces

Object used to isolate object from each others  
Pods, replicaset, Services etc... can be in separate namespaces

Examples
* `Default` : Default namespace used when creating object
* `kube-system` : Used by kubernetes to create kubernetes specific objects. Separate from default, so you don't mess around with it
* `kube-public` : Where resources available to everyone are??  

You can have resource limits per namespace  

DNS  
* Same namespace : ping `db-service`
* Different namespace : ping `db-service.namespace.svc.cluster.loca`
  * `db-service` : service name
  * `namespace` : namespace name
  * `svc` : service
  * `cluster.local` : domain
  
Commands : 
* `kubectl gets pods --namespace=kube-system`
* `kubectl get pods --all-namespaces`
* `kubectl apply -f pod.yaml --namespace=dev`
  * Can add `namespace: dev` under the pod metadata section in yaml
  
You can create a namespace with a yaml file

Switch namespace permanently
* `kubectl config --set-context $(kubectl config current-context) --namespace dev`

Limit namespace resource
* Create a resource quota yaml file

## 14 - Services

Service types
* `NodePort` : Makes internal pod accessible via a port on the worker node -> Service is accessible outside
* `ClusterIp` : The service creates a virtual IP inside the cluster to enable communication between services
* `LoadBalancer` : Creates a loadbalancer as provided by the CloudProvider

### NodePort
It maps a port on the node to a port on the Pod  
The service is in fact like a virtual server inside the node  
It has a virtual IP address

* `target port` : port on the pod
  * If not specified in yaml file, assumed to be the same as port
* `port` : port on the service
* `ClusterIp` : virtual ip adress of the Service
* `NodePort` : Port on the node, exposed to the outside
  * Can only be in the range 30000-32767
  * If not provided, free port is automatically allocated
  
Services can be created with a yaml file  

The `service` automatically select all the pods matching the selectors and forward the requests to the matching pods
The `NodePort` uses a random algorithm to balance the requests  
The `NodePort` is hence acting a built-in loadbalancer  

What happens if pods are distributed on multiple nodes?
Kubernetes automatically starts the service on all nodes  -> You can access the service with any ip in the cluster and the node port
The `NodePort` can be pinged on all the nodes having the pods matching the selector  
