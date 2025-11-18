# Configuração de Token GitHub para Jenkins

## Passo 1: Criar Personal Access Token no GitHub

1. Acesse o GitHub e faça login na sua conta
2. Vá para **Settings** (Configurações) no menu do seu perfil
3. No menu lateral esquerdo, role até o final e clique em **Developer settings**
4. Clique em **Personal access tokens** → **Tokens (classic)**
5. Clique em **Generate new token** → **Generate new token (classic)**

## Passo 2: Configurar o Token

### Nome do Token
- Dê um nome descritivo, por exemplo: `jenkins-grometis-token`

### Expiração
- Escolha a validade (recomendado: 90 dias ou conforme política da empresa)

### Escopos Necessários (Selecione os seguintes)

Para integração básica com Jenkins:
- ✅ **repo** (acesso completo aos repositórios privados)
  - repo:status
  - repo_deployment
  - public_repo
  - repo:invite
  - security_events

Para webhooks:
- ✅ **admin:repo_hook** (para criar/editar webhooks)
  - write:repo_hook
  - read:repo_hook

Para notificações:
- ✅ **notifications** (acesso às notificações)

Para usuário (opcional, mas recomendado):
- ✅ **user:email** (acesso ao email)

## Passo 3: Gerar e Copiar o Token

1. Clique em **Generate token** no final da página
2. **IMPORTANTE**: Copie o token imediatamente - ele só será mostrado uma vez
3. Salve o token em um local seguro (gerenciador de senhas)

## Passo 4: Adicionar Token no Jenkins

### Via Interface Web:

1. Acesse o Jenkins: `http://seu-jenkins:8080`
2. Vá para **Manage Jenkins** → **Manage Credentials**
3. Clique no domínio apropriado (geralmente "(global)")
4. Clique em **Add Credentials**
5. Configure:
   - **Kind**: Secret text
   - **Scope**: Global
   - **Secret**: Cole o token do GitHub
   - **ID**: `github-token` (ou outro identificador)
   - **Description**: Token GitHub para acesso aos repositórios
6. Clique em **Create**

### Via CLI (Alternativo):

```bash
# Usando Jenkins CLI
java -jar jenkins-cli.jar -s http://localhost:8080/ \
  create-credentials-by-xml system::system::jenkins \
  < credentials.xml
```

## Passo 5: Usar o Token no Pipeline

### No Jenkinsfile:

```groovy
pipeline {
    agent any
    
    environment {
        GITHUB_TOKEN = credentials('github-token')
    }
    
    stages {
        stage('Checkout') {
            steps {
                git credentialsId: 'github-token',
                    url: 'https://github.com/fabriciord/grometis-jenkins.git',
                    branch: 'main'
            }
        }
    }
}
```

### Para clonar repositórios com token:

```bash
git clone https://${GITHUB_TOKEN}@github.com/fabriciord/grometis-jenkins.git
```

## Segurança e Boas Práticas

1. **Nunca commite o token no código**: Sempre use credenciais do Jenkins
2. **Rotação regular**: Troque o token periodicamente
3. **Princípio do menor privilégio**: Dê apenas as permissões necessárias
4. **Monitore o uso**: Verifique regularmente os logs de acesso do token
5. **Revogue tokens não utilizados**: Mantenha apenas tokens ativos necessários

## Troubleshooting

### Erro: "Authentication failed"
- Verifique se o token foi copiado corretamente
- Confirme que o token tem as permissões necessárias
- Verifique se o token não expirou

### Erro: "Repository not found"
- Confirme que o token tem acesso ao repositório
- Verifique se o escopo `repo` está habilitado
- Para repos privados, certifique-se de que tem acesso ao repositório

### Webhook não funciona
- Verifique se o escopo `admin:repo_hook` está habilitado
- Confirme que o Jenkins está acessível publicamente (ou via VPN/túnel)
- Teste a URL do webhook manualmente

## Links Úteis

- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [Jenkins Credentials Plugin](https://plugins.jenkins.io/credentials/)
- [GitHub API Scopes](https://docs.github.com/en/developers/apps/building-oauth-apps/scopes-for-oauth-apps)
