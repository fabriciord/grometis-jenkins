# Configuração Jenkins + Minikube para CI/CD

Este projeto configura um **container Jenkins** para fazer deploy de **outros projetos** em um cluster **Minikube**.

## 🎯 Propósito

- **Este repo NÃO contém aplicações** - apenas a configuração do Jenkins
- Jenkins roda em container via Docker Compose
- Minikube fornece cluster Kubernetes local
- Projetos externos criam pipelines que fazem deploy no Minikube via este Jenkins

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
minikube status              # Status do cluster
minikube dashboard           # Dashboard web
minikube service list        # Listar serviços expostos
minikube stop                # Parar cluster
minikube start               # Iniciar cluster
```

### Kubectl

```bash
kubectl get pods -n production           # Pods no namespace production
kubectl get deployments -n production    # Deployments
kubectl logs <pod-name> -n production    # Logs de um pod
kubectl describe pod <pod-name>          # Detalhes do pod
kubectl rollout restart deployment/app   # Reiniciar deployment
```

### Jenkins

```bash
docker-compose logs -f jenkins           # Logs do Jenkins
docker-compose restart jenkins           # Reiniciar Jenkins
docker exec -it jenkins /bin/bash        # Shell no container
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
