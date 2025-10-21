# Redis 哨兵模式 Python 测试 Makefile

# 变量定义
PYTHON = python3
PIP = pip3
VENV_DIR = venv
VENV_PYTHON = $(VENV_DIR)/bin/python
VENV_PIP = $(VENV_DIR)/bin/pip

# 默认目标
.PHONY: all
all: install

# 创建虚拟环境
.PHONY: venv
venv:
	@echo "创建 Python 虚拟环境..."
	$(PYTHON) -m venv $(VENV_DIR)

# 安装依赖
.PHONY: install
install: venv
	@echo "安装 Python 依赖..."
	$(VENV_PIP) install -r requirements.txt

# 激活虚拟环境并运行测试
.PHONY: test
test: install
	@echo "运行 Redis 配置测试..."
	$(VENV_PYTHON) test_redis.py

# 启动 Web 应用
.PHONY: web
web: install
	@echo "启动 Web 应用..."
	$(VENV_PYTHON) web_app.py

# 运行 Redis 配置程序
.PHONY: run
run: install
	@echo "运行 Redis 配置程序..."
	$(VENV_PYTHON) redis_config.py

# 清理虚拟环境
.PHONY: clean
clean:
	@echo "清理虚拟环境..."
	rm -rf $(VENV_DIR)
	rm -rf __pycache__
	rm -rf *.pyc

# 格式化代码
.PHONY: fmt
fmt:
	@echo "格式化 Python 代码..."
	$(VENV_PYTHON) -m black *.py

# 代码检查
.PHONY: lint
lint: install
	@echo "运行 Python 代码检查..."
	$(VENV_PYTHON) -m flake8 *.py
	$(VENV_PYTHON) -m pylint *.py

# 运行测试
.PHONY: test-python
test-python: install
	@echo "运行 Python 测试..."
	$(VENV_PYTHON) -m pytest test_redis.py -v

# 安装开发依赖
.PHONY: install-dev
install-dev: install
	@echo "安装开发依赖..."
	$(VENV_PIP) install black flake8 pylint pytest

# 帮助信息
.PHONY: help
help:
	@echo "可用的 Make 目标:"
	@echo "  venv        - 创建 Python 虚拟环境"
	@echo "  install     - 安装 Python 依赖"
	@echo "  test        - 运行 Redis 配置测试"
	@echo "  web         - 启动 Web 应用"
	@echo "  run         - 运行 Redis 配置程序"
	@echo "  clean       - 清理虚拟环境"
	@echo "  fmt         - 格式化代码"
	@echo "  lint        - 运行代码检查"
	@echo "  test-python - 运行 Python 测试"
	@echo "  install-dev - 安装开发依赖"
	@echo "  help        - 显示此帮助信息"
