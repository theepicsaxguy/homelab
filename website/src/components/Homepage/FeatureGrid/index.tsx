// src/components/Homepage/FeatureGrid/index.tsx
import React, { JSX } from 'react';
import { SiKubernetes, SiGitlab, SiTerraform } from 'react-icons/si';
import { FaCloud, FaDocker, FaNetworkWired } from 'react-icons/fa';
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
    description: 'Built on Talos Linux, providing a secure and automated foundation for container orchestration.',
  },
  {
    title: 'GitOps Workflow',
    icon: <SiGitlab className={styles.featureIcon} />,
    description: 'Infrastructure and applications managed declaratively through Git using ArgoCD.',
  },
  {
    title: 'Infrastructure as Code',
    icon: <SiTerraform className={styles.featureIcon} />,
    description: 'Automated provisioning with OpenTofu, ensuring reproducible and version-controlled infrastructure.',
  },
  {
    title: 'Modern DevOps Stack',
    icon: <FaCloud className={styles.featureIcon} />,
    description: 'Integrated monitoring, logging, and security tools for a production-grade environment.',
  },
  {
    title: 'Container Management',
    icon: <FaDocker className={styles.featureIcon} />,
    description: 'Streamlined container deployment and management with Docker and Kubernetes.',
  },
  {
    title: 'Network Automation',
    icon: <FaNetworkWired className={styles.featureIcon} />,
    description: 'Automated network configuration and management for your entire homelab.',
  },
];

export function FeatureGrid(): JSX.Element {
  return (
    <section className={styles.features}>
      <div className="container">
        <h2 className={styles.title}>
          Everything You Need for a
          <span className={styles.gradientText}> Modern Homelab</span>
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
