# 🚀 Projeto CI/CD com Jenkins, Docker e Multipass

Projeto completo de CI/CD utilizando Jenkins para automatizar o processo de build, test, push e deploy de uma aplicação containerizada com Docker.

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Pré-requisitos](#pré-requisitos)
- [Arquitetura](#arquitetura)
- [Instalação e Configuração](#instalação-e-configuração)
  - [1. Criar a VM com Multipass](#1-criar-a-vm-com-multipass)
  - [2. Configurar Jenkins](#2-configurar-jenkins)
  - [3. Configurar Credenciais](#3-configurar-credenciais)
  - [4. Configurar SSH](#4-configurar-ssh)
  - [5. Criar Pipeline](#5-criar-pipeline)
- [Pipeline CI/CD](#pipeline-cicd)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Troubleshooting](#troubleshooting)
- [Boas Práticas](#boas-práticas)

---

## 🎯 Visão Geral

Este projeto implementa um pipeline completo de CI/CD que:

1. **Checkout**: Busca o código do repositório GitHub
2. **Build**: Constrói uma imagem Docker da aplicação
3. **Test**: Executa testes da imagem
4. **Push**: Envia a imagem para o Docker Hub
5. **Deploy**: Faz deploy da aplicação na VM usando Docker Compose
6. **Verify**: Verifica se o deploy foi bem-sucedido

### Tecnologias Utilizadas

- **Jenkins**: Orquestração do pipeline CI/CD
- **Docker**: Containerização da aplicação
- **Docker Compose**: Orquestração de containers
- **Multipass**: Virtualização da VM Ubuntu
- **Node.js**: Aplicação de exemplo (pode ser substituída)
- **GitHub**: Controle de versão

---

## 📦 Pré-requisitos

### No seu MacOS (máquina local):

- Acesso SSH ao servidor Ubuntu
- Git (para versionamento do código)

### No Ubuntu Server (192.168.15.6):

- **Multipass**: Já instalado e configurado no servidor
- Acesso SSH: `ssh grometis@192.168.15.6`
- Conexão com a internet
- Pelo menos 4GB de RAM e 20GB de disco disponíveis para a VM

### Contas necessárias:

- **GitHub**: Para hospedar o código
- **Docker Hub**: Para armazenar as imagens Docker

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│               MacOS (Máquina do Desenvolvedor)               │
│                                                              │
│  - Acesso SSH ao servidor                                    │
│  - Git para versionamento                                    │
│  - Git Push → GitHub Repository                              │
└────────────────────────┬────────────────────────────────────┘
                         │ SSH & Git Push
                         │ Webhook/Poll SCM
                         ↓
┌─────────────────────────────────────────────────────────────┐
│         Ubuntu Server (192.168.15.6) - Físico/VM            │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │          Multipass (instalado no servidor)          │  │
│  │                                                      │  │
│  │  ┌──────────────────────────────────────────────┐  │  │
│  │  │       VM Ubuntu (jenkins-cicd)                │  │  │
│  │  │                                               │  │  │
│  │  │  ┌────────────────────────────────────────┐  │  │  │
│  │  │  │    Jenkins (Port 8080)                 │  │  │  │
│  │  │  │                                        │  │  │  │
│  │  │  │  1. Checkout from GitHub              │  │  │  │
│  │  │  │  2. Build Docker Image                │  │  │  │
│  │  │  │  3. Push to Docker Hub                │  │  │  │
│  │  │  │  4. Deploy via SSH (localhost)        │  │  │  │
│  │  │  └────────────────────────────────────────┘  │  │  │
│  │  │                                               │  │  │
│  │  │  ┌────────────────────────────────────────┐  │  │  │
│  │  │  │    Docker + Docker Compose             │  │  │  │
│  │  │  │                                        │  │  │  │
│  │  │  │    Application (Port 3000)             │  │  │  │
│  │  │  └────────────────────────────────────────┘  │  │  │
│  │  └──────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ Pull Image
                         ↓
                  Docker Hub Registry
```

---

## 🚀 Instalação e Configuração

### 1. Criar a VM com Multipass

#### Passo 1.1: Preparar os arquivos

**IMPORTANTE**: O Multipass está instalado no Ubuntu Server (192.168.15.6), NÃO no seu MacOS.

No seu MacOS, copie os arquivos para o Ubuntu Server:

```bash
# No seu MacOS (máquina local)
cd /Users/fabriciogomes/GrOMEtiS
scp -r grometis-jenkins/ grometis@192.168.15.6:~/

# Conectar ao Ubuntu Server onde o Multipass está instalado
ssh grometis@192.168.15.6

# Navegar para o diretório
cd ~/grometis-jenkins
```

#### Passo 1.2: Criar a VM

**ATENÇÃO**: Execute estes comandos **DENTRO do servidor Ubuntu** (192.168.15.6), onde o Multipass está instalado.

```bash
# Conectado ao Ubuntu Server via SSH
ssh grometis@192.168.15.6

# Dentro do servidor Ubuntu
cd ~/grometis-jenkins

# Dar permissão de execução aos scripts
chmod +x create-vm.sh setup-jenkins.sh configure-ssh.sh verify-installation.sh

# Criar a VM com cloud-init (roda no servidor Ubuntu)
./create-vm.sh
```

Este script irá:
- Criar uma VM Ubuntu 22.04 **dentro do servidor usando Multipass**
- Instalar Docker e Docker Compose
- Instalar e configurar Jenkins
- Configurar usuários e permissões

**⏱️ Aguarde aproximadamente 5-10 minutos** para a instalação completa.

#### Passo 1.3: Verificar a instalação

```bash
# Ainda conectado ao Ubuntu Server (192.168.15.6)

# Entrar na VM criada pelo Multipass
multipass shell jenkins-cicd

# Ou via SSH (obter IP da VM)
ssh grometis@$(multipass info jenkins-cicd | grep IPv4 | awk '{print $2}')

# Dentro da VM, executar verificação
cd ~/grometis-jenkins
./verify-installation.sh
```

---

### 2. Configurar Jenkins

#### Passo 2.1: Acessar o Jenkins

1. Obter o IP da VM:
   ```bash
   multipass info jenkins-cicd | grep IPv4
   ```

2. Acessar no navegador:
   ```
   http://192.168.15.6:8080
   ```

#### Passo 2.2: Desbloquear Jenkins

1. Obter a senha inicial:
   ```bash
   multipass exec jenkins-cicd -- sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

2. Cole a senha no Jenkins

#### Passo 2.3: Instalar Plugins

Selecione **"Install suggested plugins"** e adicione:

- **Docker Pipeline**
- **SSH Agent Plugin**
- **GitHub Integration Plugin**
- **Credentials Binding Plugin**
- **Pipeline Utility Steps**
- **AnsiColor** (opcional, para logs coloridos)

#### Passo 2.4: Criar usuário admin

- Username: `admin`
- Password: (escolha uma senha forte)
- Nome completo: `Jenkins Admin`
- Email: seu email

---

### 3. Configurar Credenciais

#### Passo 3.1: Acessar Credenciais

1. No Jenkins, vá para: **Manage Jenkins** → **Credentials** → **System** → **Global credentials**

#### Passo 3.2: Adicionar Docker Hub Credentials

1. Click em **Add Credentials**
2. Configurar:
   - **Kind**: Username with password
   - **Scope**: Global
   - **Username**: seu-usuario-dockerhub
   - **Password**: seu-token-dockerhub
   - **ID**: `dockerhub-credentials`
   - **Description**: Docker Hub Credentials

#### Passo 3.3: Adicionar Docker Hub Username (separado)

1. Click em **Add Credentials**
2. Configurar:
   - **Kind**: Secret text
   - **Secret**: seu-usuario-dockerhub
   - **ID**: `dockerhub-username`
   - **Description**: Docker Hub Username

#### Passo 3.4: Adicionar GitHub Credentials

1. Click em **Add Credentials**
2. Configurar:
   - **Kind**: Username with password (ou Personal Access Token)
   - **Username**: seu-usuario-github
   - **Password**: seu-token-github (gere em GitHub → Settings → Developer settings → Personal access tokens)
   - **ID**: `github-credentials`
   - **Description**: GitHub Credentials

---

### 4. Configurar SSH

#### Passo 4.1: Gerar chave SSH

Dentro da VM:

```bash
# Conectar à VM
multipass shell jenkins-cicd

# Executar script de configuração SSH
cd ~/grometis-jenkins
./configure-ssh.sh
```

Este script irá:
- Gerar chaves SSH
- Configurar authorized_keys
- Copiar chaves para o Jenkins
- Configurar permissões corretas

#### Passo 4.2: Adicionar SSH Credentials no Jenkins

1. Obter a chave privada:
   ```bash
   sudo cat /var/lib/jenkins/.ssh/id_rsa
   ```

2. No Jenkins, adicionar credentials:
   - **Kind**: SSH Username with private key
   - **Scope**: Global
   - **ID**: `ssh-credentials`
   - **Description**: SSH Deploy Credentials
   - **Username**: `grometis`
   - **Private Key**: Cole a chave privada completa (incluindo BEGIN e END)

#### Passo 4.3: Testar conexão SSH

```bash
# Dentro da VM
sudo -u jenkins ssh -o StrictHostKeyChecking=no grometis@localhost echo "SSH OK"
```

Se retornar "SSH OK", a configuração está correta.

---

### 5. Criar Pipeline

#### Passo 5.1: Criar repositório no GitHub

1. Crie um novo repositório no GitHub
2. Faça push dos arquivos deste projeto:

```bash
# No seu MacOS ou na VM
cd ~/grometis-jenkins

# Inicializar git (se ainda não estiver)
git init
git add .
git commit -m "Initial commit: Jenkins CI/CD pipeline"

# Adicionar remote e push
git remote add origin https://github.com/seu-usuario/seu-repositorio.git
git branch -M main
git push -u origin main
```

#### Passo 5.2: Criar Multibranch Pipeline no Jenkins

1. No Jenkins Dashboard, click em **New Item**

2. Configurar:
   - **Nome**: `grometis-cicd-pipeline`
   - **Tipo**: Multibranch Pipeline
   - Click em **OK**

3. Na configuração do pipeline:

   **Branch Sources**:
   - Click em **Add source** → **GitHub**
   - **Credentials**: Selecione `github-credentials`
   - **Repository HTTPS URL**: `https://github.com/seu-usuario/seu-repositorio.git`
   - **Behaviors**: Mantenha o padrão

   **Build Configuration**:
   - **Mode**: by Jenkinsfile
   - **Script Path**: `Jenkinsfile`

   **Scan Multibranch Pipeline Triggers**:
   - ☑️ Periodically if not otherwise run
   - **Interval**: 1 minute (para testes, depois pode aumentar)

4. Click em **Save**

5. O Jenkins irá escanear o repositório e detectar branches automaticamente

#### Passo 5.3: Executar o Pipeline

1. O pipeline será executado automaticamente após o scan
2. Ou click em **Build Now** para executar manualmente
3. Acompanhe a execução clicando no número do build → **Console Output**

---

## 🔄 Pipeline CI/CD

### Stages do Pipeline

#### 1. **Checkout**
- Faz clone do repositório GitHub
- Exibe informações do commit

#### 2. **Environment Check**
- Verifica versões do Docker, Docker Compose, Git, Java
- Garante que o ambiente está correto

#### 3. **Build Docker Image**
- Constrói a imagem Docker
- Adiciona tags: `BUILD_NUMBER` e `latest`
- Inclui metadados de build

#### 4. **Test Docker Image**
- Executa testes básicos da imagem
- Verifica se a imagem inicia corretamente

#### 5. **Push to Docker Hub**
- Faz login no Docker Hub
- Envia a imagem com múltiplas tags
- Faz logout automaticamente

#### 6. **Deploy to VM**
- Conecta via SSH à própria VM
- Copia docker-compose.yml
- Faz pull da nova imagem
- Para containers antigos
- Inicia novos containers
- Limpa imagens antigas

#### 7. **Verify Deployment**
- Verifica status dos containers
- Exibe logs recentes
- Confirma que a aplicação está respondendo

### Variáveis de Ambiente do Pipeline

Você pode customizar no Jenkinsfile:

- `DOCKERHUB_USERNAME`: Seu usuário Docker Hub
- `DOCKER_IMAGE_NAME`: Nome da imagem
- `APP_NAME`: Nome da aplicação
- `DEPLOY_HOST`: IP do servidor (192.168.15.6)
- `DEPLOY_USER`: Usuário SSH (grometis)

---

## 📁 Estrutura do Projeto

```
grometis-jenkins/
│
├── README.md                   # Este arquivo
├── Jenkinsfile                 # Pipeline CI/CD
├── Dockerfile                  # Build da imagem Docker
├── docker-compose.yml          # Orquestração de containers
│
├── cloud-init.yaml             # Configuração automática da VM
├── create-vm.sh                # Script para criar VM
├── setup-jenkins.sh            # Script de configuração Jenkins
├── configure-ssh.sh            # Script de configuração SSH
├── verify-installation.sh      # Script de verificação
│
├── package.json                # Dependências Node.js
├── index.js                    # Aplicação de exemplo
└── .env.production             # Variáveis de ambiente
```

---

## 🔧 Troubleshooting

### Jenkins não está acessível

```bash
# Verificar se Jenkins está rodando
multipass exec jenkins-cicd -- sudo systemctl status jenkins

# Reiniciar Jenkins
multipass exec jenkins-cicd -- sudo systemctl restart jenkins

# Verificar logs
multipass exec jenkins-cicd -- sudo journalctl -u jenkins -f
```

### Docker permission denied

```bash
# Adicionar usuário ao grupo docker
multipass exec jenkins-cicd -- sudo usermod -aG docker jenkins
multipass exec jenkins-cicd -- sudo usermod -aG docker grometis

# Reiniciar Docker
multipass exec jenkins-cicd -- sudo systemctl restart docker

# Reiniciar Jenkins
multipass exec jenkins-cicd -- sudo systemctl restart jenkins
```

### Pipeline falha no Push to Docker Hub

1. Verifique se as credenciais Docker Hub estão corretas
2. Verifique se o token tem permissão de write
3. Teste login manualmente:
   ```bash
   docker login -u seu-usuario
   ```

### Deploy falha com erro SSH

```bash
# Verificar se SSH está configurado
multipass exec jenkins-cicd -- sudo -u jenkins ssh grometis@localhost echo OK

# Reconfigurar SSH
multipass exec jenkins-cicd -- bash -c "cd ~/grometis-jenkins && ./configure-ssh.sh"
```

### Aplicação não responde após deploy

```bash
# Verificar containers
multipass exec jenkins-cicd -- docker-compose -f ~/deployments/grometis-app/docker-compose.yml ps

# Verificar logs
multipass exec jenkins-cicd -- docker-compose -f ~/deployments/grometis-app/docker-compose.yml logs

# Reiniciar containers
multipass exec jenkins-cicd -- docker-compose -f ~/deployments/grometis-app/docker-compose.yml restart
```

### VM não inicia

```bash
# Verificar status
multipass list

# Iniciar VM
multipass start jenkins-cicd

# Deletar e recriar (CUIDADO: perda de dados)
multipass delete jenkins-cicd
multipass purge
./create-vm.sh
```

---

## ✅ Boas Práticas

### Segurança

1. **Nunca commite credenciais** no código
2. Use **environment variables** para dados sensíveis
3. Mantenha Jenkins e plugins **sempre atualizados**
4. Use **tokens de acesso** ao invés de senhas
5. Configure **SSL/TLS** para Jenkins em produção
6. Limite **permissões de usuário** no Jenkins
7. Use **imagens Docker oficiais** como base

### CI/CD

1. **Teste localmente** antes de fazer push
2. Use **tags semânticas** para imagens (ex: v1.0.0)
3. Mantenha **Jenkinsfile** versionado no Git
4. Configure **notificações** de build (Slack, email)
5. Implemente **rollback automático** em caso de falha
6. Use **stages paralelos** quando possível
7. Configure **timeouts** para evitar builds travados

### Docker

1. Use **multi-stage builds** para imagens menores
2. Rode containers como **usuário não-root**
3. Implemente **health checks**
4. Use **.dockerignore** para excluir arquivos
5. Mantenha imagens **atualizadas e escaneadas**
6. Limite **recursos** (CPU, memória) dos containers
7. Configure **logging apropriado**

### Manutenção

1. **Monitore** uso de disco e recursos
2. Configure **limpeza automática** de builds antigos
3. Faça **backup** de configurações Jenkins
4. Documente **mudanças** no pipeline
5. Revise **logs** regularmente

---

## 🎓 Próximos Passos

Depois de ter o pipeline funcionando, considere:

1. **Adicionar testes automatizados** (unit, integration)
2. **Configurar análise de código** (SonarQube)
3. **Implementar blue-green deployment**
4. **Adicionar monitoramento** (Prometheus, Grafana)
5. **Configurar alertas** automáticos
6. **Implementar staging environment**
7. **Adicionar smoke tests** pós-deploy
8. **Configurar backups** automáticos
9. **Implementar secrets management** (Vault)
10. **Adicionar security scanning** nas imagens

---

## 📞 Suporte

Para questões e problemas:

1. Verifique a seção [Troubleshooting](#troubleshooting)
2. Consulte a documentação oficial:
   - [Jenkins](https://www.jenkins.io/doc/)
   - [Docker](https://docs.docker.com/)
   - [Multipass](https://multipass.run/docs)
3. Revise os logs do Jenkins e containers

---

## 📄 Licença

Este projeto é fornecido como exemplo educacional. Use e modifique conforme necessário.

---

## 🎉 Conclusão

Você agora tem um pipeline CI/CD completo e funcional! 

**Resumo do que foi implementado:**

✅ VM Ubuntu automatizada com Multipass  
✅ Jenkins configurado e rodando  
✅ Docker e Docker Compose instalados  
✅ Pipeline completo: build → test → push → deploy  
✅ Integração com GitHub e Docker Hub  
✅ Deploy automatizado via SSH  
✅ Health checks e verificação de deploy  

**Happy Coding! 🚀**
