# 🧪 TESTE DE APIS - OAB PLATFORM

**Copie e cole os comandos abaixo para testar cada endpoint**

---

## 📌 BASE URL

```
http://localhost:3001/api/v1
```

---

## 🔐 1. AUTENTICACAO

### 1.1 Criar Usuário (Register)

```bash
curl -X POST http://localhost:3001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "joao@example.com",
    "password": "senha123",
    "name": "Joao Silva",
    "daily_hours": 2
  }'
```

**Resposta (sucesso):**
```json
{
  "message": "Usuario criado com sucesso",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "joao@example.com",
    "name": "Joao Silva"
  }
}
```

**Salve o `token` - você vai usar em todas as outras requisicoes!**

---

### 1.2 Login

```bash
curl -X POST http://localhost:3001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "joao@example.com",
    "password": "senha123"
  }'
```

**Resposta (sucesso):**
```json
{
  "message": "Login bem-sucedido",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "joao@example.com",
    "name": "Joao Silva",
    "role": "student"
  }
}
```

---

## 📚 2. QUESTOES

### 2.1 Listar Questoes

```bash
curl -X GET "http://localhost:3001/api/v1/questions?subject=civil&difficulty=medium&limit=5" \
  -H "Authorization: Bearer SEU_TOKEN_AQUI"
```

**Parâmetros:**
- `subject`: civil, penal, proc_civil, proc_penal, constitucional, administrativo, etica
- `difficulty`: easy, medium, hard
- `limit`: número de questoes (padrão: 10)

**Resposta (sucesso):**
```json
{
  "count": 5,
  "questions": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "subject": "civil",
      "topic": "Contratos",
      "difficulty": "medium",
      "text": "Uma oferta é irrevogável quando...",
      "options_json": {
        "a": "Opcao A",
        "b": "Opcao B",
        "c": "Opcao C",
        "d": "Opcao D"
      }
    }
  ]
}
```

---

### 2.2 Buscar Questão Específica (COM explicação)

```bash
curl -X GET http://localhost:3001/api/v1/questions/550e8400-e29b-41d4-a716-446655440001 \
  -H "Authorization: Bearer SEU_TOKEN_AQUI"
```

**Resposta (sucesso):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "subject": "civil",
  "topic": "Contratos",
  "difficulty": "medium",
  "text": "Uma oferta é irrevogável quando...",
  "options_json": {
    "a": "Opcao A",
    "b": "Opcao B",
    "c": "Opcao C",
    "d": "Opcao D"
  },
  "explanation": "Segundo o Código Civil, contratos podem ser revogados em certos casos..."
}
```

---

### 2.3 Responder Questão

```bash
curl -X POST http://localhost:3001/api/v1/questions/550e8400-e29b-41d4-a716-446655440001/answer \
  -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "answer_choice": "B",
    "time_spent_seconds": 45
  }'
```

**Resposta (acerto):**
```json
{
  "is_correct": true,
  "correct_answer": "B",
  "explanation": "Essa é a resposta correta porque...",
  "message": "Correto!"
}
```

**Resposta (erro):**
```json
{
  "is_correct": false,
  "correct_answer": "B",
  "explanation": "Você marcou A, mas a resposta correta é B porque...",
  "message": "Incorreto. Veja a explicacao acima."
}
```

---

## 🎯 3. SESSOES DE ESTUDO

### 3.1 Iniciar Sessão

```bash
curl -X POST http://localhost:3001/api/v1/sessions/start \
  -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "subject": "civil",
    "method": "questoes"
  }'
```

**Parâmetros de `method`:**
- `estudo`: Estudar teoria
- `questoes`: Fazer questoes
- `simulado`: Simulado completo
- `revisao`: Revisar topicos

**Resposta (sucesso):**
```json
{
  "message": "Sessao iniciada",
  "session_id": "550e8400-e29b-41d4-a716-446655440003",
  "start_time": "14:30:45"
}
```

---

### 3.2 Finalizar Sessão

```bash
curl -X POST http://localhost:3001/api/v1/sessions/550e8400-e29b-41d4-a716-446655440003/end \
  -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "duration_minutes": 60,
    "energy_level_after": 7
  }'
```

**Resposta (sucesso):**
```json
{
  "message": "Sessao finalizada",
  "session_summary": {
    "duration_minutes": 60,
    "questions_answered": 12,
    "correct_answers": 9,
    "accuracy_percent": 75
  }
}
```

---

## 📊 4. PERFORMANCE

### 4.1 Ver Performance Semanal

```bash
curl -X GET "http://localhost:3001/api/v1/students/SEU_STUDENT_ID/performance?week=5&subject=civil" \
  -H "Authorization: Bearer SEU_TOKEN_AQUI"
```

**Resposta (sucesso):**
```json
{
  "count": 1,
  "performance": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440005",
      "student_id": "550e8400-e29b-41d4-a716-446655440000",
      "week": 5,
      "subject": "civil",
      "accuracy_pct": 75.50,
      "velocity_questions_per_min": 1.2,
      "retention_score": 78.30,
      "improvement_trend": 5.2,
      "review_count": 3
    }
  ]
}
```

---

### 4.2 Ver Resumo do Estudante

```bash
curl -X GET http://localhost:3001/api/v1/students/SEU_STUDENT_ID/summary \
  -H "Authorization: Bearer SEU_TOKEN_AQUI"
```

**Resposta (sucesso):**
```json
{
  "total_study_hours": 48.5,
  "total_questions_done": 342,
  "avg_score": 71.8,
  "current_week": 5,
  "motivation_level": 8
}
```

---

## ✅ 5. HEALTH CHECK (SEM AUTENTICACAO)

```bash
curl http://localhost:3001/api/health
```

**Resposta (sucesso):**
```json
{
  "status": "OK",
  "database": "connected",
  "timestamp": "2025-06-08T14:30:00.000Z"
}
```

**Resposta (erro):**
```json
{
  "status": "ERROR",
  "database": "disconnected",
  "timestamp": "2025-06-08T14:30:00.000Z"
}
```

---

## 🧪 TESTE COMPLETO (CENARIO REAL)

### Passo 1: Criar usuario

```bash
export TOKEN=$(curl -s -X POST http://localhost:3001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste'$(date +%s)'@example.com",
    "password": "senha123",
    "name": "Usuario Teste",
    "daily_hours": 1
  }' | jq -r '.token')

echo "Token: $TOKEN"
```

### Passo 2: Pegar questao

```bash
export QUESTION_ID=$(curl -s -X GET "http://localhost:3001/api/v1/questions?limit=1" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.questions[0].id')

echo "Question: $QUESTION_ID"
```

### Passo 3: Iniciar sessao

```bash
export SESSION_ID=$(curl -s -X POST http://localhost:3001/api/v1/sessions/start \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "subject": "civil",
    "method": "questoes"
  }' | jq -r '.session_id')

echo "Session: $SESSION_ID"
```

### Passo 4: Responder questao

```bash
curl -X POST http://localhost:3001/api/v1/questions/$QUESTION_ID/answer \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "answer_choice": "A",
    "time_spent_seconds": 45
  }' | jq '.'
```

### Passo 5: Finalizar sessao

```bash
curl -X POST http://localhost:3001/api/v1/sessions/$SESSION_ID/end \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "duration_minutes": 60,
    "energy_level_after": 7
  }' | jq '.'
```

### Passo 6: Ver performance

```bash
curl -s -X GET "http://localhost:3001/api/v1/students/SEU_STUDENT_ID/summary" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

---

## 🔴 CODIGOS DE ERRO ESPERADOS

| Código | Significado | Solução |
|--------|-------------|---------|
| 200 | OK | Tudo bem! |
| 201 | Created | Usuario/sessao criado |
| 400 | Bad Request | Verificar parametros enviados |
| 401 | Unauthorized | Token inválido ou expirado |
| 403 | Forbidden | Sem permissão |
| 404 | Not Found | Recurso não existe |
| 500 | Internal Server Error | Erro no servidor - ver logs |

---

## 🛠 TESTAR COM POSTMAN

1. Baixar Postman: https://www.postman.com/downloads/
2. Criar nova Request
3. Selecionar método (GET, POST, etc)
4. Colar URL
5. Headers → Authorization: Bearer SEU_TOKEN
6. Body → raw → JSON
7. Colar JSON
8. Clicar "Send"

**Dica:** Criar variável para token no Postman:
```javascript
// Em "Tests" da response de login:
pm.environment.set("token", pm.response.json().token);

// Depois usar {{token}} em outros headers
```

---

## 📊 EXEMPLO REAL DE USO (Node.js)

```javascript
// teste.js
const axios = require('axios');

const BASE_URL = 'http://localhost:3001/api/v1';

async function testarAPI() {
  try {
    // 1. Registrar
    const registerRes = await axios.post(`${BASE_URL}/auth/register`, {
      email: `teste${Date.now()}@example.com`,
      password: 'senha123',
      name: 'Teste',
      daily_hours: 1
    });

    const token = registerRes.data.token;
    console.log('✅ Usuario criado');

    // 2. Listar questoes
    const questionsRes = await axios.get(`${BASE_URL}/questions?limit=1`, {
      headers: { Authorization: `Bearer ${token}` }
    });

    const questionId = questionsRes.data.questions[0].id;
    console.log('✅ Questao carregada');

    // 3. Responder
    const answerRes = await axios.post(`${BASE_URL}/questions/${questionId}/answer`, {
      answer_choice: 'A',
      time_spent_seconds: 45
    }, {
      headers: { Authorization: `Bearer ${token}` }
    });

    console.log('✅ Resposta registrada:', answerRes.data.is_correct ? 'CORRETO' : 'ERRADO');

  } catch (err) {
    console.error('❌ Erro:', err.response?.data || err.message);
  }
}

testarAPI();
```

---

**Pronto para testar? Comece pelo Health Check! ✅**
