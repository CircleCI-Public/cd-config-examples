#!/bin/bash

set -e

file=$1

RED='\033[0;31m'
NC='\033[0m'
CYAN='\033[0;36m'

# make sure yq is installed since is required to check the yaml file
if [ -z "$(command -v yq)" ]
then
    echo "yq is not installed. Check the official GitHub repository to install it:"
    echo "${CYAN}https://github.com/mikefarah/yq?tab=readme-ov-file#install${NC}"
    exit 1
fi

# Extract component relevant meta.labels
app_label=$(yq '.metadata.labels["app"]' "$file")
version_label=$(yq '.metadata.labels["version"]' "$file")
component_label=$(yq '.metadata.labels["circleci.com/component-name"]' "$file")
version_component=$(yq '.metadata.labels["circleci.com/version"]' "$file")

## check that a pair of (app and version) or (circleci.com/component-name and circleci.com/version) must be present and not mixed e.g. (app and circleci.com/version)
if ! [[ ( "$app_label" != "null" && "$version_label" != "null" ) || ( "$component_label" != "null" && "$version_component" != "null" ) || 
(( "$app_label" != "null" && "$version_label" != "null" ) && ( "$component_label" != "null" && "$version_component" != "null" )) ]]; then
    echo -e "${RED}the given YAML file does not contain the required .metadata.labels. Add the pair (app and version) and/or (circleci.com/component-name and circleci.com/version)${NC}"
    exit 1
fi 

# Extract component relevant spec.template.meta.labels
app_label=$(yq '.spec.template.metadata.labels["app"]' "$file")
version_label=$(yq '.spec.template.metadata.labels["version"]' "$file")
component_label=$(yq '.spec.template.metadata.labels["circleci.com/component-name"]' "$file")
version_component=$(yq '.spec.template.metadata.labels["circleci.com/version"]' "$file")

## check that a pair of (app and version) or (circleci.com/component-name and circleci.com/version) must be present and not mixed e.g. (app and circleci.com/version)
if ! [[ ( "$app_label" != "null" && "$version_label" != "null" ) || ( "$component_label" != "null" && "$version_component" != "null" ) || 
(( "$app_label" != "null" && "$version_label" != "null" ) && ( "$component_label" != "null" && "$version_component" != "null" )) ]]; then
    echo -e "${RED}the given YAML file does not contain the required .spec.template.metadata.labels. Add the pair (app and version) and/or (circleci.com/component-name and circleci.com/version)${NC}"
    exit 1
fi 

# Extract projectID from annotations
project_id=$(yq '.metadata.annotations["circleci.com/project-id"]' "$file")

## check that a pair of (app and version) or (circleci.com/component-name and circleci.com/version) must be present and not mixed e.g. (app and circleci.com/version)
if [[ "$project_id" == "null" ]]; then
    echo -e "${RED}the given YAML file does not contain the required circleci.com/project-id annotation.${NC}"
    exit 1
fi 

# Extract component relevant trigger annotations
pipeline_id=$(yq '.metadata.annotations["circleci.com/pipeline-id"]' "$file")
workflow_id=$(yq '.metadata.annotations["circleci.com/workflow-id"]' "$file")
job_number=$(yq '.metadata.annotations["circleci.com/job-number"]' "$file")
missing_triggers=""

# ## check optional deployment triggers
if [[ "$pipeline_id" == "null" ]]; then
    missing_triggers+="circleci.com/pipeline-id"
fi

if [[ "$workflow_id" == "null" ]]; then
    missing_triggers+=" circleci.com/workflow-id"
fi

if [[ "$job_number" == "null" ]]; then
    missing_triggers+=" circleci.com/job-number"
fi

## remove leading space
missing_triggers="${missing_triggers#"${missing_triggers%%[![:space:]]*}"}"

if [ -n "$missing_triggers" ]; then
    echo -e  "${CYAN}OPTIONAL: some deployment triggers are missing $missing_triggers. These are not required but can improve the experience while looking at the release history.${NC}"
fi


kind_file=$(yq '.kind' "$file")

echo "No issues found in the given Kubernetes $kind_file file"
