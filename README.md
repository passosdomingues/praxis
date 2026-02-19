# 🚄 Praxis: AI-Enhanced Kanban Manager

![Pop!_OS Aesthetic](https://img.shields.io/badge/Aesthetic-Pop!__OS-teal?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Ollama](https://img.shields.io/badge/Local_AI-Ollama-orange?style=for-the-badge)
![Flatpak](https://img.shields.io/badge/Distribution-Flathub-7f8c8d?style=for-the-badge&logo=flatpak&logoColor=white)

**Praxis** is a premium, high-performance Kanban manager designed specifically for the Linux Desktop. Inspired by the **Pop!_OS** design system, it blends glassmorphism with local AI to provide a friction-less productivity experience.

---

## ✨ Features

- 💎 **Premium UI**: Full glassmorphism, micro-animations, and custom theming.
- 🤖 **MagicAI Intelligence**: Integrated PO/SM assistance using local **DeepSeek** models.
- 🕒 **Time Travel**: Built-in Event Sourcing allows replaying the history of any board.
- 🔒 **100% Local & Private**: All data and AI processing stay in your machine.
- 🚅 **Friction-less Automation**: Unified `Makefile` for developer-centric workflows.

---

## 🚀 Quick Start

Ensure you have **Ollama** running locally:
```bash
ollama pull deepseek-coder:1.3b
```

Then, use the **Master Workflow**:

| Command | Action |
| :--- | :--- |
| `make run` | 🚀 **Launch** (Dev Mode + AI Agent) |
| `make all` | 🚄 **Full Cycle** (Clean -> Setup -> Build -> Run) |
| `make flat` | 📦 **Package** (Generate Standalone `.flatpak` bundle) |
| `make clean` | 🧹 **Deep Purge** (Clean all caches and artifacts) |

---

## 🛠️ Project Structure

Professional and lean organization:
- `lib/`: High-fidelity Flutter source code.
- `ai_engine/`: Consolidated AI Engine (Agent, Nanobot, Custom Tools).
- `assets/`: UI resources and icons.
- `io.github.passosdomingues.praxis.json`: Flathub-compliant manifest.
- `Makefile`: The single source of truth for the entire lifecycle.

---

## 📦 Distribution

To generate the standalone **praxis.flatpak** bundle:
```bash
make flat
```
This will produce a portable bundle ready for Flathub or direct installation via:
```bash
flatpak install praxis.flatpak
```

---

> [!TIP]
> **Praxis** is more than a board; it's a high-performance "trem" for your productivity. 🚀
