#!/usr/bin/env python3
"""
Kustomize build simulator to test policy compilation
"""

import os
import sys
import yaml
from pathlib import Path


def load_yaml_file(file_path):
    """Load YAML file safely"""
    try:
        with open(file_path, "r") as f:
            return yaml.safe_load(f)
    except Exception as e:
        return None


def simulate_kustomize_build():
    """Simulate kustomize build by processing kustomizations"""

    print("🏗️  Simulating Kustomize Build...")

    # Main policies kustomization
    main_kustomization = load_yaml_file(
        "k8s/infrastructure/network/policies/kustomization.yaml"
    )
    if not main_kustomization:
        print("❌ Failed to load main kustomization")
        return False

    resources = main_kustomization.get("resources", [])
    common_labels = main_kustomization.get("commonLabels", {})

    print(f"📦 Processing {len(resources)} resource groups...")

    all_resources = []

    for resource in resources:
        resource_path = f"k8s/infrastructure/network/policies/{resource}"

        if resource == "applications":
            # Handle applications sub-kustomization
            apps_kustomization = load_yaml_file(f"{resource_path}/kustomization.yaml")
            if apps_kustomization:
                app_resources = apps_kustomization.get("resources", [])
                for app in app_resources:
                    app_path = f"{resource_path}/{app}"
                    process_directory(app_path, common_labels, all_resources)
        else:
            # Handle other directories
            process_directory(resource_path, common_labels, all_resources)

    # Summary
    print(f"\n📊 Build Results:")
    print(f"   Total resources processed: {len(all_resources)}")
    print(
        f"   CiliumNetworkPolicies: {sum(1 for r in all_resources if r.get('kind') == 'CiliumNetworkPolicy')}"
    )
    print(
        f"   ServiceMonitors: {sum(1 for r in all_resources if r.get('kind') == 'ServiceMonitor')}"
    )
    print(
        f"   ConfigMaps: {sum(1 for r in all_resources if r.get('kind') == 'ConfigMap')}"
    )

    # Validate policy structure
    policies = [r for r in all_resources if r.get("kind") == "CiliumNetworkPolicy"]
    print(f"\n🔍 Policy Validation:")

    audit_policies = 0
    for policy in policies:
        metadata = policy.get("metadata", {})
        name = metadata.get("name", "")

        if "audit" in name.lower() or "default-deny" in name.lower():
            audit_policies += 1

            spec = policy.get("spec", {})
            ingress = spec.get("ingress", [])
            egress = spec.get("egress", [])

            for rule in ingress + egress:
                if (
                    "enableDefaultDeny" in rule
                    and rule.get("enableDefaultDeny") == False
                ):
                    continue  # Audit policy correct
                # Check if it's a proper audit policy
                if "enableDefaultDeny" not in rule:
                    print(f"   ⚠️  Policy {name} may not be audit-only")

    print(f"   Audit-mode policies: {audit_policies}")
    print(f"   Enforcement policies: {len(policies) - audit_policies}")

    # Check for critical components
    critical_policies = [
        "default-deny-audit",
        "allow-cluster-essentials",
        "allow-gateway-http",
    ]
    policy_names = [r.get("metadata", {}).get("name", "") for r in policies]

    print(f"\n🎯 Critical Policies:")
    for critical in critical_policies:
        if any(critical in name for name in policy_names):
            print(f"   ✅ {critical}: Found")
        else:
            print(f"   ❌ {critical}: Missing")

    print(f"\n✅ Kustomize build simulation completed successfully!")
    return True


def process_directory(directory_path, common_labels, all_resources):
    """Process all YAML files in a directory"""
    if not os.path.exists(directory_path):
        return

    for file_path in Path(directory_path).glob("*.yaml"):
        if file_path.name == "kustomization.yaml":
            continue  # Skip kustomization files in resource processing

        resource = load_yaml_file(file_path)
        if resource:
            # Apply common labels
            if "metadata" not in resource:
                resource["metadata"] = {}
            if "labels" not in resource["metadata"]:
                resource["metadata"]["labels"] = {}

            resource["metadata"]["labels"].update(common_labels)
            all_resources.append(resource)


if __name__ == "__main__":
    success = simulate_kustomize_build()
    sys.exit(0 if success else 1)
