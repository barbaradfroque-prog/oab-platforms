-- ============================================
-- OAB PLATFORM - DATABASE SCHEMA
-- PostgreSQL 13+
-- ============================================

-- Criar extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- TABELA: USERS (Autenticacao)
-- ============================================
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  role VARCHAR(50) DEFAULT 'student', -- student, teacher, admin
  plan VARCHAR(50) DEFAULT 'free', -- free, premium, pro
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- ============================================
-- TABELA: STUDENTS (Perfil do Estudante)
-- ============================================
CREATE TABLE students (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exam_date DATE,
  target_score INT DEFAULT 70, -- Meta de acerto (70-100)
  daily_hours INT DEFAULT 1, -- 1 ou 2 horas/dia
  start_date DATE DEFAULT CURRENT_DATE,
  current_week INT DEFAULT 1,
  plan_phase VARCHAR(50) DEFAULT 'foundation', -- foundation, profundidade, dominio, refinamento
  total_study_hours DECIMAL(10,2) DEFAULT 0,
  total_questions_done INT DEFAULT 0,
  avg_score DECIMAL(5,2) DEFAULT 0,
  motivation_level INT DEFAULT 5, -- 1-10
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_students_user_id ON students(user_id);
CREATE INDEX idx_students_exam_date ON students(exam_date);
CREATE INDEX idx_students_current_week ON students(current_week);

-- ============================================
-- TABELA: QUESTIONS (Base de Questoes)
-- ============================================
CREATE TABLE questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subject VARCHAR(100) NOT NULL, -- civil, penal, proc_civil, etc
  topic VARCHAR(255) NOT NULL,
  difficulty VARCHAR(50) DEFAULT 'medium', -- easy, medium, hard
  year INT,
  text TEXT NOT NULL,
  options_json JSONB, -- {a: "opcao A", b: "opcao B", c: "opcao C", d: "opcao D"}
  correct_answer CHAR(1) NOT NULL, -- A, B, C, D
  explanation TEXT,
  source_oab VARCHAR(255), -- Qual prova OAB veio
  times_answered INT DEFAULT 0,
  avg_score_pct DECIMAL(5,2) DEFAULT 0,
  discrimination_index DECIMAL(5,2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_questions_subject ON questions(subject);
CREATE INDEX idx_questions_topic ON questions(topic);
CREATE INDEX idx_questions_difficulty ON questions(difficulty);
CREATE INDEX idx_questions_year ON questions(year);

-- ============================================
-- TABELA: STUDY_SESSIONS (Sessoes de Estudo)
-- ============================================
CREATE TABLE study_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  session_date DATE NOT NULL DEFAULT CURRENT_DATE,
  session_time TIME NOT NULL DEFAULT CURRENT_TIME,
  duration_minutes INT NOT NULL,
  subject VARCHAR(100) NOT NULL,
  method VARCHAR(50) NOT NULL, -- estudo, questoes, simulado, revisao
  questions_count INT DEFAULT 0,
  correct_count INT DEFAULT 0,
  avg_time_per_question_sec DECIMAL(10,2) DEFAULT 0,
  energy_level_before INT, -- 1-10
  energy_level_after INT, -- 1-10
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sessions_student_id ON study_sessions(student_id);
CREATE INDEX idx_sessions_date ON study_sessions(session_date);
CREATE INDEX idx_sessions_subject ON study_sessions(subject);

-- ============================================
-- TABELA: STUDENT_ANSWERS (Respostas do Estudante)
-- ============================================
CREATE TABLE student_answers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  session_id UUID REFERENCES study_sessions(id) ON DELETE SET NULL,
  answer_choice CHAR(1) NOT NULL, -- A, B, C, D
  is_correct BOOLEAN NOT NULL,
  time_spent_seconds INT,
  attempt_number INT DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_answers_student_id ON student_answers(student_id);
CREATE INDEX idx_answers_question_id ON student_answers(question_id);
CREATE INDEX idx_answers_session_id ON student_answers(session_id);
CREATE INDEX idx_answers_created_at ON student_answers(created_at);

-- ============================================
-- TABELA: PERFORMANCE_METRICS (Metricas Semanais)
-- ============================================
CREATE TABLE performance_metrics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  week INT NOT NULL,
  subject VARCHAR(100) NOT NULL,
  accuracy_pct DECIMAL(5,2),
  velocity_questions_per_min DECIMAL(10,2),
  retention_score DECIMAL(5,2),
  mistake_patterns_json JSONB, -- {topic: "count", ...}
  improvement_trend DECIMAL(5,2), -- % de melhora vs semana anterior
  review_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(student_id, week, subject)
);

CREATE INDEX idx_metrics_student_id ON performance_metrics(student_id);
CREATE INDEX idx_metrics_week ON performance_metrics(week);

-- ============================================
-- TABELA: ERROR_LOGS (Rastreamento de Erros)
-- ============================================
CREATE TABLE error_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  error_code VARCHAR(50) NOT NULL,
  error_message TEXT,
  stack_trace TEXT,
  student_id UUID REFERENCES students(id) ON DELETE SET NULL,
  endpoint VARCHAR(255),
  method VARCHAR(10), -- GET, POST, PUT, DELETE
  status_code INT,
  response_time_ms INT,
  severity VARCHAR(50) DEFAULT 'error', -- critical, error, warning, info
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_errors_code ON error_logs(error_code);
CREATE INDEX idx_errors_timestamp ON error_logs(timestamp);
CREATE INDEX idx_errors_severity ON error_logs(severity);

-- ============================================
-- TABELA: FLASHCARDS (Para Ebbinghaus)
-- ============================================
CREATE TABLE flashcards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  question_id UUID REFERENCES questions(id) ON DELETE CASCADE,
  front_text TEXT NOT NULL, -- pergunta
  back_text TEXT NOT NULL, -- resposta
  next_review_date TIMESTAMP,
  review_count INT DEFAULT 0,
  ease_factor DECIMAL(3,2) DEFAULT 2.5,
  interval_days INT DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_flashcards_student_id ON flashcards(student_id);
CREATE INDEX idx_flashcards_next_review ON flashcards(next_review_date);

-- ============================================
-- FUNCOES UTEIS
-- ============================================

-- Funcao para calcular acuracia de sessao
CREATE OR REPLACE FUNCTION calculate_session_accuracy(
  p_session_id UUID
) RETURNS DECIMAL AS $$
BEGIN
  RETURN (
    SELECT CASE 
      WHEN COUNT(*) = 0 THEN 0
      ELSE ROUND(100.0 * SUM(CASE WHEN is_correct THEN 1 ELSE 0 END) / COUNT(*), 2)
    END
    FROM student_answers
    WHERE session_id = p_session_id
  );
END;
$$ LANGUAGE plpgsql;

-- Funcao para recalcular metricas do estudante
CREATE OR REPLACE FUNCTION recalculate_student_metrics(
  p_student_id UUID
) RETURNS VOID AS $$
BEGIN
  UPDATE students SET
    total_questions_done = (
      SELECT COUNT(*) FROM student_answers WHERE student_id = p_student_id
    ),
    avg_score = (
      SELECT ROUND(100.0 * SUM(CASE WHEN is_correct THEN 1 ELSE 0 END) / COUNT(*), 2)
      FROM student_answers WHERE student_id = p_student_id
    ),
    total_study_hours = (
      SELECT COALESCE(SUM(duration_minutes), 0) / 60.0
      FROM study_sessions WHERE student_id = p_student_id
    ),
    updated_at = CURRENT_TIMESTAMP
  WHERE id = p_student_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- DADOS DE EXEMPLO (OPCIONAL)
-- ============================================

-- Criar usuario exemplo
INSERT INTO users (email, password_hash, name, role, plan) 
VALUES (
  'estudante@example.com',
  crypt('senha123', gen_salt('bf')),
  'Joao Silva',
  'student',
  'premium'
) ON CONFLICT DO NOTHING;

-- Criar perfil estudante
INSERT INTO students (user_id, exam_date, target_score, daily_hours)
SELECT id, CURRENT_DATE + INTERVAL '12 weeks', 75, 2
FROM users WHERE email = 'estudante@example.com'
ON CONFLICT DO NOTHING;

-- ============================================
-- TRIGGERS PARA AUDITORIA
-- ============================================

CREATE TABLE audit_log (
  id BIGSERIAL PRIMARY KEY,
  table_name VARCHAR(255),
  operation VARCHAR(50),
  record_id UUID,
  old_data JSONB,
  new_data JSONB,
  changed_by VARCHAR(255),
  changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_log (table_name, operation, record_id, old_data, new_data, changed_at)
  VALUES (TG_TABLE_NAME, TG_OP, COALESCE(NEW.id, OLD.id), row_to_json(OLD), row_to_json(NEW), CURRENT_TIMESTAMP);
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_audit AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION audit_trigger();

CREATE TRIGGER student_answers_audit AFTER INSERT ON student_answers
FOR EACH ROW EXECUTE FUNCTION audit_trigger();

-- ============================================
-- PERMISSOES (Seguranca)
-- ============================================

-- Criar usuario para aplicacao (nao root)
CREATE ROLE app_user WITH PASSWORD 'app_secure_password_123';
GRANT CONNECT ON DATABASE oab_platform TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO app_user;

-- ============================================
-- FIM DO SCHEMA
-- ============================================
