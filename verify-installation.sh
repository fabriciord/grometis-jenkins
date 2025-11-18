#!/bin/bash

################################################################################
# Script de verificação do ambiente
# 
# Verifica se todas as dependências estão instaladas e configuradas
# Uso: ./verify-installation.sh
################################################################################

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================="
echo "Verificação de Instalação"
echo "========================================="
echo ""

# Função para verificar comando
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $2 instalado"
        return 0
    else
        echo -e "${RED}✗${NC} $2 NÃO instalado"
        return 1
    fi
}

# Função para verificar serviço
check_service() {
    if systemctl is-active --quiet "$1"; then
        echo -e "${GREEN}✓${NC} $2 está rodando"
        return 0
    else
        echo -e "${RED}✗${NC} $2 NÃO está rodando"
        return 1
    fi
}

# Verificar comandos
echo "Verificando comandos instalados:"
check_command "docker" "Docker"
check_command "docker-compose" "Docker Compose"
check_command "java" "Java"
check_command "git" "Git"
echo ""

# Verificar serviços
echo "Verificando serviços:"
check_service "docker" "Docker"
check_service "jenkins" "Jenkins"
echo ""

# Verificar grupos do usuário
echo "Verificando grupos do usuário:"
if groups | grep -q docker; then
    echo -e "${GREEN}✓${NC} Usuário está no grupo docker"
else
    echo -e "${RED}✗${NC} Usuário NÃO está no grupo docker"
    echo "  Execute: sudo usermod -aG docker $USER && newgrp docker"
fi
echo ""

# Verificar acesso ao Docker
echo "Verificando acesso ao Docker:"
if docker ps > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Docker acessível"
    docker --version
else
    echo -e "${RED}✗${NC} Erro ao acessar Docker"
fi
echo ""

# Verificar Jenkins
echo "Verificando Jenkins:"
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    echo -e "${GREEN}✓${NC} Jenkins instalado"
    echo "  URL: http://$(hostname -I | awk '{print $1}'):8080"
    echo "  Senha inicial: $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo 'N/A')"
else
    echo -e "${YELLOW}!${NC} Jenkins pode ainda estar inicializando"
fi
echo ""

# Verificar SSH
echo "Verificando configuração SSH:"
if [ -f ~/.ssh/id_rsa ]; then
    echo -e "${GREEN}✓${NC} Chave SSH privada existe"
else
    echo -e "${YELLOW}!${NC} Chave SSH privada não encontrada"
    echo "  Execute: ssh-keygen -t rsa -b 4096"
fi

if [ -f ~/.ssh/id_rsa.pub ]; then
    echo -e "${GREEN}✓${NC} Chave SSH pública existe"
else
    echo -e "${YELLOW}!${NC} Chave SSH pública não encontrada"
fi
echo ""

echo "========================================="
echo "Verificação completa!"
echo "========================================="
