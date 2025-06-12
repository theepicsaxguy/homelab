import React, { JSX, useEffect, useState } from 'react';
import styles from './styles.module.css';
interface Technology {
  name: string;
  logo: string;
}
const techConfigs = [
  { name: 'Kubernetes', repo: 'kubernetes/kubernetes' },
  { name: 'Talos', repo: 'siderolabs/talos' },
  { name: 'ArgoCD', repo: 'argoproj/argo-cd' },
  { name: 'OpenTofu', repo: 'opentofu/opentofu' },
  { name: 'Prometheus', repo: 'prometheus/prometheus' },
  { name: 'Grafana', repo: 'grafana/grafana' },
  { name: 'Proxmox', org: 'proxmox' },
];

export function TechStack(): JSX.Element {
  const [technologies, setTechnologies] = useState<Technology[]>([]);

  useEffect(() => {
    async function fetchLogos(): Promise<void> {
      const items: Technology[] = await Promise.all(
        techConfigs.map(async (cfg) => {
          try {
            const url = cfg.repo
              ? `https://api.github.com/repos/${cfg.repo}`
              : `https://api.github.com/orgs/${cfg.org}`;
            const res = await fetch(url);
            const data = await res.json();
            const logo = data.owner ? data.owner.avatar_url : data.avatar_url;
            return { name: cfg.name, logo };
          } catch {
            return { name: cfg.name, logo: '' };
          }
        }),
      );
      setTechnologies(items);
    }
    fetchLogos();
  }, []);

  return (
    <section className={styles.techStack}>
      <div className="container">
        <h2 className={styles.techStackTitle}>Powered By</h2>
        <div className={styles.techGrid}>
          {technologies.map((tech, idx) => (
            <div key={idx} className={styles.techItem}>
              <img
                src={tech.logo}
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
