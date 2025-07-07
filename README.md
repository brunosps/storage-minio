# MinIO Hot/Cold Tiering Project

Estrutura mínima para rodar **MinIO** (compatível S3) em modo standalone com dois
pontos de montagem simulando:

* **🔥 /data-hot** → SSD (arquivos recentes/frequentes)
* **❄️ /data-cold** → HDD (arquivos menos acessados)

Inclui **script de movimentação** via `mc` (`scripts/tiering-minio.sh`) que implementa:

| Regra | Ação |
|-------|------|
| `hot/` permanece 60 dias | move para `cold/` |
| Arquivos > 10 MB & +3 dias | move para `cold/` |
| `temp/` | delete após 7 dias |

## Uso local

```bash
cp .env.example .env          # ajuste usuário/senha se quiser
docker compose up -d
```

O tiering será executado **automaticamente a cada 3 horas** via container `minio-tiering`.

**⏰ Execução inicial**: O script roda pela primeira vez após 60 segundos do startup.

Para verificar os logs do tiering:
```bash
docker logs minio-tiering
```

Para executar tiering manualmente:
```bash
docker exec minio-tiering /usr/local/bin/tiering-minio.sh
```

Acesse:
* UI: <http://localhost:9001>
* S3: <http://localhost:9000>

## Deploy no Dokku (máquina rápida)

1. Crie app:
```bash
dokku apps:create minio
```
2. Monte volumes:
```bash
dokku storage:mount minio /mnt/ssd:/data-hot
dokku storage:mount minio /mnt/nfs-hdd:/data-cold
```
3. Defina variáveis:
```bash
dokku config:set minio MINIO_ROOT_USER=admin MINIO_ROOT_PASSWORD=senhaSegura
```
4. Configure o remote e faça deploy:
```bash
git remote add dokku dokku@s3.techdp.app:minio
git push dokku main
# OU apenas a pasta minio: git subtree push --prefix=minio dokku main
```

5. **⚠️ IMPORTANTE**: Configure as variáveis de ambiente no servidor:
```bash
# No servidor Dokku (s3.techdp.app)
dokku config:set minio MINIO_ROOT_USER=admin MINIO_ROOT_PASSWORD=senhaSegura123
```

6. **🔗 Acesso ao MinIO no Dokku**:
   - **S3 API**: `http://minio.us:9000` 
   - **Console Web**: `http://minio.us:9001`

## Agendar Tiering

### Local (Docker Compose)
O tiering já executa automaticamente a cada 3 horas via container `minio-tiering`.

### Deploy Dokku (máquina rápida)
```bash
# máquina rápida (onde roda o MinIO)
(crontab -l ; echo "0 */3 * * * /home/dokku/scripts/tiering-minio.sh >> /var/log/minio-tier.log 2>&1") | crontab -
```

## Mapeamento de Pastas

### Local (desenvolvimento)
```yaml
volumes:
  - ./data/hot:/data-hot     # pasta local
  - ./data/cold:/data-cold   # pasta local
```

### Produção (discos reais)
```yaml
volumes:
  - /mnt/ssd:/data-hot       # 🔥 SSD rápido
  - /mnt/hdd:/data-cold      # ❄️ HDD mais lento
```
