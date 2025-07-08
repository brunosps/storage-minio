# MinIO S3 Storage Manager

Sistema completo para gerenciar buckets, usuários e permissões no MinIO S3.

## 🚀 Início Rápido

### 1. Configuração

```bash
# 1. Configure suas credenciais
cp .env.example .env
nano .env

# 2. Execute o gerenciador principal
./minio-manager.sh
```

### 2. Estrutura do Projeto

```
├── minio-manager.sh          # Script principal
├── .env                      # Configurações (não commitado)
├── .env.example             # Template de configurações
├── scripts/
│   ├── manage-buckets.sh    # Gerenciador de buckets e usuários
│   ├── cleanup-buckets.sh   # Limpeza e configuração
│   └── tiering-minio.sh     # Script de tiering (Docker)
├── minio/
│   ├── Dockerfile           # Container customizado
│   └── tiering-minio.sh     # Script interno do container
└── docker-compose.yml       # Orquestração dos serviços
```

## 🔧 Configuração do .env

```bash
# Configurações obrigatórias
MINIO_ENDPOINT=https://s3.techdb.app
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=sua_senha_segura

# Configurações opcionais
MINIO_ALIAS=s3admin
MINIO_REGION=us-east-1
```

## 📋 Funcionalidades

### 🔧 Gerenciador de Buckets e Usuários

- ✅ Criar buckets com estrutura de pastas automática
- ✅ Criar usuários com permissões específicas
- ✅ Vincular usuários a buckets
- ✅ Gerenciar permissões (full/readonly)
- ✅ Testar acessos

### 🏗️ Estrutura de Buckets

Cada bucket criado tem a seguinte estrutura:

```
bucket-nome/
├── images/     # Imagens, fotos
├── public/     # Arquivos públicos (acesso direto)
└── uploads/    # Arquivos privados
```

### 🌐 URLs Públicas

Arquivos na pasta `public/` ficam acessíveis via:
```
https://s3.techdb.app/bucket-nome/public/arquivo.jpg
```

## 🎯 Uso em Aplicações

### Configuração S3 (Node.js)

```javascript
const s3Config = {
  endpoint: process.env.MINIO_ENDPOINT,
  accessKeyId: 'usuario-criado',
  secretAccessKey: 'senha-do-usuario',
  bucket: 'nome-do-bucket',
  region: 'us-east-1'
}
```

### Upload de Arquivos

```javascript
// Upload para pasta específica
const uploadPath = {
  image: 'bucket-nome/images/produto-123.jpg',
  public: 'bucket-nome/public/banner.png',
  document: 'bucket-nome/uploads/contrato.pdf'
}
```

## 🛠️ Scripts Disponíveis

### Script Principal
```bash
./minio-manager.sh
```

### Scripts Individuais
```bash
# Gerenciar buckets e usuários
./scripts/manage-buckets.sh

# Limpeza de buckets
./scripts/cleanup-buckets.sh
```

## 🔐 Segurança

- ✅ Credenciais em variáveis de ambiente
- ✅ Permissões específicas por usuário
- ✅ Buckets privados por padrão
- ✅ Acesso público controlado (apenas pasta public/)

## 📊 Comandos Úteis

### Verificar Status
```bash
# Via script principal (opção 4)
./minio-manager.sh

# Via MinIO Client direto
mc admin info s3admin
```

### Backup de Configurações
```bash
# Fazer backup do .env
cp .env .env.backup

# Restaurar backup
cp .env.backup .env
```

## 🚨 Troubleshooting

### Erro de Conexão
1. Verifique as credenciais no `.env`
2. Teste conectividade: `curl -k https://s3.techdb.app`
3. Verifique se o MinIO está rodando

### Permissões Negadas
1. Verifique se o usuário foi vinculado ao bucket
2. Confirme o tipo de acesso (full/readonly)
3. Teste com usuário admin primeiro

### Bucket Não Encontrado
1. Liste buckets: `mc ls s3admin/`
2. Verifique nome exato do bucket
3. Confirme se bucket foi criado com sucesso

## 📝 Changelog

### v2.0.0
- ✅ Reorganização em pastas
- ✅ Remoção de credenciais hardcoded
- ✅ Script principal unificado
- ✅ Estrutura de pastas internas (não sub-buckets)
- ✅ Documentação completa

### v1.0.0
- ✅ Scripts básicos de gerenciamento
- ✅ Funcionalidade de tiering hot/cold
- ✅ Deploy via Docker/Dokku
