# CircleCI Deployment using Helm

This guideline shows how to configure your CircleCI workflow to deploy a Kubernetes deployment usign Helm. It also assumes that you have a Kubernetes cluster accessible from the internet with the CircleCI [k8s-release-agent](https://circleci-public.github.io/cci-k8s-release-agent) installed.

## Pre-requistes

- KUBECONFIG_DATA loaded in base64 as environment variable in CircleCI. Generate the base64 like `cat ~/.kube/config | base64`.

- Load the necesary credentials to CircleCI as [enviroment variables](https://circleci.com/docs/set-environment-variable) so the client can authenticate correctly with your cluster to do the deployment. e.g for aws load AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY and any other AWS env var you might need. Or in general configure OIDC authentication between Circle CI and your cloud provider following [this guideline](https://circleci.com/docs/openid-connect-tokens/#authenticate-jobs-with-cloud-providers).

## You want to test before reading?

- Make sure you have gone through the pre-requirements above
- Copy or download this project, rename [this](../../.circleci/deployment_helm_config.yml) file to `config.yml`
- Push your changes and wait for CircleCI to deploy, then check your CircleCI dashboard and you can see your release
- Change the [`version`](../../version), merge your change and wait few seconds for CircleCI to deploy, the go to the [releases](https://app.circleci.com/releases) dashobard and see your new release.

## Details

### Kubernetes Manifest

The example Kubernetes manifest this guideline referes can be found [here](../../examples/helm/k8s_deployment).

The Kubernetes manifest in the example folder includes a Deployment, a Service, and an Ingress. The Deployment utilizes a pre-built public image `argoproj/rollouts-demo` for demonstration simplicity. The Ingress configuration has the host property commented out, allowing you to define a host suitable for end-to-end testing. If an Ingress setup is not preferred, you can opt to port forward the service or the pod for testing.

One of the key parts of the manifest that helps to understand the CircleCI config is the values file

```yaml
version: ${VERSION}
componentName: helm-cci-deploy-demo
replicas: 2
pipelineId: ${CIRCLE_PIPELINE_ID}
workflowId: ${CIRCLE_WORKFLOW_ID}
projectId: ${CIRCLE_PROJECT_ID}
jobNumber: ${CIRCLE_BUILD_NUM}
tag: ${TAG}
```

As described above, certain fields reference an environment variable style. This is because the CircleCI job will replace all those values using envsubst, leveraging the information automatically loaded by CircleCI into the job, along with other variables generated along the way.

### CircleCI config

The CircleCI config used for this guideline is the [deployment_helm_config.yml](../../.circleci/deployment_helm_config.yml). If you download this repo and try yourself rename this file to `config.yml` and that's it.

Going from top to bottom these are key parts you might be interested in understanding

**Set up**

- the command generate_deploy_info: it reads the version from the [`version`](../../version) file of this repo to determine what is the version of the workload to be deployed, also as a quick hack to change the docker image tag it determines that if the minor version (in semver style) is even then we use the `purple` tag otherwise we use `green` basically useful to show a different page in the UI and make sure the release has worked.

- the load_deploy_info commands loads the VERSION and TAG information into a file so we can reuse it in subsequential jobs.

- the orbs `circleci/kubernetes@1.3.1` and  `circleci/helm@3.0.2` are configred to be used during the setup and deployment process.

**Validaiton**

The step `validate-manifiest` installs `yq` and calls a utility script [check_deploy_rollout](../../scripts/check_deploy_rollout.sh) to make sure that the kubernetes manifest constains the minimun requirements for the k8s-release-agent to proccess it.

**Preparation**

Once validated the Kubernetes manifest the `render-manifest` replaces the environment variables place holders located at the values.yaml file in the chart for real values. Then the `kubernetes/install-kubeconfig` and the `helm/install_helm_client` install the tools required to perform the deployment

**Deployment**

The `install-chart` step proceeds to install the local chart into the kubernetes cluster configured in the `KUBECONFIG_DATA` environment variable.

After this step the release must be visible in the CircleCI [releases](https://app.circleci.com/releases) dashobard.
