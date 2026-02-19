# Praxis: Master Lifecycle Makefile
# Zero-Baderna Orchestrator

SHELL := /bin/bash
PROJECT_DIR := $(shell pwd)
FLATPAK_ID := io.github.passosdomingues.praxis
LOCAL_TOOLCHAIN := $(PROJECT_DIR)/local_toolchain
FLUTTER_BIN_DIR := $(LOCAL_TOOLCHAIN)/flutter/bin
FLUTTER_BIN := $(FLUTTER_BIN_DIR)/flutter
VENV_DIR := $(PROJECT_DIR)/.venv
BUILD_DIR := build_staging
REPO_DIR := repo
AI_ENGINE_DIR := ai_engine
MODEL_NAME := deepseek-coder:1.3b
MANIFEST := $(FLATPAK_ID).json

# Helper: Auto-install Flutter Master
define check_flutter
	@if [ ! -f "$(FLUTTER_BIN)" ]; then \
		echo "Incompatible Flutter version. Installing Flutter Master branch locally..."; \
		mkdir -p $(LOCAL_TOOLCHAIN); \
		git clone https://github.com/flutter/flutter.git -b master $(LOCAL_TOOLCHAIN)/flutter; \
		$(FLUTTER_BIN) config --no-analytics; \
	fi
endef

.PHONY: all run build flat setup clean kill help models test install lint deps launch run-flat all-flat

help:
	@echo "Praxis: Master Lifecycle CLI"
	@echo "--------------------------------------------"
	@echo "make run      - Launch App + AI Engine (Parallel Mode)"
	@echo "make all      - Full cycle (Clean -> Setup -> Build -> Run)"

kill:
	@echo "Stopping Praxis processes (surgical strike)..."
	@# Filtramos o grep para ignorar o próprio comando e o shell
	@ps -ef | grep -E "praxis_agent.py|praxis_executable" | grep -v grep | awk '{print $$2}' | xargs -r kill -9 || true
	@echo "Cleanup complete."

run: kill
	@echo "Initializing Database..."
	@touch $(PROJECT_DIR)/praxis_events.db
	@echo "Starting Praxis (Parallel AI + UI)..."
	@export PATH=$(FLUTTER_BIN_DIR):$$PATH && \
	 export PYTHONPATH="$(PROJECT_DIR)/$(AI_ENGINE_DIR)/nanobot_core:$(PROJECT_DIR)/$(AI_ENGINE_DIR)/agent" && \
	 export PRAXIS_DB_PATH="$(PROJECT_DIR)/praxis_events.db" && \
	 source $(VENV_DIR)/bin/activate && \
	 python3 $(AI_ENGINE_DIR)/agent/praxis_agent.py & \
	 AGENT_PID=$$! ; \
	 $(FLUTTER_BIN) run -d linux ; \
	 kill $$AGENT_PID || true

deps:
	@echo "Installing Build Dependencies..."
	@flatpak install -y flathub org.flatpak.Builder || true

models:
	@echo "Checking AI Models (Ollama)..."
	@if command -v ollama &> /dev/null; then \
		ollama serve > /dev/null 2>&1 & \
		sleep 2; \
		ollama pull $(MODEL_NAME); \
	else \
		echo "Warning: Ollama not found."; \
	fi

setup: models
	$(call check_flutter)
	@echo "Setting up Python environment..."
	@if [ ! -d "$(VENV_DIR)" ]; then python3 -m venv $(VENV_DIR); fi
	@source $(VENV_DIR)/bin/activate && pip install --upgrade pip && pip install -r requirements.txt
	@echo "Repairing and Upgrading Flutter dependencies..."
	@if [ -f "pubspec.lock" ]; then rm pubspec.lock; fi
	@$(FLUTTER_BIN) pub upgrade

clean:
	@echo "Deep cleaning workspace..."
	@if [ -f "$(FLUTTER_BIN)" ]; then $(FLUTTER_BIN) clean &> /dev/null || true; fi
	@rm -rf build/ $(BUILD_DIR)/ .dart_tool/ $(REPO_DIR)/ local_libs/ $(VENV_DIR)/
	@rm -f praxis.flatpak praxis_events.db pubspec.lock .flutter-plugins*
	@echo "Workspace cleaned."

build: setup
	@echo "Building Release..."
	@$(FLUTTER_BIN) build linux --release

flat: setup build
	@echo "Packaging Flatpak Bundle..."
	@mkdir -p local_libs
	@source $(VENV_DIR)/bin/activate && pip install -r requirements.txt -t local_libs
	@rm -rf $(BUILD_DIR) && mkdir -p $(BUILD_DIR)
	
	@# 1. Copia o binário e bibliotecas do Flutter
	@cp -r build/linux/x64/release/bundle/* $(BUILD_DIR)/
	
	@# 2. Copia a Engine de IA e dependências Python
	@mkdir -p $(BUILD_DIR)/$(AI_ENGINE_DIR)
	@cp -r $(AI_ENGINE_DIR)/* $(BUILD_DIR)/$(AI_ENGINE_DIR)/
	@cp -r local_libs $(BUILD_DIR)/$(AI_ENGINE_DIR)/
	@cp requirements.txt $(BUILD_DIR)/$(AI_ENGINE_DIR)/
	@mv $(BUILD_DIR)/praxis $(BUILD_DIR)/praxis_executable
	
	@# 3. INJEÇÃO DOS ÍCONES E DESKTOP (O pulo do gato)
	@echo "Injecting Linux Integration metadata..."
	@mkdir -p $(BUILD_DIR)/share/applications
	@mkdir -p $(BUILD_DIR)/share/metainfo
	@mkdir -p $(BUILD_DIR)/share/icons/hicolor/512x512/apps
	@cp flatpak/$(FLATPAK_ID).desktop $(BUILD_DIR)/share/applications/
	@cp flatpak/$(FLATPAK_ID).metainfo.xml $(BUILD_DIR)/share/metainfo/
	@cp flatpak/icons/icon.png $(BUILD_DIR)/share/icons/hicolor/512x512/apps/$(FLATPAK_ID).png
	
	@# 4. Script de entrada (Wrapper)
	@printf "#!/bin/bash\n\
	APP_DIR=\$$(dirname \"\$$0\")\n\
	export LD_LIBRARY_PATH=\"\$$APP_DIR/lib:\$$LD_LIBRARY_PATH\"\n\
	export PYTHONPATH=\"\$$APP_DIR/$(AI_ENGINE_DIR)/local_libs:\$$APP_DIR/$(AI_ENGINE_DIR)/nanobot_core\"\n\
	export PRAXIS_DB_PATH=\"\$$HOME/.var/app/$(FLATPAK_ID)/data/praxis_events.db\"\n\
	python3 \"\$$APP_DIR/$(AI_ENGINE_DIR)/agent/praxis_agent.py\" &\n\
	AGENT_PID=\$$!\n\
	\"\$${APP_DIR}/praxis_executable\"\n\
	kill \$$AGENT_PID" > $(BUILD_DIR)/praxis
	@chmod +x $(BUILD_DIR)/praxis
	
	@# 5. Build Final
	@echo "Building with flatpak-builder..."
	@flatpak-builder --force-clean --repo="$(REPO_DIR)" --install-deps-from=flathub build-dir $(MANIFEST)
	@flatpak build-bundle $(REPO_DIR) praxis.flatpak $(FLATPAK_ID)
	@echo "praxis.flatpak ready with icons."

install:
	@echo "Installing Flatpak..."
	@flatpak uninstall --user -y $(FLATPAK_ID) || true
	@flatpak install --user -y praxis.flatpak

all: clean setup build run