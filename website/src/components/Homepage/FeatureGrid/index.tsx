import React, { JSX } from 'react';
import styles from './styles.module.css';
interface Feature {
  title: string;
  icon: string;
  description: string;
  iconAlt: string;
}
const features: Feature[] = [
  {
    title: 'Kubernetes at the Core',
    icon: 'kubernetes.svg',
    iconAlt: 'Kubernetes',
    description: 'Built on <b>Talos Linux</b>, providing a secure and automated foundation for container orchestration.',
  },
  {
    title: 'GitOps Workflow',
    icon: 'argocd.svg',
    iconAlt: 'ArgoCD',
    description: 'Infrastructure and applications managed declaratively through Git using <b>ArgoCD</b>.',
  },
  {
    title: 'Infrastructure as Code',
    icon: 'opentofu.svg',
    iconAlt: 'OpenTofu',
    description: 'Automated provisioning with <b>OpenTofu</b>, ensuring reproducible and version-controlled infrastructure.',
  },
  {
    title: 'Modern DevOps Stack',
    icon: 'devops.svg',
    iconAlt: 'DevOps tools',
    description: 'Integrated monitoring, logging, and security tools for a <b>production-grade</b> environment.',
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
                {/* Use actual logos; ensure these icons exist */}
                <img
                  src={`/img/icons/${feature.icon}`}
                  alt={feature.iconAlt}
                  className={styles.icon}
                  loading="lazy"
                />
              </div>
              <h3 className={styles.featureTitle}>{feature.title}</h3>
              <p className={styles.featureDescription} dangerouslySetInnerHTML={{ __html: feature.description }} />
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
