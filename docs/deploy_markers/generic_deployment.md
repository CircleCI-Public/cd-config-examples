# Generic Deployment with Deploy Markers

This guide shows how to track any deployment using CircleCI deploy markers. This approach works for any deployment target, whether you're deploying to servers, cloud platforms, CDNs, or any other infrastructure.

## Overview

Deploy markers provide a lightweight way to track deployments without installing any agent. You simply add CLI commands to your CircleCI config to log deployment events.

## Pre-requisites

- A CircleCI account with a project set up
- An environment integration created in CircleCI (see [onboarding guide](../../guidelines/deploy-markers-onboarding.md#1-create-an-environment-integration))

## Quick Start

### Simple deployment logging

The simplest approach—just log when a deployment happens:

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
            # Replace with your actual deployment commands
            echo "Deploying version $(cat version)..."
            # ./deploy.sh
      - run:
          name: Log deployment to CircleCI
          command: |
            circleci run release log \
              --environment-name=production \
              --component-name=my-application \
              --target-version=$(cat version)

workflows:
  deploy-workflow:
    jobs:
      - deploy:
          filters:
            branches:
              only: main
```

## Full Example: Deployment with Status Tracking

For more comprehensive tracking with deployment lifecycle status:

```yaml
version: 2.1

commands:
  get_version:
    description: "Get application version"
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
      DEPLOY_NAME: production-deploy
      ENVIRONMENT_NAME: production
      COMPONENT_NAME: my-application
    steps:
      - checkout
      - get_version
      
      # Step 1: Plan the deployment
      - run:
          name: Plan deployment
          command: |
            circleci run release plan $DEPLOY_NAME \
              --environment-name=$ENVIRONMENT_NAME \
              --component-name=$COMPONENT_NAME \
              --target-version=$VERSION
      
      # Step 2: Execute deployment
      - run:
          name: Deploy application
          command: |
            echo "Deploying $COMPONENT_NAME version $VERSION to $ENVIRONMENT_NAME..."
            # Add your deployment commands here
            # For example:
            # - SSH to server and pull new code
            # - Run database migrations
            # - Restart services
            # - Update load balancer
      
      # Step 3: Update status to RUNNING
      - run:
          name: Update status to RUNNING
          command: |
            circleci run release update $DEPLOY_NAME --status=RUNNING
      
      # Step 4: Validate deployment
      - run:
          name: Validate deployment
          command: |
            echo "Validating deployment..."
            # Add validation commands here
            # For example:
            # - Health check endpoints
            # - Smoke tests
            # - Monitor for errors
            
            # If validation fails, save the reason
            # if ! ./health_check.sh; then
            #   echo "FAILURE_REASON='Health check failed'" > failure_reason.env
            #   exit 1
            # fi
      
      # Step 5: Update final status
      - run:
          name: Update deployment to SUCCESS
          command: |
            circleci run release update $DEPLOY_NAME --status=SUCCESS
          when: on_success
      
      - run:
          name: Update deployment to FAILED
          command: |
            if [ -f failure_reason.env ]; then
              source failure_reason.env
            fi
            circleci run release update $DEPLOY_NAME \
              --status=FAILED \
              --failure-reason="${FAILURE_REASON:-Deployment failed}"
          when: on_fail

  cancel-deploy:
    docker:
      - image: cimg/base:current
    environment:
      DEPLOY_NAME: production-deploy
    steps:
      - run:
          name: Update deployment to CANCELED
          command: |
            circleci run release update $DEPLOY_NAME --status=CANCELED

workflows:
  deploy-workflow:
    jobs:
      - deploy:
          filters:
            branches:
              only: main
      - cancel-deploy:
          requires:
            - deploy:
              - canceled
```

## CircleCI Config Files

Ready-to-use CircleCI config files are available:
- [Generic deploy markers config](../../.circleci/deploy_markers_config.yml) - Template for any deployment target
- [Kubernetes deploy markers config](../../.circleci/deploy_markers_k8s_config.yml) - K8s without the release agent
- [AWS ECS deploy markers config](../../.circleci/deploy_markers_aws_ecs_config.yml) - ECS/Fargate deployments
- [AWS Lambda deploy markers config](../../.circleci/deploy_markers_aws_lambda_config.yml) - Lambda deployments

To use any of these:
1. Copy or rename the file to `.circleci/config.yml`
2. Update the environment variables (`ENVIRONMENT_NAME`, `COMPONENT_NAME`, `DEPLOY_NAME`)
3. Replace the placeholder deployment commands with your actual deployment logic
4. Create a "Custom" environment integration in CircleCI
5. Push to your repository

## Versioning Strategies

Choose a version format that matches your release process:

### Semantic versioning from a file

```yaml
- run:
    command: |
      circleci run release log \
        --target-version=$(cat version)
```

### Git commit SHA

```yaml
- run:
    command: |
      circleci run release log \
        --target-version=$CIRCLE_SHA1
```

### Git tag (for tagged releases)

```yaml
- run:
    command: |
      circleci run release log \
        --target-version=$CIRCLE_TAG
```

### Build number

```yaml
- run:
    command: |
      circleci run release log \
        --target-version="build-$CIRCLE_BUILD_NUM"
```

### Pipeline number

```yaml
- run:
    command: |
      circleci run release log \
        --target-version=<< pipeline.number >>
```

## Multi-Environment Deployments

Track deployments across different environments:

```yaml
version: 2.1

jobs:
  deploy:
    docker:
      - image: cimg/base:current
    parameters:
      environment:
        type: string
    steps:
      - checkout
      - run:
          name: Deploy to << parameters.environment >>
          command: |
            ./deploy.sh << parameters.environment >>
      - run:
          name: Log deployment
          command: |
            circleci run release log \
              --environment-name=<< parameters.environment >> \
              --component-name=my-app \
              --target-version=$(cat version)

workflows:
  deploy:
    jobs:
      - deploy:
          name: deploy-staging
          environment: staging
      - hold:
          type: approval
          requires:
            - deploy-staging
      - deploy:
          name: deploy-production
          environment: production
          requires:
            - hold
```

## Next Steps

- View your deployments in the [CircleCI Deploys Dashboard](https://app.circleci.com/releases)
- Learn about [AWS-specific deployment tracking](./aws_deployment.md)
- Explore [Kubernetes deployment tracking](./kubernetes_deployment.md) for K8s-specific options

