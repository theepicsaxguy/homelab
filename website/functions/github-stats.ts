export const onRequest = async () => {
  const cache = caches.default;
  const key   = new Request('https://homelab.orkestack.com/__githubStats');
  const cached = await cache.match(key);
  if (cached) return cached;

  const repo  = await fetch('https://api.github.com/repos/theepicsaxguy/homelab').then(r=>r.json());
  const body  = JSON.stringify({ stars: repo.stargazers_count, forks: repo.forks_count, ts: Date.now() });
  const resp  = new Response(body, { headers:{ 'content-type':'application/json', 'cache-control':'public,max-age=86400' }});
  await cache.put(key, resp.clone());
  return resp;
};

// Runs daily at 03:17 UTC
export const onSchedule = onRequest;
