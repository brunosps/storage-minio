#!/bin/bash
# Script para limpar buckets desnecessários e configurar autenticação
# Mantém apenas: backups, images, temp

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

echo "🧹 Limpeza e Configuração de Buckets MinIO"
echo "==========================================="

# Configurações
MINIO_ENDPOINT="${MINIO_ENDPOINT}"
MINIO_USER="${MINIO_ROOT_USER}"
MINIO_PASS="${MINIO_ROOT_PASSWORD}"
ALIAS="${MINIO_ALIAS:-s3test}"

echo "🔐 Conectando ao MinIO..."
mc alias set $ALIAS $MINIO_ENDPOINT $MINIO_USER $MINIO_PASS

echo ""
echo "📋 Buckets atuais:"
mc ls $ALIAS/

echo ""
echo "🗑️ REMOVENDO BUCKETS DESNECESSÁRIOS..."
echo "======================================"

# Lista de buckets para remover (manter apenas: backups, images, temp)
BUCKETS_TO_REMOVE=("hot" "cold" "documents" "trip-hosts")

for bucket in "${BUCKETS_TO_REMOVE[@]}"; do
    echo "🗑️ Removendo bucket: $bucket"
    
    # Verificar se bucket existe
    if mc ls $ALIAS/$bucket >/dev/null 2>&1; then
        # Remover todos os objetos primeiro
        echo "   📄 Removendo objetos..."
        mc rm --recursive --force $ALIAS/$bucket/ 2>/dev/null || echo "   ⚠️ Bucket já estava vazio"
        
        # Remover o bucket
        echo "   🗂️ Removendo bucket..."
        mc rb $ALIAS/$bucket 2>/dev/null || echo "   ⚠️ Erro ao remover bucket $bucket"
        
        echo "   ✅ Bucket $bucket removido"
    else
        echo "   ⚠️ Bucket $bucket não existe"
    fi
    echo ""
done

echo "📋 Buckets após limpeza:"
mc ls $ALIAS/

echo ""
echo "🔒 CONFIGURANDO AUTENTICAÇÃO OBRIGATÓRIA"
echo "========================================"

echo "🚫 Removendo qualquer acesso público/anônimo..."

# Verificar e remover políticas públicas dos buckets mantidos
REMAINING_BUCKETS=("backups" "images" "temp")

for bucket in "${REMAINING_BUCKETS[@]}"; do
    echo "🔐 Configurando bucket: $bucket"
    
    # Verificar se bucket existe
    if mc ls $ALIAS/$bucket >/dev/null 2>&1; then
        # Remover acesso anônimo
        echo "   🚫 Removendo acesso anônimo..."
        mc anonymous set none $ALIAS/$bucket 2>/dev/null || echo "   ℹ️ Já estava sem acesso anônimo"
        
        # Verificar política atual
        echo "   📋 Política atual:"
        mc anonymous get $ALIAS/$bucket 2>/dev/null || echo "   ✅ Sem acesso público"
        
    else
        echo "   📁 Criando bucket $bucket..."
        mc mb $ALIAS/$bucket
        echo "   ✅ Bucket $bucket criado (sem acesso público)"
    fi
    echo ""
done

echo "👥 CONFIGURANDO USUÁRIOS E POLÍTICAS"
echo "===================================="

# Remover usuários de teste antigos
echo "🗑️ Removendo usuários de teste antigos..."
mc admin user remove $ALIAS readwrite 2>/dev/null || echo "ℹ️ Usuário readwrite não existia"
mc admin user remove $ALIAS readonly 2>/dev/null || echo "ℹ️ Usuário readonly não existia"

# Criar políticas específicas para cada bucket
echo ""
echo "📜 Criando políticas específicas..."

# Política para backups (acesso total)
cat > /tmp/backups-policy.json << 'EOF'
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
        "arn:aws:s3:::backups",
        "arn:aws:s3:::backups/*"
      ]
    }
  ]
}
EOF

# Política para images (acesso total)
cat > /tmp/images-policy.json << 'EOF'
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
        "arn:aws:s3:::images",
        "arn:aws:s3:::images/*"
      ]
    }
  ]
}
EOF

# Política para temp (acesso total)
cat > /tmp/temp-policy.json << 'EOF'
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
        "arn:aws:s3:::temp",
        "arn:aws:s3:::temp/*"
      ]
    }
  ]
}
EOF

# Política somente leitura
cat > /tmp/readonly-policy.json << 'EOF'
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
        "arn:aws:s3:::backups",
        "arn:aws:s3:::backups/*",
        "arn:aws:s3:::images",
        "arn:aws:s3:::images/*",
        "arn:aws:s3:::temp",
        "arn:aws:s3:::temp/*"
      ]
    }
  ]
}
EOF

echo "📝 Criando políticas no MinIO..."
mc admin policy create $ALIAS backups-access /tmp/backups-policy.json
mc admin policy create $ALIAS images-access /tmp/images-policy.json  
mc admin policy create $ALIAS temp-access /tmp/temp-policy.json
mc admin policy create $ALIAS readonly-access /tmp/readonly-policy.json

echo ""
echo "👤 Criando usuários específicos..."

# Usuário para backups
echo "🔐 Criando usuário para backups..."
mc admin user add $ALIAS backup-user backup-secure-pass123
mc admin policy attach $ALIAS backups-access --user backup-user
echo "✅ Usuário backup-user criado (acesso apenas a bucket backups)"

# Usuário para images
echo "🔐 Criando usuário para images..."
mc admin user add $ALIAS images-user images-secure-pass123
mc admin policy attach $ALIAS images-access --user images-user
echo "✅ Usuário images-user criado (acesso apenas a bucket images)"

# Usuário para temp
echo "🔐 Criando usuário para temp..."
mc admin user add $ALIAS temp-user temp-secure-pass123
mc admin policy attach $ALIAS temp-access --user temp-user
echo "✅ Usuário temp-user criado (acesso apenas a bucket temp)"

# Usuário somente leitura (todos os buckets)
echo "🔐 Criando usuário somente leitura..."
mc admin user add $ALIAS readonly-user readonly-secure-pass123
mc admin policy attach $ALIAS readonly-access --user readonly-user
echo "✅ Usuário readonly-user criado (leitura em todos os buckets)"

echo ""
echo "🧹 Limpando arquivos temporários..."
rm -f /tmp/*-policy.json

echo ""
echo "✅ CONFIGURAÇÃO CONCLUÍDA!"
echo "========================="
echo ""
echo "📁 BUCKETS MANTIDOS:"
mc ls $ALIAS/

echo ""
echo "👥 USUÁRIOS CRIADOS:"
echo "🔐 backup-user / backup-secure-pass123 (acesso: backups)"
echo "🔐 images-user / images-secure-pass123 (acesso: images)"
echo "🔐 temp-user / temp-secure-pass123 (acesso: temp)"
echo "🔐 readonly-user / readonly-secure-pass123 (leitura: todos)"
echo "🔐 admin / 73743368 (administrador: todos)"

echo ""
echo "🎯 CONFIGURAÇÃO DE APLICAÇÕES:"
echo "=============================="
echo ""
echo "Para BACKUPS:"
echo "  Endpoint: https://s3.techdb.app"
echo "  Access Key: backup-user"
echo "  Secret Key: backup-secure-pass123"
echo "  Bucket: backups"
echo ""
echo "Para IMAGES:"
echo "  Endpoint: https://s3.techdb.app"
echo "  Access Key: images-user"
echo "  Secret Key: images-secure-pass123"
echo "  Bucket: images"
echo ""
echo "Para TEMP:"
echo "  Endpoint: https://s3.techdb.app"
echo "  Access Key: temp-user"
echo "  Secret Key: temp-secure-pass123"
echo "  Bucket: temp"
echo ""
echo "Para LEITURA (qualquer bucket):"
echo "  Endpoint: https://s3.techdb.app"
echo "  Access Key: readonly-user"
echo "  Secret Key: readonly-secure-pass123"
echo ""
echo "🚫 ACESSO PÚBLICO: Totalmente removido"
echo "🔐 AUTENTICAÇÃO: Obrigatória para todos os buckets"

echo ""
echo "🧪 TESTE RÁPIDO:"
echo "==============="
echo "# Testar acesso com usuário específico:"
echo "mc alias set test-backup https://s3.techdb.app backup-user backup-secure-pass123"
echo "mc ls test-backup/  # Deve mostrar apenas bucket 'backups'"
