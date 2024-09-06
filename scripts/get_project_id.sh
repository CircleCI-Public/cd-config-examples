#!/bin/bash

set -e

RED='\033[0;31m'
NC='\033[0m'
CYAN='\033[0;36m'

while [[ $# -gt 0 ]]; do
    case "$1" in
    -p | --project-slug)
        PROJECT_SLUG="$2"
        shift 2
        ;;
    -t | --cci-api-token)
        CCI_API_TOKEN="$2"
        shift 2
        ;;
    *)
        break
        ;;
    esac
done

shift $((OPTIND - 1))

if [ -z "$CCI_API_TOKEN" ]; then
    echo -e "${CYAN} Enter the CircleCI API TOKEN \n created at https://circleci.com/docs/managing-api-tokens/#creating-a-personal-api-token:${NC}"
    read -s CCI_API_TOKEN
fi

echo "token $CCI_API_TOKEN"

response=$(curl --location --write-out "%{http_code}" --silent --output - 'https://circleci.com/api/v2/project/'$PROJECT_SLUG'' --header 'Circle-Token: '$CCI_API_TOKEN'' --header 'Accept: application/json')
http_status=$(echo "${response: -3}")

if [ "$http_status" != "200" ]; then
    echo "$response"
    exit 1
fi

project_id=$(echo "$response" | awk -F'"id":"' '{print $2}' | awk -F'"' '{print $1}')
echo "$project_id"