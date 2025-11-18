#!/bin/bash

################################################################################
# Script de Diagnóstico SSH para Jenkins Deploy
# 
# Verifica a configuração SSH entre Jenkins e servidor de destino
################################################################################

set -e

echo "========================================="
echo "Diagnóstico SSH - Jenkins Deploy"
echo "========================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "[1] Verificando VM jenkins-cicd..."
if multipass list | grep -q jenkins-cicd; then
    check_pass "VM jenkins-cicd está rodando"
    VM_IP=$(multipass info jenkins-cicd | grep IPv4 | awk '{print $2}')
    echo "    IP da VM: $VM_IP"
else
    check_fail "VM jenkins-cicd não encontrada"
    exit 1
fi

echo ""
echo "[2] Verificando chaves SSH na VM..."

# Verificar chave privada do Jenkins
if multipass exec jenkins-cicd -- sudo test -f /var/lib/jenkins/.ssh/id_rsa; then
    check_pass "Chave privada do Jenkins existe"
    KEY_TYPE=$(multipass exec jenkins-cicd -- sudo ssh-keygen -l -f /var/lib/jenkins/.ssh/id_rsa | awk '{print $4}')
    echo "    Tipo: $KEY_TYPE"
else
    check_fail "Chave privada do Jenkins não encontrada"
    echo "    Execute: multipass exec jenkins-cicd -- bash -c 'cd ~/grometis-jenkins && sudo bash configure-ssh.sh'"
fi

# Verificar chave pública
if multipass exec jenkins-cicd -- sudo test -f /var/lib/jenkins/.ssh/id_rsa.pub; then
    check_pass "Chave pública do Jenkins existe"
    PUB_KEY=$(multipass exec jenkins-cicd -- sudo cat /var/lib/jenkins/.ssh/id_rsa.pub)
    echo "    Key fingerprint: $(echo $PUB_KEY | awk '{print $1, $2, substr($3,1,20)"..."}')"
else
    check_fail "Chave pública do Jenkins não encontrada"
fi

# Verificar permissões
PERMS=$(multipass exec jenkins-cicd -- sudo stat -c %a /var/lib/jenkins/.ssh/id_rsa 2>/dev/null || echo "000")
if [ "$PERMS" = "600" ]; then
    check_pass "Permissões da chave privada corretas (600)"
else
    check_fail "Permissões incorretas da chave privada: $PERMS (deveria ser 600)"
fi

echo ""
echo "[3] Verificando configuração no servidor de destino (192.168.15.6)..."

# Verificar se authorized_keys existe
if [ -f ~/.ssh/authorized_keys ]; then
    check_pass "Arquivo authorized_keys existe"
    
    # Verificar se a chave do Jenkins está no authorized_keys
    if [ -n "$PUB_KEY" ]; then
        KEY_PART=$(echo $PUB_KEY | awk '{print $2}' | cut -c1-50)
        if grep -q "$KEY_PART" ~/.ssh/authorized_keys; then
            check_pass "Chave do Jenkins está no authorized_keys"
        else
            check_fail "Chave do Jenkins NÃO está no authorized_keys"
            echo ""
            echo "Para adicionar a chave, execute:"
            echo "  ./setup-ssh-target.sh"
        fi
    fi
    
    # Verificar permissões do authorized_keys
    AUTH_PERMS=$(stat -c %a ~/.ssh/authorized_keys)
    if [ "$AUTH_PERMS" = "600" ]; then
        check_pass "Permissões do authorized_keys corretas (600)"
    else
        check_warn "Permissões do authorized_keys: $AUTH_PERMS (recomendado: 600)"
    fi
else
    check_fail "Arquivo authorized_keys não existe"
    echo "    Execute: ./setup-ssh-target.sh"
fi

echo ""
echo "[4] Testando conectividade SSH..."

# Teste de conectividade básica
if ping -c 1 -W 2 192.168.15.6 >/dev/null 2>&1; then
    check_pass "Servidor 192.168.15.6 está acessível"
else
    check_fail "Não foi possível alcançar 192.168.15.6"
fi

# Teste de conexão SSH da VM para o servidor
echo ""
echo "Testando conexão SSH da VM para o servidor..."
SSH_TEST=$(multipass exec jenkins-cicd -- sudo -u jenkins ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes grometis@192.168.15.6 "echo SSH_OK" 2>&1 || echo "FAILED")

if [[ "$SSH_TEST" == *"SSH_OK"* ]]; then
    check_pass "Conexão SSH funcionando!"
    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}✓ Tudo configurado corretamente!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "O Jenkins deve conseguir fazer deploy para 192.168.15.6"
elif [[ "$SSH_TEST" == *"Permission denied"* ]]; then
    check_fail "Conexão SSH falhou: Permissão negada"
    echo ""
    echo "Possíveis causas:"
    echo "1. A chave pública não está no authorized_keys do servidor"
    echo "2. As permissões dos arquivos SSH estão incorretas"
    echo ""
    echo "Solução:"
    echo "  ./setup-ssh-target.sh"
elif [[ "$SSH_TEST" == *"Connection refused"* ]]; then
    check_fail "Conexão SSH falhou: Conexão recusada"
    echo ""
    echo "Verifique se o serviço SSH está rodando no servidor:"
    echo "  sudo systemctl status ssh"
else
    check_fail "Conexão SSH falhou"
    echo ""
    echo "Detalhes do erro:"
    echo "$SSH_TEST"
fi

echo ""
echo "========================================="
echo "Resumo das Configurações"
echo "========================================="
echo ""
echo "VM Jenkins:"
echo "  IP: $VM_IP"
echo "  Usuário: jenkins"
echo "  Chave: /var/lib/jenkins/.ssh/id_rsa"
echo ""
echo "Servidor Destino:"
echo "  IP: 192.168.15.6"
echo "  Usuário: grometis"
echo "  Authorized Keys: ~/.ssh/authorized_keys"
echo ""
echo "Para ver a chave privada (adicionar no Jenkins):"
echo "  multipass exec jenkins-cicd -- sudo cat /var/lib/jenkins/.ssh/id_rsa"
echo ""
