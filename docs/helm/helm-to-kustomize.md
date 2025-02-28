I am moving away from helm to be able to fully see what is being rendered. To really render all the files etc so we can
use it with our approach. Make sure everything is set in the values file and delete the other files. Then follow this:

# Helm To Kustomize

## Why helm is not declarative

The idea behind declarative infrastructure is that what you define is what gets set up on your system when you are
talking about helm there is a tendency to believe that specifying a value.yaml file is being "declarative" however the
main problem is that these values get injected into templates at runtime, meaning there is an opportunity for divergence
if the templates change. Also, the templates aren't generally kept in the same repo as the values.yaml so when trying to
figure out what is being deployed you have to go chart hunting.

_"Look at that beautiful helm template"_ said nobody, ever

This speaks volumes as let's face it Helm templates are complex and very hard to figure out what is going on.

## The hard to argue upside to Helm

So the question is why use helm then? Well believe it or not putting together all the resources needed for an
application (deployments, service, ingress, validation hooks etc) is a lot of work. My default nginx-ingress install has
11 resources. Remembering all that for each application is difficult, then you start including all the configurable
properties (env, args, commands etc) it's almost impossible to do this every time. This is where helm shines, it allows
to set "sensible" defaults that are configurable via the values if needed. Making installing most applications very
simple, however this comes with a downside, upfront visibility and transparency is lost, you don't generally figure out
what a helm chart has installed until it is up and running on your cluster, making for huge security problems (the same
security issues that you can get when installing pip or npm packages).

## The Way forward

So what is the way forward, we want to keep the awesome magic of Helm but at the same time, if we want to use
methodologies like GitOps, we need a more declarative way. This is where I suggest using both Helm and Kustomize in
conjunction with each other. Helm has a handy templating feature that allows you to template out all the resource that
you can then easily specify in a Kustoomize base, the steps are straight forward

## Step 1: Helm Fetch

Add the stable repo

```bash
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
```

Fetch the chart as helm template needs it locally to template out the yaml

```bash
helm fetch \
--untar \
--untardir charts \
nginx-stable/nginx-ingress
```

## Step 2: Helm Template

Template out the yaml into a file, this is the step where you add the values to the chart and also set the namespace
(more on this later)

```bash
helm template \
--output-dir base \
--namespace ingress \
--values values.yaml \
ingress-controller \
charts/nginx-ingress
```

This should give you a folder with a whole bunch of Kubernetes resources:

```bash
ls -l base/nginx-ingress/templates/

-rw-r--r--  1 spazzy  staff   1.0K Sep 24 08:44 clusterrole.yaml
-rw-r--r--  1 spazzy  staff   510B Sep 24 08:44 clusterrolebinding.yaml
-rw-r--r--  1 spazzy  staff   2.5K Sep 24 08:44 controller-deployment.yaml
-rw-r--r--  1 spazzy  staff   690B Sep 24 08:44 controller-hpa.yaml
-rw-r--r--  1 spazzy  staff   1.4K Sep 24 08:44 controller-role.yaml
-rw-r--r--  1 spazzy  staff   500B Sep 24 08:44 controller-rolebinding.yaml
-rw-r--r--  1 spazzy  staff   602B Sep 24 08:44 controller-service.yaml
-rw-r--r--  1 spazzy  staff   273B Sep 24 08:44 controller-serviceaccount.yaml
-rw-r--r--  1 spazzy  staff   1.6K Sep 24 08:44 default-backend-deployment.yaml
-rw-r--r--  1 spazzy  staff   541B Sep 24 08:44 default-backend-service.yaml
-rw-r--r--  1 spazzy  staff   288B Sep 24 08:44 default-backend-serviceaccount.yaml
```

just to neaten things up lets move these up a dir and delete the template dir:

```bash
mv base/nginx-ingress/templates/* base/nginx-ingress && rm -rf base/nginx-ingress/templates
```

## Step 3: create the Kustomization config

One thing that is not very well known is that helm does not handle namespaces very well, when you define `--namespace`
while running `helm install` tiller does all the namespace work at runtime, it does not actually specify the namespace
on any of the resources, meaning that in order to be more declarative you will need to create you namespace config
manually:

```bash
cat <<EOF > base/nginx-ingress/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ingress
EOF
```

You can now go into the directory where the configuration is found and use kustomize to generathe the config

```bash
cd base/nginx-ingress

kustomize create --autodetect

cd ../..
```

## Step 4: Apply your new base to a cluster

as of Kubectl 1.14, Kustomize is integrated therefore you can simply run:

```
kubectl apply -k base/nginx-ingress
```

## Conclusion

Yes this is a lot more work than just running `helm install`, however the transparency you gain is worth it, as in any
system you dont want any unknowns lurking in the dark. Once you have grasped this concept I would suggesting going to
have a look at GitOps, this will change the way you handle operations.
