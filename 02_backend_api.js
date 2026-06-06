// ============================================
// OAB PLATFORM - BACKEND API
// Express.js + PostgreSQL
// npm install express pg cors dotenv bcryptjs jsonwebtoken axios
// ============================================

const express = require('express');
const { Pool } = require('pg');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(express.json());
app.use(cors());

// ============================================
// DATABASE CONNECTION
// ============================================
const pool = new Pool({
  user: process.env.DB_USER || 'app_user',
  password: process.env.DB_PASSWORD || 'app_secure_password_123',
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'oab_platform',
});

// ============================================
// MIDDLEWARE DE AUTENTICACAO
// ============================================
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Token nao fornecido' });
  }

  jwt.verify(token, process.env.JWT_SECRET || 'your_secret_key', (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Token invalido' });
    }
    req.user = user;
    next();
  });
};

// ============================================
// MIDDLEWARE DE ERROR HANDLING
// ============================================
const errorHandler = (err, req, res, next) => {
  const errorLog = {
    timestamp: new Date(),
    error_code: err.code || 'UNKNOWN_ERROR',
    error_message: err.message,
    stack_trace: err.stack,
    endpoint: req.path,
    method: req.method,
    status_code: err.status || 500,
    student_id: req.user?.student_id || null,
  };

  // Salvar erro no banco
  pool.query(
    'INSERT INTO error_logs (error_code, error_message, stack_trace, endpoint, method, status_code, student_id) VALUES ($1, $2, $3, $4, $5, $6, $7)',
    [
      errorLog.error_code,
      errorLog.error_message,
      errorLog.stack_trace,
      errorLog.endpoint,
      errorLog.method,
      errorLog.status_code,
      errorLog.student_id,
    ]
  ).catch(console.error);

  console.error('[ERROR]', errorLog);

  res.status(err.status || 500).json({
    error: err.message,
    code: err.code || 'INTERNAL_SERVER_ERROR',
  });
};

// ============================================
// ROTAS: AUTENTICACAO
// ============================================

// POST /api/v1/auth/register
app.post('/api/v1/auth/register', async (req, res, next) => {
  try {
    const { email, password, name, daily_hours } = req.body;

    if (!email || !password || !name) {
      return res.status(400).json({ error: 'Email, senha e nome sao obrigatorios' });
    }

    // Hash da senha
    const hashedPassword = await bcrypt.hash(password, 10);

    // Inserir usuario
    const userResult = await pool.query(
      'INSERT INTO users (email, password_hash, name, role, plan) VALUES ($1, $2, $3, $4, $5) RETURNING id, email, name',
      [email, hashedPassword, name, 'student', 'free']
    );

    const userId = userResult.rows[0].id;

    // Criar perfil estudante
    await pool.query(
      'INSERT INTO students (user_id, daily_hours, exam_date) VALUES ($1, $2, CURRENT_DATE + INTERVAL \'12 weeks\')',
      [userId, daily_hours || 1]
    );

    // Gerar JWT
    const token = jwt.sign(
      { user_id: userId, email: email, student_id: userId },
      process.env.JWT_SECRET || 'your_secret_key',
      { expiresIn: '1h' }
    );

    res.status(201).json({
      message: 'Usuario criado com sucesso',
      user_id: userId,
      token: token,
      user: userResult.rows[0],
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/auth/login
app.post('/api/v1/auth/login', async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email e senha obrigatorios' });
    }

    // Buscar usuario
    const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);

    if (userResult.rows.length === 0) {
      return res.status(401).json({ error: 'Email ou senha incorretos' });
    }

    const user = userResult.rows[0];

    // Verificar senha
    const validPassword = await bcrypt.compare(password, user.password_hash);

    if (!validPassword) {
      return res.status(401).json({ error: 'Email ou senha incorretos' });
    }

    // Buscar student_id
    const studentResult = await pool.query('SELECT id FROM students WHERE user_id = $1', [user.id]);
    const student_id = studentResult.rows[0]?.id;

    // Gerar JWT
    const token = jwt.sign(
      { user_id: user.id, email: user.email, student_id: student_id },
      process.env.JWT_SECRET || 'your_secret_key',
      { expiresIn: '1h' }
    );

    res.json({
      message: 'Login bem-sucedido',
      token: token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      },
    });
  } catch (err) {
    next(err);
  }
});

// ============================================
// ROTAS: QUESTOES
// ============================================

// GET /api/v1/questions?subject=civil&difficulty=medium&limit=10
app.get('/api/v1/questions', authenticateToken, async (req, res, next) => {
  try {
    const { subject, difficulty, limit } = req.query;
    let query = 'SELECT id, subject, topic, difficulty, text, options_json FROM questions WHERE 1=1';
    const params = [];

    if (subject) {
      query += ` AND subject = $${params.length + 1}`;
      params.push(subject);
    }

    if (difficulty) {
      query += ` AND difficulty = $${params.length + 1}`;
      params.push(difficulty);
    }

    query += ` ORDER BY RANDOM() LIMIT $${params.length + 1}`;
    params.push(limit || 10);

    const result = await pool.query(query, params);

    res.json({
      count: result.rows.length,
      questions: result.rows,
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/questions/:id
app.get('/api/v1/questions/:id', authenticateToken, async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      'SELECT id, subject, topic, difficulty, text, options_json, explanation FROM questions WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Questao nao encontrada' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/questions/:id/answer
app.post('/api/v1/questions/:id/answer', authenticateToken, async (req, res, next) => {
  try {
    const { id } = req.params;
    const { answer_choice, time_spent_seconds } = req.body;
    const student_id = req.user.student_id;

    // Buscar questao
    const questionResult = await pool.query('SELECT correct_answer, explanation FROM questions WHERE id = $1', [id]);

    if (questionResult.rows.length === 0) {
      return res.status(404).json({ error: 'Questao nao encontrada' });
    }

    const question = questionResult.rows[0];
    const isCorrect = question.correct_answer === answer_choice.toUpperCase();

    // Registrar resposta
    await pool.query(
      'INSERT INTO student_answers (student_id, question_id, answer_choice, is_correct, time_spent_seconds) VALUES ($1, $2, $3, $4, $5)',
      [student_id, id, answer_choice, isCorrect, time_spent_seconds || 0]
    );

    // Atualizar metricas do estudante
    await pool.query('SELECT recalculate_student_metrics($1)', [student_id]);

    res.json({
      is_correct: isCorrect,
      correct_answer: question.correct_answer,
      explanation: question.explanation,
      message: isCorrect ? 'Correto!' : 'Incorreto. Veja a explicacao acima.',
    });
  } catch (err) {
    next(err);
  }
});

// ============================================
// ROTAS: SESSOES DE ESTUDO
// ============================================

// POST /api/v1/sessions/start
app.post('/api/v1/sessions/start', authenticateToken, async (req, res, next) => {
  try {
    const { subject, method } = req.body;
    const student_id = req.user.student_id;

    if (!subject || !method) {
      return res.status(400).json({ error: 'Subject e method sao obrigatorios' });
    }

    const result = await pool.query(
      'INSERT INTO study_sessions (student_id, subject, method, duration_minutes) VALUES ($1, $2, $3, $4) RETURNING id, session_date, session_time',
      [student_id, subject, method, 0]
    );

    res.status(201).json({
      message: 'Sessao iniciada',
      session_id: result.rows[0].id,
      start_time: result.rows[0].session_time,
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/sessions/:id/end
app.post('/api/v1/sessions/:id/end', authenticateToken, async (req, res, next) => {
  try {
    const { id } = req.params;
    const { duration_minutes, energy_level_after } = req.body;
    const student_id = req.user.student_id;

    // Atualizar sessao
    const sessionResult = await pool.query(
      'UPDATE study_sessions SET duration_minutes = $1, energy_level_after = $2 WHERE id = $3 AND student_id = $4 RETURNING *',
      [duration_minutes, energy_level_after, id, student_id]
    );

    if (sessionResult.rows.length === 0) {
      return res.status(404).json({ error: 'Sessao nao encontrada' });
    }

    // Calcular acuracia
    const answersResult = await pool.query(
      'SELECT COUNT(*) as total, SUM(CASE WHEN is_correct THEN 1 ELSE 0 END) as correct FROM student_answers WHERE session_id = $1',
      [id]
    );

    const answers = answersResult.rows[0];
    const accuracy = answers.total > 0 ? Math.round((answers.correct / answers.total) * 100) : 0;

    res.json({
      message: 'Sessao finalizada',
      session_summary: {
        duration_minutes: duration_minutes,
        questions_answered: parseInt(answers.total),
        correct_answers: parseInt(answers.correct),
        accuracy_percent: accuracy,
      },
    });
  } catch (err) {
    next(err);
  }
});

// ============================================
// ROTAS: PERFORMANCE
// ============================================

// GET /api/v1/students/:id/performance?week=5&subject=civil
app.get('/api/v1/students/:id/performance', authenticateToken, async (req, res, next) => {
  try {
    const { week, subject } = req.query;
    const student_id = req.user.student_id;

    let query = 'SELECT * FROM performance_metrics WHERE student_id = $1';
    const params = [student_id];

    if (week) {
      query += ` AND week = $${params.length + 1}`;
      params.push(week);
    }

    if (subject) {
      query += ` AND subject = $${params.length + 1}`;
      params.push(subject);
    }

    const result = await pool.query(query, params);

    res.json({
      count: result.rows.length,
      performance: result.rows,
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/students/:id/summary
app.get('/api/v1/students/:id/summary', authenticateToken, async (req, res, next) => {
  try {
    const student_id = req.user.student_id;

    const result = await pool.query(
      'SELECT total_study_hours, total_questions_done, avg_score, current_week, motivation_level FROM students WHERE id = $1',
      [student_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Estudante nao encontrado' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

// ============================================
// ROTAS: HEALTH CHECK
// ============================================

app.get('/api/health', async (req, res) => {
  try {
    // Testar conexao com DB
    await pool.query('SELECT 1');
    res.json({ status: 'OK', timestamp: new Date().toISOString(), database: 'connected' });
  } catch (err) {
    res.status(503).json({ status: 'ERROR', timestamp: new Date().toISOString(), database: 'disconnected' });
  }
});

// ============================================
// ERROR HANDLER MIDDLEWARE
// ============================================
app.use(errorHandler);

// ============================================
// INICIAR SERVIDOR
// ============================================
const PORT = process.env.PORT || 3001;

app.listen(PORT, () => {
  console.log(`OAB Platform API rodando em http://localhost:${PORT}`);
  console.log(`Database: ${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || 5432}/${process.env.DB_NAME || 'oab_platform'}`);
});

module.exports = app;
