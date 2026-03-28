# 权限问题

```bash
mkdir data/n8n/backup
chmod 775 -R data/n8n/backup
chown -R 1000:1000 data/n8n/backup


# ollama 模型
docker exec -it ollama ollama pull llama3.2:latest
docker exec -it ollama ollama pull qwen3-embedding:0.6b
```
