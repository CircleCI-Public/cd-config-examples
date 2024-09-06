#!/bin/sh

set -e

# paramaters
VERSION=$1
CIRCLE_PROJECT_ID=$2
TAG=$3
K8S_MANIFESTS_LOCATION=$4
PIPELINE_ID=${5:-""}
WORKFLOW_ID=${6:-""}
BUILD_NUM=${7:-""}

# replace placeholders by real vales
sed -e "s/<<CIRCLE_PIPELINE_ID>>/\"$PIPELINE_ID\"/g; \
        s/<<CIRCLE_WORKFLOW_ID>>/\"$WORKFLOW_ID\"/g;\
        s/<<CIRCLE_BUILD_NUM>>/\"$BUILD_NUM\"/g; \
        s/<<version>>/\"$VERSION\"/g; \
        s/<<image-tag>>/$TAG/g; \
        s/<<CIRCLE_PROJECT_ID>>/\"$CIRCLE_PROJECT_ID\"/g" $K8S_MANIFESTS_LOCATION/deployment.yaml >$K8S_MANIFESTS_LOCATION/manifest-rendered.yaml

# create yaml separator
echo "---" >>$K8S_MANIFESTS_LOCATION/manifest-rendered.yaml

## add service the to rendered file
cat $K8S_MANIFESTS_LOCATION/service.yaml >>$K8S_MANIFESTS_LOCATION/manifest-rendered.yaml

# create yaml separator
echo "---" >>$K8S_MANIFESTS_LOCATION/manifest-rendered.yaml

# add ingress the to rendered file
cat $K8S_MANIFESTS_LOCATION/ingress.yaml >>$K8S_MANIFESTS_LOCATION/manifest-rendered.yaml
