FROM public.ecr.aws/docker/library/node:22-slim

# Instalar dependências do sistema necessárias
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app

# 1. Copiar package.json do backend
COPY package*.json ./
RUN npm install --loglevel=error

# 2. Copiar package.json do client
COPY client/package*.json ./client/
RUN cd client && npm install --legacy-peer-deps --loglevel=error

# 3. Copiar todo o código
COPY . .

# 4. Build do front-end (AGORA VITE ESTÁ INSTALADO)
RUN cd client && VITE_API_URL=https://bia-formaws.com npm run build

# 5. Limpar node_modules do client (opcional para reduzir tamanho)
RUN rm -rf client/node_modules

# 6. Limpar devDependencies do backend (mantendo apenas production)
RUN npm prune --production

# 7. Expor porta
EXPOSE 8080

# 8. Iniciar aplicação
# Verifique qual arquivo é o entry point
CMD ["node", "server.js"]  # OU ["npm", "start"]
