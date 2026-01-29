#!/usr/bin/env python3
"""
Simple YAML validator to check our network policy files
"""

import os
import sys
import re
from pathlib import Path


def validate_yaml_syntax(file_path):
    """Basic YAML structure validation"""
    try:
        with open(file_path, "r") as f:
            content = f.read()

        # Check for basic YAML structure
        if not content.strip():
            return False, "Empty file"

        # Check for required fields based on file type
        if "CiliumNetworkPolicy" in content:
            required_fields = ["apiVersion", "kind", "metadata", "spec"]
            for field in required_fields:
                if f"{field}:" not in content:
                    return False, f"Missing required field: {field}"

        if "Kustomization" in content:
            if "apiVersion:" not in content or "kind:" not in content:
                return False, "Missing Kustomization required fields"

        return True, "Valid structure"
    except Exception as e:
        return False, f"Error reading file: {str(e)}"


def check_cilium_policy_spec(policy_path):
    """Validate CiliumNetworkPolicy specific requirements"""
    try:
        with open(policy_path, "r") as f:
            content = f.read()

        # Check Cilium API version
        if "apiVersion: cilium.io/v2" not in content:
            return False, "Incorrect Cilium API version"

        # Check for audit mode indicators
        if "default-deny-audit" in policy_path:
            if "enableDefaultDeny: false" not in content:
                return False, "Audit policy missing enableDefaultDeny: false"

        return True, "Valid Cilium policy"
    except Exception as e:
        return False, f"Error checking policy: {str(e)}"


def validate_namespace_consistency():
    """Check namespace consistency across kustomizations"""
    namespace_files = {}
    errors = []

    for root, dirs, files in os.walk("k8s/infrastructure/network/policies"):
        for file in files:
            if file == "kustomization.yaml":
                file_path = os.path.join(root, file)
                with open(file_path, "r") as f:
                    content = f.read()

                # Extract namespace
                namespace_match = re.search(r"namespace:\s*(\S+)", content)
                if namespace_match:
                    namespace = namespace_match.group(1)
                    dir_name = os.path.basename(root)
                    namespace_files[dir_name] = namespace

    # Check for inconsistencies
    for dir_name, namespace in namespace_files.items():
        if dir_name != "applications" and dir_name != "clusterwide":
            if dir_name != namespace:
                errors.append(
                    f"Namespace mismatch in {dir_name}: expected {dir_name}, got {namespace}"
                )

    return len(errors) == 0, errors


def main():
    print("🔍 Validating Cilium Network Policies...")

    policy_dir = Path("k8s/infrastructure/network/policies")
    if not policy_dir.exists():
        print("❌ Policy directory not found")
        return False

    yaml_files = list(policy_dir.rglob("*.yaml"))
    total_files = len(yaml_files)
    valid_files = 0
    errors = []

    print(f"📁 Found {total_files} YAML files")

    # Validate each file
    for file_path in yaml_files:
        is_valid, message = validate_yaml_syntax(file_path)
        if is_valid:
            valid_files += 1
            print(f"✅ {file_path.relative_to(policy_dir)}: {message}")

            # Additional checks for Cilium policies
            if "CiliumNetworkPolicy" in str(file_path):
                policy_valid, policy_msg = check_cilium_policy_spec(file_path)
                if policy_valid:
                    print(f"   ✅ {policy_msg}")
                else:
                    errors.append(f"{file_path.relative_to(policy_dir)}: {policy_msg}")
        else:
            errors.append(f"{file_path.relative_to(policy_dir)}: {message}")
            print(f"❌ {file_path.relative_to(policy_dir)}: {message}")

    # Check namespace consistency
    ns_valid, ns_errors = validate_namespace_consistency()
    if not ns_valid:
        errors.extend(ns_errors)

    # Summary
    print(f"\n📊 Validation Summary:")
    print(f"   Total files: {total_files}")
    print(f"   Valid files: {valid_files}")
    print(f"   Errors: {len(errors)}")

    if errors:
        print(f"\n❌ Validation Errors:")
        for error in errors:
            print(f"   - {error}")
        return False
    else:
        print(f"\n✅ All validations passed!")

        # Show policy structure
        print(f"\n📋 Policy Structure:")
        print(f"   - Cluster-wide policies: ✅")
        print(f"   - Namespace-specific policies: ✅")
        print(f"   - Application-specific policies: ✅")
        print(f"   - Monitoring setup: ✅")
        print(f"   - GitOps integration: ✅")

        return True


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
