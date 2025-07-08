import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function fetchWithRetry(url, retries = 3, delay = 1000) {
  for (let i = 0; i < retries; i++) {
    try {
      const response = await fetch(url);
      if (response.ok) {
        return response;
      } else if (response.status === 403 && i < retries - 1) {
        const retryAfter = response.headers.get('Retry-After');
        const waitTime = retryAfter ? parseInt(retryAfter) * 1000 : delay * Math.pow(2, i);
        console.warn(`Rate limit hit for ${url}. Retrying in ${waitTime / 1000} seconds...`);
        await sleep(waitTime);
      } else {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
    } catch (error) {
      if (i < retries - 1) {
        console.warn(`Fetch error for ${url}: ${error.message}. Retrying in ${delay / 1000} seconds...`);
        await sleep(delay);
      } else {
        throw error;
      }
    }
  }
  throw new Error(`Failed to fetch ${url} after ${retries} retries.`);
}

async function fetchTechLogos() {
  const logosDir = path.join(__dirname, '..', 'static', 'img', 'tech-logos');
  if (!fs.existsSync(logosDir)) {
    fs.mkdirSync(logosDir, { recursive: true });
  }

  const targets = [
    { slug: 'theepicsaxguy', repo: 'theepicsaxguy/homelab' }, // For the Homelab logo
    { slug: 'kubernetes', repo: 'kubernetes/kubernetes' },
    { slug: 'talos',      repo: 'siderolabs/talos' },
    { slug: 'argocd',     repo: 'argoproj/argo-cd' },
    { slug: 'opentofu',   repo: 'opentofu/opentofu' },
    { slug: 'prometheus', repo: 'prometheus/prometheus' },
    { slug: 'grafana',    repo: 'grafana/grafana' },
    { slug: 'proxmox',    org: 'proxmox' }, // Proxmox is an organization, not a repo
  ];

  for (const t of targets) {
    const outputPath = path.join(logosDir, `${t.slug}.png`);
    if (fs.existsSync(outputPath)) {
      console.log(`Logo for ${t.slug} already exists. Skipping download.`);
      continue;
    }

    let avatarUrl = '';
    try {
      if (t.repo) {
        const url = `https://api.github.com/repos/${t.repo}`;
        const res = await fetchWithRetry(url);
        const data = await res.json();
        avatarUrl = data.owner.avatar_url;
      } else if (t.org) {
        const url = `https://api.github.com/orgs/${t.org}`;
        const res = await fetchWithRetry(url);
        const data = await res.json();
        avatarUrl = data.avatar_url;
      }
    } catch (error) {
      console.error(`Error fetching GitHub data for ${t.slug}: ${error.message}`);
      continue;
    }

    if (avatarUrl) {
      try {
        const response = await fetchWithRetry(avatarUrl);
        const arrayBuffer = await response.arrayBuffer();
        const buffer = Buffer.from(arrayBuffer);
        fs.writeFileSync(outputPath, buffer);
        console.log(`Successfully downloaded ${t.slug}.png`);
      } catch (error) {
        console.warn(`Failed to download avatar for ${t.slug}: ${error.message}`);
      }
    } else {
      console.warn(`No avatar URL found for ${t.slug}.`);
    }
    await sleep(500); // Add a small delay between each logo download
  }
}

fetchTechLogos();
