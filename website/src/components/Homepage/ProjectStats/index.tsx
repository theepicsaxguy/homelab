import React, { JSX, useState, useEffect } from 'react';
import styles from './styles.module.css';
import initialStats from '@site/src/data/github-stats.json';

export function ProjectStats(): JSX.Element {
  const [stars, setStars] = useState(initialStats.stars);
  const [forks, setForks] = useState(initialStats.forks);
  const [issues, setIssues] = useState(initialStats.issues);

  useEffect(() => {
    const repoUrl = 'https://api.github.com/repos/theepicsaxguy/homelab';
    const issuesUrl = 'https://api.github.com/search/issues?q=repo:theepicsaxguy/homelab+is:issue+is:open';


    Promise.all([fetch(repoUrl), fetch(issuesUrl)])
      .then(([repoRes, issuesRes]) => Promise.all([repoRes.json(), issuesRes.json()]))
      .then(([repoData, issuesData]) => {
        if (repoData.stargazers_count !== undefined) {
          setStars(repoData.stargazers_count);
        }
        if (repoData.forks_count !== undefined) {
          setForks(repoData.forks_count);
        }
        if (issuesData.total_count !== undefined) {
          setIssues(issuesData.total_count);
        }
      })
      .catch((error) => {
        console.error('Error fetching GitHub stats:', error);
        // If the API fails, the initial static stats will be used.
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