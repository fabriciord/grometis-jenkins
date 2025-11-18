# 📝 Guia Rápido de Configuração

## 🚀 Setup Inicial (5 minutos)

### ⚠️ IMPORTANTE: Onde executar cada comando

- **MacOS (sua máquina local)**: Apenas para copiar arquivos via SCP
- **Ubuntu Server (192.168.15.6)**: Onde o **Multipass já está instalado** e onde você executará todos os scripts
- **VM Multipass**: Será criada automaticamente dentro do Ubuntu Server

### 1. Preparar e Copiar Arquivos

```bash
# No seu MacOS (máquina local)
cd /Users/fabriciogomes/GrOMEtiS
scp -r grometis-jenkins/ grometis@192.168.15.6:~/
```

### 2. No Ubuntu Server (192.168.15.6)

```bash
# 1. Conectar ao servidor Ubuntu onde o Multipass está instalado
ssh grometis@192.168.15.6

# 2. Entrar no diretório
cd ~/grometis-jenkins

# 3. Dar permissão aos scripts
chmod +x *.sh

# 4. Criar a VM usando Multipass (no servidor Ubuntu)
./create-vm.sh
```

**⏱️ Aguarde 5-10 minutos** para a instalação completa.

**NOTA**: A VM será criada **dentro do servidor Ubuntu** usando Multipass, não no seu MacOS.

---

### 3. Obter Senha do Jenkins

```bash
# Ainda no Ubuntu Server (192.168.15.6)

# Obter IP da VM criada pelo Multipass
multipass info jenkins-cicd | grep IPv4

# Obter senha inicial do Jenkins
multipass exec jenkins-cicd -- sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

### 4. Acessar Jenkins

1. **No seu navegador (MacOS ou qualquer máquina na rede)**: `http://192.168.15.6:8080`
2. Cole a senha inicial
3. Instale plugins sugeridos + Docker Pipeline + SSH Agent
4. Crie usuário admin

---

### 5. Configurar Credenciais

**Jenkins → Manage Jenkins → Credentials → Global**

#### Docker Hub:
- Kind: Username with password
- ID: `dockerhub-credentials`
- Username: seu-usuario-dockerhub
- Password: seu-token-dockerhub

#### Docker Hub Username:
- Kind: Secret text
- ID: `dockerhub-username`
- Secret: seu-usuario-dockerhub

#### GitHub:
- Kind: Username with password
- ID: `github-credentials`
- Username: seu-usuario-github
- Password: seu-personal-access-token

#### SSH:
```bash
# Gerar chave SSH (executar no Ubuntu Server)
ssh grometis@192.168.15.6
multipass shell jenkins-cicd
cd ~/grometis-jenkins
./configure-ssh.sh
sudo cat /var/lib/jenkins/.ssh/id_rsa
```

- Kind: SSH Username with private key
- ID: `ssh-credentials`
- Username: `grometis`
- Private Key: (colar a chave)

---

### 6. Criar Pipeline

1. **New Item** → Nome: `grometis-cicd-pipeline` → **Multibranch Pipeline**

2. **Branch Sources**:
   - Add source → GitHub
   - Credentials: `github-credentials`
   - Repository: `https://github.com/seu-usuario/seu-repo.git`

3. **Build Configuration**:
   - Script Path: `Jenkinsfile`

4. **Save** e aguarde o scan

---

### 7. Atualizar Jenkinsfile

Edite o `Jenkinsfile` e atualize:

```groovy
environment {
    DOCKERHUB_USERNAME = credentials('dockerhub-username')
    DOCKER_IMAGE_NAME = "${DOCKERHUB_USERNAME}/grometis-app"  // ✅ Seu username
}
```

---

### 8. Push e Teste

```bash
# No seu MacOS ou dentro do servidor Ubuntu
git add .
git commit -m "Configure Jenkins pipeline"
git push
```

O pipeline será executado automaticamente!

---

## ✅ Checklist

- [ ] VM criada com `./create-vm.sh`
- [ ] Jenkins acessível em http://192.168.15.6:8080
- [ ] Plugins instalados (Docker Pipeline, SSH Agent)
- [ ] Credenciais Docker Hub configuradas
- [ ] Credenciais GitHub configuradas
- [ ] Credenciais SSH configuradas
- [ ] Pipeline Multibranch criado
- [ ] Jenkinsfile atualizado com seu username
- [ ] Primeiro build executado com sucesso

---

## 🔍 Verificação

```bash
# Status da VM
multipass list

# Logs do Jenkins
multipass exec jenkins-cicd -- sudo journalctl -u jenkins -f

# Testar Docker
multipass exec jenkins-cicd -- docker ps

# Ver aplicação rodando
curl http://192.168.15.6:3000
```

---

## 🆘 Problemas Comuns

### Jenkins não inicia?
```bash
multipass exec jenkins-cicd -- sudo systemctl restart jenkins
```

### Docker permission denied?
```bash
multipass exec jenkins-cicd -- sudo usermod -aG docker jenkins
multipass exec jenkins-cicd -- sudo systemctl restart jenkins
```

### Pipeline falha no SSH?
```bash
multipass shell jenkins-cicd
cd ~/grometis-jenkins
./configure-ssh.sh
```

---

## 📞 Comandos Úteis

```bash
# Entrar na VM
multipass shell jenkins-cicd

# Ver logs da aplicação
multipass exec jenkins-cicd -- docker-compose -f ~/deployments/grometis-app/docker-compose.yml logs -f

# Reiniciar aplicação
multipass exec jenkins-cicd -- docker-compose -f ~/deployments/grometis-app/docker-compose.yml restart

# Parar VM
multipass stop jenkins-cicd

# Iniciar VM
multipass start jenkins-cicd

# Deletar VM (CUIDADO!)
multipass delete jenkins-cicd && multipass purge
```

---

**Pronto! Seu pipeline CI/CD está funcionando! 🎉**

Para mais detalhes, veja o [README.md](README.md) completo.
