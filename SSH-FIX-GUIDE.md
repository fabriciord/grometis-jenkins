# 🔧 Guia Rápido: Corrigir Erro de SSH no Deploy

## 🎯 Problema

O Jenkins está falhando no stage de Deploy com erro:
```
Permission denied (publickey,password)
```

Isso significa que a chave SSH do Jenkins não está autorizada no servidor de destino (192.168.15.6).

---

## ✅ Solução Rápida

### Passo 1: Conectar ao Servidor Ubuntu (192.168.15.6)

No seu **MacOS**, conecte via SSH ao servidor:

```bash
ssh grometis@192.168.15.6
```

### Passo 2: Navegar para o Diretório do Projeto

```bash
cd ~/grometis-jenkins
```

### Passo 3: Atualizar os Arquivos do Projeto

```bash
# Fazer pull das atualizações
git pull origin main

# Dar permissões de execução aos scripts
chmod +x *.sh
```

### Passo 4: Executar Diagnóstico SSH

```bash
./diagnose-ssh.sh
```

Este script irá verificar:
- ✓ Se a VM jenkins-cicd está rodando
- ✓ Se as chaves SSH existem na VM
- ✓ Se o authorized_keys está configurado no servidor
- ✓ Se a conexão SSH está funcionando

### Passo 5: Configurar o SSH Automaticamente

```bash
./setup-ssh-target.sh
```

Este script irá:
1. Obter a chave pública do Jenkins (da VM jenkins-cicd)
2. Adicionar ao `~/.ssh/authorized_keys` do usuário grometis no servidor
3. Configurar permissões corretas
4. Testar a conexão

### Passo 6: Verificar a Chave no Jenkins

Se o script solicitar, copie a chave privada do Jenkins:

```bash
multipass exec jenkins-cicd -- sudo cat /var/lib/jenkins/.ssh/id_rsa
```

E verifique se ela está configurada corretamente no Jenkins:
- **Manage Jenkins** → **Credentials** → **ssh-credentials**

---

## 🧪 Teste Manual (Opcional)

Para testar manualmente a conexão SSH:

```bash
# Entre na VM
multipass shell jenkins-cicd

# Dentro da VM, teste como usuário jenkins
sudo -u jenkins ssh grometis@192.168.15.6 echo "SSH OK"
```

Se retornar "SSH OK", a configuração está correta! ✅

Se pedir senha ou der erro, execute novamente o `setup-ssh-target.sh`.

---

## 📋 Resumo dos Comandos (Copie e Cole)

```bash
# No seu MacOS
ssh grometis@192.168.15.6

# Dentro do servidor Ubuntu (192.168.15.6)
cd ~/grometis-jenkins
git pull origin main
chmod +x *.sh
./diagnose-ssh.sh
./setup-ssh-target.sh
```

---

## 🚀 Após Corrigir

1. Execute um novo build no Jenkins manualmente
2. Ou espere o Jenkins detectar o próximo commit automaticamente
3. O stage de Deploy deve funcionar agora! 🎉

---

## ❓ Troubleshooting

### Se o diagnóstico mostrar que a chave não está no authorized_keys:

```bash
./setup-ssh-target.sh
```

### Se ainda falhar, verifique manualmente:

```bash
# No servidor (192.168.15.6)
ls -la ~/.ssh/
cat ~/.ssh/authorized_keys

# Deve conter uma linha começando com:
# ssh-rsa AAAAB3NzaC1yc2EA... grometis@jenkins-deploy
```

### Para reconfigurar tudo do zero:

```bash
# Dentro da VM (multipass shell jenkins-cicd)
cd ~/grometis-jenkins
sudo bash configure-ssh.sh

# Depois no servidor (ssh grometis@192.168.15.6)
cd ~/grometis-jenkins
./setup-ssh-target.sh
```

---

## 📝 Arquitetura do SSH

```
┌─────────────────────────────────────────┐
│  VM jenkins-cicd (10.224.139.135)      │
│                                         │
│  /var/lib/jenkins/.ssh/                │
│    ├── id_rsa         (privada) 🔑     │
│    └── id_rsa.pub     (pública) 🔓     │
│                                         │
│  Usuário: jenkins                       │
└───────────────┬─────────────────────────┘
                │ SSH Deploy
                │
                ↓
┌─────────────────────────────────────────┐
│  Servidor Ubuntu (192.168.15.6)        │
│                                         │
│  ~/.ssh/authorized_keys                │
│    └── contém a chave pública 🔓        │
│       do Jenkins                        │
│                                         │
│  Usuário: grometis                      │
└─────────────────────────────────────────┘
```

---

**Dica**: Mantenha este guia aberto enquanto executa os comandos! 📖
