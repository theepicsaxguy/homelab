#!/usr/bin/env python3
"""
Simple file structure validator without external dependencies
"""

import os
import re
import sys
from pathlib import Path


def validate_kustomization_structure():
    """Validate kustomization.yaml files without parsing YAML"""

    print("🏗️  Validating Kustomization Structure...")

    policy_dir = Path("k8s/infrastructure/network/policies")

    # Check main kustomization
    main_kust = policy_dir / "kustomization.yaml"
    if not main_kust.exists():
        print("❌ Main kustomization.yaml not found")
        return False

    with open(main_kust, "r") as f:
        main_content = f.read()

    # Check for required structure
    required_patterns = [
        r"apiVersion:\s*kustomize\.config\.k8s\.io/v1beta1",
        r"kind:\s*Kustomization",
        r"resources:",
    ]

    for pattern in required_patterns:
        if not re.search(pattern, main_content):
            print(f"❌ Main kustomization missing pattern: {pattern}")
            return False

    print("✅ Main kustomization structure valid")

    # Check subdirectories
    resources = []
    for line in main_content.split("\n"):
        match = re.match(r"\s*-\s*(\S+)", line)
        if match:
            resources.append(match.group(1))

    print(f"📦 Found {len(resources)} resource groups: {', '.join(resources)}")

    # Validate each resource
    all_valid = True
    for resource in resources:
        resource_path = policy_dir / resource

        if not resource_path.exists():
            print(f"❌ Resource directory not found: {resource}")
            all_valid = False
            continue

        # Check for kustomization.yaml in each directory (except applications which has subdirs)
        kust_file = resource_path / "kustomization.yaml"
        if not kust_file.exists() and resource != "applications":
            print(f"❌ Missing kustomization.yaml in {resource}")
            all_valid = False
        elif resource == "applications":
            # Applications should have subdirectories
            apps_dir = policy_dir / "applications"
            subdirs = [
                d for d in apps_dir.iterdir() if d.is_dir() and d.name != "monitoring"
            ]
            print(
                f"📁 Applications has {len(subdirs)} subdirectories: {', '.join([d.name for d in subdirs])}"
            )

            # Check each app subdir
            for app_dir in subdirs:
                app_kust = app_dir / "kustomization.yaml"
                if app_kust.exists():
                    print(f"   ✅ {app_dir.name}: kustomization found")
                else:
                    print(f"   ❌ {app_dir.name}: missing kustomization")
                    all_valid = False
        else:
            print(f"✅ {resource}: kustomization found")

    return all_valid


def count_resources():
    """Count all resources by type"""

    print("\n📊 Resource Inventory:")

    policy_dir = Path("k8s/infrastructure/network/policies")

    counts = {
        "CiliumNetworkPolicy": 0,
        "Kustomization": 0,
        "ServiceMonitor": 0,
        "ConfigMap": 0,
    }

    for yaml_file in policy_dir.rglob("*.yaml"):
        try:
            with open(yaml_file, "r") as f:
                content = f.read()

            # Simple kind detection
            if "kind: CiliumNetworkPolicy" in content:
                counts["CiliumNetworkPolicy"] += 1
            elif "kind: Kustomization" in content:
                counts["Kustomization"] += 1
            elif "kind: ServiceMonitor" in content:
                counts["ServiceMonitor"] += 1
            elif "kind: ConfigMap" in content:
                counts["ConfigMap"] += 1
        except:
            pass

    for kind, count in counts.items():
        print(f"   {kind}: {count}")

    return counts


def check_policy_patterns():
    """Check for specific policy patterns"""

    print("\n🔍 Policy Pattern Validation:")

    policy_dir = Path("k8s/infrastructure/network/policies")

    # Check audit policies
    audit_files = list(policy_dir.rglob("*audit*.yaml"))
    print(f"   Audit policy files: {len(audit_files)}")

    # Check clusterwide policies
    clusterwide_dir = policy_dir / "clusterwide"
    if clusterwide_dir.exists():
        clusterwide_policies = list(clusterwide_dir.glob("*.yaml"))
        print(
            f"   Clusterwide policies: {len([p for p in clusterwide_policies if p.name != 'kustomization.yaml'])}"
        )

        # Check for essential policies
        essential = [
            "default-deny-audit.yaml",
            "allow-cluster-essentials.yaml",
            "allow-gateway-http.yaml",
        ]
        for essential_file in essential:
            if (clusterwide_dir / essential_file).exists():
                print(f"   ✅ {essential_file}: Found")
            else:
                print(f"   ❌ {essential_file}: Missing")

    # Check namespace-specific policies
    namespaces = ["database", "monitoring", "auth", "argocd", "cert-manager"]
    for ns in namespaces:
        ns_dir = policy_dir / ns
        if ns_dir.exists():
            policies = list(ns_dir.glob("*.yaml"))
            ns_policies = [p for p in policies if p.name != "kustomization.yaml"]
            print(f"   {ns} namespace policies: {len(ns_policies)}")


def main():
    print("🔧 Cilium Network Policy Build Validation")
    print("=" * 50)

    # Structure validation
    structure_ok = validate_kustomization_structure()

    # Resource counting
    counts = count_resources()

    # Pattern checking
    check_policy_patterns()

    # Final summary
    print("\n" + "=" * 50)
    print("📋 Validation Summary:")

    if structure_ok:
        print("✅ Kustomization structure: VALID")
    else:
        print("❌ Kustomization structure: INVALID")

    if counts["CiliumNetworkPolicy"] > 0:
        print(f"✅ CiliumNetworkPolicies: {counts['CiliumNetworkPolicy']} found")
    else:
        print("❌ No CiliumNetworkPolicies found")

    if counts["Kustomization"] > 0:
        print(f"✅ Kustomizations: {counts['Kustomization']} found")

    if counts["ServiceMonitor"] > 0:
        print(f"✅ ServiceMonitors: {counts['ServiceMonitor']} found")

    if counts["ConfigMap"] > 0:
        print(f"✅ ConfigMaps: {counts['ConfigMap']} found")

    total_resources = sum(counts.values())
    print(f"\n🎯 Total resources: {total_resources}")

    if structure_ok and counts["CiliumNetworkPolicy"] > 0:
        print("\n✅ Build validation PASSED - Ready for deployment!")
        return True
    else:
        print("\n❌ Build validation FAILED - Fix issues before deployment")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
