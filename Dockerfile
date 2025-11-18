# Imagem base com Node.js (exemplo de aplicação)
FROM node:18-alpine AS builder

# Metadados da imagem
LABEL maintainer="grometis@jenkins-cicd"
LABEL description="Aplicação de exemplo para CI/CD com Jenkins"

# Argumentos de build
ARG BUILD_NUMBER=unknown
ARG GIT_COMMIT=unknown
ARG BUILD_DATE=unknown

# Variáveis de ambiente
ENV NODE_ENV=production \
    BUILD_NUMBER=${BUILD_NUMBER} \
    GIT_COMMIT=${GIT_COMMIT} \
    BUILD_DATE=${BUILD_DATE}

# Diretório de trabalho
WORKDIR /app

# Copiar arquivos de dependências
COPY package*.json ./

# Instalar dependências
RUN npm ci --omit=dev && \
    npm cache clean --force

# Copiar código fonte
COPY . .

# Build da aplicação (se necessário)
# RUN npm run build

# Estágio final - imagem otimizada
FROM node:18-alpine

# Adicionar usuário não-root para segurança
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Definir diretório de trabalho
WORKDIR /app

# Copiar dependências do estágio builder
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./
COPY --from=builder --chown=nodejs:nodejs /app .

# Mudar para usuário não-root
USER nodejs

# Expor porta da aplicação
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1); })" || exit 1

# Comando para iniciar a aplicação
CMD ["node", "index.js"]
