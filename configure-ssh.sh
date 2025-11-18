#!/bin/bash

################################################################################
# Script para configurar acesso SSH do Jenkins à VM
# 
# Este script configura as chaves SSH e permissões necessárias
# para que o Jenkins possa fazer deploy via SSH
################################################################################

set -e

echo "========================================="
echo "Configuração de SSH para Jenkins"
echo "========================================="
echo ""

# Criar diretório SSH se não existir
sudo mkdir -p /var/lib/jenkins/.ssh
sudo mkdir -p /home/grometis/.ssh

# Definir permissões corretas
sudo chmod 700 /var/lib/jenkins/.ssh
sudo chmod 700 /home/grometis/.ssh

# Gerar chave SSH para grometis se não existir
if [ ! -f /home/grometis/.ssh/id_rsa ]; then
    echo "Gerando nova chave SSH para grometis..."
    sudo -u grometis ssh-keygen -t rsa -b 4096 -C "grometis@jenkins-deploy" -f /home/grometis/.ssh/id_rsa -N ""
fi

# Copiar chave para authorized_keys
sudo -u grometis cat /home/grometis/.ssh/id_rsa.pub >> /home/grometis/.ssh/authorized_keys
sudo chmod 600 /home/grometis/.ssh/authorized_keys
sudo chown grometis:grometis /home/grometis/.ssh/authorized_keys

# Copiar chave privada para Jenkins
sudo cp /home/grometis/.ssh/id_rsa /var/lib/jenkins/.ssh/
sudo cp /home/grometis/.ssh/id_rsa.pub /var/lib/jenkins/.ssh/
sudo chown -R jenkins:jenkins /var/lib/jenkins/.ssh
sudo chmod 600 /var/lib/jenkins/.ssh/id_rsa
sudo chmod 644 /var/lib/jenkins/.ssh/id_rsa.pub

# Configurar SSH config para evitar prompt de host verification
cat <<EOF | sudo tee /var/lib/jenkins/.ssh/config
Host 192.168.15.6 localhost 127.0.0.1
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
    LogLevel ERROR
EOF

sudo chown jenkins:jenkins /var/lib/jenkins/.ssh/config
sudo chmod 600 /var/lib/jenkins/.ssh/config

echo ""
echo "✓ Chaves SSH configuradas"
echo "✓ Permissões ajustadas"
echo ""
echo "Chave pública (adicione ao Jenkins como credential):"
echo "========================================="
sudo cat /var/lib/jenkins/.ssh/id_rsa.pub
echo "========================================="
echo ""
echo "Chave privada localizada em:"
echo "/var/lib/jenkins/.ssh/id_rsa"
echo ""
echo "Para copiar a chave privada:"
echo "sudo cat /var/lib/jenkins/.ssh/id_rsa"
