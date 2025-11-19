#!/bin/bash

################################################################################
# Script de Setup Completo Jenkins + Minikube
# 
# Este script automatiza:
# 1. Instalação do Docker (se necessário)
# 2. Instalação do Minikube + kubectl
# 3. Configuração do Jenkins
# 4. Configuração do kubeconfig
################################################################################

set -e

JENKINS_HOME="${HOME}/jenkins_home"
KUBECONFIG_PATH="${HOME}/.kube/config"

echo "========================================="
echo "Setup Jenkins + Minikube CI/CD"
echo "========================================="
echo ""

# Verificar sistema operacional
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "⚠️  Este script é para Linux Ubuntu/Debian"
    exit 1
fi

echo "[1/5] Verificando Docker..."
if ! command -v docker &> /dev/null; then
    echo "Docker não encontrado. Instalando..."
    chmod +x install-docker-production.sh
    ./install-docker-production.sh
else
    echo "✓ Docker já instalado: $(docker --version)"
fi

echo ""
echo "[2/5] Verificando Minikube..."
if ! command -v minikube &> /dev/null; then
    echo "Minikube não encontrado. Instalando..."
    chmod +x install-minikube.sh
    ./install-minikube.sh
else
    echo "✓ Minikube já instalado: $(minikube version --short)"
    
    # Verificar se cluster está rodando
    if ! minikube status &> /dev/null; then
        echo "Iniciando Minikube..."
        minikube start --driver=docker --cpus=2 --memory=2g
    else
        echo "✓ Minikube cluster já está rodando"
    fi
fi

echo ""
echo "[3/5] Criando namespaces Kubernetes..."
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace development --dry-run=client -o yaml | kubectl apply -f -
echo "✓ Namespaces criados: production, staging, development"

echo ""
echo "[4/5] Configurando Jenkins..."
if [ ! -d "$JENKINS_HOME" ]; then
    mkdir -p "$JENKINS_HOME"
    echo "✓ Diretório Jenkins criado: $JENKINS_HOME"
fi

# Copiar kubeconfig para local acessível pelo Jenkins
if [ -f "$KUBECONFIG_PATH" ]; then
    cp "$KUBECONFIG_PATH" "$(pwd)/kubeconfig"
    echo "✓ Kubeconfig copiado para $(pwd)/kubeconfig"
    echo "  Use este arquivo nas credenciais do Jenkins (ID: kubeconfig)"
fi

echo ""
echo "[5/5] Iniciando Jenkins..."
if docker compose -f docker-compose.jenkins.yml ps | grep -q "jenkins"; then
    echo "Jenkins já está rodando"
    docker compose -f docker-compose.jenkins.yml ps
else
    docker compose -f docker-compose.jenkins.yml up -d
    echo "Aguardando Jenkins iniciar (isso pode levar 1-2 minutos)..."
    sleep 30
fi

echo ""
echo "========================================="
echo "✓ Setup Completo!"
echo "========================================="
echo ""
echo "🌐 Acesse Jenkins: http://$(hostname -I | awk '{print $1}'):8080"
echo ""
echo "🔑 Senha inicial do Jenkins:"
echo "   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
echo ""
echo "📋 Próximos passos:"
echo ""
echo "1. Acesse o Jenkins no navegador"
echo "2. Use a senha inicial mostrada acima"
echo "3. Instale os plugins recomendados"
echo "4. Crie um usuário admin"
echo ""
echo "5. Configure as credenciais (Manage Jenkins → Credentials):"
echo "   a) Docker Hub (ID: dockerhub-credentials)"
echo "      - Username: seu usuário Docker Hub"
echo "      - Password: seu token Docker Hub"
echo ""
echo "   b) GitHub (ID: github-credentials)"
echo "      - Secret text: seu token GitHub"
echo ""
echo "   c) Kubeconfig (ID: kubeconfig)"
echo "      - Secret file: arquivo $(pwd)/kubeconfig"
echo ""
echo "6. Crie um pipeline apontando para seu repositório"
echo ""
echo "📚 Documentação completa: MINIKUBE-JENKINS-GUIDE.md"
echo ""
echo "🔧 Comandos úteis:"
echo "   minikube status           # Status do cluster"
echo "   minikube dashboard        # Dashboard Kubernetes"
echo "   kubectl get pods -A       # Ver todos os pods"
echo "   docker-compose -f docker-compose.jenkins.yml logs -f  # Logs Jenkins"
echo ""
