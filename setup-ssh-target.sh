#!/bin/bash

################################################################################
# Script para configurar acesso SSH no SERVIDOR DE DESTINO (192.168.15.6)
# 
# Execute este script NO SERVIDOR Ubuntu (192.168.15.6) para:
# 1. Obter a chave pública do Jenkins (da VM jenkins-cicd)
# 2. Adicionar ao authorized_keys do usuário grometis no servidor host
################################################################################

set -e

echo "========================================="
echo "Setup SSH - Servidor de Destino"
echo "========================================="
echo ""
echo "Este script configura o acesso SSH do Jenkins"
echo "para fazer deploy no servidor 192.168.15.6"
echo ""

# Verificar se estamos no servidor correto
if [ ! -d ~/grometis-jenkins ]; then
    echo "❌ Erro: Diretório ~/grometis-jenkins não encontrado"
    echo "Execute este script no servidor Ubuntu (192.168.15.6)"
    exit 1
fi

# Verificar se a VM jenkins-cicd existe
if ! multipass list | grep -q jenkins-cicd; then
    echo "❌ Erro: VM jenkins-cicd não encontrada"
    echo "Execute primeiro: ./create-vm.sh"
    exit 1
fi

echo "[1/4] Verificando usuário grometis no servidor..."
if ! id grometis &>/dev/null; then
    echo "❌ Erro: Usuário grometis não existe no servidor"
    exit 1
fi
echo "✓ Usuário grometis encontrado"

echo ""
echo "[2/4] Obtendo chave pública do Jenkins (da VM)..."

# Obter a chave pública do Jenkins na VM
JENKINS_PUBLIC_KEY=$(multipass exec jenkins-cicd -- sudo cat /var/lib/jenkins/.ssh/id_rsa.pub 2>/dev/null || echo "")

if [ -z "$JENKINS_PUBLIC_KEY" ]; then
    echo "⚠️  Chave não encontrada. Gerando chave SSH na VM..."
    
    # Executar configure-ssh.sh dentro da VM
    multipass exec jenkins-cicd -- bash -c "
        cd ~/grometis-jenkins
        sudo bash configure-ssh.sh
    "
    
    # Tentar obter novamente
    JENKINS_PUBLIC_KEY=$(multipass exec jenkins-cicd -- sudo cat /var/lib/jenkins/.ssh/id_rsa.pub)
fi

echo "✓ Chave pública obtida"

echo ""
echo "[3/4] Configurando authorized_keys no servidor..."

# Criar diretório .ssh se não existir
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Adicionar chave pública ao authorized_keys
if ! grep -q "$JENKINS_PUBLIC_KEY" ~/.ssh/authorized_keys 2>/dev/null; then
    echo "$JENKINS_PUBLIC_KEY" >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    echo "✓ Chave adicionada ao authorized_keys"
else
    echo "✓ Chave já existe no authorized_keys"
fi

echo ""
echo "[4/4] Testando conexão SSH..."

# Obter IP da VM
VM_IP=$(multipass info jenkins-cicd | grep IPv4 | awk '{print $2}')

# Testar conexão SSH da VM para o servidor
TEST_RESULT=$(multipass exec jenkins-cicd -- sudo -u jenkins ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 grometis@192.168.15.6 "echo 'SSH_OK'" 2>&1 || echo "FAILED")

if [[ "$TEST_RESULT" == *"SSH_OK"* ]]; then
    echo "✓ Conexão SSH funcionando!"
    echo ""
    echo "========================================="
    echo "✓ Setup SSH Completo!"
    echo "========================================="
    echo ""
    echo "Próximos passos:"
    echo "1. A chave SSH já está configurada"
    echo "2. Execute um novo build no Jenkins"
    echo "3. O deploy para 192.168.15.6 deve funcionar"
else
    echo "⚠️  Teste de conexão SSH falhou"
    echo ""
    echo "Detalhes do erro:"
    echo "$TEST_RESULT"
    echo ""
    echo "Tente os seguintes comandos manualmente:"
    echo ""
    echo "1. Entre na VM:"
    echo "   multipass shell jenkins-cicd"
    echo ""
    echo "2. Teste a conexão:"
    echo "   sudo -u jenkins ssh grometis@192.168.15.6"
    echo ""
    echo "3. Se pedir senha, a chave não está configurada corretamente"
fi

echo ""
echo "========================================="
echo "Informações da Chave SSH"
echo "========================================="
echo ""
echo "Chave pública do Jenkins:"
echo "$JENKINS_PUBLIC_KEY"
echo ""
echo "Localização no servidor (192.168.15.6):"
echo "  ~/.ssh/authorized_keys"
echo ""
echo "Para visualizar a chave privada (para adicionar no Jenkins):"
echo "  multipass exec jenkins-cicd -- sudo cat /var/lib/jenkins/.ssh/id_rsa"
echo ""
