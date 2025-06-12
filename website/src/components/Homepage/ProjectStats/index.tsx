import React, { JSX } from 'react';
import styles from './styles.module.css';

const stats = [
  { label: 'Stars', value: '1.2k' },
  { label: 'Forks', value: '150' },
  { label: 'Open Issues', value: '12' },
  { label: 'Last Commit', value: 'Today' },
];

export function ProjectStats(): JSX.Element {
  return (
    <section className={styles.statsSection}>
      <div className="container">
        <div className={styles.statsGrid}>
          {stats.map((stat, idx) => (
            <div key={idx} className={styles.statItem}>
              <div className={styles.statValue}>{stat.value}</div>
              <div className={styles.statLabel}>{stat.label}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
