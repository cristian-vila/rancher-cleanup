#!/bin/bash

# Function to print finalizers for a resource
print_finalizers() {
    local resource_type=$1
    local namespace=$2
    local name=$3
    echo "Finalizers for $resource_type/$name:"
    kubectl get -n "$namespace" "$resource_type/$name" -o json | jq -Mcr '.metadata.finalizers // []'
}

# Remove finalizers from namespaced Rancher resources
echo "Removing finalizers from namespaced Rancher resources"
for type in $NS_TYPES; do
    echo "Removing finalizers for $type"
    kubectl get $type --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace','NAME:.metadata.name' --no-headers | awk '{print $1 " " $2}' | while read -r namespace name; do
        echo "Modifying $type/$name"
        echo "Finalizers before modification:"
        print_finalizers "$type" "$namespace" "$name"
        kubectl patch -n "$namespace" "$type/$name" --type=merge -p "$(kubectl get -n "$namespace" "$type/$name" -o json | jq -Mcr '.metadata.finalizers // [] | {metadata:{finalizers:map(select(. | (contains("controller.cattle.io/") or contains("wrangler.cattle.io/")) | not ))}}')"
        echo "Finalizers after modification:"
        print_finalizers "$type" "$namespace" "$name"
        echo ""
    done
done

# Remove finalizers from cluster Rancher resources
echo "Removing finalizers from cluster Rancher resources"
for type in $CLUSTER_TYPES; do
    echo "Removing finalizers for $type"
    kubectl get $type -o name --show-kind --no-headers | while read -r name; do
        echo "Modifying $type/$name"
        echo "Finalizers before modification:"
        print_finalizers "$type" "" "$name"
        kubectl patch "$type/$name" --type=merge -p "$(kubectl get "$type/$name" -o json | jq -Mcr '.metadata.finalizers // [] | {metadata:{finalizers:map(select(. | (contains("controller.cattle.io/") or contains("wrangler.cattle.io/")) | not ))}}')"
        echo "Finalizers after modification:"
        print_finalizers "$type" "" "$name"
        echo ""
    done
done