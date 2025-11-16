// src/components/Homepage/Footer/index.tsx
import React, { JSX } from 'react';
import Link from '@docusaurus/Link';
import styles from './styles.module.css';

export function Footer(): JSX.Element {
  return (
    <footer className={styles.footer}>
      <div className="container">
        <div className={styles.grid}>
          <div className={styles.column}>
            <h3 className={styles.title}>Homelab</h3>
            <p className={styles.description}>
              Modern infrastructure automation for your home
            </p>
          </div>
          <div className={styles.column}>
            <h3 className={styles.title}>Documentation</h3>
            <ul className={styles.list}>
              <li><Link to="/docs/getting-started">Getting Started</Link></li>
              <li><Link to="/docs/architecture">Architecture</Link></li>
            </ul>
          </div>
          <div className={styles.column}>
            <h3 className={styles.title}>Community</h3>
            <ul className={styles.list}>
              <li><Link to="https://github.com/theepicsaxguy/homelab">GitHub</Link></li>
              <li><Link to="https://goingdark.social/">Mastodon</Link></li>
            </ul>
          </div>
          {/* <div className={styles.column}>
            <h3 className={styles.title}>Legal</h3>
            <ul className={styles.list}>
              <li><Link to="/privacy">Privacy Policy</Link></li>
              <li><Link to="/terms">Terms of Service</Link></li>
            </ul>
          </div> */}
        </div>
      </div>
    </footer>
  );
}
