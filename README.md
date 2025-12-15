# CD Config Examples

This repository provides a set of guidelines and examples that demonstrate how to implement continuous delivery (CD) using CircleCI.

## Introduction

Continuous delivery (CD) is a software development practice in which code changes are automatically built, tested, and prepared for a release to production. Continuous delivery is an extension of continuous integration (CI), taking the concept a step further by deploying all code changes after the build stage.

An effective CI/CD setup monitors to ensure that the newly released version is in a stable state and ready to take on more responsibility or be promoted to other environments. This practice ensures that you can release a new version of your software quickly and sustainably, without dedicating resources to oversee the deployment of your software.

The examples in this repo are designed to help you implement robust CI/CD pipelines using CircleCI. It contains practical examples and guidelines, providing a hands-on approach to setting up your own continuous delivery pipelines.

## Deployment Tracking Options

CircleCI provides two approaches to track deployments:

| Feature | Release Agent | Deploy Markers |
|---------|---------------------------|---------------------------|
| **Setup complexity** | Requires agent installation in cluster | No installation required |
| **Supported targets** | Kubernetes only | Any deployment target |
| **Status updates** | Automatic | Manual via CLI commands |
| **Rollback support** | Yes (via UI) | Yes (via rollback.yml file) |
| **Scaling/Restart controls** | Yes (via UI) | No |
| **Best for** | Kubernetes with full control | AWS, GCP, Heroku, any target |

### Agent-based (Kubernetes Release Agent)

The CircleCI Release Agent is installed in your Kubernetes cluster and automatically tracks deployments. It provides advanced controls like rollback, scaling, and restart directly from the CircleCI UI.

**Use when:** You deploy to Kubernetes and want automatic tracking with operational controls.

### Deploy Markers

Deploy markers are CLI commands added to your CircleCI config that log deployment events. No agent installation required—works with any deployment target.

**Use when:** You deploy to non-Kubernetes targets, want simpler setup, or can't install agents.

## Examples

### Agent-based (Kubernetes Release Agent)

* [Kubernetes release agent onboarding](./guidelines/k8s-release-agent-onboarding.md): Install and configure the CircleCI Kubernetes Release Agent for automatic deployment tracking with rollback, scaling, and restart controls.

#### Deploy via CircleCI with the Release Agent

- [Deploy a Deployment workload using Kubectl](./docs/cci_deploy/deployment_kubectl.md)
- [Deploy an Argo Rollouts workload using Kubectl](./docs/cci_deploy/rollout_kubectl.md)
- [Deploy a Deployment workload using Kustomize](./docs/cci_deploy/deployment_kustomize.md)
- [Deploy an Argo Rollouts Workload using Kustomize](./docs/cci_deploy/rollout_kustomize.md)
- [Deploy a Deployment workload using Helm](./docs/cci_deploy/deployment_helm.md)
- [Deploy an Argo Rollouts Workload using Helm](./docs/cci_deploy/rollout_helm.md)

### Deploy Markers

* [Deploy markers onboarding](./guidelines/deploy-markers-onboarding.md): Track deployments to any target using CLI commands—no agent required.

#### Deploy via CircleCI with Deploy Markers

- [Generic deployment with deploy markers](./docs/deploy_markers/generic_deployment.md): Track any deployment target
- [AWS deployment with deploy markers](./docs/deploy_markers/aws_deployment.md): Track ECS, Lambda, S3, and other AWS deployments
- [Kubernetes deployment with deploy markers](./docs/deploy_markers/kubernetes_deployment.md): Lightweight K8s tracking without the agent

#### CircleCI Config Examples for Deploy Markers

- [Generic deploy markers config](./\.circleci/deploy_markers_config.yml): Template for any deployment
- [AWS ECS deploy markers config](./.circleci/deploy_markers_aws_ecs_config.yml): ECS/Fargate deployment tracking
- [Kubernetes deploy markers config](./.circleci/deploy_markers_k8s_config.yml): K8s deployment without the agent

## Quick Start

### Option 1: Deploy Markers (Fastest Setup)

1. Create a "Custom" environment integration in CircleCI
2. Add deploy marker commands to your CircleCI config:

```yaml
jobs:
  deploy:
    docker:
      - image: cimg/base:current
    steps:
      - checkout
      - run:
          name: Deploy application
          command: ./deploy.sh
      - run:
          name: Log deployment
          command: |
            circleci run release log \
              --environment-name=production \
              --component-name=my-app \
              --target-version=$CIRCLE_SHA1
```

3. View your deployments in the [CircleCI Deploys Dashboard](https://app.circleci.com/releases)

For full status tracking (planned → RUNNING → SUCCESS/FAILED), see the [deploy markers onboarding guide](./guidelines/deploy-markers-onboarding.md).

### Option 2: Agent-based (Kubernetes)

1. Create a "Kubernetes Cluster" environment integration in CircleCI
2. Install the release agent in your cluster
3. Add CircleCI annotations and labels to your Kubernetes manifests
4. Deploy via CircleCI

See the [Kubernetes release agent onboarding guide](./guidelines/k8s-release-agent-onboarding.md) for detailed instructions.

## Repository Structure

```
├── .circleci/                     # CircleCI config examples
│   ├── config.yml                 # Main config (Helm + release agent)
│   ├── deploy_markers_config.yml  # Generic deploy markers
│   ├── deploy_markers_aws_ecs_config.yml
│   ├── deploy_markers_k8s_config.yml
│   ├── deploy_k8s_cli_config.yml
│   ├── deployment_helm_config.yml
│   └── ...
├── docs/
│   ├── cci_deploy/               # Agent-based deployment guides
│   ├── deploy_markers/           # Deploy markers guides
│   └── onboarding_appendix.md
├── examples/
│   ├── helm/                     # Helm chart examples
│   ├── k8s_cli/                  # Kubectl manifest examples
│   └── kustomize/                # Kustomize examples
├── guidelines/
│   ├── k8s-release-agent-onboarding.md  # Agent setup guide
│   └── deploy-markers-onboarding.md     # Deploy markers setup guide
└── scripts/                      # Helper scripts
```

> [!NOTE]
> As time progresses, more guidelines will be added to this repository, and existing ones will be updated to reflect the evolution of CircleCI's Continuous Delivery offerings. Stay tuned for these enhancements.
