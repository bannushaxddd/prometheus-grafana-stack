/**
 * Demo API with Prometheus custom instrumentation
 * + optional MySQL / MongoDB health probes for DB dashboards
 */
const express = require('express');
const client = require('prom-client');
const morgan = require('morgan');
const net = require('net');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

const register = new client.Registry();
client.collectDefaultMetrics({
  register,
  prefix: 'nodejs_',
  labels: { app: 'demo-api' },
});

// ── HTTP metrics ─────────────────────────────────────────────────────
const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
  registers: [register],
});

const httpRequestsInFlight = new client.Gauge({
  name: 'http_requests_in_flight',
  help: 'Number of HTTP requests currently being processed',
  registers: [register],
});

// ── Business metrics ─────────────────────────────────────────────────
const ordersCreated = new client.Counter({
  name: 'app_orders_created_total',
  help: 'Total orders created by the demo application',
  labelNames: ['status'],
  registers: [register],
});

const activeUsers = new client.Gauge({
  name: 'app_active_users',
  help: 'Simulated number of active users',
  registers: [register],
});

const orderValue = new client.Histogram({
  name: 'app_order_value_dollars',
  help: 'Order value distribution in dollars',
  buckets: [5, 10, 25, 50, 100, 250, 500, 1000],
  registers: [register],
});

const cacheHits = new client.Counter({
  name: 'app_cache_hits_total',
  help: 'Cache hits',
  registers: [register],
});

const cacheMisses = new client.Counter({
  name: 'app_cache_misses_total',
  help: 'Cache misses',
  registers: [register],
});

const dbUp = new client.Gauge({
  name: 'app_dependency_up',
  help: '1 if dependency TCP port is reachable',
  labelNames: ['dependency'],
  registers: [register],
});

setInterval(() => {
  activeUsers.set(Math.floor(20 + Math.random() * 80));
}, 5000);

function checkPort(host, port, label) {
  return new Promise((resolve) => {
    const socket = net.connect({ host, port, timeout: 2000 }, () => {
      dbUp.set({ dependency: label }, 1);
      socket.end();
      resolve(true);
    });
    socket.on('error', () => {
      dbUp.set({ dependency: label }, 0);
      resolve(false);
    });
    socket.on('timeout', () => {
      dbUp.set({ dependency: label }, 0);
      socket.destroy();
      resolve(false);
    });
  });
}

setInterval(() => {
  checkPort(process.env.MYSQL_HOST || 'mysql', 3306, 'mysql');
  try {
    const u = new URL(process.env.MONGO_URI || 'mongodb://mongo:27017');
    checkPort(u.hostname, Number(u.port || 27017), 'mongodb');
  } catch {
    checkPort('mongo', 27017, 'mongodb');
  }
}, 10000);

// ── Middleware ───────────────────────────────────────────────────────
app.use(express.json());
app.use(morgan('combined'));

app.use((req, res, next) => {
  if (req.path === '/metrics') return next();

  httpRequestsInFlight.inc();
  const end = httpRequestDuration.startTimer();

  res.on('finish', () => {
    const route = req.route?.path || req.path;
    const labels = {
      method: req.method,
      route,
      status_code: String(res.statusCode),
    };
    httpRequestsTotal.inc(labels);
    end(labels);
    httpRequestsInFlight.dec();
  });

  next();
});

// ── Routes ───────────────────────────────────────────────────────────
app.get('/health', async (_req, res) => {
  const mysqlOk = await checkPort(process.env.MYSQL_HOST || 'mysql', 3306, 'mysql');
  let mongoOk = false;
  try {
    const u = new URL(process.env.MONGO_URI || 'mongodb://mongo:27017');
    mongoOk = await checkPort(u.hostname, Number(u.port || 27017), 'mongodb');
  } catch {
    mongoOk = await checkPort('mongo', 27017, 'mongodb');
  }

  res.json({
    status: 'ok',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    dependencies: { mysql: mysqlOk, mongodb: mongoOk },
  });
});

app.get('/', (_req, res) => {
  // Serve the demo UI when present in the image; fall back to the API index.
  res.sendFile(path.join(__dirname, 'public', 'index.html'), (err) => {
    if (err) {
      res.json({
        name: 'monitored-demo-app',
        endpoints: ['/health', '/api/orders', '/api/users', '/api/cache', '/api/slow', '/metrics'],
      });
    }
  });
});

app.get('/api/users', (_req, res) => {
  const users = Array.from({ length: 5 }, (_, i) => ({
    id: i + 1,
    name: `User ${i + 1}`,
  }));
  res.json({ users });
});

app.post('/api/orders', (req, res) => {
  const amount = Number(req.body?.amount) || Math.round((Math.random() * 200 + 5) * 100) / 100;
  const fail = Math.random() < 0.05;

  if (fail) {
    ordersCreated.inc({ status: 'failed' });
    return res.status(500).json({ error: 'Order processing failed (simulated)' });
  }

  const delay = Math.random() < 0.1 ? 800 + Math.random() * 1200 : 20 + Math.random() * 80;

  setTimeout(() => {
    ordersCreated.inc({ status: 'success' });
    orderValue.observe(amount);
    res.status(201).json({
      id: `ord_${Date.now()}`,
      amount,
      currency: 'USD',
      status: 'created',
    });
  }, delay);
});

app.get('/api/orders', (_req, res) => {
  res.json({ message: 'Use POST /api/orders to create orders', sample: { amount: 49.99 } });
});

app.get('/api/cache', (_req, res) => {
  const hit = Math.random() < 0.7;
  if (hit) {
    cacheHits.inc();
    return res.json({ source: 'cache', data: { key: 'demo', value: 'cached-value' } });
  }
  cacheMisses.inc();
  res.json({ source: 'origin', data: { key: 'demo', value: 'fresh-value' } });
});

app.get('/api/slow', (_req, res) => {
  setTimeout(() => res.json({ message: 'slow response' }), 1500 + Math.random() * 1000);
});

app.get('/metrics', async (_req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (err) {
    res.status(500).end(err.message);
  }
});

app.use((_req, res) => {
  res.status(404).json({ error: 'not found' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Demo app listening on :${PORT}`);
  console.log(`Metrics: http://localhost:${PORT}/metrics`);
});
