param (
    [string]$op,
    [string]$installIngress = "",
    [string]$installRollouts = ""
)

$k8sVersion = "v1.29.0"
$rolloutsVersion = "v1.6.0"
$clusterName = "local-cci-demo-cluster"
$context = "kind-$clusterName"

function Cleanup-Cluster {
    Write-Host "Cleaning up Kind cluster $clusterName..."
    & kind delete cluster --name $clusterName
    Write-Host "Done."
}

function Init-K8s {
    $currentCluster = kind get clusters 2>&1 | Select-String -Pattern $clusterName

    if ($currentCluster) {
        Write-Host "cluster is already initialized, if this is an error run kind delete cluster --name $clusterName to manually delete it"
        exit
    }

    Write-Host "Initializing Kind cluster $clusterName with k8s-version $k8sVersion..."
    $kind_cmd = "kind create cluster --name $clusterName --image kindest/node:$k8sVersion"
    
   if ($installIngress -eq "install-ingress") {
        Write-Host "adding nginx ingress controller to the installation"
        $kind_cmd += " --config=scripts/kind-ingress-mappings.yaml"
    }

    Invoke-Expression $kind_cmd

    Write-Host "Done."
}

function Check-K8sContext {
    $currentK8sContext = kubectl config current-context
    if ($context -ne $currentK8sContext) {
        Write-Host "Expected current Kubernetes context of kind-'$clusterName' but got '$currentK8sContext'. Updating context."
        kubectl config use-context $context
    }
}

function Install-MetricsServer {
    Write-Host "Installing k8s metrics server..."
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.3/components.yaml
    kubectl patch deployment metrics-server --namespace kube-system --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/command", "value": ["/metrics-server", "--kubelet-insecure-tls", "--kubelet-preferred-address-types=InternalIP"]}]'
    Write-Host "Done."
}

function Install-ArgoRollouts {
    Write-Host "Installing Argo Rollouts with version $rolloutsVersion..."
    if (-not (kubectl get namespace argo-rollouts -o jsonpath='{.metadata.name}' 2>$null)) {
        kubectl create namespace argo-rollouts
    }
    if ($rolloutsVersion -eq "latest") {
        kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
    } else {
        kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/download/$rolloutsVersion/install.yaml
    }
    Write-Host "Done."
}

function Install-NginxIngress {
    Write-Host "Installing NGINX Ingress controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    Write-Host "Done."
}

function Start-LocalCluster {
    Write-Host "Starting local cluster setup..."
    Init-K8s
    Check-K8sContext
    if ($installRollouts -eq "install-argo-rollouts") {
        Install-MetricsServer
        Install-ArgoRollouts
    }
    if ($installIngress -eq "install-ingress") {
        Install-NginxIngress
    }
}

function Destroy-Cluster {
    Write-Host "Destroying $clusterName local k8s cluster."
    Cleanup-Cluster
}

if (-not (Get-Command kind -ErrorAction SilentlyContinue)) {
    Write-Host "Looks like kind is not installed. Please refer to the official guideline to install it https://kind.sigs.k8s.io/docs/user/quick-start before executing this script"
    exit 0
}

switch ($op) {
    "setup-local-cluster" {
        Write-Host "Setting up $clusterName local cluster"
        Start-LocalCluster
    }
    "destroy-local-cluster" {
        Destroy-Cluster
    }
    default {
        Write-Host "Valid options are setup-local-cluster or destroy-local-cluster"
    }
}
