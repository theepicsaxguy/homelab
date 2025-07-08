// src/components/Homepage/HeroSection/index.tsx
import React, { JSX, useEffect } from 'react';
import Link from '@docusaurus/Link';
import Typed from 'typed.js';
import styles from './styles.module.css';

export function HeroSection(): JSX.Element {
  useEffect(() => {
    const typed = new Typed('#typed', {
      strings: [
        'Automating my Kubernetes cluster with GitOps.',
        'Learning enterprise patterns on personal hardware.',
        'Documenting the entire process, mistakes included.',
        'An open invitation to explore and collaborate.'
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
          <h2 className={styles.heroTitle}>
            An Over-Engineered
            <span className={styles.gradientText}> Homelab Journey</span>
          </h2>
          <div className={styles.typedWrapper}>
            <span id="typed"></span>
          </div>
          <div className={styles.ctaButtons}>
            <Link
              href="/docs/intro"
              className={styles.primaryButton}
            >
              Explore the Docs →
            </Link>
            <Link
              to="https://github.com/theepicsaxguy/homelab"
              className={styles.secondaryButton}
            >
              View on GitHub
            </Link>
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
