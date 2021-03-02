#!/bin/bash

# Load secret variables from file
source creds/secrets.sh

# Applies kustomized argocd server to cluster
kustomize build \
    argo-cd/overlays/production \
    | kubectl apply --filename -

# Wait for deployment to succeed
kubectl --namespace argocd \
    rollout status \
    deployment argocd-server

# Get the argocd password
export PASS=$(kubectl \
    --namespace argocd \
    get secret argocd-initial-admin-secret \
    --output jsonpath="{.data.password}" \
    | base64 --decode)

# Login to argocd CLI
argocd login \
    --insecure \
    --username admin \
    --password $PASS \
    --grpc-web \
    argo-cd.$BASE_HOST

# Change password to super secret password
argocd account update-password \
    --current-password $PASS \
    --new-password admin

# Creates argo cd project for staging and production
kubectl apply --filename project.yaml

# Applies the argo cd app of apps for staging and production
kubectl apply --filename apps.yaml