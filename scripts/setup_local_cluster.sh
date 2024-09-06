#!/bin/bash
set -eu

RED='\033[0;31m'
NC='\033[0m'
CYAN='\033[0;36m'

OP=$1
INSTALL_INGRESS=${2:-""}
INSTALL_ROLLOUTS=${3:-""}

K8S_VERSION="v1.29.0"
ROLLOUTS_VERSION="v1.6.0"
CLUSTER_NAME="local-cci-demo-cluster"
CONTEXT="kind-$CLUSTER_NAME"


cleanup_cluster() {
    echo -e "${CYAN}Cleaning up Kind cluster $CLUSTER_NAME...${NC}"
    kind delete cluster --name $CLUSTER_NAME
    echo -e "${CYAN}Done.${NC}"
}

init_k8s() {
    CURRENT_CLUSTER=`kind get clusters 2>&1 | { grep $CLUSTER_NAME || true; }`
    if [ -n "$CURRENT_CLUSTER" ]
    then
      echo "cluster is already initialized, if this is an error run kind delete cluster --name $CLUSTER_NAME to manually delete it"
      exit 0
    fi

    echo -e "${CYAN}Initializing Kind cluster $CLUSTER_NAME with k8s-version $K8S_VERSION...${NC}"
    kind_cmd=(kind create cluster --name $CLUSTER_NAME --image kindest/node:$K8S_VERSION)
    
    if [ "$INSTALL_INGRESS" == "install-ingress" ]; then
      echo "adding nginx ingress controller to the installation"
      kind_cmd+=(--config=scripts/kind-ingress-mappings.yaml)
    fi

    "${kind_cmd[@]}"

    echo -e "${CYAN}Done.${NC}"
}

check_k8s_context() {
    current_k8s_context=$(kubectl config current-context)
    if [ $CONTEXT != "$current_k8s_context" ]; then
        echo -e "${RED}Expected current Kubernetes context of kind-'$CLUSTER_NAME' but got '$current_k8s_context'. Updating context.${NC}"
        kubectl config set-context $CONTEXT
    fi
}

install_metrics_server () {
  echo -e "${CYAN}Installing k8s metrics server..."
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.3/components.yaml
  kubectl patch deployment \
  metrics-server \
  --namespace kube-system \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/command", "value": [
  "/metrics-server",
  "--kubelet-insecure-tls",
  "--kubelet-preferred-address-types=InternalIP",
  ]}]'
  
  echo -e "${CYAN}Done.${NC}"
}

install_argo_rollouts() {
    echo -e "${CYAN}Installing Argo Rollouts with version $ROLLOUTS_VERSION...${NC}"
    # Install Argo Rollouts https://argoproj.github.io/argo-rollouts/
    kubectl create namespace argo-rollouts
    if [ $ROLLOUTS_VERSION == "latest" ];
    then
      kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
    else
      kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/download/$ROLLOUTS_VERSION/install.yaml
    fi
    echo -e "${CYAN}Done.${NC}"
}

start_local_cluster() {
    init_k8s
    check_k8s_context
    if [ "$INSTALL_ROLLOUTS" == "install-argo-rollouts" ]; then
      install_metrics_server
      install_argo_rollouts
    fi

    if [ "$INSTALL_INGRESS" == "install-ingress" ]; then 
      kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    fi
}

destroy_cluster(){
  echo -e "${CYAN}destroying $CLUSTER_NAME local k8s cluster.${NC}"
  cleanup_cluster
}

if [ -z "$(command -v kind)" ]
then
    echo "looks like kind is not installed. Please refer to the official guideline to install it https://kind.sigs.k8s.io/docs/user/quick-start before executing this script"
    exit 0
fi

trap destroy_cluster SIGINT

case $OP in
  setup-local-cluster)
    echo "setting up $CLUSTER_NAME local cluster"
    start_local_cluster
    ;;

  destroy-local-cluster)
    destroy_cluster
    ;;
  *)
    echo -e "${CYAN} valid options are setup-local-cluster or destroy-local-cluster"
    ;;
esac
