// src/components/Homepage/FeatureGrid/index.tsx
import React, { JSX } from 'react';
import { SiKubernetes, SiGitlab, SiTerraform } from 'react-icons/si';
import { FaLock } from 'react-icons/fa';
import styles from './styles.module.css';

interface Feature {
  title: string;
  icon: JSX.Element;
  description: string;
}

const features: Feature[] = [
  {
    title: 'Kubernetes at the Core',
    icon: <SiKubernetes className={styles.featureIcon} />,
    description:
      "I use Talos Linux for a minimal, secure, and API-driven Kubernetes foundation. It's immutable and built for automation.",
  },
  {
    title: 'GitOps Workflow',
    icon: <SiGitlab className={styles.featureIcon} />,
    description:
      'This repository is the single source of truth. ArgoCD ensures the cluster state matches what\'s defined here in Git.',
  },
  {
    title: 'Infrastructure as Code',
    icon: <SiTerraform className={styles.featureIcon} />,
    description:
      'Proxmox VMs are provisioned with OpenTofu, making the entire hardware setup reproducible and version-controlled.',
  },
  {
    title: 'Secure by Default',
    icon: <FaLock className={styles.featureIcon} />,
    description:
      'I prioritize security with non-root containers, network policies, and secrets managed outside of Git using the External Secrets Operator.',
  },
];

export function FeatureGrid(): JSX.Element {
  return (
    <section className={styles.features}>
      <div className="container">
        <h2 className={styles.title}>
          The Philosophy Behind This
          <span className={styles.gradientText}> Homelab</span>
        </h2>
        <div className={styles.featureGrid}>
          {features.map((feature, idx) => (
            <div key={idx} className={styles.featureCard}>
              <div className={styles.iconWrapper}>
                {feature.icon}
              </div>
              <h3 className={styles.featureTitle}>{feature.title}</h3>
              <p className={styles.featureDescription}>{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
