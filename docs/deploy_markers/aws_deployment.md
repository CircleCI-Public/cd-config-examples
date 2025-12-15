# AWS Deployment with Deploy Markers

This guide shows how to track AWS deployments (ECS, Lambda, S3, EC2, etc.) using CircleCI deploy markers.

## Overview

Deploy markers allow you to track deployments to AWS services without installing any agent. This is ideal for:
- ECS/Fargate deployments
- Lambda function updates
- S3 static site deployments
- EC2/Auto Scaling Group updates
- Elastic Beanstalk deployments

## Pre-requisites

- A CircleCI account with a project set up
- AWS credentials configured in CircleCI (via environment variables or OIDC)
- An environment integration created in CircleCI (type: "Custom")

## Examples

### ECS/Fargate Deployment

Track ECS service deployments with deploy markers:

```yaml
version: 2.1

orbs:
  aws-cli: circleci/aws-cli@4.1.3
  aws-ecs: circleci/aws-ecs@4.0.0

jobs:
  deploy-ecs:
    docker:
      - image: cimg/base:current
    environment:
      DEPLOY_NAME: ecs-production
      ECS_CLUSTER: my-cluster
      ECS_SERVICE: my-service
    steps:
      - checkout
      
      # Setup AWS credentials via OIDC (recommended)
      - aws-cli/setup:
          role_arn: $AWS_OIDC_ROLE
          region: $AWS_REGION
          role_session_name: "cci-ecs-deploy"
      
      # Plan the deployment
      - run:
          name: Plan deployment
          command: |
            circleci run release plan $DEPLOY_NAME \
              --environment-name=production \
              --component-name=$ECS_SERVICE \
              --target-version=$CIRCLE_SHA1
      
      # Deploy to ECS
      - aws-ecs/update-service:
          cluster: $ECS_CLUSTER
          service-name: $ECS_SERVICE
          container-image-name-updates: "container=my-container,tag=$CIRCLE_SHA1"
      
      # Update status to RUNNING
      - run:
          name: Update status to RUNNING
          command: |
            circleci run release update $DEPLOY_NAME --status=RUNNING
      
      # Wait for deployment to stabilize
      - run:
          name: Wait for ECS deployment
          command: |
            aws ecs wait services-stable \
              --cluster $ECS_CLUSTER \
              --services $ECS_SERVICE
      
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
              --failure-reason="ECS deployment failed to stabilize"
          when: on_fail

workflows:
  deploy:
    jobs:
      - deploy-ecs:
          filters:
            branches:
              only: main
```

### Lambda Function Deployment

Track Lambda function updates:

```yaml
version: 2.1

orbs:
  aws-cli: circleci/aws-cli@4.1.3

jobs:
  deploy-lambda:
    docker:
      - image: cimg/python:3.11
    environment:
      FUNCTION_NAME: my-lambda-function
      DEPLOY_NAME: lambda-deploy
    steps:
      - checkout
      
      - aws-cli/setup:
          role_arn: $AWS_OIDC_ROLE
          region: $AWS_REGION
      
      # Plan the deployment
      - run:
          name: Plan deployment
          command: |
            circleci run release plan $DEPLOY_NAME \
              --environment-name=production \
              --component-name=$FUNCTION_NAME \
              --target-version=$CIRCLE_SHA1
      
      # Package Lambda function
      - run:
          name: Package Lambda
          command: |
            pip install -r requirements.txt -t package/
            cd package && zip -r ../function.zip . && cd ..
            zip -g function.zip lambda_function.py
      
      # Deploy Lambda function
      - run:
          name: Deploy Lambda function
          command: |
            aws lambda update-function-code \
              --function-name $FUNCTION_NAME \
              --zip-file fileb://function.zip
      
      # Update status to RUNNING
      - run:
          name: Update status to RUNNING
          command: |
            circleci run release update $DEPLOY_NAME --status=RUNNING
      
      # Wait for function update
      - run:
          name: Wait for Lambda update
          command: |
            aws lambda wait function-updated --function-name $FUNCTION_NAME
      
      # Validate with test invocation
      - run:
          name: Validate Lambda
          command: |
            aws lambda invoke \
              --function-name $FUNCTION_NAME \
              --payload '{"test": true}' \
              response.json
            cat response.json
      
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
              --failure-reason="Lambda deployment or validation failed"
          when: on_fail

workflows:
  deploy:
    jobs:
      - deploy-lambda
```

### S3 Static Site Deployment

Track static site deployments to S3:

```yaml
version: 2.1

orbs:
  aws-cli: circleci/aws-cli@4.1.3

jobs:
  deploy-s3:
    docker:
      - image: cimg/node:20.9
    environment:
      S3_BUCKET: my-static-site-bucket
      CLOUDFRONT_DISTRIBUTION: ABCDEFGHIJKLM
    steps:
      - checkout
      
      - aws-cli/setup:
          role_arn: $AWS_OIDC_ROLE
          region: $AWS_REGION
      
      # Build static site
      - run:
          name: Install dependencies
          command: npm ci
      
      - run:
          name: Build site
          command: npm run build
      
      # Log the deployment (simple logging without status tracking)
      - run:
          name: Deploy to S3
          command: |
            aws s3 sync dist/ s3://$S3_BUCKET/ --delete
      
      # Invalidate CloudFront cache
      - run:
          name: Invalidate CloudFront
          command: |
            aws cloudfront create-invalidation \
              --distribution-id $CLOUDFRONT_DISTRIBUTION \
              --paths "/*"
      
      # Log deployment
      - run:
          name: Log deployment
          command: |
            circleci run release log \
              --environment-name=production \
              --component-name=static-site \
              --target-version=$CIRCLE_SHA1

workflows:
  deploy:
    jobs:
      - deploy-s3:
          filters:
            branches:
              only: main
```

### Elastic Beanstalk Deployment

Track Elastic Beanstalk application deployments:

```yaml
version: 2.1

orbs:
  aws-cli: circleci/aws-cli@4.1.3
  eb: circleci/aws-elastic-beanstalk@2.0.1

jobs:
  deploy-eb:
    docker:
      - image: cimg/python:3.11
    environment:
      EB_APP_NAME: my-application
      EB_ENV_NAME: my-application-prod
      DEPLOY_NAME: eb-production
    steps:
      - checkout
      
      - aws-cli/setup:
          role_arn: $AWS_OIDC_ROLE
          region: $AWS_REGION
      
      - eb/setup
      
      # Plan deployment
      - run:
          name: Plan deployment
          command: |
            circleci run release plan $DEPLOY_NAME \
              --environment-name=production \
              --component-name=$EB_APP_NAME \
              --target-version=$(cat version)
      
      # Deploy to Elastic Beanstalk
      - run:
          name: Deploy to Elastic Beanstalk
          command: |
            eb deploy $EB_ENV_NAME --staged
      
      # Update status to RUNNING
      - run:
          name: Update status to RUNNING
          command: |
            circleci run release update $DEPLOY_NAME --status=RUNNING
      
      # Wait for environment to be ready
      - run:
          name: Wait for deployment
          command: |
            aws elasticbeanstalk wait environment-updated \
              --environment-name $EB_ENV_NAME
      
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
              --failure-reason="Elastic Beanstalk deployment failed"
          when: on_fail

workflows:
  deploy:
    jobs:
      - deploy-eb
```

## CircleCI Config Files

Ready-to-use CircleCI config files are available:
- [ECS/Fargate deployment](../../.circleci/deploy_markers_aws_ecs_config.yml)
- [Lambda deployment](../../.circleci/deploy_markers_aws_lambda_config.yml)
- [Generic deployment template](../../.circleci/deploy_markers_config.yml)

## Best Practices

1. **Use OIDC authentication**: Prefer OIDC over static credentials for AWS authentication
2. **Include wait/stabilization steps**: Ensure deployments are fully complete before marking success
3. **Add validation**: Include health checks or smoke tests before marking deployment as successful
4. **Track failure reasons**: Capture and report meaningful failure reasons to aid debugging
5. **Use consistent versioning**: Use the same version format across all environments

## Next Steps

- View your deployments in the [CircleCI Deploys Dashboard](https://app.circleci.com/releases)
- Learn about [generic deployment tracking](./generic_deployment.md)
- For Kubernetes deployments, consider the [Release Agent](../../guidelines/k8s-release-agent-onboarding.md) for additional controls

