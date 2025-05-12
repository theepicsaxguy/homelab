import React, { JSX } from 'react';
import styles from './styles.module.css';

interface Feature {
  title: string;
  icon: string;
  description: string;
}

const features: Feature[] = [
  {
    title: 'Kubernetes at the Core',
    icon: 'kubernetes',
    description: 'Built on Talos Linux, providing a secure and automated foundation for container orchestration.',
  },
  {
    title: 'GitOps Workflow',
    icon: 'gitops',
    description: 'Infrastructure and applications managed declaratively through Git using ArgoCD.',
  },
  {
    title: 'Infrastructure as Code',
    icon: 'iac',
    description: 'Automated provisioning with OpenTofu, ensuring reproducible and version-controlled infrastructure.',
  },
  {
    title: 'Modern DevOps Stack',
    icon: 'devops',
    description: 'Integrated monitoring, logging, and security tools for a production-grade environment.',
  },
];

export function FeatureGrid(): JSX.Element {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className={styles.featureGrid}>
          {features.map((feature, idx) => (
            <div key={idx} className={styles.featureCard}>
              <div className={styles.featureIcon}>
                <img
                  src={`/img/icons/${feature.icon}.svg`}
                  alt={feature.title}
                  className={styles.icon}
                  loading="lazy"
                />
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
