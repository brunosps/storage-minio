<div align="center">

# 🗄️ MinIO S3 Storage Manager

<img src="https://img.shields.io/badge/MinIO-C72E29?style=for-the-badge&logo=minio&logoColor=white" alt="MinIO">
<img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
<img src="https://img.shields.io/badge/Shell_Script-121011?style=for-the-badge&logo=gnu-bash&logoColor=white" alt="Shell Script">

**Sistema completo e automatizado para gerenciar buckets, usuários e permissões no MinIO S3**

[🚀 Início Rápido](#-início-rápido) • [📋 Funcionalidades](#-funcionalidades) • [🔧 Configuração](#-configuração-do-env) • [🛠️ Scripts](#️-scripts-disponíveis) • [📚 Documentação](#-troubleshooting)

</div>

---

## 🌟 Principais Características

<table>
<tr>
<td width="50%">

### ⚡ **Automatização Completa**
- 🤖 Scripts automatizados para todas as operações
- 📁 Criação de estrutura de pastas automática
- 🔄 Tiering hot/cold configurado
- 🎯 Menu interativo unificado

</td>
<td width="50%">

### 🔐 **Segurança Avançada**
- 🛡️ Credenciais em variáveis de ambiente
- 👤 Gerenciamento granular de usuários
- 🔒 Permissões específicas por bucket
- 🚫 Proteção contra acesso não autorizado

</td>
</tr>
</table>

---

## 🚀 Início Rápido

### ⚙️ **Configuração em 2 passos**

```bash
# 1️⃣ Configure suas credenciais
cp .env.example .env && nano .env

# 2️⃣ Execute o gerenciador principal
./minio-manager.sh
```

### 📁 **Estrutura do Projeto**

```
📦 storage-minio
├── 🎯 minio-manager.sh          # Script principal com menu
├── 🔒 .env                      # Configurações seguras
├── 📄 .env.example             # Template de configurações
├── 📂 scripts/
│   ├── 🛠️ manage-buckets.sh    # Gerenciador de buckets/usuários
│   ├── 🧹 cleanup-buckets.sh   # Limpeza e configuração
│   └── ⚡ tiering-minio.sh     # Script de tiering
├── 🐳 minio/
│   ├── 📄 Dockerfile           # Container customizado
│   └── ⚡ tiering-minio.sh     # Script interno
└── 🐙 docker-compose.yml       # Orquestração dos serviços
```

---

## 🔧 Configuração do .env

<div align="center">

### 📝 **Template de Configuração**

</div>

```bash
# 🌐 Configurações de Conexão (OBRIGATÓRIAS)
MINIO_ENDPOINT=https://s3.techdb.app
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=sua_senha_super_segura_aqui

# ⚙️ Configurações Opcionais
MINIO_ALIAS=s3admin           # Alias para MinIO Client
MINIO_REGION=us-east-1        # Região padrão
```

> ⚠️ **Importante:** Mantenha o arquivo `.env` sempre atualizado e **nunca** o commite no git!

---

## 📋 Funcionalidades

<div align="center">

### 🎯 **Funcionalidades Principais**

</div>

<table>
<tr>
<td width="33%">

#### �️ **Gerenciamento de Buckets**
- ✅ Criação automatizada
- ✅ Estrutura de pastas padrão
- ✅ Configuração de políticas
- ✅ Backup e restauração

</td>
<td width="33%">

#### 👥 **Gerenciamento de Usuários**
- ✅ Criação com permissões específicas
- ✅ Vinculação a buckets
- ✅ Tipos de acesso (full/readonly)
- ✅ Testes de conectividade

</td>
<td width="34%">

#### 🔐 **Segurança e Acesso**
- ✅ Políticas granulares
- ✅ URLs públicas controladas
- ✅ Autenticação robusta
- ✅ Logs de auditoria

</td>
</tr>
</table>

### 🏗️ **Estrutura Automática de Buckets**

Cada bucket criado segue esta organização padrão:

```
📦 bucket-nome/
├── 🖼️ images/      # Imagens, fotos, logos
├── 🌐 public/      # Arquivos de acesso público
└── 📁 uploads/     # Documentos e arquivos privados
```

### � **URLs Públicas Automáticas**

```
🔗 Acesso direto: https://s3.techdb.app/bucket-nome/public/arquivo.jpg
🔗 Via API:       https://s3.techdb.app/minio/bucket-nome/public/arquivo.jpg
```

---

## 🎯 Uso em Aplicações

<div align="center">

### 💻 **Integração com Código**

</div>

#### 🟢 **Node.js / JavaScript**

```javascript
// 📦 Configuração S3 Client
const s3Config = {
  endpoint: process.env.MINIO_ENDPOINT,
  accessKeyId: 'usuario-app',          // ← Usuário criado pelos scripts
  secretAccessKey: 'senha-do-usuario', // ← Senha gerada automaticamente
  bucket: 'meu-projeto',
  region: 'us-east-1',
  forcePathStyle: true                 // ← Importante para MinIO
}

// 📤 Upload com organização automática
const uploadPaths = {
  profile: 'meu-projeto/images/usuarios/avatar-123.jpg',
  banner:  'meu-projeto/public/banners/promo-2025.png',
  doc:     'meu-projeto/uploads/contratos/contrato-456.pdf'
}
```

#### 🐍 **Python**

```python
import boto3

# 📦 Configuração boto3
s3_client = boto3.client(
    's3',
    endpoint_url=os.getenv('MINIO_ENDPOINT'),
    aws_access_key_id='usuario-app',
    aws_secret_access_key='senha-do-usuario',
    region_name='us-east-1'
)

# 📤 Upload organizado
s3_client.upload_file(
    'local-file.jpg',
    'meu-projeto',
    'images/produtos/produto-789.jpg'
)
```

---

## 🛠️ Scripts Disponíveis

<div align="center">

### 🎮 **Interface Unificada**

</div>

<table>
<tr>
<td width="50%">

#### 🎯 **Script Principal**
```bash
./minio-manager.sh
```

**Menu Interativo:**
- 🗄️ Gerenciar Buckets
- 👥 Gerenciar Usuários  
- 🧹 Limpeza do Sistema
- 📊 Status e Informações
- ⚙️ Configurações

</td>
<td width="50%">

#### ⚡ **Scripts Individuais**
```bash
# 🛠️ Gerenciamento avançado
./scripts/manage-buckets.sh

# 🧹 Limpeza e manutenção
./scripts/cleanup-buckets.sh

# 📊 Status do tiering
docker logs minio-tiering
```

</td>
</tr>
</table>

---

## 🔐 Recursos de Segurança

<div align="center">

### 🛡️ **Camadas de Proteção**

</div>

| 🔒 **Aspecto** | ✅ **Implementado** | 📝 **Descrição** |
|---|---|---|
| **Credenciais** | Variáveis de ambiente | Senhas nunca no código |
| **Usuários** | Permissões específicas | Acesso limitado por função |
| **Buckets** | Privados por padrão | Acesso público controlado |
| **Políticas** | Granulares | Controle fino de permissões |
| **Logs** | Auditoria completa | Rastreamento de ações |
| **SSL/TLS** | Sempre ativo | Comunicação criptografada |

---

## 📊 Comandos Úteis

<div align="center">

### 🔍 **Monitoramento e Diagnóstico**

</div>

<table>
<tr>
<td width="50%">

#### 📈 **Verificar Status**
```bash
# 🎯 Via menu principal
./minio-manager.sh

# 🔍 Status direto do MinIO
mc admin info s3admin

# 📊 Uso de espaço
mc du s3admin/bucket-nome
```

</td>
<td width="50%">

#### 💾 **Backup e Restauração**
```bash
# 💾 Backup das configurações
cp .env .env.backup.$(date +%Y%m%d)

# 🔄 Restaurar backup
cp .env.backup.20250707 .env

# 📦 Backup de bucket
mc mirror s3admin/bucket-nome ./backup/
```

</td>
</tr>
</table>

---

## 🚨 Troubleshooting

<div align="center">

### 🛠️ **Resolução de Problemas Comuns**

</div>

<details>
<summary>🔌 <strong>Erro de Conexão</strong></summary>

**Sintomas:** `Connection refused` ou `Unable to connect`

**Soluções:**
1. ✅ Verifique as credenciais no `.env`
2. 🌐 Teste conectividade: `curl -k https://s3.techdb.app`
3. 🐳 Verifique se o MinIO está rodando: `docker ps`
4. 🔍 Verifique logs: `docker logs minio-server`

</details>

<details>
<summary>🚫 <strong>Permissões Negadas</strong></summary>

**Sintomas:** `Access Denied` ou `Forbidden`

**Soluções:**
1. 👤 Verifique se o usuário foi vinculado ao bucket
2. 🔒 Confirme o tipo de acesso (full/readonly)
3. 🧪 Teste com usuário admin primeiro
4. 📋 Verifique políticas: `mc admin policy list s3admin`

</details>

<details>
<summary>📦 <strong>Bucket Não Encontrado</strong></summary>

**Sintomas:** `Bucket does not exist` ou `NoSuchBucket`

**Soluções:**
1. 📂 Liste buckets: `mc ls s3admin/`
2. ✏️ Verifique nome exato do bucket
3. ✅ Confirme se bucket foi criado: `./scripts/manage-buckets.sh`
4. 🔄 Recrie se necessário

</details>

---

## 📝 Changelog

<div align="center">

### 🎯 **Histórico de Versões**

</div>

<table>
<tr>
<td width="50%">

#### 🚀 **v2.0.0 - Atual**
- ✅ Reorganização completa em pastas
- ✅ Remoção de credenciais hardcoded
- ✅ Script principal unificado
- ✅ Estrutura de pastas internas
- ✅ Documentação visual melhorada
- ✅ Sistema de troubleshooting

</td>
<td width="50%">

#### 🎯 **v1.0.0 - Base**
- ✅ Scripts básicos de gerenciamento
- ✅ Funcionalidade de tiering hot/cold
- ✅ Deploy via Docker/Dokku
- ✅ Configuração inicial

</td>
</tr>
</table>

---

<div align="center">

## 🎉 **Projeto Pronto para Produção!**

### 🚀 [Começar Agora](#-início-rápido) • 📚 [Ver Scripts](#️-scripts-disponíveis) • 🔧 [Configurar](#-configuração-do-env)

---

**Desenvolvido com ❤️ para automação MinIO S3**

<img src="https://img.shields.io/badge/Status-Pronto-brightgreen?style=for-the-badge" alt="Status">
<img src="https://img.shields.io/badge/Versão-2.0.0-blue?style=for-the-badge" alt="Versão">
<img src="https://img.shields.io/badge/Scripts-3_Ativos-orange?style=for-the-badge" alt="Scripts">

</div>
