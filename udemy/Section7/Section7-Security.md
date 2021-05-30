#Section 6
##Security primitives

You need security for your hosts ofc  
Lecture is more focused on kubernetes specific resources, such as

* Kube-apiserver
* tls certificates between the components
* Pods between pods : Everything is authorized by default
    * Can be restricted with network policies
    
##Authentication

Two kind of people accessing clusters
* Users
* 'Bots'

Kubernetes doesn't manage users
Kubernetes can manage 'bots' (`service account`)

All kubernetes access for users is managed by the `kube-apiserver`  
Auth mechanisms:
* Static password file
* Static token file
* Certificates
* Identity services (LDAP, IAM)

For static files, you can use csv files  
* See flag `--basic-auth-file=user-details.csv` for password
* See flag `--token-auth-file=user-details.csv` for token based  
Of course, this is not the best practice
  
## TLS in kubernetes
###Types of certificates
Server certificates
* `Api-server` exposes an https API : `apiserver.crt` and `apiserver.key` for api-server tls
* Same for `etcd` : `etcdserver.crt` and `etcdserver.key`  
* Same for the `kubelet servers` : `kubelet.crt` and `kubelet.key`

Client certificates
* `Admin` : `admin.crt` and ...
* `kube-scheduler` : is a client as well. Talks to the kube-apiserver, same as users
* `kube-controlller-manager` : ...
* `kube-proxy` : ...

Also, you need a CA to sign all the certificates : `ca.crt` and `ca.key`

###Certificates in Kubernetes
You can ofc generate the certificates yourself. Lots of stuff, check the video

####How to check the certificates?
You can deploy your kubernetes components with multiple ways
* The hard way -> Kubernetes components might be deployed as services on your node
* The kubeadm way -> Components might be deployed as pods in your cluster (`/etc/kubernetes/manifests`)

