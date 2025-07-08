#!/bin/bash
# Script principal para gerenciar MinIO S3

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para mostrar banner
show_banner() {
    echo ""
    echo "🚀 MINIO S3 STORAGE MANAGER"
    echo "============================"
    echo ""
}

# Função para verificar dependências
check_dependencies() {
    if ! command -v mc &> /dev/null; then
        echo "❌ MinIO Client (mc) não está instalado!"
        echo "📋 Para instalar:"
        echo "   wget https://dl.min.io/client/mc/release/linux-amd64/mc"
        echo "   chmod +x mc"
        echo "   sudo mv mc /usr/local/bin/"
        exit 1
    fi
}

# Função para verificar configuração
check_config() {
    if [[ ! -f ".env" ]]; then
        echo "❌ Arquivo .env não encontrado!"
        echo "📋 Criando .env baseado no template..."
        
        if [[ -f ".env.example" ]]; then
            cp .env.example .env
            echo "✅ Arquivo .env criado!"
            echo "⚠️  IMPORTANTE: Edite o arquivo .env com suas credenciais reais:"
            echo "   nano .env"
            echo ""
            echo "📋 Configure as seguintes variáveis:"
            echo "   MINIO_ENDPOINT=https://seu-dominio.com"
            echo "   MINIO_ROOT_USER=admin"
            echo "   MINIO_ROOT_PASSWORD=sua_senha_segura"
            echo ""
            echo "Após configurar, execute novamente este script."
            exit 1
        else
            echo "❌ Template .env.example não encontrado!"
            exit 1
        fi
    fi
    
    # Carregar .env
    source .env
    
    # Verificar variáveis obrigatórias
    if [[ -z "$MINIO_ENDPOINT" || -z "$MINIO_ROOT_USER" || -z "$MINIO_ROOT_PASSWORD" ]]; then
        echo "❌ Configuração incompleta no .env!"
        echo "📋 Certifique-se de definir:"
        echo "   MINIO_ENDPOINT=https://seu-dominio.com"
        echo "   MINIO_ROOT_USER=admin"
        echo "   MINIO_ROOT_PASSWORD=sua_senha_segura"
        exit 1
    fi
    
    echo "✅ Configuração carregada:"
    echo "   Endpoint: $MINIO_ENDPOINT"
    echo "   Usuário: $MINIO_ROOT_USER"
    echo "   Senha: ${MINIO_ROOT_PASSWORD:0:3}***"
}

# Função para mostrar menu principal
show_main_menu() {
    echo ""
    echo "📋 ESCOLHA UMA FERRAMENTA:"
    echo "========================="
    echo ""
    echo "1. 🔧 Gerenciador de Buckets e Usuários"
    echo "2. 🧹 Limpeza e Configuração de Buckets"
    echo "3. ⚙️  Configurações do Sistema"
    echo "4. 📊 Status do MinIO"
    echo "5. ❌ Sair"
    echo ""
    echo -n "Escolha uma opção: "
}

# Função para mostrar status do MinIO
show_status() {
    echo ""
    echo "📊 STATUS DO MINIO"
    echo "=================="
    
    source .env
    ALIAS="${MINIO_ALIAS:-status}"
    
    echo "🔐 Testando conexão..."
    if mc alias set $ALIAS $MINIO_ENDPOINT $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD &>/dev/null; then
        echo "✅ Conexão estabelecida com sucesso!"
        
        echo ""
        echo "📁 Buckets existentes:"
        mc ls $ALIAS/ 2>/dev/null || echo "❌ Erro ao listar buckets"
        
        echo ""
        echo "👥 Usuários cadastrados:"
        mc admin user list $ALIAS 2>/dev/null || echo "❌ Erro ao listar usuários"
        
        echo ""
        echo "ℹ️  Informações do servidor:"
        mc admin info $ALIAS 2>/dev/null || echo "❌ Erro ao obter informações do servidor"
        
    else
        echo "❌ Falha na conexão!"
        echo "🔧 Verifique as configurações no arquivo .env"
    fi
}

# Função para gerenciar configurações
manage_config() {
    echo ""
    echo "⚙️  CONFIGURAÇÕES DO SISTEMA"
    echo "============================"
    echo ""
    echo "1. 📝 Editar configurações (.env)"
    echo "2. 🔍 Visualizar configurações atuais"
    echo "3. 🔄 Recriar arquivo .env"
    echo "4. ↩️  Voltar ao menu principal"
    echo ""
    echo -n "Escolha uma opção: "
    
    read config_choice
    
    case $config_choice in
        1)
            echo "📝 Abrindo editor..."
            ${EDITOR:-nano} .env
            ;;
        2)
            echo ""
            echo "📋 Configurações atuais:"
            echo "======================"
            if [[ -f ".env" ]]; then
                source .env
                echo "MINIO_ENDPOINT=$MINIO_ENDPOINT"
                echo "MINIO_ROOT_USER=$MINIO_ROOT_USER"
                echo "MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD:0:3}***"
                echo "MINIO_ALIAS=${MINIO_ALIAS:-s3admin}"
                echo "MINIO_REGION=${MINIO_REGION:-us-east-1}"
            else
                echo "❌ Arquivo .env não encontrado!"
            fi
            ;;
        3)
            echo "🔄 Recriando arquivo .env..."
            if [[ -f ".env" ]]; then
                cp .env .env.backup
                echo "💾 Backup salvo como .env.backup"
            fi
            cp .env.example .env
            echo "✅ Arquivo .env recriado!"
            echo "📝 Edite agora com suas configurações:"
            ${EDITOR:-nano} .env
            ;;
        4)
            return
            ;;
        *)
            echo "❌ Opção inválida!"
            ;;
    esac
}

# Script principal
main() {
    show_banner
    check_dependencies
    check_config
    
    while true; do
        show_main_menu
        read choice
        
        case $choice in
            1)
                echo "🔧 Iniciando Gerenciador de Buckets e Usuários..."
                cd scripts && ./manage-buckets.sh && cd ..
                ;;
            2)
                echo "🧹 Iniciando Limpeza de Buckets..."
                cd scripts && ./cleanup-buckets.sh && cd ..
                ;;
            3)
                manage_config
                ;;
            4)
                show_status
                ;;
            5)
                echo "👋 Saindo..."
                exit 0
                ;;
            *)
                echo "❌ Opção inválida!"
                ;;
        esac
        
        echo ""
        echo -n "Pressione Enter para continuar..."
        read
    done
}

# Executar script principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
