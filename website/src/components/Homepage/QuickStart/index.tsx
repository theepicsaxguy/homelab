import React, { JSX } from 'react';
import Link from '@docusaurus/Link';
import styles from './styles.module.css';

export function QuickStart(): JSX.Element {
  return (
    <section className={styles.quickStart}>
      <div className="container">
        <h2 className={styles.quickStartTitle}>Quick Start Guide</h2>
        <div className={styles.quickStartSteps}>
          <div className={styles.step}>
            <span className={styles.stepNumber}>1</span>
            <h3>Clone the Repository</h3>
            <pre className={styles.codeBlock}>
              <code>git clone https://github.com/yourusername/homelab.git</code>
            </pre>
          </div>
          <div className={styles.step}>
            <span className={styles.stepNumber}>2</span>
            <h3>Configure Environment</h3>
            <pre className={styles.codeBlock}>
              <code>cp .env.example .env && vim .env</code>
            </pre>
          </div>
          <div className={styles.step}>
            <span className={styles.stepNumber}>3</span>
            <h3>Deploy Infrastructure</h3>
            <pre className={styles.codeBlock}>
              <code>make bootstrap</code>
            </pre>
          </div>
        </div>
        <div className={styles.quickStartCta}>
          <Link
            className="button button--primary button--lg"
            to="/docs/quick-start"
          >
            View Full Guide
          </Link>
        </div>
      </div>
    </section>
  );
}
