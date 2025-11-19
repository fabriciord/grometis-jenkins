#!/bin/bash

################################################################################
# Script para instalar Minikube no Servidor Ubuntu (192.168.15.6)
# 
# Minikube é uma ferramenta para rodar Kubernetes localmente
# Ideal para desenvolvimento e CI/CD
################################################################################

set -e

echo "========================================="
echo "Instalação Minikube + kubectl"
echo "========================================="
echo ""

# Verificar se está rodando como usuário correto
if [ "$USER" != "grometis" ]; then
    echo "⚠️  Execute como usuário grometis"
    exit 1
fi

echo "[1/6] Instalando dependências..."
sudo apt-get update
sudo apt-get install -y curl apt-transport-https

echo ""
echo "[2/6] Instalando kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo ""
echo "[3/6] Instalando Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

echo ""
echo "[4/6] Verificando Docker..."
if ! docker --version &> /dev/null; then
    echo "⚠️  Docker não encontrado. Execute primeiro: ./install-docker-production.sh"
    exit 1
fi

echo ""
echo "[5/6] Iniciando Minikube com Docker driver..."
minikube start --driver=docker --cpus=2 --memory=2g

echo ""
echo "[6/6] Configurando kubectl..."
kubectl config use-context minikube
kubectl get nodes

echo ""
echo "========================================="
echo "✓ Minikube instalado com sucesso!"
echo "========================================="
echo ""
echo "Comandos úteis:"
echo "  minikube status              # Ver status do cluster"
echo "  minikube dashboard           # Abrir dashboard web"
echo "  minikube stop                # Parar cluster"
echo "  minikube start               # Iniciar cluster"
echo "  minikube delete              # Deletar cluster"
echo ""
echo "  kubectl get nodes            # Ver nodes"
echo "  kubectl get pods -A          # Ver todos os pods"
echo "  kubectl get namespaces       # Ver namespaces"
echo ""
echo "Próximos passos:"
echo "  1. Jenkins fará deploy dos seus projetos neste cluster"
echo "  2. Configure as credenciais do kubectl no Jenkins"
echo ""
