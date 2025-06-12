import React, { JSX } from 'react';
import styles from './styles.module.css';
interface Technology {
  name: string;
  logo: string;
}
const technologies: Technology[] = [
  {
    name: 'Kubernetes',
    logo:
      'https://raw.githubusercontent.com/cncf/artwork/master/projects/kubernetes/icon/color/kubernetes.svg',
  },
  {
    name: 'Talos',
    logo:
      'https://raw.githubusercontent.com/siderolabs/talos/master/website/static/img/talos-logo.svg',
  },
  {
    name: 'ArgoCD',
    logo:
      'https://raw.githubusercontent.com/argoproj/argo-cd/master/docs/assets/logo.png',
  },
  {
    name: 'OpenTofu',
    logo:
      'https://raw.githubusercontent.com/opentofu/artwork/main/horizontal/color/opentofu-horizontal-color.svg',
  },
  {
    name: 'Prometheus',
    logo:
      'https://raw.githubusercontent.com/cncf/artwork/master/projects/prometheus/icon/color/prometheus-icon-color.svg',
  },
  {
    name: 'Grafana',
    logo:
      'https://raw.githubusercontent.com/grafana/grafana/main/public/img/grafana_icon.svg',
  },
  {
    name: 'Proxmox',
    logo: 'https://www.proxmox.com/images/proxmox_logo.png',
  },
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
