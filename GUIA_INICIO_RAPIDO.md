# 🚀 GUIA DE INÍCIO RÁPIDO - OAB PLATFORM

**Tempo estimado: 15 minutos para ter tudo rodando**

---

## 📋 PRÉ-REQUISITOS

Instale antes de começar:

```bash
# 1. Node.js 18+
# Download em: https://nodejs.org/
node --version  # Deve mostrar v18.0.0 ou maior

# 2. PostgreSQL 13+
# Download em: https://www.postgresql.org/download/
psql --version  # Deve mostrar 13.0 ou maior

# 3. Redis (opcional, mas recomendado)
# Download em: https://redis.io/download/
redis-cli --version  # Deve mostrar redis 7.0 ou maior

# 4. Git
git --version  # Deve mostrar 2.0 ou maior
```

---

## 🔧 INSTALAÇÃO (3 opções)

### OPÇÃO 1: Docker (RECOMENDADO - Mais fácil)

```bash
# 1. Baixar ou clonar projeto
git clone <seu-repo> oab-platform
cd oab-platform

# 2. Começar tudo com um comando
docker-compose up -d

# 3. Verificar se tudo está rodando
docker-compose ps

# 4. Visualizar logs
docker-compose logs -f backend

# 5. Parar tudo
docker-compose down
```

**Pronto! O sistema está rodando:**
- API: http://localhost:3001
- pgAdmin: http://localhost:5050 (email: admin@example.com, senha: admin)
- Redis: localhost:6379

---

### OPÇÃO 2: Instalação Local (Sem Docker)

#### Passo 1: Criar banco de dados

```bash
# Conectar ao PostgreSQL
psql -U postgres

# No prompt do PostgreSQL, rodar:
CREATE DATABASE oab_platform;
\q

# Aplicar schema
psql -U postgres -d oab_platform -f 01_database_schema.sql

# Verificar se funcionou
psql -U postgres -d oab_platform -c "SELECT * FROM users LIMIT 1;"
```

#### Passo 2: Instalar Node.js

```bash
# Installar dependencias
npm install

# Verificar
npm list pg express jsonwebtoken
```

#### Passo 3: Configurar .env

```bash
# Copiar arquivo de exemplo
cp .env.example .env

# Editar .env com suas credenciais
nano .env
# ou
code .env  # VS Code
```

#### Passo 4: Rodar servidor

```bash
# Em desenvolvimento (com reload automático)
npm run dev

# Em produção
npm start
```

**Pronto! API rodando em http://localhost:3001**

---

### OPÇÃO 3: Deploy em Produção (Heroku/Railway/Render)

#### Heroku

```bash
# 1. Criar conta em https://heroku.com

# 2. Instalar Heroku CLI
curl https://cli-assets.heroku.com/install.sh | sh

# 3. Fazer login
heroku login

# 4. Criar app
heroku create oab-platform

# 5. Adicionar PostgreSQL
heroku addons:create heroku-postgresql:hobby-dev

# 6. Deploy
git push heroku main

# 7. Ver logs
heroku logs --tail
```

---

## ✅ TESTE SE FUNCIONOU

### 1. Health Check

```bash
curl http://localhost:3001/api/health
```

**Resposta esperada:**
```json
{
  "status": "OK",
  "database": "connected",
  "timestamp": "2025-06-08T10:30:00.000Z"
}
```

### 2. Criar usuário

```bash
curl -X POST http://localhost:3001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "estudante@example.com",
    "password": "senha123",
    "name": "Joao Silva",
    "daily_hours": 2
  }'
```

**Resposta esperada:**
```json
{
  "message": "Usuario criado com sucesso",
  "user_id": "uuid-aqui",
  "token": "jwt-token-aqui",
  "user": {
    "id": "uuid-aqui",
    "email": "estudante@example.com",
    "name": "Joao Silva"
  }
}
```

### 3. Fazer login

```bash
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "estudante@example.com",
    "password": "senha123"
  }'
```

**Guarde o token retornado - você vai precisar dele!**

### 4. Listar questões (com autenticação)

```bash
curl http://localhost:3001/api/v1/questions?subject=civil&limit=5 \
  -H "Authorization: Bearer SEU_TOKEN_AQUI"
```

---

## 📊 INSERIR QUESTÕES NA BASE

O sistema começa vazio. Você precisa importar questões reais da OAB.

### Opção A: Via SQL direto

```sql
-- Conectar ao banco
psql -U app_user -d oab_platform

-- Inserir exemplo
INSERT INTO questions (subject, topic, difficulty, year, text, options_json, correct_answer, explanation, source_oab)
VALUES (
  'civil',
  'Contratos',
  'medium',
  2024,
  'Uma oferta é irrevogável quando...',
  '{"a": "Resposta A", "b": "Resposta B", "c": "Resposta C", "d": "Resposta D"}',
  'B',
  'Contratos podem ser revogados em certos casos...',
  'OAB 2024-01'
);
```

### Opção B: Carregar CSV

```bash
# Copiar arquivo CSV com questões
\COPY questions (subject, topic, difficulty, year, text, options_json, correct_answer) FROM 'questoes.csv' WITH CSV HEADER;
```

### Opção C: Via script Node

```javascript
// 03_seed_questions.js
const pool = require('pg').Pool;
const fs = require('fs');

const questions = JSON.parse(fs.readFileSync('questoes.json', 'utf8'));

questions.forEach(async (q) => {
  await pool.query(
    'INSERT INTO questions (subject, topic, difficulty, year, text, options_json, correct_answer, explanation) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
    [q.subject, q.topic, q.difficulty, q.year, q.text, JSON.stringify(q.options), q.correct, q.explanation]
  );
});

console.log('Questoes importadas com sucesso!');
```

---

## 🔐 SEGURANÇA EM PRODUÇÃO

Antes de ir pro ar, fazer essas 3 coisas:

```bash
# 1. Mudar JWT_SECRET
# Gerar string aleatoria
openssl rand -base64 32

# 2. Mudar senhas de database
# Editar .env com senhas fortes

# 3. Ativar SSL
# Em produção, SEMPRE use HTTPS
# Usar Let's Encrypt (gratis)
# https://letsencrypt.org/

# 4. Rate limiting
# Já está configurado, mas revisar valores em 02_backend_api.js

# 5. CORS
# Editar lista de origens permitidas em 02_backend_api.js
```

---

## 📱 CONECTAR FRONTEND

### React

```javascript
// src/api.js
import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost:3001/api/v1',
});

// Adicionar token em cada request
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default api;
```

### Exemplo de uso

```javascript
// components/Login.jsx
import api from '../api';

const handleLogin = async (email, password) => {
  const response = await api.post('/auth/login', { email, password });
  localStorage.setItem('token', response.data.token);
  // Redirecionar para dashboard
};
```

---

## 🐛 TROUBLESHOOTING

### Erro: "connect ECONNREFUSED 127.0.0.1:5432"

```bash
# PostgreSQL não está rodando
# Solução:
sudo systemctl start postgresql  # Linux
brew services start postgresql   # MacOS
# Windows: Iniciar via Services
```

### Erro: "password authentication failed"

```bash
# Senha incorreta no .env
# Solução:
psql -U postgres
ALTER USER app_user WITH PASSWORD 'new_password';
# Atualizar .env
```

### Erro: "ENOENT: no such file or directory .env"

```bash
# Arquivo .env não existe
# Solução:
cp .env.example .env
# Editar com suas credenciais
```

### API responde 401 Unauthorized

```bash
# Token expirou ou inválido
# Solução:
# 1. Fazer login novamente
# 2. Usar novo token
# 3. Verificar se JWT_SECRET é o mesmo no .env
```

---

## 📊 MONITORAR PRODUÇÃO

### Ver logs em tempo real

```bash
# Docker
docker-compose logs -f backend

# Arquivo
tail -f logs/app.log

# Sentry (opcional)
# https://sentry.io/
# Integrar em 02_backend_api.js
```

### Verificar performance

```bash
# Conexões de database
psql -U app_user -d oab_platform -c "SELECT count(*) FROM pg_stat_activity;"

# Tamanho do database
psql -U app_user -d oab_platform -c "SELECT pg_size_pretty(pg_database_size('oab_platform'));"

# Queries lentas
psql -U app_user -d oab_platform -c "SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"
```

---

## 🚀 PRÓXIMOS PASSOS

1. ✅ Backend rodando? Ir para **Conectar Frontend**
2. 🔐 Mudar senhas de produção
3. 📱 Implementar React frontend
4. 🧪 Testar todos endpoints com Postman
5. 🚢 Deploy em produção
6. 📊 Monitorar com Datadog/NewRelic
7. 🔔 Configurar alertas no Slack

---

## 📞 SUPORTE

Se algo der errado:

1. Verificar logs: `docker-compose logs backend`
2. Verificar saúde: `curl http://localhost:3001/api/health`
3. Testar database: `psql -U app_user -d oab_platform -c "SELECT 1;"`
4. Reiniciar: `docker-compose restart`

---

**Parabéns! 🎉 Seu sistema de aprovação OAB está online!**
