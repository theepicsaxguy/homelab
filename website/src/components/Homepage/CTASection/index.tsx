// src/components/Homepage/CTASection/index.tsx
import React, { JSX } from 'react';
import Link from '@docusaurus/Link';
import styles from './styles.module.css';

export function CTASection(): JSX.Element {
  return (
    <section className={styles.cta}>
      <div className="container">
        <h2 className={styles.title}>Dive In and Explore</h2>
        <div className={styles.buttons}>
          <Link
            to="/docs/getting-started"
            className={styles.primaryButton}
          >
            Quick Start Guide
          </Link>
          <Link
            to="https://github.com/theepicsaxguy/homelab"
            className={styles.secondaryButton}
          >
            Browse the Code on GitHub
          </Link>
        </div>
      </div>
    </section>
  );
}
