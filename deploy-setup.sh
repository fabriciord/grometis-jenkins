#!/bin/bash

################################################################################
# Script Automatizado de Deploy do Jenkins CI/CD
# 
# Este script irá guiá-lo através do processo completo de deploy
# Execute este script NO SERVIDOR UBUNTU (192.168.15.6)
################################################################################

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Jenkins CI/CD - Deploy Automatizado${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Verificar se está no servidor correto
read -p "Você está conectado ao servidor Ubuntu (192.168.15.6)? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${RED}Por favor, conecte-se ao servidor primeiro:${NC}"
    echo "ssh grometis@192.168.15.6"
    exit 1
fi

# Passo 1: Verificar se multipass está instalado
echo -e "${BLUE}[1/7] Verificando Multipass...${NC}"
if ! command -v multipass &> /dev/null; then
    echo -e "${RED}✗ Multipass não encontrado${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Multipass instalado${NC}"
echo ""

# Passo 2: Verificar se VM existe
echo -e "${BLUE}[2/7] Verificando VM jenkins-cicd...${NC}"
if multipass list | grep -q "jenkins-cicd"; then
    echo -e "${GREEN}✓ VM jenkins-cicd encontrada${NC}"
    VM_IP=$(multipass info jenkins-cicd | grep IPv4 | awk '{print $2}')
    echo -e "${GREEN}  IP: ${VM_IP}${NC}"
else
    echo -e "${YELLOW}! VM não encontrada. Criando...${NC}"
    read -p "Deseja criar a VM agora? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        ./create-vm.sh
        VM_IP=$(multipass info jenkins-cicd | grep IPv4 | awk '{print $2}')
    else
        exit 1
    fi
fi
echo ""

# Passo 3: Obter senha do Jenkins
echo -e "${BLUE}[3/7] Obtendo senha inicial do Jenkins...${NC}"
JENKINS_PASSWORD=$(multipass exec jenkins-cicd -- sudo cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "")

if [ -z "$JENKINS_PASSWORD" ]; then
    echo -e "${YELLOW}! Senha não disponível ainda. Jenkins pode estar inicializando...${NC}"
    echo "  Aguarde 1-2 minutos e tente novamente"
else
    echo -e "${GREEN}✓ Senha do Jenkins:${NC}"
    echo ""
    echo -e "${YELLOW}================================================${NC}"
    echo -e "${YELLOW}  ${JENKINS_PASSWORD}${NC}"
    echo -e "${YELLOW}================================================${NC}"
    echo ""
    echo "  Salve esta senha! Você precisará dela para acessar:"
    echo "  http://${VM_IP}:8080"
fi
echo ""

# Passo 4: Configurar SSH
echo -e "${BLUE}[4/7] Configurando SSH...${NC}"
read -p "Deseja configurar o SSH agora? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    multipass exec jenkins-cicd -- bash -c "cd ~/grometis-jenkins && ./configure-ssh.sh"
    echo -e "${GREEN}✓ SSH configurado${NC}"
    echo ""
    echo -e "${YELLOW}Chave SSH privada (copie para usar no Jenkins):${NC}"
    echo -e "${YELLOW}================================================${NC}"
    multipass exec jenkins-cicd -- sudo cat /var/lib/jenkins/.ssh/id_rsa
    echo -e "${YELLOW}================================================${NC}"
else
    echo -e "${YELLOW}! Pulando configuração SSH${NC}"
fi
echo ""

# Passo 5: Verificar instalação
echo -e "${BLUE}[5/7] Verificando instalação...${NC}"
multipass exec jenkins-cicd -- bash -c "cd ~/grometis-jenkins && ./verify-installation.sh" || true
echo ""

# Passo 6: Instruções para Jenkins
echo -e "${BLUE}[6/7] Próximos passos no Jenkins:${NC}"
echo ""
echo "1. Acesse: http://${VM_IP}:8080"
echo "   Senha: ${JENKINS_PASSWORD}"
echo ""
echo "2. Instale os plugins sugeridos + Docker Pipeline + SSH Agent"
echo ""
echo "3. Crie as credenciais:"
echo ""
echo "   a) Docker Hub (dockerhub-credentials):"
echo "      - Kind: Username with password"
echo "      - Username: <seu-usuario-dockerhub>"
echo "      - Password: <seu-token-dockerhub>"
echo "      - ID: dockerhub-credentials"
echo ""
echo "   b) SSH (mahindra):"
echo "      - Kind: SSH Username with private key"
echo "      - Username: grometis"
echo "      - Private Key: Cole a chave exibida acima"
echo "      - ID: mahindra"
echo ""

# Passo 7: GitHub
echo -e "${BLUE}[7/7] Push para GitHub:${NC}"
echo ""
read -p "Você já fez push do código para o GitHub? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo ""
    echo "Execute no seu MacOS ou servidor:"
    echo ""
    echo "  cd ~/grometis-jenkins"
    echo "  git init"
    echo "  git add ."
    echo "  git commit -m \"Initial commit: Jenkins CI/CD\""
    echo "  git branch -M main"
    echo "  git remote add origin https://github.com/SEU-USUARIO/SEU-REPO.git"
    echo "  git push -u origin main"
fi
echo ""

# Resumo final
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Setup Concluído!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Checklist:"
echo "  [✓] VM jenkins-cicd criada"
echo "  [✓] Jenkins rodando"
echo "  [✓] SSH configurado"
echo ""
echo "Próximos passos:"
echo "  1. Configure credenciais no Jenkins"
echo "  2. Faça push do código para GitHub"
echo "  3. Crie o Multibranch Pipeline no Jenkins"
echo ""
echo "Depois disso, o deploy será automático! 🚀"
echo ""
