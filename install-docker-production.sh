#!/bin/bash

################################################################################
# Script para instalar Docker no Servidor de Produção (192.168.15.6)
# 
# Execute este script NO SERVIDOR Ubuntu (192.168.15.6)
# Este servidor será o ambiente de PRODUÇÃO onde a aplicação rodará
################################################################################

set -e

echo "========================================="
echo "Instalação Docker - Servidor Produção"
echo "========================================="
echo ""
echo "Este script instalará Docker e Docker Compose"
echo "no servidor de produção (192.168.15.6)"
echo ""

# Verificar se está rodando como usuário correto
if [ "$USER" != "grometis" ]; then
    echo "⚠️  Este script deve ser executado como usuário grometis"
    echo "Execute: su - grometis"
    exit 1
fi

echo "[1/6] Atualizando sistema..."
sudo apt-get update

echo ""
echo "[2/6] Instalando dependências..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

echo ""
echo "[3/6] Adicionando chave GPG do Docker..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo ""
echo "[4/6] Adicionando repositório do Docker..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo ""
echo "[5/6] Instalando Docker Engine..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo ""
echo "[6/6] Configurando permissões..."
# Adicionar usuário ao grupo docker
sudo usermod -aG docker grometis

# Habilitar Docker para iniciar no boot
sudo systemctl enable docker
sudo systemctl start docker

echo ""
echo "========================================="
echo "✓ Instalação Concluída!"
echo "========================================="
echo ""
echo "Docker instalado com sucesso!"
echo ""
echo "⚠️  IMPORTANTE: Faça logout e login novamente para aplicar as permissões do grupo docker"
echo ""
echo "Para testar:"
echo "  exit  # Sair da sessão SSH"
echo "  ssh grometis@192.168.15.6  # Conectar novamente"
echo "  docker --version"
echo "  docker ps"
echo ""
echo "Após re-login, o deploy do Jenkins funcionará corretamente!"
echo ""
