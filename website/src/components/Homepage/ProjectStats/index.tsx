import React, { JSX, useEffect, useState } from 'react';
import styles from './styles.module.css';

interface RepoStats {
  stars: string;
  forks: string;
  issues: string;
  lastCommit: string;
}

export function ProjectStats(): JSX.Element {
  const [stats, setStats] = useState<RepoStats>();

  useEffect(() => {
    async function fetchStats(): Promise<void> {
      const repo = await fetch(
        'https://api.github.com/repos/theepicsaxguy/homelab',
      ).then((r) => r.json());
      const commit = await fetch(
        'https://api.github.com/repos/theepicsaxguy/homelab/commits?per_page=1',
      ).then((r) => r.json());
      setStats({
        stars: repo.stargazers_count.toString(),
        forks: repo.forks_count.toString(),
        issues: repo.open_issues_count.toString(),
        lastCommit: new Date(commit[0].commit.committer.date).toLocaleDateString(),
      });
    }
    fetchStats();
  }, []);
  return (
    <section className={styles.statsSection}>
      <div className="container">
        <div className={styles.statsGrid}>
          {stats && (
            <>
              <div className={styles.statItem}>
                <div className={styles.statValue}>{stats.stars}</div>
                <div className={styles.statLabel}>Stars</div>
              </div>
              <div className={styles.statItem}>
                <div className={styles.statValue}>{stats.forks}</div>
                <div className={styles.statLabel}>Forks</div>
              </div>
              <div className={styles.statItem}>
                <div className={styles.statValue}>{stats.issues}</div>
                <div className={styles.statLabel}>Open Issues</div>
              </div>
              <div className={styles.statItem}>
                <div className={styles.statValue}>{stats.lastCommit}</div>
                <div className={styles.statLabel}>Last Commit</div>
              </div>
            </>
          )}
        </div>
      </div>
    </section>
  );
}
