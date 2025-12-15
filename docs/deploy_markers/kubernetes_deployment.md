# Kubernetes Deployment with Deploy Markers

This guide shows how to track Kubernetes deployments using CircleCI deploy markers **without** installing the release agent.

## Overview

While CircleCI offers a [release agent](../../guidelines/k8s-release-agent-onboarding.md) for Kubernetes that provides automatic tracking and additional controls (scaling, restart from UI), you can also use deploy markers for a lightweight approach without installing an agent.

### When to Use Deploy Markers vs Release Agent

| Feature | Deploy Markers | Release Agent |
|---------|---------------------------|---------------|
| Setup complexity | None - just CLI commands | Agent installation required |
| Automatic status tracking | No - manual updates | Yes |
| Rollback support | Yes (via config) | Yes (via UI) |
| Scale/Restart from UI | No | Yes |
| Works offline/air-gapped | No | Yes (after initial setup) |
| Non-K8s workload support | Yes | No |

**Use deploy markers when:**
- You want the simplest possible setup
- You're already tracking non-K8s deployments with deploy markers and want consistency
- You can't install agents in your cluster

**Use the release agent when:**
- You want automatic status tracking
- You need scaling or restart controls from the CircleCI UI
- You're using Argo Rollouts and want promotion controls

## Pre-requisites

- A CircleCI account with a project set up
- KUBECONFIG_DATA environment variable with base64-encoded kubeconfig
- Kubernetes cluster access credentials configured

## Examples

### Simple Kubectl Deployment with Deploy Markers

```yaml
version: 2.1

orbs:
  kubernetes: circleci/kubernetes@1.3.1

commands:
  get_version:
    steps:
      - run:
          name: Get version
          command: |
            VERSION=$(cat version)
            echo "export VERSION='$VERSION'" >> $BASH_ENV

jobs:
  deploy:
    docker:
      - image: cimg/base:current
    environment:
      DEPLOY_NAME: k8s-production
      NAMESPACE: production
      COMPONENT_NAME: my-app
    steps:
      - checkout
      - get_version
      
      - kubernetes/install-kubectl
      - kubernetes/install-kubeconfig:
          kubeconfig: KUBECONFIG_DATA
      
      # Plan the deployment
      - run:
          name: Plan deployment
          command: |
            circleci run release plan $DEPLOY_NAME \
              --environment-name=production \
              --component-name=$COMPONENT_NAME \
              --target-version=$VERSION
      
      # Apply Kubernetes manifests
      - run:
          name: Deploy to Kubernetes
          command: |
            kubectl apply -f manifests/ -n $NAMESPACE
      
      # Update status to RUNNING
      - run:
          name: Update status to RUNNING
          command: |
            circleci run release update $DEPLOY_NAME --status=RUNNING
      
      # Wait for rollout to complete
      - run:
          name: Wait for rollout
          command: |
            kubectl rollout status deployment/$COMPONENT_NAME -n $NAMESPACE --timeout=300s
      
      # Update final status
      - run:
          name: Update deployment to SUCCESS
          command: |
            circleci run release update $DEPLOY_NAME --status=SUCCESS
          when: on_success
      
      - run:
          name: Update deployment to FAILED
          command: |
            circleci run release update $DEPLOY_NAME \
              --status=FAILED \
              --failure-reason="Kubernetes rollout failed"
          when: on_fail

workflows:
  deploy:
    jobs:
      - deploy
```

### Helm Deployment with Deploy Markers

```yaml
version: 2.1

orbs:
  kubernetes: circleci/kubernetes@1.3.1
  helm: circleci/helm@3.0.2

commands:
  get_version:
    steps:
      - run:
          name: Get version
          command: |
            VERSION=$(cat version)
            echo "export VERSION='$VERSION'" >> $BASH_ENV

jobs:
  deploy:
    docker:
      - image: cimg/base:current
    environment:
      DEPLOY_NAME: helm-production
      NAMESPACE: production
      RELEASE_NAME: my-app
      CHART_PATH: ./charts/my-app
    steps:
      - checkout
      - get_version
      
      - kubernetes/install-kubeconfig:
          kubeconfig: KUBECONFIG_DATA
      - helm/install_helm_client
      
      # Plan the deployment
      - run:
          name: Plan deployment
          command: |
            circleci run release plan $DEPLOY_NAME \
              --environment-name=production \
              --component-name=$RELEASE_NAME \
              --target-version=$VERSION
      
      # Deploy with Helm
      - run:
          name: Deploy with Helm
          command: |
            helm upgrade --install $RELEASE_NAME $CHART_PATH \
              --namespace $NAMESPACE \
              --create-namespace \
              --set image.tag=$VERSION \
              --wait \
              --timeout 5m
      
      # Update status to RUNNING
      - run:
          name: Update status to RUNNING
          command: |
            circleci run release update $DEPLOY_NAME --status=RUNNING
      
      # Validate deployment
      - run:
          name: Validate deployment
          command: |
            # Check pods are running
            kubectl get pods -n $NAMESPACE -l app=$RELEASE_NAME
            
            # Optional: Run smoke tests
            # ./smoke-tests.sh
      
      # Update final status
      - run:
          name: Update deployment to SUCCESS
          command: |
            circleci run release update $DEPLOY_NAME --status=SUCCESS
          when: on_success
      
      - run:
          name: Update deployment to FAILED
          command: |
            circleci run release update $DEPLOY_NAME \
              --status=FAILED \
              --failure-reason="Helm deployment failed"
          when: on_fail

workflows:
  deploy:
    jobs:
      - deploy
```

### Kustomize Deployment with Deploy Markers

```yaml
version: 2.1

orbs:
  kubernetes: circleci/kubernetes@1.3.1

commands:
  get_version:
    steps:
      - run:
          name: Get version
          command: |
            VERSION=$(cat version)
            TAG=$(echo $VERSION | sed 's/\./-/g')
            echo "export VERSION='$VERSION'" >> $BASH_ENV
            echo "export TAG='$TAG'" >> $BASH_ENV

jobs:
  deploy:
    docker:
      - image: cimg/base:current
    environment:
      DEPLOY_NAME: kustomize-production
      NAMESPACE: production
      COMPONENT_NAME: my-app
      OVERLAY: overlays/production
    steps:
      - checkout
      - get_version
      
      - kubernetes/install-kubectl
      - kubernetes/install-kubeconfig:
          kubeconfig: KUBECONFIG_DATA
      
      # Plan the deployment
      - run:
          name: Plan deployment
          command: |
            circleci run release plan $DEPLOY_NAME \
              --environment-name=production \
              --component-name=$COMPONENT_NAME \
              --target-version=$VERSION
      
      # Update kustomization with new image tag
      - run:
          name: Update image tag
          command: |
            cd $OVERLAY
            kustomize edit set image my-app=my-registry/my-app:$VERSION
      
      # Apply with Kustomize
      - run:
          name: Deploy with Kustomize
          command: |
            kubectl apply -k $OVERLAY -n $NAMESPACE
      
      # Update status to RUNNING
      - run:
          name: Update status to RUNNING
          command: |
            circleci run release update $DEPLOY_NAME --status=RUNNING
      
      # Wait for rollout
      - run:
          name: Wait for rollout
          command: |
            kubectl rollout status deployment/$COMPONENT_NAME -n $NAMESPACE --timeout=300s
      
      # Update final status
      - run:
          name: Update deployment to SUCCESS
          command: |
            circleci run release update $DEPLOY_NAME --status=SUCCESS
          when: on_success
      
      - run:
          name: Update deployment to FAILED
          command: |
            circleci run release update $DEPLOY_NAME \
              --status=FAILED \
              --failure-reason="Kustomize deployment failed"
          when: on_fail

workflows:
  deploy:
    jobs:
      - deploy
```

## Comparison: Deploy Markers vs Release Agent Configuration

### With Deploy Markers

Your Kubernetes manifests are standard—no special annotations or labels needed for CircleCI:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: my-app
          image: my-registry/my-app:v1.0.0
```

### With Release Agent

Your manifests need CircleCI-specific annotations and labels:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  annotations:
    circleci.com/project-id: ${CIRCLE_PROJECT_ID}
    circleci.com/pipeline-id: ${CIRCLE_PIPELINE_ID}
    circleci.com/workflow-id: ${CIRCLE_WORKFLOW_ID}
    circleci.com/job-number: "${CIRCLE_BUILD_NUM}"
  labels:
    circleci.com/component-name: my-app
    circleci.com/version: ${VERSION}
spec:
  replicas: 3
  selector:
    matchLabels:
      circleci.com/component-name: my-app
  template:
    metadata:
      labels:
        circleci.com/component-name: my-app
        circleci.com/version: ${VERSION}
    spec:
      containers:
        - name: my-app
          image: my-registry/my-app:v1.0.0
```

## Next Steps

- For additional controls (scaling, restart from UI), consider the [Release Agent](../../guidelines/k8s-release-agent-onboarding.md)
- View your deployments in the [CircleCI Deploys Dashboard](https://app.circleci.com/releases)
- Learn about [generic deployment tracking](./generic_deployment.md) for non-K8s targets

