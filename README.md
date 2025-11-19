# Jenkins + Minikube CI/CD Infrastructure

Infraestrutura completa de CI/CD usando **Jenkins em container** para fazer deploy de aplicações em cluster **Minikube (Kubernetes)**.

## 🎯 Propósito

Este repositório contém **APENAS a configuração da infraestrutura CI/CD**:
- Jenkins rodando em Docker Compose
- Minikube como cluster Kubernetes local
- Scripts de instalação automatizada
- Documentação para criar pipelines de outros projetos

> ⚠️ **Este repo NÃO contém aplicações**. Suas apps devem estar em repositórios separados com seus próprios Jenkinsfiles.

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────┐
│  Servidor Ubuntu (192.168.15.6)                     │
│                                                       │
│  ┌─────────────────┐         ┌──────────────────┐  │
│  │  Jenkins         │         │  Minikube        │  │
│  │  Container       │────────▶│  Cluster K8s     │  │
│  │  (Docker)        │ kubectl │                   │  │
│  └─────────────────┘         └──────────────────┘  │
│           │                            │             │
│           │ Build/Deploy               │ Pods        │
│           ▼                            ▼             │
│     Outros Repos              ┌──────────────┐      │
│     (Aplicações)              │ App 1 | App 2│      │
│                               └──────────────┘      │
└─────────────────────────────────────────────────────┘

Pipeline Flow:
GitHub (push) → Webhook → Jenkins → Build → Docker Hub → Minikube Deploy
```

## 📋 Pré-requisitos

- Ubuntu Server (testado em 22.04)
- Docker instalado
- Git configurado
- Conta Docker Hub (para registry)
- Conta GitHub (para repositórios)

## 🚀 Instalação Rápida (1 Comando)

```bash
chmod +x setup-complete.sh
./setup-complete.sh
```

Este script automatiza:
1. ✅ Instalação do Docker (se necessário)
2. ✅ Instalação do Minikube + kubectl
3. ✅ Criação de namespaces Kubernetes (production, staging, development)
4. ✅ Inicialização do Jenkins
5. ✅ Configuração do kubeconfig

## 🔧 Instalação Manual

### 1. Instalar Minikube

```bash
chmod +x install-minikube.sh
./install-minikube.sh
```

### 2. Iniciar Jenkins

```bash
docker-compose -f docker-compose.jenkins.yml up -d
```

### 3. Obter Senha Inicial do Jenkins

```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### 4. Acessar Jenkins

```
http://192.168.15.6:8080
```

(Ou substitua pelo IP do seu servidor: `hostname -I`)

## 🔐 Configurar Credenciais no Jenkins

**Manage Jenkins → Credentials → Global → Add Credentials**

### 1. Docker Hub
- **Kind**: Username with password
- **ID**: `dockerhub-credentials`
- **Username**: seu usuário Docker Hub
- **Password**: seu token Docker Hub

### 2. GitHub
- **Kind**: Secret text
- **ID**: `github-credentials`
- **Secret**: seu token GitHub (com permissões `repo`, `admin:repo_hook`)

### 3. Kubeconfig
- **Kind**: Secret file
- **ID**: `kubeconfig`
- **File**: arquivo `kubeconfig` gerado pelo setup (na pasta do projeto)

## 📦 Como Criar Pipeline para Outro Projeto

### 1. Estrutura do Seu Projeto (Exemplo)

```
meu-app/
├── Dockerfile              # Build da aplicação
├── Jenkinsfile             # Pipeline CI/CD
├── k8s/
│   ├── deployment.yaml     # Deployment Kubernetes
│   └── service.yaml        # Service Kubernetes
├── src/
│   └── ... (código)
└── package.json
```

### 2. Jenkinsfile do Seu Projeto

```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = "seu-usuario/meu-app:${BUILD_NUMBER}"
        KUBECONFIG = credentials('kubeconfig')
    }
    
    stages {
        stage('Build') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE} .'
            }
        }
        
        stage('Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh '''
                        echo "$PASS" | docker login -u "$USER" --password-stdin
                        docker push ${DOCKER_IMAGE}
                    '''
                }
            }
        }
        
        stage('Deploy') {
            steps {
                sh """
                    kubectl set image deployment/meu-app meu-app=${DOCKER_IMAGE} -n production
                    kubectl rollout status deployment/meu-app -n production
                """
            }
        }
    }
}
```

### 3. Criar Pipeline no Jenkins

1. **New Item** → Digite nome → **Pipeline** → OK
2. **Pipeline from SCM** → Git
3. **Repository URL**: `https://github.com/seu-usuario/meu-app.git`
4. **Credentials**: selecione `github-credentials`
5. **Script Path**: `Jenkinsfile`
6. **Save**

### 4. Configurar Webhook (Opcional)

Para builds automáticos:

1. GitHub → Repositório → Settings → Webhooks → Add webhook
2. **Payload URL**: `http://192.168.15.6:8080/github-webhook/`
3. **Content type**: `application/json`
4. **Events**: Just the push event
5. **Active**: ✓

## 📁 Estrutura do Repositório

```
grometis-jenkins/
├── docker-compose.jenkins.yml    # Jenkins container
├── install-minikube.sh           # Instalação Minikube
├── install-docker-production.sh  # Instalação Docker
├── setup-complete.sh             # Setup completo automatizado
├── MINIKUBE-JENKINS-GUIDE.md     # Guia detalhado
├── archived-app/                 # Aplicação antiga (arquivada)
│   ├── Dockerfile
│   ├── Jenkinsfile
│   ├── index.js
│   └── README.md
└── README.md
```

## 🛠️ Comandos Úteis

### Minikube

```bash
minikube status              # Status do cluster
minikube dashboard           # Dashboard Kubernetes (web)
minikube service list        # Listar serviços expostos
minikube ip                  # IP do cluster
minikube stop                # Parar cluster
minikube start               # Iniciar cluster
```

### Kubectl

```bash
kubectl get pods -n production           # Pods no namespace production
kubectl get deployments -n production    # Deployments
kubectl get services -n production       # Services
kubectl logs <pod-name> -n production    # Logs de um pod
kubectl describe pod <pod-name>          # Detalhes do pod
kubectl rollout restart deployment/app   # Reiniciar deployment
```

### Jenkins

```bash
docker-compose -f docker-compose.jenkins.yml logs -f  # Logs
docker-compose -f docker-compose.jenkins.yml restart  # Reiniciar
docker-compose -f docker-compose.jenkins.yml down     # Parar
docker-compose -f docker-compose.jenkins.yml up -d    # Iniciar
```

## 🐛 Troubleshooting

### Jenkins não conecta no Minikube

```bash
# Copiar kubeconfig atualizado
cp ~/.kube/config ./kubeconfig
docker-compose -f docker-compose.jenkins.yml restart
```

### Minikube sem recursos

```bash
minikube stop
minikube delete
minikube start --cpus=4 --memory=4g  # Aumentar recursos
```

### Pod não inicia

```bash
kubectl describe pod <pod-name> -n production  # Ver eventos
kubectl logs <pod-name> -n production          # Ver logs
```

### Build falha no Jenkins

- Verifique Console Output do build
- Confirme credenciais do Docker Hub
- Verifique sintaxe do Dockerfile

## 📚 Documentação Completa

Consulte **[MINIKUBE-JENKINS-GUIDE.md](MINIKUBE-JENKINS-GUIDE.md)** para:
- Exemplos completos de Jenkinsfile
- Manifests Kubernetes (Deployment, Service)
- Configuração avançada
- Boas práticas de segurança
- Exemplos de múltiplos projetos

## 📝 Aplicação Exemplo (Arquivada)

A aplicação `grometis-app` original foi movida para `archived-app/` como referência.

Para criar um novo projeto baseado nela:
```bash
# Ver instruções em:
cat archived-app/README.md
```

## 🔄 Workflow CI/CD

```
1. Desenvolvedor faz push → GitHub
2. GitHub webhook → Jenkins
3. Jenkins executa pipeline:
   ✓ Checkout código
   ✓ Build imagem Docker
   ✓ Testes automatizados
   ✓ Push para Docker Hub
   ✓ Deploy no Minikube via kubectl
4. Aplicação rodando no Kubernetes
```

## 🚀 Próximos Passos

Após setup completo:

1. ✅ Jenkins rodando: `http://192.168.15.6:8080`
2. ✅ Minikube cluster ativo: `minikube status`
3. ✅ Namespaces criados: `kubectl get namespaces`
4. ⏳ Criar repositório da sua aplicação
5. ⏳ Adicionar Jenkinsfile no projeto
6. ⏳ Criar pipeline no Jenkins
7. ⏳ Fazer primeiro deploy!

## 👤 Autor

**Fabricio Gomes**
- GitHub: [@fabriciord](https://github.com/fabriciord)

---

**Importante**: Esta é a infraestrutura CI/CD. Suas aplicações devem estar em repositórios separados com seus próprios Jenkinsfiles que fazem deploy neste ambiente.
