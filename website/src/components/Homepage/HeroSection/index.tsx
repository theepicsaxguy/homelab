import React, { JSX } from 'react';
import Link from '@docusaurus/Link';
import clsx from 'clsx';
import styles from './styles.module.css';

export function HeroSection(): JSX.Element {
  return (
    <header className={clsx('hero', styles.heroBanner)}>
      <div className="container">
        <div className={styles.heroContent}>
          <h1 className={styles.heroTitle}>
            Modern Homelab Infrastructure
            <span className={styles.heroHighlight}>Powered by Kubernetes</span>
          </h1>
          <p className={styles.heroSubtitle}>
            A production-grade, GitOps-driven homelab built with Kubernetes, Talos, and modern DevOps practices
          </p>
          <div className={styles.buttons}>
            <Link className="button button--primary button--lg" to="/docs/getting-started">
              Get Started
            </Link>
            <Link className="button button--secondary button--lg" to="/docs/architecture">
              View Architecture
            </Link>
          </div>
        </div>
      </div>
    </header>
  );
}
