// src/components/Homepage/HeroSection/index.tsx
import React, { JSX, useEffect } from 'react';
import Link from '@docusaurus/Link';
import Typed from 'typed.js';
import styles from './styles.module.css';

export function HeroSection(): JSX.Element {
  useEffect(() => {
    const typed = new Typed('#typed', {
      strings: [
        'Run Kubernetes at home like a pro.',
        'GitOps-driven infrastructure automation.',
        'Production-grade homelab setup.',
        'Self-hosted cloud native stack.'
      ],
      typeSpeed: 50,
      backSpeed: 30,
      backDelay: 1500,
      loop: true
    });

    return () => {
      typed.destroy();
    };
  }, []);

  return (
    <section className={styles.hero}>
      <div className="container">
        <div className={styles.heroContent}>
          <h1 className={styles.heroTitle}>
            Your Home Infrastructure,
            <span className={styles.gradientText}>Enterprise Grade</span>
          </h1>
          <div className={styles.typedWrapper}>
            <span id="typed"></span>
          </div>
          <div className={styles.ctaButtons}>
            <Link
              to="/docs/quick-start"
              className={styles.primaryButton}
            >
              Get Started →
            </Link>
            {/* <Link
              to="#demo"
              className={styles.secondaryButton}
            >
              Watch Demo
            </Link> */}
          </div>
          {/* Add stats section */}
        </div>
        <div className={styles.codePreview}>
          {/* Add code preview section */}
        </div>
      </div>
    </section>
  );
}
