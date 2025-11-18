# 🚀 Guia: Deploy para Servidor de Produção Separado

## 📐 Nova Arquitetura

```
┌─────────────────────────────────────────┐
│  MacOS (Desenvolvedor)                  │
│  - Desenvolve código                    │
│  - git push → GitHub                    │
└──────────────┬──────────────────────────┘
               │
               ↓
┌─────────────────────────────────────────┐
│  GitHub Repository                      │
│  - Armazena código fonte                │
└──────────────┬──────────────────────────┘
               │
               ↓ Webhook/Poll
┌─────────────────────────────────────────┐
│  VM Jenkins (10.224.139.x)             │
│  Ubuntu Server: 192.168.15.6            │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │ jenkins-cicd (Multipass VM)      │  │
│  │ - Jenkins (porta 8080)            │  │
│  │ - CI/CD Automation                │  │
│  │ - Build & Test                    │  │
│  └──────────────────────────────────┘  │
└──────────────┬──────────────────────────┘
               │
               │ SSH Deploy
               ↓
┌─────────────────────────────────────────┐
│  SERVIDOR DE PRODUÇÃO                   │
│  192.168.15.6 (Host Ubuntu)             │
│                                         │
│  - Docker instalado                     │
│  - Aplicação rodando (porta 3000)       │
│  - Acessível na rede local              │
└─────────────────────────────────────────┘
```

## ✅ Vantagens desta Arquitetura

1. **Separação de Responsabilidades**
   - Jenkins (VM): Apenas automação
   - Produção (Host): Apenas aplicação

2. **Melhor Performance**
   - Recursos não competem
   - App tem mais memória/CPU disponível

3. **Isolamento**
   - Se Jenkins cair, app continua rodando
   - Manutenção do Jenkins não afeta produção

4. **Segurança**
   - Jenkins em VM isolada
   - Produção no host físico mais estável

## 🔧 Setup Completo

### Passo 1: Instalar Docker no Servidor de Produção

**Execute no servidor Ubuntu (192.168.15.6)** via SSH:

```bash
# Do seu MacOS, conecte ao servidor
ssh grometis@192.168.15.6

# Dentro do servidor
cd ~/grometis-jenkins

# Atualizar repositório
git pull origin main

# Dar permissão e executar script
chmod +x install-docker-production.sh
./install-docker-production.sh
```

**⚠️ IMPORTANTE**: Após a instalação, você DEVE fazer logout e login novamente:

```bash
# Sair
exit

# Reconectar
ssh grometis@192.168.15.6

# Testar Docker
docker --version
docker ps
```

### Passo 2: Verificar Chaves SSH

O SSH já está configurado! Execute o diagnóstico para confirmar:

```bash
cd ~/grometis-jenkins
./diagnose-ssh.sh
```

Deve mostrar:
- ✓ Chave privada do Jenkins existe
- ✓ Chave pública do Jenkins existe  
- ✓ Chave do Jenkins está no authorized_keys
- ✓ Conexão SSH funcionando!

### Passo 3: Testar Deploy Manual (Opcional)

Antes de rodar o pipeline, você pode testar manualmente:

```bash
# No servidor de produção (192.168.15.6)
mkdir -p ~/deployments/grometis-app
cd ~/deployments/grometis-app

# Criar docker-compose.yml de teste
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  app:
    image: fabriciobackend/grometis-app:latest
    ports:
      - "3000:3000"
    restart: unless-stopped
EOF

# Testar
docker compose pull
docker compose up -d
docker compose ps

# Testar aplicação
curl http://localhost:3000/health

# Limpar (opcional)
docker compose down
```

### Passo 4: Executar Pipeline no Jenkins

1. **Acesse o Jenkins**: http://10.224.139.x:8080

2. **Abra seu pipeline**: `grometis-cicd-pipeline` → `main`

3. **Click em "Build Now"**

4. **Acompanhe a execução**: Click no número do build → Console Output

## 📊 O que o Pipeline Faz Agora

```
[1] Checkout
    ↓ Busca código do GitHub
    
[2] Environment Check
    ↓ Verifica Docker, Git, Java
    
[3] Build Docker Image
    ↓ Cria imagem na VM Jenkins
    
[4] Test Docker Image
    ↓ Testa se a imagem funciona
    
[5] Push to Docker Hub
    ↓ Envia imagem para Docker Hub
    
[6] Deploy to Production 🆕
    ↓ SSH para 192.168.15.6
    ↓ Copia docker-compose.yml
    ↓ docker compose pull (baixa do Docker Hub)
    ↓ docker compose up -d (inicia app)
    
[7] Verify Deployment 🆕
    ↓ SSH para 192.168.15.6
    ↓ Verifica containers rodando
    ↓ Mostra logs
    ↓ Testa endpoint /health
    
✅ App rodando em http://192.168.15.6:3000
```

## 🎯 Fluxo de Desenvolvimento

### 1. Desenvolvimento Local (seu MacOS)

```bash
cd ~/meu-projeto
# Edita código
code .

# Testa localmente
npm run dev

# Commita
git add .
git commit -m "Adiciona nova feature"
git push origin main
```

### 2. CI/CD Automático (Jenkins)

```
⏱️ Em ~1 minuto, Jenkins detecta o push

🔄 Pipeline executa automaticamente:
   ✓ Build
   ✓ Test
   ✓ Push to Docker Hub
   ✓ Deploy to Production (192.168.15.6)
   
✅ Em 3-5 minutos: Nova versão em produção!
```

### 3. Verificar em Produção

```bash
# Acessar app
curl http://192.168.15.6:3000
# ou no navegador
open http://192.168.15.6:3000

# Ver logs
ssh grometis@192.168.15.6
cd ~/deployments/grometis-app
docker compose logs -f
```

## 🔍 Monitoramento

### Ver status da aplicação

```bash
ssh grometis@192.168.15.6
cd ~/deployments/grometis-app

# Status dos containers
docker compose ps

# Logs em tempo real
docker compose logs -f

# Logs específicos
docker compose logs app --tail=50

# Uso de recursos
docker stats
```

### Restart manual se necessário

```bash
ssh grometis@192.168.15.6
cd ~/deployments/grometis-app

# Restart
docker compose restart

# Rebuild (se mudou docker-compose.yml)
docker compose down
docker compose up -d
```

## 🚨 Troubleshooting

### App não inicia após deploy

```bash
# Ver logs detalhados
ssh grometis@192.168.15.6
cd ~/deployments/grometis-app
docker compose logs

# Verificar se a porta está em uso
sudo netstat -tlnp | grep 3000

# Parar todos os containers
docker compose down

# Iniciar novamente
docker compose up -d
```

### Docker não encontrado

```bash
# Verificar instalação
docker --version

# Se der erro de permissão
sudo usermod -aG docker $USER
# Faça logout e login novamente
```

### SSH falha no pipeline

```bash
# No servidor de produção (192.168.15.6)
cd ~/grometis-jenkins
./diagnose-ssh.sh

# Se necessário, reconfigurar
./setup-ssh-target.sh
```

## 📈 Próximos Passos (Opcional)

### 1. Adicionar Monitoramento

- Instalar Prometheus + Grafana
- Monitorar recursos (CPU, RAM, Disk)
- Alertas automáticos

### 2. Configurar SSL/HTTPS

- Usar Nginx como reverse proxy
- Certificado SSL com Let's Encrypt
- Acesso seguro via HTTPS

### 3. Múltiplos Ambientes

```
Branch dev → Deploy em servidor de staging
Branch main → Deploy em produção
```

### 4. Backup Automático

- Backup de dados da aplicação
- Backup de configurações
- Restore automático

### 5. Zero Downtime Deployment

- Blue-Green Deployment
- Rolling Updates
- Health checks antes de finalizar

---

## 📝 Checklist de Setup

- [ ] Docker instalado no servidor de produção (192.168.15.6)
- [ ] Logout e login após instalar Docker
- [ ] SSH testado e funcionando (./diagnose-ssh.sh)
- [ ] Jenkinsfile atualizado (já feito automaticamente)
- [ ] Pipeline executado com sucesso
- [ ] Aplicação acessível em http://192.168.15.6:3000

---

**Pronto! Agora você tem um pipeline CI/CD profissional com deploy em servidor de produção separado! 🎉**
