"""HTTP helpers shared by the plugin resolvers and the Paper version check."""

import json
import urllib.error
import urllib.request

TIMEOUT = 15
USER_AGENT = "minecraft-plugin-updater/1.0"


def _request(url, method=None):
    return urllib.request.Request(
        url, method=method, headers={"User-Agent": USER_AGENT}
    )


def fetch_json(url):
    with urllib.request.urlopen(_request(url), timeout=TIMEOUT) as r:
        return json.loads(r.read())


def url_ok(url):
    """Return True if url responds with 2xx/3xx (follows redirects)."""
    for method in ("HEAD", None):
        try:
            with urllib.request.urlopen(_request(url, method), timeout=TIMEOUT) as r:
                return r.status < 400
        except Exception:
            continue
    return False
