#!/bin/bash
set -e

if [[ -z "$BUCKET_NAME" ]]; then
    echo "BUCKET_NAME is not set"
    exit 1
fi
if [[ -z "$REGION" ]]; then
    echo "REGION is not set"
    exit 1
fi
if [[ -z "$ENDPOINT_URL" ]]; then
    echo "ENDPOINT_URL is not set"
    exit 1
fi
if [[ -z "$BUCKET_DIR" ]]; then
    echo "BUCKET_DIR is not set"
    exit 1
fi
if [[ -z "$SITES_PVC" ]]; then
    echo "SITES_PVC is not set"
    exit 1
fi
if [[ -z "$VERSION" ]]; then
    echo "VERSION is not set"
    exit 1
fi
export TIMESTAMP=$(date +%s)

envsubst '${TIMESTAMP}
    ${VERSION}
    ${BUCKET_NAME}
    ${REGION}
    ${ENDPOINT_URL}
    ${BUCKET_DIR}
    ${SITES_PVC}' \
    < ./pushbackupsjob.yaml.template > pushbackupsjob-$TIMESTAMP.yaml
