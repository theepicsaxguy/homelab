import React, { JSX } from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import styles from './styles.module.css';

interface Technology {
  name: string;
  logo: string;
}

const techList: Technology[] = [
  { name: 'Homelab', logo: useBaseUrl('/img/tech-logos/theepicsaxguy.png') },
  { name: 'Kubernetes', logo: useBaseUrl('/img/tech-logos/kubernetes.png') },
  { name: 'Talos', logo: useBaseUrl('/img/tech-logos/talos.png') },
  { name: 'ArgoCD', logo: useBaseUrl('/img/tech-logos/argocd.png') },
  { name: 'OpenTofu', logo: useBaseUrl('/img/tech-logos/opentofu.png') },
  { name: 'Prometheus', logo: useBaseUrl('/img/tech-logos/prometheus.png') },
  { name: 'Grafana', logo: useBaseUrl('/img/tech-logos/grafana.png') },
  { name: 'Proxmox', logo: useBaseUrl('/img/tech-logos/proxmox.png') },
];

export function TechStack(): JSX.Element {
  return (
    <section className={styles.techStack}>
      <div className="container">
        <h2 className={styles.techStackTitle}>Powered By</h2>
        <ul className={styles.techGrid}>
          {techList.map((tech) => (
            <li key={tech.name} className={styles.techItem}>
              <img
                src={tech.logo}
                alt={`${tech.name} logo`}
                className={styles.techLogo}
                loading="lazy"
              />
              <span className={styles.techName}>{tech.name}</span>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
