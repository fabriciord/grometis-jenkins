#!/bin/bash

# Script para criar token GitHub para Jenkins
# Autor: GitHub Copilot
# Data: 18/11/2025

set -e

echo "=========================================="
echo "Criação de Token GitHub para Jenkins"
echo "=========================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar se gh está instalado
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Erro: GitHub CLI (gh) não está instalado${NC}"
    echo "Instale com: brew install gh"
    exit 1
fi

# Verificar se está logado
echo "Verificando autenticação..."
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}Você não está autenticado no GitHub CLI${NC}"
    echo ""
    echo "Iniciando processo de login..."
    echo "Escolha as seguintes opções quando solicitado:"
    echo "  1. GitHub.com"
    echo "  2. HTTPS"
    echo "  3. Login with a web browser (recomendado)"
    echo ""
    
    gh auth login
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Erro na autenticação${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Autenticação realizada com sucesso!${NC}"
    echo ""
fi

# Atualizar token com os escopos necessários para Jenkins
echo "Atualizando token com escopos necessários para Jenkins..."
echo "Escopos: repo, admin:repo_hook, notifications, user:email"
echo ""

gh auth refresh -h github.com -s repo,admin:repo_hook,notifications,user:email

if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao atualizar escopos do token${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Token criado/atualizado com sucesso!${NC}"
echo ""

# Obter e exibir o token
echo "=========================================="
echo "Seu Token GitHub:"
echo "=========================================="
TOKEN=$(gh auth token)
echo -e "${GREEN}${TOKEN}${NC}"
echo ""

# Salvar token em arquivo (opcional)
read -p "Deseja salvar o token em um arquivo? (s/N): " SAVE_TOKEN
if [[ $SAVE_TOKEN =~ ^[Ss]$ ]]; then
    TOKEN_FILE="github-token-jenkins-$(date +%Y%m%d).txt"
    echo "$TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    echo -e "${GREEN}Token salvo em: $TOKEN_FILE${NC}"
    echo -e "${YELLOW}IMPORTANTE: Mantenha este arquivo seguro e não commite no git!${NC}"
    echo ""
fi

# Instruções de uso
echo "=========================================="
echo "Próximos Passos:"
echo "=========================================="
echo ""
echo "1. Copie o token acima (ele só aparece uma vez!)"
echo ""
echo "2. No Jenkins, vá para:"
echo "   Manage Jenkins → Manage Credentials → (global) → Add Credentials"
echo ""
echo "3. Configure:"
echo "   - Kind: Secret text"
echo "   - Scope: Global"
echo "   - Secret: [Cole o token]"
echo "   - ID: github-token"
echo "   - Description: Token GitHub para acesso aos repositórios"
echo ""
echo "4. Use no Jenkinsfile:"
echo "   environment {"
echo "       GITHUB_TOKEN = credentials('github-token')"
echo "   }"
echo ""
echo -e "${YELLOW}AVISO DE SEGURANÇA:${NC}"
echo "• Nunca commite o token no código"
echo "• Guarde-o em um gerenciador de senhas"
echo "• Troque regularmente (a cada 90 dias)"
echo ""
echo "=========================================="
echo "Informações do Token:"
echo "=========================================="
gh auth status
echo ""

echo -e "${GREEN}✓ Processo concluído com sucesso!${NC}"
