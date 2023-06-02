#!/bin/bash

NS_TYPES=$(kubectl api-resources --verbs=list -o name --namespaced=true | grep "cattle.io")
CLUSTER_TYPES=$(kubectl api-resources --verbs=list -o name --namespaced=false | grep "cattle.io")

# Remove finalizers from namespaced Rancher resources
echo "Removing finalizers from namespaced Rancher resources"
for type in $NS_TYPES; do
    echo "Removing finalizers for $type"
    kubectl get $type --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace','NAME:.metadata.name' --no-headers | awk '{print $1 " " $2}' | while read -r namespace name; do 
    resource="$type/$name"
    kubectl patch "$resource" -n "$namespace" --type=merge -p "$(kubectl get "$resource" -n "$namespace" -o json | jq -Mcr '.metadata.finalizers // [] | {metadata:{finalizers:map(select(. | (contains("controller.cattle.io/") or contains("wrangler.cattle.io/")) | not ))}}')"
done
done

# Remove finalizers from cluster Rancher resources
echo "Removing finalizers from cluster Rancher resources"
for type in $CLUSTER_TYPES; do
    echo "Removing finalizers for $type"
    kubectl get $type -o name --show-kind --no-headers | while read -r name; do
        kubectl patch "$name" --type=merge -p "$(kubectl get "$name" -o json | jq -Mcr '.metadata.finalizers // [] | {metadata:{finalizers:map(select(. | (contains("controller.cattle.io/") or contains("wrangler.cattle.io/")) | not ))}}')"
    done
done