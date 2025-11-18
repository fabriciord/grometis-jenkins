const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware para JSON
app.use(express.json());

// Informações de build
const buildInfo = {
  buildNumber: process.env.BUILD_NUMBER || 'dev',
  gitCommit: process.env.GIT_COMMIT || 'unknown',
  buildDate: process.env.BUILD_DATE || new Date().toISOString(),
  nodeVersion: process.version,
  environment: process.env.NODE_ENV || 'development'
};

// Rota principal
app.get('/', (req, res) => {
  res.json({
    message: 'Bem-vindo à aplicação GrOMEtiS CI/CD!',
    status: 'running',
    timestamp: new Date().toISOString(),
    build: buildInfo
  });
});

// Rota de health check
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// Rota para informações de build
app.get('/info', (req, res) => {
  res.json({
    application: 'GrOMEtiS App',
    version: '1.0.0',
    build: buildInfo,
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    platform: process.platform,
    arch: process.arch
  });
});

// Rota de exemplo - API
app.get('/api/data', (req, res) => {
  res.json({
    data: [
      { id: 1, name: 'Item 1', description: 'Exemplo de dados' },
      { id: 2, name: 'Item 2', description: 'Mais dados de exemplo' },
      { id: 3, name: 'Item 3', description: 'Dados do Jenkins CI/CD' }
    ],
    timestamp: new Date().toISOString()
  });
});

// Tratamento de erro 404
app.use((req, res) => {
  res.status(404).json({
    error: 'Rota não encontrada',
    path: req.path
  });
});

// Tratamento de erros gerais
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Erro interno do servidor',
    message: err.message
  });
});

// Iniciar servidor
app.listen(PORT, '0.0.0.0', () => {
  console.log('========================================');
  console.log(`🚀 Servidor rodando na porta ${PORT}`);
  console.log(`📝 Ambiente: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔨 Build: ${buildInfo.buildNumber}`);
  console.log(`📦 Commit: ${buildInfo.gitCommit?.substring(0, 7) || 'unknown'}`);
  console.log(`📅 Data: ${buildInfo.buildDate}`);
  console.log('========================================');
  console.log(`\nEndpoints disponíveis:`);
  console.log(`  - http://localhost:${PORT}/`);
  console.log(`  - http://localhost:${PORT}/health`);
  console.log(`  - http://localhost:${PORT}/info`);
  console.log(`  - http://localhost:${PORT}/api/data`);
  console.log('');
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM recebido. Encerrando servidor...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT recebido. Encerrando servidor...');
  process.exit(0);
});
