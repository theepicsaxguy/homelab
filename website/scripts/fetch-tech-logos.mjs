import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

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
    if (t.repo) {
      const url = `https://api.github.com/repos/${t.repo}`;
      const res = await fetch(url);
      const data = await res.json();
      avatarUrl = data.owner.avatar_url;
    } else if (t.org) {
      const url = `https://api.github.com/orgs/${t.org}`;
      const res = await fetch(url);
      const data = await res.json();
      avatarUrl = data.avatar_url;
    }

    if (avatarUrl) {
      const response = await fetch(avatarUrl);
      if (!response.ok) {
        console.warn(`Failed to fetch avatar for ${t.slug}: ${response.statusText}`);
        continue;
      }

      const arrayBuffer = await response.arrayBuffer();
      const buffer = Buffer.from(arrayBuffer);
      fs.writeFileSync(outputPath, buffer);
      console.log(`Successfully downloaded ${t.slug}.png`);
    } else {
      console.warn(`No avatar URL found for ${t.slug}.`);
    }
  }
}

fetchTechLogos();
