#!/bin/bash
# Overridden on package
SCRIPT_VERSION="unreleased"
echo "Running cleanup.sh version ${SCRIPT_VERSION}"

# Warning
echo "==================== WARNING ===================="
echo "THIS WILL DELETE ALL RESOURCES CREATED BY RANCHER"
echo "MAKE SURE YOU HAVE CREATED AND TESTED YOUR BACKUPS"
echo "THIS IS A NON REVERSIBLE ACTION"
echo "==================== WARNING ===================="

# Linux only for now
if [ "$(uname -s)" != "Linux" ]; then
  echo "Must be run on Linux"
  exit 1
fi

# Check kubectl existence
if ! type kubectl >/dev/null 2>&1; then
  echo "kubectl not found in PATH, make sure kubectl is available"
  exit 1
fi

# Check timeout existence
if ! type timeout >/dev/null 2>&1; then
  echo "timeout not found in PATH, make sure timeout is available"
  exit 1
fi


# Test connectivity
if ! kubectl get nodes >/dev/null 2>&1; then
  echo "'kubectl get nodes' exited non-zero, make sure environment variable KUBECONFIG is set to a working kubeconfig file"
  exit 1
fi

echo "=> Printing cluster info for confirmation"
kubectl cluster-info
kubectl get nodes -o wide

kcpf()
{
  FINALIZERS=$(kubectl get -o jsonpath="{.metadata.finalizers}" "$@")
  if [ "x${FINALIZERS}" != "x" ]; then
      echo "Finalizers before for ${*}: ${FINALIZERS}"
      kubectl patch -p '{"metadata":{"finalizers":null}}' --type=merge "$@"
      echo "Finalizers after for ${*}: $(kubectl get -o jsonpath="{.metadata.finalizers}" "${*}")"
  fi
}


printapiversion()
{
if echo "$1" | grep -q '/'; then
  echo "$1" | cut -d'/' -f1
else
  echo ""
fi
}

set -x
# Namespaces with resources that probably have finalizers/dependencies (needs manual traverse to patch and delete else it will hang)
CATTLE_NAMESPACES="local cattle-system cattle-impersonation-system cattle-global-data cattle-global-nt"
TOOLS_NAMESPACES="istio-system cattle-resources-system cis-operator-system cattle-dashboards cattle-gatekeeper-system cattle-alerting cattle-logging cattle-pipeline cattle-prometheus rancher-operator-system cattle-monitoring-system cattle-logging-system cattle-elemental-system"
FLEET_NAMESPACES="cattle-fleet-clusters-system cattle-fleet-local-system cattle-fleet-system fleet-default fleet-local fleet-system"


# Delete generic k8s resources either labeled with norman or resource name starting with "cattle|rancher|fleet"
# ClusterRole/ClusterRoleBinding
kubectl get clusterrolebinding -l cattle.io/creator=norman --no-headers -o custom-columns=NAME:.metadata.name | while read -r CRB; do
  kcpf clusterrolebindings "$CRB"
done

kubectl get clusterrolebinding --no-headers -o custom-columns=NAME:.metadata.name | grep ^cattle- | while read -r CRB; do
  kcpf clusterrolebindings "$CRB"
done

kubectl get clusterrolebinding --no-headers -o custom-columns=NAME:.metadata.name | grep rancher | while read -r CRB; do
  kcpf clusterrolebindings "$CRB"
done

kubectl get clusterrolebinding --no-headers -o custom-columns=NAME:.metadata.name | grep ^fleet- | while read -r CRB; do
  kcpf clusterrolebindings "$CRB"
done

kubectl get clusterrolebinding --no-headers -o custom-columns=NAME:.metadata.name | grep ^gitjob | while read -r CRB; do
  kcpf clusterrolebindings "$CRB"
done

kubectl get clusterrolebinding --no-headers -o custom-columns=NAME:.metadata.name | grep ^pod-impersonation-helm- | while read -r CRB; do
  kcpf clusterrolebindings "$CRB"
done

kubectl get clusterrolebinding --no-headers -o custom-columns=NAME:.metadata.name | grep ^gatekeeper | while read -r CRB; do
  kcpf clusterrolebindings "$CRB"
done

kubectl get clusterrolebinding --no-headers -o custom-columns=NAME:.metadata.name | grep ^cis | while read -r CRB; do
  kcpf clusterrolebindings "$CRB"
done

kubectl get clusterrolebinding --no-headers -o custom-columns=NAME:.metadata.name | grep ^istio | while read -r CRB; do
  kcpf clusterrolebindings "$CRB"
done

kubectl get clusterrolebinding --no-headers -o custom-columns=NAME:.metadata.name | grep ^elemental | while read -r CRB; do
  kcpf clusterrolebindings "$CRB"
done

kubectl  get clusterroles -l cattle.io/creator=norman --no-headers -o custom-columns=NAME:.metadata.name | while read -r CR; do
  kcpf clusterroles "$CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^cattle- | while read -r CR; do
  kcpf clusterroles "$CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep rancher | while read -r CR; do
  kcpf clusterroles "$CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^fleet | while read -r CR; do
  kcpf clusterroles "$CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^gitjob | while read -r CR; do
  kcpf clusterroles "$CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^pod-impersonation-helm | while read -r CR; do
  kcpf clusterroles "$CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^logging- | while read -r CR; do
  kcpf clusterroles "$CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^monitoring- | while read -r CR; do
  kcpf clusterroles "$CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^gatekeeper | while read -r CR; do
  kcpf clusterroles "$CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^cis | while read -r CR; do
  kcpf clusterroles "$CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^istio | while read -r CR; do
  kcpf clusterroles "$CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^elemental | while read -r CR; do
  kcpf clusterroles "$CR"
done




# Get all namespaced resources and delete in loop
# Exclude helm.cattle.io and k3s.cattle.io to not break K3S/RKE2 addons
kubectl get "$(kubectl api-resources --namespaced=true --verbs=delete -o name| grep cattle\.io | grep -v helm\.cattle\.io | grep -v k3s\.cattle\.io | tr "\n" "," | sed -e 's/,$//')" -A --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | while read -r NAME NAMESPACE KIND APIVERSION; do
  kcpf -n "$NAMESPACE" "${KIND}.$(printapiversion "$APIVERSION")" "$NAME"
done

# Logging
kubectl get "$(kubectl api-resources --namespaced=true --verbs=delete -o name| grep logging\.banzaicloud\.io | tr "\n" "," | sed -e 's/,$//')" -A --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | while read -r NAME NAMESPACE KIND APIVERSION; do
  kcpf -n "$NAMESPACE" "${KIND}.$(printapiversion "$APIVERSION")" "$NAME"
done

kubectl get "$(kubectl api-resources --namespaced=true --verbs=delete -o name | grep -v events\.events\.k8s\.io | grep -v ^events$ | tr "\n" "," | sed -e 's/,$//')" -A --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | grep rancher-monitoring | while read -r NAME NAMESPACE KIND APIVERSION; do
  kcpf -n "$NAMESPACE" "${KIND}.$(printapiversion "$APIVERSION")" "$NAME"
done

# Monitoring
kubectl get "$(kubectl api-resources --namespaced=true --verbs=delete -o name| grep monitoring\.coreos\.com | tr "\n" "," | sed -e 's/,$//')" -A --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | while read -r NAME NAMESPACE KIND APIVERSION; do
  kcpf -n "$NAMESPACE" "${KIND}.$(printapiversion "$APIVERSION")" "$NAME"
done

# Gatekeeper
kubectl get "$(kubectl api-resources --namespaced=true --verbs=delete -o name| grep gatekeeper\.sh | tr "\n" "," | sed -e 's/,$//')" -A --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | while read -r NAME NAMESPACE KIND APIVERSION; do
  kcpf -n "$NAMESPACE" "${KIND}.$(printapiversion "$APIVERSION")" "$NAME"
done

# Cluster-api
kubectl get "$(kubectl api-resources --namespaced=true --verbs=delete -o name| grep cluster\.x-k8s\.io | tr "\n" "," | sed -e 's/,$//')" -A --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | while read -r NAME NAMESPACE KIND APIVERSION; do
  kcpf -n "$NAMESPACE" "${KIND}.$(printapiversion "$APIVERSION")" "$NAME"
done

# Get all non-namespaced resources and delete in loop
kubectl get "$(kubectl api-resources --namespaced=false --verbs=delete -o name| grep cattle\.io | tr "\n" "," | sed -e 's/,$//')" -A --no-headers -o name | while read -r NAME; do
  kcpf "$NAME"
done

# Logging
kubectl get "$(kubectl api-resources --namespaced=false --verbs=delete -o name| grep logging\.banzaicloud\.io | tr "\n" "," | sed -e 's/,$//')" -A --no-headers -o name | while read -r NAME; do
  kcpf "$NAME"
done

# Gatekeeper
kubectl get "$(kubectl api-resources --namespaced=false --verbs=delete -o name| grep gatekeeper\.sh | tr "\n" "," | sed -e 's/,$//')" -A --no-headers -o name | while read -r NAME; do
  kcpf "$NAME"
done


