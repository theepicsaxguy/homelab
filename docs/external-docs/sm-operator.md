# Bitwarden Secrets Manager Operator

This chart is for the deployment of the Kubernetes Operator for Secrets Manager to different Kubernetes environments.
The operator installs into your cluster and allows you to create a custom resource called a BitwardenSecret to
synchronize secrets stored in Secrets Manager into your cluster as Kubernetes secrets.

> [!NOTE] This is a beta release and might be missing some functionality.

## Requirements

- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm 3](https://v3.helm.sh/docs/intro/install/)
- A [Bitwarden Organization with Secrets Manager](https://bitwarden.com/help/sign-up-for-secrets-manager/). You will
  need the organization ID GUID for your organization.
- One or more [access tokens](https://bitwarden.com/help/access-tokens/) for a Secrets Manager machine account tied to
  the projects you want to pull.

---

## Add the repo to Helm

```shell
helm repo add bitwarden https://charts.bitwarden.com/
helm repo update
```

## Installation Steps

### Create config file

Run the following command to create a custom values file used for deployment:

```shell
helm show values bitwarden/sm-operator > my-values.yaml
```

### Update the config file

Edit the `my-values.yaml` file and fill out the values. Required values that must be set. The values included can be
used as is, but you should verify the following values make sense for your installation. More information on each
setting is found in `values.yaml`

- settings.bwSecretsManagerRefreshInterval
- settings.cloudRegion
- settings.bwApiUrlOverride (if you are self-hosting Bitwarden)
- settings.bwIdentityUrlOverride (if you are self-hosting Bitwarden)
- containers.enableSeccompProfileRuntimeDefault

**NOTE: If you are testing this chart via the DevContainer and trying to point to a locally running copy of Bitwarden
server, you will need to use the `host.docker.internal` hostname.**

#### Using non-default chart images

Update `containers.manager.image.tag` to use a different operator image version than the one shipped with the chart.

### Install Helm Chart

1. Run
   `helm upgrade sm-operator bitwarden/sm-operator -i --debug -n sm-operator-system --create-namespace --values my-values.yaml`.
   - This installs/upgrades a release named `sm-operator`, in the namespace `sm-operator-system`, using values from
     `my-values.yaml`.
   - You can see help information for the `helm install` command by running `helm install --help`.
   - You can see help information for the `helm upgrade` command by running `helm upgrade --help`.

> [!NOTE] While the chart is in beta, you will need to add the `--devel` flag to the `helm upgrade` command above.

## Creating BitwardenSecrets

Below is an example of creating a BitwardenSecret object to synchronsize secrets stored in Bitwarden Secrets Manager
into Kubernetes secrets.

### Create an authorization token secret

Each namespace where a BitwardenSecret is created will require a Kubernetes secret be created to authenticate against
Secrets Manager.

```shell
kubectl create secret generic bw-auth-token -n <YOUR_NAMESPACE> --from-literal=token="<TOKEN_HERE>"
```

**_NOTE: This command is recorded in your shell history. To avoid this, consider deploying via an ephemeral pipeline
agent._**

### Deploy a BitwardenSecret

Think of the BitwardenSecret object as the synchronization settings that will be used by the operator to create and
synchronize a Kubernetes secret. This Kubernetes secret will live inside of a namespace and will be injected with the
data available to a Secrets Manager machine account. The resulting Kubernetes secret will include all secrets that a
specific machine account has access to. The key settings that you will want to update are listed below:

- **metadata.name**: The name of the BitwardenSecret object you are deploying

- **spec.organizationId**: The Bitwarden organization ID you are pulling Secrets Manager data from

- **spec.secretName**: The name of the Kubernetes secret that will be created and injected with Secrets Manager data.

- **spec.authToken**: The name of a secret inside of the Kubernetes namespace that the BitwardenSecrets object is being
  deployed into that contains the Secrets Manager machine account authorization token being used to access secrets.

Secrets Manager does not guarantee unique secret names across projects, so by default secrets will be created with the
Secrets Manager secret UUID used as the key. To make your generated secret easier to use, you can create a map of
Bitwarden Secret IDs to Kubernetes secret keys. The generated secret will replace the Bitwarden Secret IDs with the
mapped friendly name you provide. Below are the map settings available:

- **bwSecretId**: This is the UUID of the secret in Secrets Manager. This can found under the secret name in the Secrets
  Manager web portal or by using the [Bitwarden Secrets Manager CLI](https://github.com/bitwarden/sdk/releases).

- **secretKeyName**: The resulting key inside the Kubernetes secret that replaces the UUID

Note that the custom mapping is made available on the generated secret for informational purposes in the
`k8s.bitwarden.com/custom-map` annotation.

Below is an example deployment of a BitwardenSecret with a custom mapping. Note that the map element is optional.

```shell
cat <<EOF | kubectl apply -n <YOUR_NAMESPACE> -f -
apiVersion: k8s.bitwarden.com/v1
kind: BitwardenSecret
metadata:
  labels:
    app.kubernetes.io/name: bitwardensecret
    app.kubernetes.io/instance: bitwardensecret-sample
    app.kubernetes.io/part-of: sm-operator
    app.kubernetes.io/managed-by: kustomize
    app.kubernetes.io/created-by: sm-operator
  name: bitwardensecret-sample
spec:
  organizationId: "a08a8157-129e-4002-bab4-b118014ca9c7"
  secretName: bw-sample-secret
  map:
    - bwSecretId: 6c230265-d472-45f7-b763-b11b01023ca6
    secretKeyName: test__secret__1
    - bwSecretId: d132a5ed-12bd-49af-9b74-b11b01025d58
    secretKeyName: test__secret__2
  authToken:
    secretName: bw-auth-token
    secretKey: token
EOF
```
