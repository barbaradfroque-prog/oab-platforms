# ============================================
# Dockerfile - OAB Platform Backend
# ============================================

FROM node:18-alpine

WORKDIR /app

# Copiar package.json e package-lock.json
COPY package*.json ./

# Instalar dependencias
RUN npm ci --only=production

# Copiar codigo
COPY 02_backend_api.js .
COPY .env .

# Criar diretorio de logs
RUN mkdir -p logs

# Expor porta
EXPOSE 3001

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/api/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Iniciar aplicacao
CMD ["npm", "start"]
