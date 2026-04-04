const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
const PORT = parseInt(process.env.PORT || '3000');

app.use(cors());
app.use(express.json());

// ── Database connection pool ───────────────────────────────────────────────────
const pool = new Pool({
  host:     process.env.DB_HOST,
  port:     parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME,
  user:     process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  ssl:      process.env.DB_SSL === 'false' ? false : { rejectUnauthorized: false },
  max:      10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

// ── Schema initialization ──────────────────────────────────────────────────────
async function initDB() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS tasks (
      id          SERIAL PRIMARY KEY,
      title       VARCHAR(255) NOT NULL,
      description TEXT         DEFAULT '',
      completed   BOOLEAN      DEFAULT false,
      created_at  TIMESTAMP    DEFAULT NOW(),
      updated_at  TIMESTAMP    DEFAULT NOW()
    )
  `);

  // Seed demo data on first run
  const { rows } = await pool.query('SELECT COUNT(*) FROM tasks');
  if (parseInt(rows[0].count) === 0) {
    await pool.query(`
      INSERT INTO tasks (title, description) VALUES
        ('Deploy three-tier app on AWS', 'VPC + ECS Fargate + RDS PostgreSQL'),
        ('Build Docker image and push to ECR', 'Run scripts/build-and-push.ps1'),
        ('Upload frontend to S3', 'Run scripts/deploy-frontend.ps1'),
        ('Plan migration to Azure', 'See migration-to-azure/README.md')
    `);
  }
  console.log('[DB] Schema initialized');
}

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', db: 'connected', timestamp: new Date().toISOString() });
  } catch {
    res.status(503).json({ status: 'error', db: 'disconnected' });
  }
});

// ── GET /api/tasks ─────────────────────────────────────────────────────────────
app.get('/api/tasks', async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT * FROM tasks ORDER BY completed ASC, created_at DESC'
    );
    res.json(rows);
  } catch (err) {
    console.error('[GET /api/tasks]', err.message);
    res.status(500).json({ error: 'Failed to fetch tasks' });
  }
});

// ── GET /api/tasks/:id ────────────────────────────────────────────────────────
app.get('/api/tasks/:id', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM tasks WHERE id = $1', [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'Task not found' });
    res.json(rows[0]);
  } catch (err) {
    console.error('[GET /api/tasks/:id]', err.message);
    res.status(500).json({ error: 'Failed to fetch task' });
  }
});

// ── POST /api/tasks ────────────────────────────────────────────────────────────
app.post('/api/tasks', async (req, res) => {
  const { title, description = '' } = req.body;
  if (!title || !title.trim()) {
    return res.status(400).json({ error: 'Title is required' });
  }
  try {
    const { rows } = await pool.query(
      'INSERT INTO tasks (title, description) VALUES ($1, $2) RETURNING *',
      [title.trim(), description.trim()]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error('[POST /api/tasks]', err.message);
    res.status(500).json({ error: 'Failed to create task' });
  }
});

// ── PUT /api/tasks/:id ────────────────────────────────────────────────────────
app.put('/api/tasks/:id', async (req, res) => {
  const { title, description, completed } = req.body;
  try {
    const { rows } = await pool.query(
      `UPDATE tasks
         SET title       = COALESCE($1, title),
             description = COALESCE($2, description),
             completed   = COALESCE($3, completed),
             updated_at  = NOW()
       WHERE id = $4
       RETURNING *`,
      [title ?? null, description ?? null, completed ?? null, req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Task not found' });
    res.json(rows[0]);
  } catch (err) {
    console.error('[PUT /api/tasks/:id]', err.message);
    res.status(500).json({ error: 'Failed to update task' });
  }
});

// ── DELETE /api/tasks/:id ─────────────────────────────────────────────────────
app.delete('/api/tasks/:id', async (req, res) => {
  try {
    const { rows } = await pool.query(
      'DELETE FROM tasks WHERE id = $1 RETURNING id',
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Task not found' });
    res.json({ message: 'Task deleted', id: rows[0].id });
  } catch (err) {
    console.error('[DELETE /api/tasks/:id]', err.message);
    res.status(500).json({ error: 'Failed to delete task' });
  }
});

// ── App info (useful during demo) ─────────────────────────────────────────────
app.get('/api/info', (req, res) => {
  res.json({
    app:     'Task Manager — AWS Three-Tier Demo',
    version: '1.0.0',
    tier:    'backend',
    runtime: `Node.js ${process.version}`,
    env:     process.env.NODE_ENV || 'development',
    db:      { host: process.env.DB_HOST, name: process.env.DB_NAME }
  });
});

// ── 404 fallback ──────────────────────────────────────────────────────────────
app.use((req, res) => res.status(404).json({ error: 'Not found' }));

// ── Start ─────────────────────────────────────────────────────────────────────
initDB()
  .then(() => {
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`[SERVER] Task Manager API running on port ${PORT}`);
      console.log(`[DB]     Connecting to ${process.env.DB_HOST}/${process.env.DB_NAME}`);
    });
  })
  .catch((err) => {
    console.error('[FATAL] DB initialization failed:', err.message);
    process.exit(1);
  });
