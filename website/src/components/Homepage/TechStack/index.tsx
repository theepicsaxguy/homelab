import React, { JSX } from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import styles from './styles.module.css';

interface Technology {
  name: string;
  logo: string;
}

export function TechStack(): JSX.Element {
  const withBase = useBaseUrl;

  const techList: Technology[] = [
    { name: 'Homelab', logo: withBase('/img/tech-logos/theepicsaxguy.png') },
    { name: 'Kubernetes', logo: withBase('/img/tech-logos/kubernetes.png') },
    { name: 'Talos', logo: withBase('/img/tech-logos/talos.png') },
    { name: 'ArgoCD', logo: withBase('/img/tech-logos/argocd.png') },
    { name: 'OpenTofu', logo: withBase('/img/tech-logos/opentofu.png') },
    { name: 'Prometheus', logo: withBase('/img/tech-logos/prometheus.png') },
    { name: 'Grafana', logo: withBase('/img/tech-logos/grafana.png') },
    { name: 'Proxmox', logo: withBase('/img/tech-logos/proxmox.png') },
  ];
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
