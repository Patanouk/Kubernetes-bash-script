#Section 5
##1 - Rolling updates and rollback

Kubernetes add versioning when deploying `deployments`  

###See the rollout
`kubectl rollout status deployment/myapp-deployment`  
`kubectl rollout history deployment/my-deployment`

###Tow types of deployment strategies
* Destroy all and recreate all (Recreate)
* Take down some and update them (Rolling Update) <- Default strategy

`kubectl apply` will do a rollout if the object has changed

###What happens when upgrading?

1. When first creating a deployment, the kubernetes deployment creates a replicaset
2. When upgrading, the deployment is creating another replicaset
   * Can be seen if listing the replicaset when doing an upgrade 
3. Take down the pods in the old replicaset and start pod in new replicaset

###Rollback
`kubectl rollout undo deployment/my-deployment` 

##2 - Configure applications
###2.1 - Commands

Reminder:
Containers are meant to run tasks   
Once the task is done, we can exit  

* `CMD` : command run when the container is ran
* `ENTRYPOINT` : Content of `CMD` is passed to the `ENTRYPOINT`  

####How to change the command in docker image?
* `CLI` : add at the end of docker run
* `DOCKERFILE` : Change the `CMD`

####How to override the entrypoint?
`docker run --entrypoint sleep2.0 ubuntu-sleeper 10`

####Commands and arguments in kubernetes POD
See [pod-command.yaml](pod-command.yaml)

###2-2 Environment Variables
They can be added as key-value pair, from secrets or configmaps  

See [pod-environmentvariables](pod-environmentvariables.yaml)

###2.3 Secrets
Store data in hashed format
See [pod-environmentvariables](pod-environmentvariables.yaml)

You need to pass data in base64 encoded format

You can also create a volume from the secret  
In which case, each secret creates a file with the key as name of the file  

Of course, secrets are not inherently safe. Anyone can base64 decode them  
Still more secure

* A secret is only sent to a node if a pod on that node requires it.
* Kubelet stores the secret into a tmpfs so that the secret is not written to disk storage.
* Once the Pod that depends on the secret is deleted, kubelet will delete its local copy of the secret data as well.
