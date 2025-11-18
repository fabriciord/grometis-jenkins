#!/bin/bash

################################################################################
# Script de instalação e configuração do Jenkins
# 
# Este script deve ser executado DENTRO da VM Ubuntu
# Uso: ./setup-jenkins.sh
################################################################################

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Jenkins Setup Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Verificar se está executando como grometis
if [ "$USER" != "grometis" ]; then
    echo -e "${RED}Este script deve ser executado como usuário grometis${NC}"
    exit 1
fi

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker não está instalado. Execute o cloud-init primeiro.${NC}"
    exit 1
fi

# Verificar se Jenkins está rodando
if ! systemctl is-active --quiet jenkins; then
    echo -e "${YELLOW}Jenkins não está rodando. Iniciando...${NC}"
    sudo systemctl start jenkins
    sleep 10
fi

echo -e "${GREEN}✓ Docker instalado${NC}"
echo -e "${GREEN}✓ Jenkins rodando${NC}"
echo ""

# Obter senha inicial do Jenkins
JENKINS_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "")

if [ -z "$JENKINS_PASSWORD" ]; then
    echo -e "${RED}Não foi possível obter a senha inicial do Jenkins${NC}"
    echo "Tente executar: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Informações do Jenkins${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Jenkins URL: http://$(hostname -I | awk '{print $1}'):8080"
echo "Initial Admin Password: $JENKINS_PASSWORD"
echo ""
echo "Salve esta senha! Você precisará dela para acessar o Jenkins pela primeira vez."
echo ""

# Criar diretório para SSH keys se não existir
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Verificar se já existe chave SSH
if [ ! -f ~/.ssh/id_rsa ]; then
    echo -e "${YELLOW}Gerando chave SSH para deploy...${NC}"
    ssh-keygen -t rsa -b 4096 -C "grometis@jenkins-cicd" -f ~/.ssh/id_rsa -N ""
    echo -e "${GREEN}✓ Chave SSH gerada${NC}"
else
    echo -e "${GREEN}✓ Chave SSH já existe${NC}"
fi

# Adicionar chave pública ao authorized_keys
if [ ! -f ~/.ssh/authorized_keys ]; then
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi

if ! grep -q "$(cat ~/.ssh/id_rsa.pub)" ~/.ssh/authorized_keys 2>/dev/null; then
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    echo -e "${GREEN}✓ Chave pública adicionada ao authorized_keys${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Chave Pública SSH${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
cat ~/.ssh/id_rsa.pub
echo ""

# Copiar chave privada para Jenkins
echo -e "${YELLOW}Configurando chave SSH para Jenkins...${NC}"
sudo mkdir -p /var/lib/jenkins/.ssh
sudo cp ~/.ssh/id_rsa /var/lib/jenkins/.ssh/
sudo cp ~/.ssh/id_rsa.pub /var/lib/jenkins/.ssh/
sudo chown -R jenkins:jenkins /var/lib/jenkins/.ssh
sudo chmod 700 /var/lib/jenkins/.ssh
sudo chmod 600 /var/lib/jenkins/.ssh/id_rsa
echo -e "${GREEN}✓ Chave SSH configurada para Jenkins${NC}"

# Testar acesso Docker
echo ""
echo -e "${YELLOW}Testando acesso ao Docker...${NC}"
if docker ps > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Docker acessível pelo usuário grometis${NC}"
else
    echo -e "${RED}✗ Erro ao acessar Docker${NC}"
    echo "Execute: newgrp docker"
fi

# Verificar se Jenkins pode acessar Docker
if sudo -u jenkins docker ps > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Docker acessível pelo Jenkins${NC}"
else
    echo -e "${YELLOW}! Jenkins precisa de logout/login para acessar Docker${NC}"
    echo "Execute: sudo systemctl restart jenkins"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Próximos Passos${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "1. Acesse o Jenkins: http://$(hostname -I | awk '{print $1}'):8080"
echo ""
echo "2. Use a senha inicial: $JENKINS_PASSWORD"
echo ""
echo "3. Instale os plugins recomendados + os seguintes:"
echo "   - Docker Pipeline"
echo "   - SSH Agent"
echo "   - GitHub Integration"
echo "   - Credentials Binding"
echo ""
echo "4. Configure as credenciais:"
echo "   - Docker Hub (tipo: Username with password)"
echo "     ID: dockerhub-credentials"
echo ""
echo "   - GitHub (tipo: Username with password ou Personal Access Token)"
echo "     ID: github-credentials"
echo ""
echo "   - SSH Key (tipo: SSH Username with private key)"
echo "     ID: ssh-credentials"
echo "     Username: grometis"
echo "     Private Key: Cole a chave de ~/.ssh/id_rsa"
echo ""
echo "5. Crie um Multibranch Pipeline apontando para seu repositório GitHub"
echo ""
echo "6. Certifique-se de que o Jenkinsfile está na raiz do repositório"
echo ""
echo -e "${GREEN}Setup completo!${NC}"
