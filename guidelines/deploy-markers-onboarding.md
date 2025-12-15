# Deployment Tracking with Deploy Markers

This guide provides instructions on tracking deployments using CircleCI deploy markers. Deploy markers allow you to track deployments to **any target** (Kubernetes, AWS, GCP, Azure, Heroku, etc.) without installing an agent.

## Table of contents

- [Deployment Tracking with Deploy Markers](#deployment-tracking-with-deploy-markers)
  - [Table of contents](#table-of-contents)
  - [Key Terms](#key-terms)
  - [Release Agent vs Deploy Markers](#release-agent-vs-deploy-markers)
    - [When to use the Release Agent](#when-to-use-the-release-agent)
    - [When to use Deploy Markers](#when-to-use-deploy-markers)
  - [Benefits of Deploy Markers](#benefits-of-deploy-markers)
  - [Quick Start: Track your first deployment in 3 steps](#quick-start-track-your-first-deployment-in-3-steps)
    - [1. Create an Environment Integration](#1-create-an-environment-integration)
    - [2. Add deploy markers to your CircleCI config](#2-add-deploy-markers-to-your-circleci-config)
    - [3. View your deployments](#3-view-your-deployments)
  - [Deploy Marker Commands Reference](#deploy-marker-commands-reference)
    - [Plan a deployment with status tracking](#plan-a-deployment-with-status-tracking)
    - [Update deployment status](#update-deployment-status)
    - [Log a deployment without status tracking](#log-a-deployment-without-status-tracking)
  - [Full Configuration Examples](#full-configuration-examples)
    - [Basic deployment logging](#basic-deployment-logging)
    - [Full status tracking with SUCCESS/FAILED handling](#full-status-tracking-with-successfailed-handling)
    - [Multiple environments from a single workflow](#multiple-environments-from-a-single-workflow)
  - [Handling Canceled Deployments](#handling-canceled-deployments)
  - [Next Steps](#next-steps)

## Key Terms

- **Deploy Marker**: A CircleCI CLI command that logs deployment events to CircleCI's deploys dashboard without requiring an agent.

- **Environment Integration**: A configuration in CircleCI that represents a deployment target environment (e.g., production, staging). For deploy markers, use the "Custom" type.

- **Component**: A deployable unit that you want to track. This could be a microservice, application, or any piece of software you deploy.

- **Target Version**: The version identifier of what you're deploying. This could be a semantic version (v1.2.3), commit SHA, or any string that identifies the release.

## Release Agent vs Deploy Markers

CircleCI offers two approaches to track deployments:

| Feature | Release Agent | Deploy Markers |
|---------|---------------------------|---------------------------|
| **Setup complexity** | Requires agent installation in cluster | No installation required |
| **Supported targets** | Kubernetes only | Any deployment target |
| **Status updates** | Automatic | Manual via CLI commands |
| **Rollback support** | Yes (via UI) | Yes (via rollback.yml file) |
| **Scaling controls** | Yes (via UI) | No |
| **Restart controls** | Yes (via UI) | No |
| **Release promotion** | Yes (for Argo Rollouts) | No |

### When to use the Release Agent

Use the [CircleCI Release Agent](./k8s-release-agent-onboarding.md) when:
- You deploy to Kubernetes
- You want automatic status tracking
- You need scaling or restart controls from the CircleCI UI
- You're using Argo Rollouts and want promotion controls

### When to use Deploy Markers

Use Deploy Markers when:
- You deploy to non-Kubernetes targets (AWS ECS, Lambda, Heroku, etc.)
- You want lightweight deployment tracking without installing anything
- You prefer explicit control over deployment status updates
- Your deployment target doesn't allow agent installation

## Benefits of Deploy Markers

- **Universal**: Works with any deployment target - Kubernetes, AWS, GCP, Azure, Heroku, on-premise servers, and more
- **No installation required**: Simply add CLI commands to your CircleCI config
- **Centralized visibility**: View all deployments across environments in one dashboard
- **Flexible status tracking**: Choose between simple logging or full status lifecycle tracking
- **Pipeline integration**: Links deployments to commits, workflows, and jobs automatically

## Quick Start: Track your first deployment in 3 steps

### 1. Create an Environment Integration

1. In the [CircleCI web app](https://app.circleci.com/home/), select your organization
2. Select **Deploys** in the sidebar
3. Select the **Environments** tab and click **Create Environment Integration**
4. Enter a name for your environment (e.g., "production", "staging")
5. Select **Custom** as the integration type
6. Click **Save and Continue**

> [!NOTE]
> Unlike the release agent setup, you don't need to install anything when using deploy markers. The "Custom" environment type is designed for deploy markers.

### 2. Add deploy markers to your CircleCI config

Add the `circleci run release log` command to your deployment job:

```yaml
version: 2.1

jobs:
  deploy:
    docker:
      - image: cimg/base:current
    steps:
      - checkout
      - run:
          name: Deploy application
          command: |
            # Your deployment commands here
            echo "Deploying to production..."
      - run:
          name: Log deployment
          command: |
            circleci run release log \
              --environment-name=production \
              --component-name=my-service \
              --target-version=$CIRCLE_SHA1

workflows:
  deploy-workflow:
    jobs:
      - deploy:
          filters:
            branches:
              only: main
```

### 3. View your deployments

After the workflow runs, view your deployment in the [CircleCI Deploys Dashboard](https://app.circleci.com/releases). You'll see:
- The component name
- The target version
- The environment
- A link to the triggering commit and workflow

## Deploy Marker Commands Reference

### Plan a deployment with status tracking

Use `circleci run release plan` when you want to track the full lifecycle of a deployment (planned → RUNNING → SUCCESS/FAILED).

```bash
circleci run release plan <deploy-name> \
  --target-version=<version> \
  [--environment-name=<env>] \
  [--component-name=<component>] \
  [--namespace=<namespace>]
```

**Parameters:**
- `<deploy-name>` (required): A unique identifier for this deployment (e.g., "production-deploy")
- `--target-version` (required): The version being deployed
- `--environment-name` (optional): Target environment name. Creates the environment if it doesn't exist
- `--component-name` (optional): Name displayed in the CircleCI UI
- `--namespace` (optional): Namespace for the deployment (defaults to "default")

**Version formats:**

You can use various version formats:

```yaml
# Semantic version
--target-version=v1.2.3

# Git SHA
--target-version=$CIRCLE_SHA1

# Git tag
--target-version=$CIRCLE_TAG

# Pipeline number
--target-version=<< pipeline.number >>

# Custom format
--target-version="build-${CIRCLE_BUILD_NUM}"
```

### Update deployment status

Use `circleci run release update` to update the status of a planned deployment.

```bash
circleci run release update <deploy-name> \
  --status=<status> \
  [--failure-reason=<reason>]
```

**Status values:**
- `RUNNING`: Deployment is in progress
- `SUCCESS`: Deployment completed successfully
- `FAILED`: Deployment failed
- `CANCELED`: Deployment was canceled

> [!IMPORTANT]
> The `circleci run release update` command is **only for use with deploy markers**. If you're using the CircleCI release agent for Kubernetes deployments, do NOT use the update commands—the release agent handles status updates automatically.

### Log a deployment without status tracking

Use `circleci run release log` for simple deployment logging without status lifecycle tracking.

```bash
circleci run release log \
  --target-version=<version> \
  [--environment-name=<env>] \
  [--component-name=<component>] \
  [--namespace=<namespace>]
```

This is simpler than `plan`/`update` when you just want to log that a deployment happened without tracking its status over time.

## Full Configuration Examples

### Basic deployment logging

The simplest way to track deployments—just log that it happened:

```yaml
version: 2.1

jobs:
  deploy:
    docker:
      - image: cimg/base:current
    steps:
      - checkout
      - run:
          name: Deploy to production
          command: |
            # Your deployment logic here
            ./deploy.sh
      - run:
          name: Log deployment
          command: |
            circleci run release log \
              --environment-name=production \
              --component-name=my-app \
              --target-version=$(cat version)

workflows:
  deploy:
    jobs:
      - deploy
```

### Full status tracking with SUCCESS/FAILED handling

For complete deployment lifecycle tracking with status updates:

```yaml
version: 2.1

jobs:
  deploy:
    docker:
      - image: cimg/base:current
    steps:
      - checkout
      - run:
          name: Plan deployment
          command: |
            circleci run release plan production-deploy \
              --environment-name=production \
              --component-name=my-app \
              --target-version=$(cat version)
      - run:
          name: Deploy application
          command: |
            # Your deployment logic here
            ./deploy.sh
      - run:
          name: Update status to RUNNING
          command: |
            circleci run release update production-deploy --status=RUNNING
      - run:
          name: Validate deployment
          command: |
            # Your validation logic here
            ./validate.sh || echo "FAILURE_REASON='Validation failed'" > failure_reason.env
      - run:
          name: Update deployment to SUCCESS
          command: |
            circleci run release update production-deploy --status=SUCCESS
          when: on_success
      - run:
          name: Update deployment to FAILED
          command: |
            if [ -f failure_reason.env ]; then
              source failure_reason.env
            fi
            circleci run release update production-deploy \
              --status=FAILED \
              --failure-reason="${FAILURE_REASON:-Deployment failed}"
          when: on_fail

  cancel-deploy:
    docker:
      - image: cimg/base:current
    steps:
      - run:
          name: Update deployment to CANCELED
          command: |
            circleci run release update production-deploy --status=CANCELED

workflows:
  deploy-workflow:
    jobs:
      - deploy
      - cancel-deploy:
          requires:
            - deploy:
              - canceled
```

### Multiple environments from a single workflow

When deploying to multiple environments, specify the environment for each:

```yaml
version: 2.1

jobs:
  deploy-staging:
    docker:
      - image: cimg/base:current
    steps:
      - checkout
      - run:
          name: Deploy to staging
          command: ./deploy.sh staging
      - run:
          name: Log staging deployment
          command: |
            circleci run release log \
              --environment-name=staging \
              --component-name=my-app \
              --target-version=$CIRCLE_SHA1

  deploy-production:
    docker:
      - image: cimg/base:current
    steps:
      - checkout
      - run:
          name: Deploy to production
          command: ./deploy.sh production
      - run:
          name: Log production deployment
          command: |
            circleci run release log \
              --environment-name=production \
              --component-name=my-app \
              --target-version=$CIRCLE_SHA1

workflows:
  deploy:
    jobs:
      - deploy-staging
      - hold:
          type: approval
          requires:
            - deploy-staging
      - deploy-production:
          requires:
            - hold
```

## Handling Canceled Deployments

If you want to update your deployment to `CANCELED` when the deploy job is canceled, add a separate job that only runs when the main deploy job is canceled:

```yaml
workflows:
  deploy-workflow:
    jobs:
      - deploy
      - cancel-deploy:
          requires:
            - deploy:
              - canceled
```

The `cancel-deploy` job will only run when the `deploy` job is explicitly canceled, updating the deployment status accordingly.

## Next Steps

- View your deployments in the [CircleCI Deploys Dashboard](https://app.circleci.com/releases)
- Learn about [rollback](https://circleci.com/docs/guides/deploy/rollback-a-deployment/) options
- Explore [agent-based deployment tracking](./k8s-release-agent-onboarding.md) for Kubernetes with advanced controls
- Check out example configurations:
  - [AWS deployment with deploy markers](../docs/deploy_markers/aws_deployment.md)
  - [Generic deployment with deploy markers](../docs/deploy_markers/generic_deployment.md)

