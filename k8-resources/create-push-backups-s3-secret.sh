#!/bin/bash
set -e

if [[ -z "$ACCESS_KEY_ID" ]]; then
    echo "ACCESS_KEY_ID is not set"
    exit 1
fi
if [[ -z "$SECRET_ACCESS_KEY" ]]; then
    echo "SECRET_ACCESS_KEY is not set"
    exit 1
fi

export ACCESS_KEY_ID_BASE64=$(echo -n "${ACCESS_KEY_ID}" | base64)
export SECRET_ACCESS_KEY_BASE64=$(echo -n "${SECRET_ACCESS_KEY}" | base64)

envsubst '${ACCESS_KEY_ID_BASE64}
    ${SECRET_ACCESS_KEY_BASE64}' \
    < ./pushbackups3secret.yaml.template > ./pushbackups3secret.yaml
