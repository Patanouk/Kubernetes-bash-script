#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -n|--node)
    NODE="$2"
    shift
    shift
    ;;
	*)
	echo "Unknown flag $1, will be ignored"
	shift
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ -z "$NODE" ]
	then
		echo "Usage : -n || --node"
		exit 1
fi
echo "Listing pod resources for node $NODE"

kubectl get pods --all-namespaces -o wide | grep $NODE | grep Running | awk '{print $1" "$2}' | xargs -n2 kubectl top pods --no-headers --namespace | sort -t ' ' --key 2 --numeric --reverse
