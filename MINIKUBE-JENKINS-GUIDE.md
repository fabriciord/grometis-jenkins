# Configuração Jenkins + Minikube para CI/CD

Este projeto configura um **container Jenkins** para fazer deploy de **outros projetos** em um cluster **Minikube**.

## 🎯 Propósito

- **Este repo NÃO contém aplicações** - apenas a configuração do Jenkins
- Jenkins roda em container via Docker Compose
- Minikube fornece cluster Kubernetes local
- Projetos externos criam pipelines que fazem deploy no Minikube via este Jenkins

## 💪 Capacidades do Jenkins

O Jenkins está configurado para fazer **builds de QUALQUER projeto**:

### ✅ Docker Build & Push
- **Socket Docker montado**: `/var/run/docker.sock`
- Pode fazer build de imagens Docker de qualquer linguagem
- Pode fazer push para Docker Hub, GitHub Registry, etc.
- Acessa Docker daemon do host diretamente

### ✅ Deploy em Kubernetes (Minikube)
- **Kubeconfig montado**: `~/.kube:/root/.kube`
- Pode executar `kubectl` para fazer deploys
- Gerencia pods, deployments, services, configmaps, secrets
- Acesso a todos os namespaces (production, staging, development)

### ✅ Modo Privilegiado
- Permissões completas para operações avançadas
- Pode instalar ferramentas adicionais (npm, maven, gradle, etc.)
- Executa como root para acesso total

### 📦 Suporta Múltiplos Tipos de Projetos:
- **Node.js** (npm/yarn)
- **Python** (pip/poetry)
- **Java** (maven/gradle)
- **Go** (go build)
- **Ruby** (bundler)
- **PHP** (composer)
- **Rust** (cargo)
- **Qualquer linguagem** que possa ser conteinerizada

### 🔄 Pipeline Típico:
```
1. Jenkins recebe webhook do GitHub/GitLab
2. Clona repositório do projeto
3. Faz build da imagem Docker (Dockerfile do projeto)
4. Executa testes (definidos no Jenkinsfile do projeto)
5. Push da imagem para registry (Docker Hub, etc.)
6. Deploy no Minikube via kubectl
7. Verifica health checks
```

### 🎯 Exemplo de Projetos Suportados:
- API REST em Node.js
- Aplicação Python Flask/Django
- Microsserviço Java Spring Boot
- Frontend React/Vue/Angular
- Backend Go
- Qualquer app conteinerizada!

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
│           │ Deploy                     │ Pods        │
│           ▼                            ▼             │
│     Outros Repos              ┌──────────────┐      │
│     (Aplicações)              │ App 1 | App 2│      │
│                               └──────────────┘      │
└─────────────────────────────────────────────────────┘
```

## 📋 Pré-requisitos

- Ubuntu Server com Docker instalado
- Multipass (para VM Jenkins) ou Docker direto
- Acesso GitHub com token/SSH
- Conta Docker Hub para imagens

## 🚀 Setup Rápido

### 1. Instalar Minikube no Servidor

```bash
# No servidor Ubuntu (192.168.15.6)
chmod +x install-minikube.sh
./install-minikube.sh
```

### 2. Iniciar Jenkins

```bash
# No servidor ou via Multipass
docker-compose up -d
```

### 3. Configurar Jenkins

Acesse `http://192.168.15.6:8080` (ou IP do Jenkins):

1. **Senha inicial**: `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`
2. **Instalar plugins recomendados**
3. **Criar usuário admin**

### 4. Adicionar Credenciais no Jenkins

**Manage Jenkins → Credentials → Global → Add Credentials**

#### Docker Hub
- **Kind**: Username with password
- **ID**: `dockerhub-credentials`
- **Username**: seu usuário Docker Hub
- **Password**: seu token Docker Hub

#### GitHub
- **Kind**: Secret text (para token) ou SSH Username with private key
- **ID**: `github-credentials`
- **Token/Key**: seu token/chave GitHub

#### Kubectl (Minikube)
- **Kind**: Secret file
- **ID**: `kubeconfig`
- **File**: conteúdo de `~/.kube/config` do servidor

### 5. Criar Pipeline para Outro Projeto

No Jenkins:

1. **New Item** → Pipeline
2. **Pipeline from SCM** → Git
3. **Repository URL**: URL do seu projeto (ex: `https://github.com/fabriciord/meu-app.git`)
4. **Script Path**: `Jenkinsfile`

## 📁 Estrutura de Projeto Externo

Seus outros projetos devem ter esta estrutura:

```
meu-app/
├── Dockerfile              # Build da aplicação
├── Jenkinsfile             # Pipeline CI/CD
├── k8s/
│   ├── deployment.yaml     # Deployment Kubernetes
│   └── service.yaml        # Service Kubernetes
├── src/
│   └── ... (código do app)
└── package.json
```

### Exemplo de Jenkinsfile (no projeto externo)

```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = "fabriciobackend/meu-app:${BUILD_NUMBER}"
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
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', 
                                                   usernameVariable: 'DOCKER_USER', 
                                                   passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_IMAGE}
                    '''
                }
            }
        }
        
        stage('Deploy to Minikube') {
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

### Exemplo de deployment.yaml (no projeto externo)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: meu-app
  namespace: production
spec:
  replicas: 2
  selector:
    matchLabels:
      app: meu-app
  template:
    metadata:
      labels:
        app: meu-app
    spec:
      containers:
      - name: meu-app
        image: fabriciobackend/meu-app:latest
        ports:
        - containerPort: 3000
        resources:
          limits:
            memory: "256Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: meu-app-service
  namespace: production
spec:
  type: NodePort
  selector:
    app: meu-app
  ports:
  - port: 80
    targetPort: 3000
    nodePort: 30001
```

## 🔧 Comandos Úteis

### Minikube

```bash
# Gerenciamento do Cluster
minikube status                          # Status do cluster
minikube start                           # Iniciar cluster
minikube stop                            # Parar cluster
minikube delete                          # Deletar cluster
minikube pause                           # Pausar cluster (mantém pods)
minikube unpause                         # Retomar cluster pausado

# Informações e Acesso
minikube ip                              # IP do cluster
minikube dashboard                       # Dashboard Kubernetes (web)
minikube service list                    # Listar serviços expostos
minikube service <service-name>          # Abrir serviço no browser
minikube logs                            # Logs do Minikube

# Configuração
minikube config view                     # Ver configuração
minikube addons list                     # Listar addons disponíveis
minikube addons enable ingress           # Habilitar ingress
minikube addons enable metrics-server    # Habilitar métricas

# SSH e Debugging
minikube ssh                             # SSH no node do cluster
minikube ssh "docker ps"                 # Executar comando no node
```

### Kubectl - Comandos Essenciais

#### 📦 Pods

```bash
# Listar Pods
kubectl get pods -n production                    # Listar pods no namespace
kubectl get pods -A                               # Listar todos os pods
kubectl get pods -o wide                          # Informações detalhadas
kubectl get pods --watch                          # Monitorar mudanças em tempo real

# Inspecionar Pods
kubectl describe pod <pod-name> -n production     # Detalhes completos do pod
kubectl logs <pod-name> -n production             # Logs do pod
kubectl logs <pod-name> -f -n production          # Logs em tempo real
kubectl logs <pod-name> --previous                # Logs do container anterior (se crashou)
kubectl logs <pod-name> -c <container-name>       # Logs de container específico

# Interagir com Pods
kubectl exec -it <pod-name> -n production -- /bin/sh    # Shell no pod
kubectl exec <pod-name> -n production -- ls -la          # Executar comando
kubectl port-forward <pod-name> 8080:3000 -n production  # Port forward local

# Gerenciar Pods
kubectl delete pod <pod-name> -n production       # Deletar pod (será recriado)
kubectl top pod <pod-name> -n production          # Uso de CPU/Memória
```

#### 🚀 Deployments

```bash
# Listar Deployments
kubectl get deployments -n production             # Listar deployments
kubectl get deploy -A                             # Todos os deployments
kubectl describe deployment <deploy-name> -n production

# Atualizar Deployments
kubectl set image deployment/<deploy-name> <container>=<image>:<tag> -n production
kubectl rollout status deployment/<deploy-name> -n production
kubectl rollout history deployment/<deploy-name> -n production

# Escalar Deployments
kubectl scale deployment/<deploy-name> --replicas=3 -n production
kubectl autoscale deployment/<deploy-name> --min=2 --max=5 --cpu-percent=80

# Rollback
kubectl rollout undo deployment/<deploy-name> -n production
kubectl rollout undo deployment/<deploy-name> --to-revision=2 -n production

# Reiniciar
kubectl rollout restart deployment/<deploy-name> -n production
```

#### 🌐 Services

```bash
# Listar Services
kubectl get services -n production                # Listar services
kubectl get svc -A                                # Todos os services
kubectl describe service <service-name> -n production

# Endpoints
kubectl get endpoints -n production               # Ver endpoints dos services
kubectl port-forward service/<service-name> 8080:80 -n production
```

#### 📋 Namespaces

```bash
# Gerenciar Namespaces
kubectl get namespaces                            # Listar namespaces
kubectl create namespace <name>                   # Criar namespace
kubectl delete namespace <name>                   # Deletar namespace
kubectl config set-context --current --namespace=production  # Mudar namespace padrão
```

#### 📄 Manifests e Configurações

```bash
# Aplicar Manifests
kubectl apply -f deployment.yaml                  # Aplicar arquivo
kubectl apply -f k8s/                             # Aplicar pasta
kubectl apply -f https://url/manifest.yaml        # Aplicar de URL

# Ver Manifests
kubectl get deployment <name> -o yaml -n production    # Ver YAML do deployment
kubectl get deployment <name> -o json -n production    # Ver JSON do deployment

# Deletar Recursos
kubectl delete -f deployment.yaml                 # Deletar via arquivo
kubectl delete deployment <name> -n production    # Deletar deployment
kubectl delete pod <name> --force --grace-period=0  # Forçar deleção
```

#### 🔐 Secrets e ConfigMaps

```bash
# Secrets
kubectl get secrets -n production                 # Listar secrets
kubectl create secret generic <name> --from-literal=key=value
kubectl describe secret <name> -n production
kubectl delete secret <name> -n production

# ConfigMaps
kubectl get configmaps -n production              # Listar configmaps
kubectl create configmap <name> --from-file=file.conf
kubectl describe configmap <name> -n production
```

#### 🔍 Debugging e Troubleshooting

```bash
# Eventos
kubectl get events -n production                  # Ver eventos do namespace
kubectl get events --sort-by=.metadata.creationTimestamp

# Recursos e Métricas
kubectl top nodes                                 # Uso de recursos dos nodes
kubectl top pods -n production                    # Uso de recursos dos pods
kubectl api-resources                             # Listar tipos de recursos

# Informações do Cluster
kubectl cluster-info                              # Info do cluster
kubectl version                                   # Versão do kubectl e cluster
kubectl get nodes                                 # Listar nodes
kubectl describe node <node-name>                 # Detalhes do node

# Labels e Selectors
kubectl get pods -l app=meu-app -n production     # Filtrar por label
kubectl label pod <pod-name> env=staging          # Adicionar label
```

#### 🔄 Contextos e Configuração

```bash
# Contextos
kubectl config get-contexts                       # Listar contextos
kubectl config current-context                    # Ver contexto atual
kubectl config use-context minikube               # Mudar contexto

# Kubeconfig
kubectl config view                               # Ver configuração
kubectl config set-credentials user --token=xxx   # Adicionar credencial
```

#### 📊 Recursos Avançados

```bash
# Jobs e CronJobs
kubectl get jobs -n production
kubectl get cronjobs -n production
kubectl create job <name> --image=<image>

# StatefulSets
kubectl get statefulsets -n production
kubectl scale statefulset <name> --replicas=3 -n production

# DaemonSets
kubectl get daemonsets -n production

# Ingress
kubectl get ingress -n production
kubectl describe ingress <name> -n production
```

### Jenkins

```bash
# Logs e Monitoramento
docker-compose -f docker-compose.jenkins.yml logs -f jenkins    # Logs em tempo real
docker-compose -f docker-compose.jenkins.yml logs --tail=100    # Últimas 100 linhas

# Gerenciamento
docker-compose -f docker-compose.jenkins.yml restart jenkins    # Reiniciar
docker-compose -f docker-compose.jenkins.yml stop               # Parar
docker-compose -f docker-compose.jenkins.yml start              # Iniciar
docker-compose -f docker-compose.jenkins.yml down               # Parar e remover
docker-compose -f docker-compose.jenkins.yml up -d              # Iniciar detached

# Acesso e Debugging
docker exec -it jenkins /bin/bash                               # Shell no container
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword  # Senha inicial

# Volumes e Dados
docker volume ls | grep jenkins                                 # Ver volumes
docker volume inspect grometis-jenkins_jenkins_home             # Inspecionar volume
```

## 📦 Namespaces Recomendados

Crie namespaces para organizar seus deploys:

```bash
kubectl create namespace production
kubectl create namespace staging
kubectl create namespace development
```

## 🔐 Segurança

- Jenkins expõe porta 8080 (configure firewall)
- Use sempre credenciais no Jenkins, nunca hardcode
- Secrets do Kubernetes para dados sensíveis
- Token Docker Hub com permissões mínimas

## 🐛 Troubleshooting

### Jenkins não conecta no Minikube

```bash
# Copiar kubeconfig do servidor para Jenkins
docker cp ~/.kube/config jenkins:/var/jenkins_home/.kube/config
docker exec jenkins chown jenkins:jenkins /var/jenkins_home/.kube/config
```

### Pod não inicia

```bash
kubectl describe pod <pod-name> -n production
kubectl logs <pod-name> -n production
```

### Minikube sem recursos

```bash
minikube stop
minikube delete
minikube start --cpus=4 --memory=4g  # Aumentar recursos
```

## ❓ FAQ - Builds de Outros Projetos

### Posso fazer build de projetos em qualquer linguagem?

**Sim!** O Jenkins tem acesso ao Docker daemon e pode fazer build de qualquer imagem Docker. Exemplos:

- **Node.js**: `FROM node:18-alpine`
- **Python**: `FROM python:3.11-slim`
- **Java**: `FROM openjdk:17-jdk`
- **Go**: `FROM golang:1.21-alpine`
- **PHP**: `FROM php:8.2-fpm`

### O Jenkins precisa ter as ferramentas instaladas?

**Não!** O build acontece dentro do Docker. O Dockerfile do seu projeto define as ferramentas necessárias:

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
CMD ["node", "index.js"]
```

### Como adicionar um novo projeto?

1. **No seu projeto**, crie um `Jenkinsfile`:

```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = "seu-usuario/seu-app:${BUILD_NUMBER}"
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
                    kubectl set image deployment/seu-app seu-app=${DOCKER_IMAGE} -n production
                    kubectl rollout status deployment/seu-app -n production
                """
            }
        }
    }
}
```

2. **No Jenkins**, crie um novo pipeline:
   - New Item → Pipeline
   - Pipeline from SCM → Git
   - Repository URL: URL do seu projeto
   - Credentials: `github-credentials`
   - Script Path: `Jenkinsfile`

3. **Configure webhook** (opcional):
   - GitHub → Settings → Webhooks → Add webhook
   - URL: `http://192.168.15.6:8080/github-webhook/`

### Quantos projetos posso ter?

**Ilimitados!** Cada projeto tem seu próprio pipeline no Jenkins. Você pode ter:
- 1 API em Node.js
- 1 API em Python
- 1 Frontend em React
- 1 Microsserviço em Go
- Etc.

Cada um com seu próprio:
- Repositório Git
- Jenkinsfile
- Dockerfile
- Manifests Kubernetes (k8s/)

### Os projetos compartilham recursos?

**Sim**, no Minikube. Mas você pode separar por namespaces:
- `production` - Aplicações em produção
- `staging` - Testes de pré-produção
- `development` - Desenvolvimento

```bash
kubectl create namespace meu-projeto-dev
kubectl create namespace meu-projeto-staging
```

### Posso ter diferentes versões do mesmo app?

**Sim!** Use tags Docker e namespaces:

```groovy
// Build com tag da branch
DOCKER_IMAGE = "usuario/app:${env.BRANCH_NAME}-${BUILD_NUMBER}"

// Deploy em namespace específico
kubectl set image deployment/app app=${DOCKER_IMAGE} -n staging
```

### Como fazer rollback se algo der errado?

```bash
# Ver histórico de deploys
kubectl rollout history deployment/meu-app -n production

# Fazer rollback para versão anterior
kubectl rollout undo deployment/meu-app -n production

# Rollback para versão específica
kubectl rollout undo deployment/meu-app --to-revision=3 -n production
```

Ou via Jenkins:
```groovy
stage('Rollback') {
    when {
        expression { currentBuild.result == 'FAILURE' }
    }
    steps {
        sh 'kubectl rollout undo deployment/meu-app -n production'
    }
}
```

### Posso executar testes antes do deploy?

**Sim!** Adicione no Jenkinsfile:

```groovy
stage('Test') {
    steps {
        sh '''
            docker run --rm ${DOCKER_IMAGE} npm test
            # ou
            docker run --rm ${DOCKER_IMAGE} python -m pytest
            # ou
            docker run --rm ${DOCKER_IMAGE} go test ./...
        '''
    }
}
```

### Como ver logs de builds?

No Jenkins:
1. Acesse o pipeline
2. Clique no número do build
3. **Console Output**

Ou via CLI:
```bash
# Logs do Jenkins
docker-compose -f docker-compose.jenkins.yml logs -f jenkins
```

### Como adicionar secrets (senhas, tokens)?

**No Kubernetes**:
```bash
# Criar secret
kubectl create secret generic meu-app-secrets \
  --from-literal=DB_PASSWORD=senha123 \
  --from-literal=API_KEY=abc123 \
  -n production

# Usar no deployment
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: meu-app-secrets
      key: DB_PASSWORD
```

**No Jenkins**:
1. Manage Jenkins → Credentials → Add Credentials
2. No Jenkinsfile: `credentials('credential-id')`

### Performance: Quantos builds simultâneos?

Depende dos recursos do servidor. Configure executors no Jenkins:
- Manage Jenkins → Configure System → # of executors

Recomendação:
- 2 CPUs → 2 executors
- 4 CPUs → 4 executors
- 8 CPUs → 6-8 executors

## 📚 Recursos

- [Jenkins Pipeline](https://www.jenkins.io/doc/book/pipeline/)
- [Minikube Docs](https://minikube.sigs.k8s.io/docs/)
- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [Docker Hub](https://hub.docker.com/)

## 📝 Próximos Passos

1. ✅ Instalar Minikube
2. ✅ Iniciar Jenkins
3. ⏳ Configurar credenciais
4. ⏳ Criar namespace `production`
5. ⏳ Criar primeiro pipeline de projeto externo
6. ⏳ Testar deploy no Minikube

---

**Nota**: Este projeto é apenas a infraestrutura CI/CD. Suas aplicações devem estar em repositórios separados com seus próprios Jenkinsfiles.
