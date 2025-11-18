#!/bin/bash

################################################################################
# Script para criar VM Multipass com Jenkins, Docker e Docker Compose
# 
# Uso: ./create-vm.sh
# 
# Este script cria uma VM Ubuntu com todas as dependências necessárias
# para executar o pipeline CI/CD com Jenkins
################################################################################

set -e  # Exit on error

# Configurações da VM
VM_NAME="jenkins-cicd"
VM_CPUS="2"
VM_MEMORY="4G"
VM_DISK="20G"
CLOUD_INIT_FILE="cloud-init.yaml"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Jenkins CI/CD VM Setup${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}IMPORTANTE: Este script deve ser executado${NC}"
echo -e "${YELLOW}no Ubuntu Server (192.168.15.6) onde o${NC}"
echo -e "${YELLOW}Multipass está instalado.${NC}"
echo ""

# Verificar se multipass está instalado
if ! command -v multipass &> /dev/null; then
    echo -e "${RED}Error: Multipass não está instalado${NC}"
    echo "Instale com: sudo snap install multipass"
    echo "Ou verifique se está no PATH do sistema"
    exit 1
fi

# Verificar se o arquivo cloud-init existe
if [ ! -f "$CLOUD_INIT_FILE" ]; then
    echo -e "${RED}Error: Arquivo $CLOUD_INIT_FILE não encontrado${NC}"
    echo "Certifique-se de que o arquivo cloud-init.yaml está no mesmo diretório"
    exit 1
fi

# Verificar se a VM já existe
if multipass list | grep -q "$VM_NAME"; then
    echo -e "${YELLOW}VM $VM_NAME já existe${NC}"
    read -p "Deseja deletar e recriar? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}Deletando VM existente...${NC}"
        multipass delete "$VM_NAME"
        multipass purge
    else
        echo -e "${YELLOW}Mantendo VM existente${NC}"
        exit 0
    fi
fi

echo -e "${GREEN}Criando VM $VM_NAME...${NC}"
echo "Configurações:"
echo "  - CPUs: $VM_CPUS"
echo "  - Memory: $VM_MEMORY"
echo "  - Disk: $VM_DISK"
echo "  - Cloud-init: $CLOUD_INIT_FILE"
echo ""

# Criar a VM com cloud-init
multipass launch \
    --name "$VM_NAME" \
    --cpus "$VM_CPUS" \
    --memory "$VM_MEMORY" \
    --disk "$VM_DISK" \
    --cloud-init "$CLOUD_INIT_FILE" \
    22.04

echo -e "${GREEN}VM criada com sucesso!${NC}"
echo ""

# Aguardar a VM estar pronta
echo -e "${YELLOW}Aguardando a VM inicializar...${NC}"
sleep 10

# Obter informações da VM
VM_IP=$(multipass info "$VM_NAME" | grep IPv4 | awk '{print $2}')

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}VM Information${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Nome: $VM_NAME"
echo "IP: $VM_IP"
echo "Usuário: grometis"
echo "Senha: grometis123"
echo ""

echo -e "${YELLOW}Aguardando instalação do Jenkins (isso pode levar alguns minutos)...${NC}"
sleep 60

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Próximos Passos${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "1. Acesse a VM via SSH:"
echo "   multipass shell $VM_NAME"
echo "   ou"
echo "   ssh grometis@$VM_IP"
echo ""
echo "2. Verifique a senha inicial do Jenkins:"
echo "   multipass exec $VM_NAME -- sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo ""
echo "3. Acesse o Jenkins no navegador:"
echo "   http://$VM_IP:8080"
echo ""
echo "4. Configure as credenciais do Docker Hub e GitHub no Jenkins"
echo ""
echo "5. Execute o script de configuração adicional:"
echo "   ./setup-jenkins.sh"
echo ""
echo -e "${GREEN}Setup completo!${NC}"
