# 2) Put Grafana behind HTTPS

Goal: users open `https://monitor.yourdomain.com` with a real TLS certificate.  
Never leave Grafana as plain `http://IP:3001` on the public internet.

---

## Why this matters (interview answer)

> “Credentials and session cookies must travel over TLS. I put Grafana behind a reverse proxy with Let’s Encrypt so browsers get HTTPS, and I stopped exposing Grafana’s raw port publicly.”

---

## Easiest path: Caddy (auto HTTPS)

Caddy gets free certificates from Let’s Encrypt automatically.

### Prerequisites

1. A **domain name** (Namecheap, Cloudflare, Google Domains, etc.)
2. DNS **A record**:

```text
monitor.yourdomain.com  →  YOUR_SERVER_PUBLIC_IP
```

3. Ports **80** and **443** open on the VM firewall  
4. Stack already running on the VM (`docker compose up -d`)

Wait 2–10 minutes for DNS to propagate. Check:

```bash
dig +short monitor.yourdomain.com
# should print your server IP
```

---

## Step 1: Add Caddy to the stack

Create `caddy/Caddyfile` on the server:

```bash
mkdir -p /opt/monitoring/caddy
cat > /opt/monitoring/caddy/Caddyfile <<'EOF'
monitor.yourdomain.com {
        encode gzip

        # Security headers
        header {
                Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
                X-Content-Type-Options nosniff
                X-Frame-Options DENY
                Referrer-Policy strict-origin-when-cross-origin
                -Server
        }

        reverse_proxy grafana:3000
}
EOF
```

**Replace** `monitor.yourdomain.com` with your real domain.

---

## Step 2: Add Caddy service to docker-compose

Add this service to `docker-compose.yml` (or use the snippet file `docker-compose.https.yml`):

```yaml
  caddy:
    image: caddy:2.9-alpine
    container_name: caddy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - monitoring
    restart: unless-stopped
    depends_on:
      - grafana
```

And under `volumes:`:

```yaml
  caddy_data:
  caddy_config:
```

---

## Step 3: Stop publishing Grafana publicly

In `docker-compose.yml`, change Grafana ports from:

```yaml
    ports:
      - "3001:3000"
```

to (internal only):

```yaml
    # ports:
    #   - "3001:3000"
    expose:
      - "3000"
```

Same idea later for Prometheus if it was public — remove host port mappings.

Update `.env`:

```env
GRAFANA_ROOT_URL=https://monitor.yourdomain.com
```

Restart:

```bash
cd /opt/monitoring
docker compose up -d
docker compose logs caddy --tail 50
```

---

## Step 4: Verify HTTPS

Browser:

```text
https://monitor.yourdomain.com
```

You should see:

- Padlock / HTTPS  
- Grafana login  
- Login with your admin user from `.env`

Also:

```bash
curl -I https://monitor.yourdomain.com
```

Expect `HTTP/2 200` or a redirect to login.

---

## Step 5: Firewall final state

```bash
ufw status
# allow: 22, 80, 443
# deny / absent: 3001, 9090, 9100, 9093, 3306, 27017...
```

Remove temporary openings:

```bash
ufw delete allow 3001/tcp
ufw delete allow 9090/tcp
```

---

## No domain yet? Temporary options

### A) Use a free dynamic DNS / free subdomain

- [DuckDNS](https://www.duckdns.org) free subdomain → point to your IP  
- Put that name in Caddyfile  

### B) Self-signed cert (lab only — browsers warn)

Not ideal for portfolio screenshots. Prefer free domain + Let’s Encrypt.

### C) Cloudflare tunnel (advanced, no open 80/443 required)

Good story for interviews, more setup. Stick to Caddy first.

---

## Nginx + Certbot alternative (if interviewer asks)

High-level only:

1. Nginx reverse_proxy to `grafana:3000`  
2. `certbot --nginx -d monitor.yourdomain.com`  
3. Force HTTPS redirect  

Caddy is faster for a portfolio lab.

---

## Portfolio screenshots

1. Browser padlock on `https://monitor...`  
2. Grafana login page over HTTPS  
3. `curl -I https://...` showing TLS  
4. Firewall showing only 22/80/443  

---

## Interview line

> “I terminated TLS at Caddy with Let’s Encrypt, reverse-proxied only Grafana, set `GF_SERVER_ROOT_URL` correctly, and kept Prometheus and exporters off the public internet.”
