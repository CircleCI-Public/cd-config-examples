#!/bin/bash

set -e

RED='\033[0;31m'
NC='\033[0m'
CYAN='\033[0;36m'

# Initialize default values
AGENT_NAMESPACE="circleci-release-agent-system"
KUBE_CONFIG="$HOME/.kube/config"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--cci-token)
            CCI_TOKEN="$2"
            shift 2
            ;;
        -n|--managed-namespaces)
            MANAGED_NAMESPACES="$2"
            shift 2
            ;;
        -a|--agent-namespace)
            AGENT_NAMESPACE="$2"
            shift 2
            ;;
        -k|--kube-config-path)
            KUBE_CONFIG="$2"
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

shift $((OPTIND - 1))

if [ -z "$(command -v helm)" ]; then
    echo "helm is not installed. Check the official website to install it:"
    echo -e "${CYAN}https://helm.sh/docs/intro/install${NC}"
    exit 1
fi

helm repo add release-agent https://circleci-public.github.io/cci-k8s-release-agent
helm repo update

if [ -z "$CCI_TOKEN" ]; then
    echo -e "${CYAN} Enter the CircleCI Integration token created \n at https://app.circleci.com/releases in the environments section:${NC}"
    read -s CCI_TOKEN
fi


if [ -z "$MANAGED_NAMESPACES" ]; then
    echo -e "${CYAN} Enter a comma separated list of namespaces that the k8s agent should watch:${NC}"
    read  MANAGED_NAMESPACES
fi

helm upgrade --install cci-release-agent release-agent/circleci-release-agent \
    --set tokenSecret.token=$CCITOKEN --create-namespace \
    --set "managedNamespaces={$MANAGED_NAMESPACES}" \
    --namespace $AGENT_NAMESPACE
    --kubeconfig $KUBE_CONFIG
