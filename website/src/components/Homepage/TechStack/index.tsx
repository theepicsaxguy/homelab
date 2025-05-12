import React, { JSX } from 'react';
import styles from './styles.module.css';

interface Technology {
  name: string;
  logo: string;
}

const technologies: Technology[] = [
  { name: 'Kubernetes', logo: 'kubernetes.svg' },
  { name: 'Talos', logo: 'talos.svg' },
  { name: 'ArgoCD', logo: 'argo.svg' },
  { name: 'OpenTofu', logo: 'opentofu.svg' },
  { name: 'Proxmox', logo: 'proxmox.svg' },
];

export function TechStack(): JSX.Element {
  return (
    <section className={styles.techStack}>
      <div className="container">
        <h2 className={styles.techStackTitle}>Powered By</h2>
        <div className={styles.techGrid}>
          {technologies.map((tech, idx) => (
            <div key={idx} className={styles.techItem}>
              <img
                src={`/img/tech/${tech.logo}`}
                alt={tech.name}
                className={styles.techLogo}
                loading="lazy"
              />
              <span className={styles.techName}>{tech.name}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
