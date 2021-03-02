# Load secret variables from file
source creds/secrets.sh

# shellcheck disable=SC2002
cat orig/sealed-secrets.yaml \
    | sed -e "s@carr-james@$GH_ORG@g" \
    | tee production/sealed-secrets.yaml

# shellcheck disable=SC2002
cat argo-cd/base/ingress.yaml \
    | sed -e "s@acme.com@argo-cd.$BASE_HOST@g" \
    | tee argo-cd/overlays/production/ingress.yaml

# shellcheck disable=SC2002
cat argo-workflows/base/ingress.yaml \
    | sed -e "s@acme.com@argo-workflows.$BASE_HOST@g" \
    | tee argo-workflows/overlays/production/ingress.yaml

# shellcheck disable=SC2002
cat argo-events/base/event-sources.yaml \
    | sed -e "s@carr-james@$GH_ORG@g" \
    | sed -e "s@acme.com@webhook.$BASE_HOST@g" \
    | tee argo-events/overlays/production/event-sources.yaml

# shellcheck disable=SC2002
cat argo-events/base/sensors.yaml \
    | sed -e "s@value: carr-james@value: $GH_ORG@g" \
    | sed -e "s@value: CHANGE_ME_IMAGE_OWNER@value: $REGISTRY_USER@g" \
    | tee argo-events/overlays/production/sensors.yaml

# shellcheck disable=SC2002
cat production/argo-cd.yaml \
    | sed -e "s@carr-james@$GH_ORG@g" \
    | tee production/argo-cd.yaml

# shellcheck disable=SC2002
cat production/argo-workflows.yaml \
    | sed -e "s@carr-james@$GH_ORG@g" \
    | tee production/argo-workflows.yaml

# shellcheck disable=SC2002
cat production/argo-events.yaml \
    | sed -e "s@carr-james@$GH_ORG@g" \
    | tee production/argo-events.yaml

# shellcheck disable=SC2002
cat production/argo-rollouts.yaml \
    | sed -e "s@carr-james@$GH_ORG@g" \
    | tee production/argo-rollouts.yaml

# shellcheck disable=SC2002
cat production/argo-combined-app.yaml \
    | sed -e "s@github.com/carr-james@github.com/$GH_ORG@g" \
    | sed -e "s@- jamescarr1993@- $REGISTRY_USER@g" \
    | tee production/argo-combined-app.yaml

# shellcheck disable=SC2002
cat staging/argo-combined-app.yaml \
    | sed -e "s@github.com/carr-james@github.com/$GH_ORG@g" \
    | sed -e "s@- jamescarr1993@- $REGISTRY_USER@g" \
    | tee staging/argo-combined-app.yaml

# Applies sealed secrets controller if install already
kubectl apply --filename sealed-secrets

# Creates sealed secret containing docker registry details
# Wait for a while and repeat the previous command if the output contains `cannot fetch certificate` error message
kubectl --namespace workflows \
    create secret \
    docker-registry regcred \
    --docker-server="$REGISTRY_SERVER" \
    --docker-username="$REGISTRY_USER" \
    --docker-password="$REGISTRY_PASS" \
    --docker-email="$REGISTRY_EMAIL" \
    --output json \
    --dry-run=client \
    | kubeseal --format yaml \
    | tee argo-workflows/overlays/production/regcred.yaml

# Creates sealed secret for github credentials in workflows namespace
echo "apiVersion: v1
kind: Secret
metadata:
  name: github-access
  namespace: workflows
type: Opaque
data:
  token: $(echo -n "$GH_TOKEN" | base64)
  user: $(echo -n "$GH_ORG" | base64)
  email: $(echo -n "$GH_EMAIL" | base64)" \
    | kubeseal --format yaml \
    | tee argo-workflows/overlays/workflows/githubcred.yaml

# Creates sealed secret for github credentials in argo-events namespace
echo "apiVersion: v1
kind: Secret
metadata:
  name: github-access
  namespace: argo-events
type: Opaque
data:
  token: $(echo -n $GH_TOKEN | base64)" \
    | kubeseal --format yaml \
    | tee argo-events/overlays/production/githubcred.yaml