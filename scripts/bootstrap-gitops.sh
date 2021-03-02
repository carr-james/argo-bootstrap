#!/bin/bash

# Load secret variables from file
source creds/secrets.sh

kustomize build \
    argo-cd/overlays/production \
    | kubectl apply --filename -