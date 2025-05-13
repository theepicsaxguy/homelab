// src/components/Homepage/CTASection/index.tsx
import React, { JSX } from 'react';
import Link from '@docusaurus/Link';
import styles from './styles.module.css';

export function CTASection(): JSX.Element {
  return (
    <section className={styles.cta}>
      <div className="container">
        <h2 className={styles.title}>Ready to Transform Your Homelab?</h2>
        <div className={styles.buttons}>
          <Link
            to="https://github.com/yourusername/homelab"
            className={styles.primaryButton}
          >
            Star on GitHub
          </Link>
          <Link
            to="/docs"
            className={styles.secondaryButton}
          >
            Read the Docs
          </Link>
        </div>
      </div>
    </section>
  );
}
