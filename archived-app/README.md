# Arquivos da aplicação grometis-app

Esta pasta contém os arquivos da aplicação original que foram movidos do root do projeto.

## ⚠️ Importante

Este repositório **grometis-jenkins** agora é dedicado APENAS à configuração da infraestrutura CI/CD:
- Jenkins (container)
- Minikube (cluster Kubernetes)
- Scripts de instalação e configuração

## 📦 Conteúdo Arquivado

- `Dockerfile` - Build da aplicação Node.js grometis-app
- `Jenkinsfile` - Pipeline específico para grometis-app
- `index.js` - Código da aplicação
- `package.json` - Dependências do Node.js

## 🔄 Migração

Se você precisa continuar desenvolvendo a aplicação **grometis-app**, crie um novo repositório:

```bash
# Criar novo repositório para a aplicação
mkdir ~/grometis-app
cd ~/grometis-app
git init

# Copiar arquivos necessários
cp ~/GrOMEtiS/grometis-jenkins/archived-app/* .

# Criar estrutura Kubernetes
mkdir -p k8s
```

### Estrutura sugerida para grometis-app

```
grometis-app/
├── Dockerfile
├── Jenkinsfile
├── package.json
├── src/
│   └── index.js
├── k8s/
│   ├── deployment.yaml
│   └── service.yaml
└── README.md
```

### Jenkinsfile para o novo repo

```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = "fabriciobackend/grometis-app:${BUILD_NUMBER}"
        KUBECONFIG = credentials('kubeconfig')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                sh 'docker build -t ${DOCKER_IMAGE} .'
            }
        }
        
        stage('Test') {
            steps {
                sh 'docker run --rm ${DOCKER_IMAGE} npm test || true'
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_IMAGE}
                        docker tag ${DOCKER_IMAGE} fabriciobackend/grometis-app:latest
                        docker push fabriciobackend/grometis-app:latest
                    '''
                }
            }
        }
        
        stage('Deploy to Minikube') {
            steps {
                sh """
                    kubectl set image deployment/grometis-app grometis-app=${DOCKER_IMAGE} -n production
                    kubectl rollout status deployment/grometis-app -n production --timeout=5m
                """
            }
        }
        
        stage('Verify') {
            steps {
                sh """
                    kubectl get pods -n production -l app=grometis-app
                    kubectl get service grometis-app-service -n production
                """
            }
        }
    }
    
    post {
        success {
            echo "✓ Deploy realizado com sucesso!"
            echo "Acesso: http://\$(minikube ip):30000"
        }
        failure {
            echo "✗ Falha no deploy. Verifique os logs."
        }
    }
}
```

### Deployment Kubernetes (k8s/deployment.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grometis-app
  namespace: production
spec:
  replicas: 2
  selector:
    matchLabels:
      app: grometis-app
  template:
    metadata:
      labels:
        app: grometis-app
    spec:
      containers:
      - name: grometis-app
        image: fabriciobackend/grometis-app:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: grometis-app-service
  namespace: production
spec:
  type: NodePort
  selector:
    app: grometis-app
  ports:
  - port: 80
    targetPort: 3000
    nodePort: 30000
```

## 🚀 Como usar o novo repo

1. **Criar o repositório no GitHub**: `fabriciord/grometis-app`

2. **Configurar pipeline no Jenkins**:
   - New Item → Pipeline
   - Pipeline from SCM → Git
   - Repository URL: `https://github.com/fabriciord/grometis-app.git`
   - Script Path: `Jenkinsfile`

3. **Aplicar manifests Kubernetes inicialmente**:
```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

4. **Executar pipeline**: O Jenkins fará build, push e deploy automático

---

📚 Consulte `MINIKUBE-JENKINS-GUIDE.md` no root do projeto grometis-jenkins para mais detalhes.
