import fs from 'fs';
import path from 'path';

async function fetchStats() {
  const repoUrl = 'https://api.github.com/repos/theepicsaxguy/homelab';
  const issuesUrl = 'https://api.github.com/search/issues?q=repo:theepicsaxguy/homelab+is:issue+is:open';

  const [repoRes, issuesRes] = await Promise.all([fetch(repoUrl), fetch(issuesUrl)]);

  if (!repoRes.ok) {
    throw new Error(`GitHub repo API responded with ${repoRes.status}`);
  }
  if (!issuesRes.ok) {
    throw new Error(`GitHub issues API responded with ${issuesRes.status}`);
  }

  const repoData = await repoRes.json();
  const issuesData = await issuesRes.json();

  const stats = {
    stars: repoData.stargazers_count,
    forks: repoData.forks_count,
    issues: issuesData.total_count,
  };

  const outPath = path.join('src', 'data', 'github-stats.json');
  fs.writeFileSync(outPath, JSON.stringify(stats, null, 2));
  console.log('Successfully fetched and wrote GitHub stats.');
}

fetchStats();
