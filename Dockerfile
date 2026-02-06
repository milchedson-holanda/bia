FROM public.ecr.aws/docker/library/node:22-slim

# Instalar dependências do sistema necessárias
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

# 1. Copiar package.json do backend
COPY package*.json ./
RUN npm install --loglevel=error --production

# 2. Copiar package.json do client
COPY client/package*.json ./client/
RUN cd client && npm install --legacy-peer-deps --loglevel=error --production

# 3. Copiar todo o código
COPY . .

# 4. Build do front-end
RUN cd client && VITE_API_URL=https://bia-formaws.com npm run build

# 5. Mover build do frontend para pasta pública do backend (se necessário)
RUN mv client/dist ./public || true

# 6. Verificar estrutura do projeto
RUN ls -la && echo "=== Backend structure ===" && find . -name "*.js" -o -name "*.json" | head -20

# 7. Expor porta correta
EXPOSE 8080

# 8. Iniciar aplicação CORRETAMENTE
# Verifique qual é o script "start" no package.json
CMD ["node", "server.js"]  # OU ["npm", "start"] se estiver correto
