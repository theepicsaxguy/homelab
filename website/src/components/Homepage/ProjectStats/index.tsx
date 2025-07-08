import React, { JSX } from 'react';
import styles from './styles.module.css';
import stats from '@site/src/data/github-stats.json';

export function ProjectStats(): JSX.Element {
  return (
    <section className={styles.statsSection}>
      <div className="container">
        <div className={styles.statsGrid}>
          
            <div className={styles.statItem}>
              <div className={styles.statValue}>{stats.stars}</div>
              <div className={styles.statLabel}>Stars</div>
            </div>
            <div className={styles.statItem}>
              <div className={styles.statValue}>{stats.forks}</div>
              <div className={styles.statLabel}>Forks</div>
            </div>
          </>
        </div>
      </div>
    </section>
  );
}
