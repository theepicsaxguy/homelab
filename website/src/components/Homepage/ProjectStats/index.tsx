import React, { JSX, useState, useEffect } from 'react';
import styles from './styles.module.css';
import initialStats from '@site/src/data/github-stats.json';

export function ProjectStats(): JSX.Element {
  const [stars, setStars] = useState(initialStats.stars);
  const [forks, setForks] = useState(initialStats.forks);
  const [issues, setIssues] = useState(initialStats.issues);

  useEffect(() => {
    fetch('/github-stats')
      .then(r => r.json())
      .then(d => { setStars(d.stars); setForks(d.forks); setIssues(d.issues); })
      .catch(()=>{
        // silently fall back to static JSON
      });
  }, []); // Empty dependency array ensures this runs only once on mount

  return (
    <section className={styles.statsSection}>
      <div className="container">
        <div className={styles.statsGrid}>
          <div className={styles.statItem}>
            <div className={styles.statValue}>{stars}</div>
            <div className={styles.statLabel}>Stars</div>
          </div>
          <div className={styles.statItem}>
            <div className={styles.statValue}>{forks}</div>
            <div className={styles.statLabel}>Forks</div>
          </div>
          <div className={styles.statItem}>
            <div className={styles.statValue}>{issues}</div>
            <div className={styles.statLabel}>Issues</div>
          </div>
        </div>
      </div>
    </section>
  );
}