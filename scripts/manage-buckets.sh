#!/bin/bash
# Script para gerenciar usuários e buckets no MinIO
# Cada bucket principal terá 3 pastas internas: images, public, uploads

set -e

# Carregar variáveis de ambiente
if [[ -f "../.env" ]]; then
    source "../.env"
elif [[ -f ".env" ]]; then
    source ".env"
else
    echo "❌ Arquivo .env não encontrado!"
    echo "📋 Crie um arquivo .env baseado no .env.example"
    echo "   cp .env.example .env"
    echo "   # Edite o .env com suas credenciais"
    exit 1
fi

# Verificar se as variáveis necessárias estão definidas
if [[ -z "$MINIO_ENDPOINT" || -z "$MINIO_ROOT_USER" || -z "$MINIO_ROOT_PASSWORD" ]]; then
    echo "❌ Variáveis de ambiente obrigatórias não definidas!"
    echo "📋 Certifique-se de definir no .env:"
    echo "   MINIO_ENDPOINT=https://s3.techdb.app"
    echo "   MINIO_ROOT_USER=admin"
    echo "   MINIO_ROOT_PASSWORD=sua_senha"
    exit 1
fi

# Configurações
MINIO_ENDPOINT="${MINIO_ENDPOINT}"
MINIO_USER="${MINIO_ROOT_USER}"
MINIO_PASS="${MINIO_ROOT_PASSWORD}"
ALIAS="${MINIO_ALIAS:-s3admin}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para mostrar menu
show_menu() {
    echo ""
    echo "🔧 GERENCIADOR DE USUÁRIOS E BUCKETS MinIO"
    echo "=========================================="
    echo ""
    echo "1. 👤 Criar novo usuário"
    echo "2. 📁 Criar novo bucket (com sub-buckets)"
    echo "3. 🔗 Vincular usuário a bucket"
    echo "4. 📋 Listar usuários"
    echo "5. 📋 Listar buckets"
    echo "6. 🗑️ Remover usuário"
    echo "7. 🗑️ Remover bucket"
    echo "8. 🧪 Testar acesso de usuário"
    echo "9. ❌ Sair"
    echo ""
    echo -n "Escolha uma opção: "
}

# Função para conectar ao MinIO
connect_minio() {
    echo "🔐 Conectando ao MinIO..."
    mc alias set $ALIAS $MINIO_ENDPOINT $MINIO_USER $MINIO_PASS > /dev/null
    echo "✅ Conectado com sucesso!"
}

# Função para criar usuário
create_user() {
    echo ""
    echo "👤 CRIAR NOVO USUÁRIO"
    echo "===================="
    
    echo -n "Nome do usuário: "
    read username
    
    if [[ -z "$username" ]]; then
        echo "❌ Nome do usuário não pode estar vazio!"
        return 1
    fi
    
    echo -n "Senha do usuário (deixe vazio para gerar automaticamente): "
    read -s password
    echo ""
    
    if [[ -z "$password" ]]; then
        password="${username}-$(date +%s)-pass"
        echo "🔑 Senha gerada automaticamente: $password"
    fi
    
    echo -n "Tipo de acesso (full/readonly) [full]: "
    read access_type
    access_type=${access_type:-full}
    
    # Criar usuário
    echo "📝 Criando usuário $username..."
    mc admin user add $ALIAS $username $password
    
    echo "✅ Usuário $username criado com sucesso!"
    echo "🔐 Credenciais:"
    echo "   Username: $username"
    echo "   Password: $password"
    echo "   Access Type: $access_type"
    
    # Salvar credenciais em arquivo
    echo "$username:$password:$access_type:$(date)" >> users.txt
    echo "💾 Credenciais salvas em users.txt"
}

# Função para criar bucket com sub-buckets
create_bucket() {
    echo ""
    echo "📁 CRIAR NOVO BUCKET"
    echo "==================="
    
    echo -n "Nome do bucket principal: "
    read bucket_name
    
    if [[ -z "$bucket_name" ]]; then
        echo "❌ Nome do bucket não pode estar vazio!"
        return 1
    fi
    
    echo "📦 Criando estrutura de pastas para: $bucket_name"
    echo ""
    
    # Pastas que serão criadas dentro do bucket
    folders=("images" "public" "uploads")
    
    # Criar bucket principal
    echo "📁 Criando bucket principal: $bucket_name"
    mc mb $ALIAS/$bucket_name 2>/dev/null || echo "⚠️ Bucket $bucket_name já existe"
    
    # Criar pastas dentro do bucket (usando arquivos .keep para criar as pastas)
    for folder in "${folders[@]}"; do
        echo "📂 Criando pasta: $bucket_name/$folder/"
        echo "# Pasta criada automaticamente em $(date)" | mc pipe $ALIAS/$bucket_name/$folder/.keep
    done
    
    echo ""
    echo "✅ Estrutura de pastas criada:"
    echo "   📁 $bucket_name/"
    echo "   📂   ├── images/"
    echo "   📂   ├── public/"
    echo "   📂   └── uploads/"
    
    # Configurar política pública para toda a pasta public dentro do bucket
    echo ""
    echo "🌐 Configurando acesso público para $bucket_name/public/..."
    mc anonymous set public $ALIAS/$bucket_name
    echo "✅ Bucket $bucket_name configurado como público (pasta public/ acessível)"
    
    # Criar política específica para este conjunto de buckets
    create_bucket_policy $bucket_name
}

# Função para criar política específica do bucket
create_bucket_policy() {
    local bucket_name=$1
    
    echo "📜 Criando política para bucket $bucket_name..."
    
    # Política de acesso total ao bucket (todas as pastas)
    cat > /tmp/${bucket_name}-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${bucket_name}",
        "arn:aws:s3:::${bucket_name}/*"
      ]
    }
  ]
}
EOF
    
    # Política somente leitura
    cat > /tmp/${bucket_name}-readonly-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${bucket_name}",
        "arn:aws:s3:::${bucket_name}/*"
      ]
    }
  ]
}
EOF
    
    # Criar políticas no MinIO
    mc admin policy create $ALIAS ${bucket_name}-access /tmp/${bucket_name}-policy.json
    mc admin policy create $ALIAS ${bucket_name}-readonly /tmp/${bucket_name}-readonly-policy.json
    
    # Limpar arquivos temporários
    rm -f /tmp/${bucket_name}-policy.json /tmp/${bucket_name}-readonly-policy.json
    
    echo "✅ Políticas criadas: ${bucket_name}-access e ${bucket_name}-readonly"
}

# Função para vincular usuário a bucket
link_user_bucket() {
    echo ""
    echo "🔗 VINCULAR USUÁRIO A BUCKET"
    echo "============================"
    
    echo "👥 Usuários disponíveis:"
    mc admin user list $ALIAS 2>/dev/null | grep -v "^Access" | head -10
    echo ""
    echo -n "Nome do usuário: "
    read username
    
    echo ""
    echo "📁 Buckets disponíveis:"
    mc ls $ALIAS/ | grep -E "/$" | sed 's/.*\s//' | sed 's/\///' | head -20
    echo ""
    echo -n "Nome do bucket (sem sub-buckets): "
    read bucket_name
    
    echo -n "Tipo de acesso (full/readonly) [full]: "
    read access_type
    access_type=${access_type:-full}
    
    # Definir política baseada no tipo de acesso
    if [[ "$access_type" == "readonly" ]]; then
        policy_name="${bucket_name}-readonly"
    else
        policy_name="${bucket_name}-access"
    fi
    
    echo "🔗 Vinculando usuário $username ao bucket $bucket_name com acesso $access_type..."
    
    # Verificar se política existe
    if mc admin policy info $ALIAS $policy_name >/dev/null 2>&1; then
        mc admin policy attach $ALIAS $policy_name --user $username
        echo "✅ Usuário $username vinculado com sucesso!"
        echo "📋 Acesso concedido ao bucket:"
        echo "   📁 $bucket_name/"
        echo "   📂   ├── images/"
        echo "   📂   ├── public/"
        echo "   📂   └── uploads/"
    else
        echo "❌ Política $policy_name não encontrada. Crie o bucket primeiro."
    fi
}

# Função para listar usuários
list_users() {
    echo ""
    echo "👥 USUÁRIOS CADASTRADOS"
    echo "======================"
    
    echo "🔐 Usuários no MinIO:"
    mc admin user list $ALIAS 2>/dev/null || echo "❌ Erro ao listar usuários"
    
    echo ""
    if [[ -f "users.txt" ]]; then
        echo "📋 Histórico de usuários criados:"
        echo "Username:Password:AccessType:Created"
        echo "--------------------------------"
        cat users.txt
    else
        echo "📋 Nenhum histórico de usuários encontrado"
    fi
}

# Função para listar buckets
list_buckets() {
    echo ""
    echo "📁 BUCKETS CADASTRADOS"
    echo "======================"
    
    echo "📋 Todos os buckets:"
    mc ls $ALIAS/ 2>/dev/null || echo "❌ Erro ao listar buckets"
    
    echo ""
    echo "🏗️ Estruturas de buckets detectadas:"
    mc ls $ALIAS/ 2>/dev/null | grep -E "/$" | sed 's/.*\s//' | sed 's/\///' | \
    while read bucket; do
        # Verificar se tem as pastas padrão dentro do bucket
        if mc ls $ALIAS/$bucket/images/ >/dev/null 2>&1 && \
           mc ls $ALIAS/$bucket/public/ >/dev/null 2>&1 && \
           mc ls $ALIAS/$bucket/uploads/ >/dev/null 2>&1; then
            echo "📦 $bucket/ (com pastas completas: images/, public/, uploads/)"
        else
            echo "📁 $bucket/ (bucket simples)"
        fi
    done
}

# Função para remover usuário
remove_user() {
    echo ""
    echo "🗑️ REMOVER USUÁRIO"
    echo "=================="
    
    echo "👥 Usuários disponíveis:"
    mc admin user list $ALIAS 2>/dev/null | grep -v "^Access"
    echo ""
    echo -n "Nome do usuário para remover: "
    read username
    
    if [[ -z "$username" ]]; then
        echo "❌ Nome do usuário não pode estar vazio!"
        return 1
    fi
    
    echo -n "Tem certeza que deseja remover o usuário $username? (s/N): "
    read confirm
    
    if [[ "$confirm" =~ ^[Ss]$ ]]; then
        mc admin user remove $ALIAS $username
        echo "✅ Usuário $username removido com sucesso!"
        
        # Remover do arquivo de histórico
        if [[ -f "users.txt" ]]; then
            grep -v "^$username:" users.txt > users.txt.tmp && mv users.txt.tmp users.txt
        fi
    else
        echo "❌ Operação cancelada"
    fi
}

# Função para remover bucket
remove_bucket() {
    echo ""
    echo "🗑️ REMOVER BUCKET"
    echo "================="
    
    echo "📁 Buckets disponíveis:"
    mc ls $ALIAS/ | grep -E "/$" | sed 's/.*\s//' | sed 's/\///'
    echo ""
    echo -n "Nome do bucket principal para remover (removerá todas as pastas internas): "
    read bucket_name
    
    if [[ -z "$bucket_name" ]]; then
        echo "❌ Nome do bucket não pode estar vazio!"
        return 1
    fi
    
    echo -n "Tem certeza que deseja remover $bucket_name e todas as pastas internas? (s/N): "
    read confirm
    
    if [[ "$confirm" =~ ^[Ss]$ ]]; then
        # Remover todo o conteúdo do bucket (incluindo todas as pastas)
        echo "🗑️ Removendo todo o conteúdo de $bucket_name..."
        mc rm --recursive --force $ALIAS/$bucket_name/ 2>/dev/null || true
        
        # Remover bucket principal
        echo "🗑️ Removendo bucket $bucket_name..."
        mc rb $ALIAS/$bucket_name 2>/dev/null || true
        
        # Remover políticas
        mc admin policy remove $ALIAS ${bucket_name}-access 2>/dev/null || true
        mc admin policy remove $ALIAS ${bucket_name}-readonly 2>/dev/null || true
        
        echo "✅ Bucket $bucket_name e todas as pastas removidos com sucesso!"
    else
        echo "❌ Operação cancelada"
    fi
}

# Função para testar acesso
test_user_access() {
    echo ""
    echo "🧪 TESTAR ACESSO DE USUÁRIO"
    echo "==========================="
    
    echo -n "Nome do usuário: "
    read username
    echo -n "Senha do usuário: "
    read -s password
    echo ""
    
    # Configurar alias de teste
    test_alias="test-${username}"
    mc alias set $test_alias $MINIO_ENDPOINT $username $password
    
    echo "🔍 Testando acesso para usuário $username..."
    echo ""
    
    echo "📁 Buckets visíveis:"
    mc ls $test_alias/ 2>/dev/null || echo "❌ Erro ao acessar buckets"
    
    echo ""
    echo "📤 Testando upload (arquivo de teste)..."
    echo "Teste de upload - $(date)" > /tmp/test-upload.txt
    
    # Tentar upload em buckets visíveis
    mc ls $test_alias/ 2>/dev/null | grep -E "/$" | sed 's/.*\s//' | sed 's/\///' | head -3 | \
    while read bucket; do
        echo "📂 Testando upload em $bucket..."
        mc cp /tmp/test-upload.txt $test_alias/$bucket/ 2>/dev/null && \
        echo "   ✅ Upload bem-sucedido" || \
        echo "   ❌ Upload falhou"
    done
    
    rm -f /tmp/test-upload.txt
}

# Script principal
main() {
    echo "🚀 Iniciando Gerenciador MinIO..."
    
    # Conectar ao MinIO
    connect_minio
    
    while true; do
        show_menu
        read choice
        
        case $choice in
            1) create_user ;;
            2) create_bucket ;;
            3) link_user_bucket ;;
            4) list_users ;;
            5) list_buckets ;;
            6) remove_user ;;
            7) remove_bucket ;;
            8) test_user_access ;;
            9) 
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

# Verificar se está sendo executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
