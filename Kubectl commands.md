## Get pods resource requests

```shell
kubectl get pod --all-namespaces -o custom-columns="Name:metadata.name,Memory-request:spec.containers[*].resources.requests.memory,Cpu-request:spec.containers[*].resources.requests.cpu"
```