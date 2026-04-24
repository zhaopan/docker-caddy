# 权限问题

```bash
# 目录权限
mkdir -p data/n8n/userfiles
chmod 775 -R data/n8n/userfiles
chown -R 1000:1000 data/n8n/userfiles
```

## ollama 模型

```bash
# ollama 模型
docker exec -it ollama ollama pull llama3.2:1b
docker exec -it ollama ollama pull qwen3-embedding:0.6b
docker exec -it ollama ollama pull qwen2.5:7b
docker exec -it ollama ollama pull gemma4:e2b

docker exec -it ollama ollama list
docker exec -it ollama ollama pull
docker exec -it ollama ollama stop gemma4:e2b
docker exec -it ollama ollama ps
docker exec -it ollama ollama show
docker exec -it ollama ollama cp
docker exec -it ollama ollama rm gemma4:e2b

docker restart ollama
```

## n8n 迁移

- 重复导入的时候,只要ID一直,以前的就会被覆盖
- projectid 和 data_table.id 会发上变化
- n8n-api-key 要优先处理

```bash
# 进入容器
docker exec -it n8n sh

## 密钥
# 导出(解密后)
n8n export:credentials --all --decrypted --output=/home/node/.n8n/userfiles/backup/all_decrypted.json
# 导入(解密后)
n8n import:credentials --input=/home/node/.n8n/userfiles/backup/all_decrypted.json --decrypted

## 工作流
# 导出
n8n export:workflow --all --output=/home/node/.n8n/userfiles/backup/all_workflow.json
# 导入
n8n import:workflow --input=/home/node/.n8n/userfiles/backup/all_workflow.json

# 同步文件
scp /d/github/docker-caddy/data/n8n/userfiles/backup/all_workflow.json root@hahaha:/mnt/docker-caddy/data/n8n/userfiles/backup/all_workflow.json
scp /d/github/docker-caddy/data/n8n/userfiles/backup/all_decrypted.json root@hahaha:/mnt/docker-caddy/data/n8n/userfiles/backup/all_decrypted.json

```
