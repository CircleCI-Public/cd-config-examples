# Onboarding Appendices

This document contains supplementary information for the deployment tracking guides:
- [Release Agent onboarding](../guidelines/k8s-release-agent-onboarding.md) - Agent-based Kubernetes tracking
- [Deploy Markers onboarding](../guidelines/deploy-markers-onboarding.md) - Deploy markers for any target

## Obtain the CircleCI Project Id programmatically

- Use a CircleCI PAT (Peronsal Access Token) if you do not have one yet, you can create a token following the instruction [here](https://circleci.com/docs/managing-api-tokens/#creating-a-personal-api-token)

- Define your project slug to know the exact project you are looking for. The project slug is the format `<vcs>/<org>/<project_name>`. e.g assuming that the vcs is `Github`, the org is called `awesomecompany` and the project (or repository) is called `some-demo` the slug would be `gh/awesomecompany/some-demo`. Find more information about the project slug [here](https://circleci.com/docs/api-intro/#getting-started-with-the-api-v2).
  
- Get the Project Id by executing `./scripts/get_project_id.sh --project-slug 'gh/awesomecompany/some-demo' --cci-api-token CCI_API_TOKEN`.

## Use the terminal to replace the manifests placeholders

If you have [`envsubst`](https://savannah.gnu.org/projects/gettext) available, follow these steps:

- use a real value for the `project-id`:

```bash
export CIRCLE_PROJECT_ID="USE-REAL-PROJECT-ID" VERSION=$(cat version) TAG="green"
```

- Execute the following command:

```bash
 rm -f ./examples/k8s_cli/k8s_deployment/manifest-rendered.yaml && \
 envsubst < ./examples/k8s_cli/k8s_deployment/deployment.yaml >> ./examples/k8s_cli/k8s_deployment/manifest-rendered.yaml && \
 echo "---" >>  ./examples/k8s_cli/k8s_deployment/manifest-rendered.yaml  && \
 envsubst < ./examples/k8s_cli/k8s_deployment/service.yaml >> ./examples/k8s_cli/k8s_deployment/manifest-rendered.yaml && \
 echo "---" >>  ./examples/k8s_cli/k8s_deployment/manifest-rendered.yaml && \
 envsubst < ./examples/k8s_cli/k8s_deployment/ingress.yaml >> ./examples/k8s_cli/k8s_deployment/manifest-rendered.yaml
```

## Using the Release Agent when deploying outside CircleCI

Can I use the Release Agent for tracking deployments made outside of CircleCI? Yes, you can. When utilizing the Release Agent to monitor deployments made outside of CircleCI, there are two levels of visibility you can set up.

### Normal Release Component visibility

The normal mode enables tracking of every release across all environments, providing a valuable historical perspective on component changes. The only required information for this is the project ID associated with the Kubernetes workload, in addition to the necessary labels

The process for this scenario may involve the following steps:

- Configure the Release Agent following the onboarding guidelines outlined [here](https://app.circleci.com/releases) or by following the guideline [here](../guidelines/k8s-release-agent-onboarding.md#install-the-release-agent-and-onboard-a-component-in-4-steps).

- Set up the project Id for each deployed component
  - Obtain the project id following the instructions [here](../guidelines/k8s-release-agent-onboarding.md#3-get-a-circle-ci-project-id)
  - Configure your manifest to include the annotation `circleci.com/project-id` and its corresponding value.

- Build your applications with CircleCI and deploy them using your custom tools

- See your releases reflected in the CircleCI [releases dashboard](https://app.circleci.com/releases)

### Enhanced Release Component visibility

The enhanced version has the same information as before but goes a step further by linking every release record in the history to the commit, workflow number, and job name that generated the version. This advanced feature boosts tracking capabilities, enabling users to effectively trace the event and code changes that may have potentially triggered an anomaly in the system.

For doing so you would need to store the CircleCI metadata somewhere to be able to inject it during the deployment process.

Generally the process would looke like this

- Configure the Release Agent following the onboarding guidelines outlined [here](https://app.circleci.com/releases) or by following the guideline [here](../guidelines/k8s-release-agent-onboarding.md#install-the-release-agent-and-onboard-a-component-in-4-steps).

- Build your applications with CircleCI and save the metadata useful to enable full visibility

  - Inject the CircleCI information as metadata within the docker image at build time. e.g. `docker build -t your-image:tag --label cci_pipeline_id=$CIRCLE_PIPELINE_ID --label cci_project_id=$CIRCLE_PROJECT_ID --label cci_job_number=$CIRCLE_BUILD_NUM cci_workflow_id=$CIRCLE_WORKFLOW_ID`, then you could extract the labels before deploying by doing `docker inspect --format='{{json .Config.Labels}}' your-image:tag | jq`

  - Push the CircleCI metadata to a remote repository or blob storage where later could be utilized to inject the CircleCI metadata during the deployment process.

- Pull the metadata, inject it in the kubernetes manifest and deploy using your custom tools or scripts

- See your releases reflected in the CircleCI [releases dashboard](https://app.circleci.com/releases)

## Advanced local setup

You can enable a local ingress controller to test your workloads by running the setup cluster script as follows

```bash
./scripts/setup_local_cluster.sh setup-local-cluster install-ingress
```

Also Argo Rollouts can be installed with the same script in case you want to test progressive releases and the extended features of the Release Agent

```bash
./scripts/setup_local_cluster.sh setup-local-cluster install-ingress install-argo-rollouts
```

## Alternative: Deploy Markers

If installing the release agent isn't feasible for your environment, or if you're deploying to non-Kubernetes targets, consider using [Deploy Markers](../guidelines/deploy-markers-onboarding.md) for deployment tracking without an agent.

Deploy markers work by adding CLI commands to your CircleCI config:

```yaml
- run:
    name: Log deployment
    command: |
      circleci run release log \
        --environment-name=production \
        --component-name=my-app \
        --target-version=$CIRCLE_SHA1
```

This approach:
- Works with **any** deployment target (AWS, GCP, Azure, Heroku, on-prem, etc.)
- Requires **no installation** in your infrastructure
- Provides deployment visibility in the CircleCI Deploys Dashboard

See the [Deploy Markers onboarding guide](../guidelines/deploy-markers-onboarding.md) for complete setup instructions.
