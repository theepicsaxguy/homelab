import fs from 'fs';
import path from 'path';

async function fetchStats() {
  const response = await fetch('https://api.github.com/repos/theepicsaxguy/homelab');
  if (!response.ok) {
    throw new Error(`GitHub API responded with ${response.status}`);
  }
  const data = await response.json();
  const stats = {
    stars: data.stargazers_count,
    forks: data.forks_count,
  };

  const outPath = path.join('src', 'data', 'github-stats.json');
  fs.writeFileSync(outPath, JSON.stringify(stats, null, 2));
  console.log('Successfully fetched and wrote GitHub stats.');
}

fetchStats();
