#Section 5
##Rolling updates and rollback

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