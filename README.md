# Platform Bootstrap based on Argo 

## 1. Setup - Provision Kubernetes

### Cluster provisioned with IaC

Setup the cluster with terraform or pulumi.

### Install Ingress (Nginx)

Ingress controller should be set up, Nginx is widely adopted.

Can be installed by following the instructions at https://kubernetes.github.io/ingress-nginx/deploy/#digital-ocean

For digitalocean we can use the following command:
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.44.0/deploy/static/provider/do/deploy.yaml
```

### Install Sealed Secrets

Sealed secrets for storing secrets in `git`.

First, install `kubeseal` CLI from https://github.com/bitnami-labs/sealed-secrets.
Then apply the following manifests to the cluster.

```
kubectl apply -f sealed-secrets/controller.yaml 
```
