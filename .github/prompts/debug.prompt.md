Debug Kubernetes installation issue using ArgoCD/kubectl

A deployment for [RESOURCE_NAME] is failing in namespace [NAMESPACE] with error [ERROR_CODE]. Identify the root cause
and suggest a fix.

Details: Logs: [RELEVANT_LOGS] Events: [KUBECTL_GET_EVENTS_OUTPUT] Related Resources: [DEPENDENCIES_IF_ANY] Manifest:
[YAML_SNIPPET] Steps to Reproduce: Apply the manifest: sh Kopiera Redigera kubectl apply -f [MANIFEST_FILE] -n
[NAMESPACE] Check pod status: sh Kopiera Redigera kubectl get pods -n [NAMESPACE] Key Debugging Commands: Describe
failing pod: sh Kopiera Redigera kubectl describe pod [POD_NAME] -n [NAMESPACE] Retrieve logs: sh Kopiera Redigera
kubectl logs [POD_NAME] -n [NAMESPACE] Check ArgoCD application status: sh Kopiera Redigera kubectl get applications -n
argocd Inspect cluster events: sh Kopiera Redigera kubectl get events -n [NAMESPACE] Expected Outcome: Diagnose the
failure. Suggest a fix based on logs and events. Provide best practices to prevent similar issues.
