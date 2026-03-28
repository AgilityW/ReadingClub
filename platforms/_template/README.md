# 新增平台适配器指南

本目录为平台适配器的模板说明。
每个平台对应 `platforms/{platform-name}/` 目录。

---

## 目录结构（最小化）

```
platforms/{platform-name}/
├── README.md              ← 平台说明（安装、配置、使用）
├── setup.sh               ← 部署脚本（如需）
├── agent-configs/         ← 平台专属的 Agent 配置（workspace、tools）
│   ├── host.md
│   ├── philosopher.md
│   └── ...（每个 Agent 一个文件）
└── examples/              ← 示例配置文件
```

---

## 分层架构

```
核心层（平台无关）                  平台适配层
─────────────────────────────────  ──────────────────────────────
.agents/{id}/soul.md               platforms/{p}/agent-configs/{id}.md
  → Agent 的身份、视角、风格           → workspace 路径
                                      → tools 权限
.agents/{id}/profile.md              → 平台专属参数
  → 角色定义（role）
  → 行为约束

.agents/{id}/user.md               config.yaml
  → 用户偏好                          → 模型选择
                                      → 输出格式

.agents/workflows/*.md
  → 工作流定义（Phase 0-6）
```

**原则**：
- `soul.md` / `profile.md` / `user.md` 绝不包含任何平台特定内容
- 模型配置统一放在项目根目录 `config.yaml`
- 平台脚本从 `config.yaml` 读取模型，不在代码中硬编码

---

## 新增平台步骤

### 1. 创建目录

```bash
mkdir -p platforms/{platform-name}/agent-configs
mkdir -p platforms/{platform-name}/examples
```

### 2. 创建 agent-configs/{id}.md（每个 Agent 一个）

内容包含：
- **workspace**：该平台上的工作目录路径
- **tools**：该平台支持的工具和权限
- **不包含**：model（从 config.yaml 读取）、soul（在 soul.md 中）、行为约束（在 profile.md 中）

示例格式：

```markdown
# {AgentName} — {Platform} 配置

## Workspace
workspace: /path/to/workspace/{id}

## Access
read_access:
  - shared/input.md
  - shared/discussion.md

write_access:
  - shared/phase1_outputs/{id}.md

## Tools（平台专属）
tools:
  some_tool:
    enabled: true
```

### 3. 创建 setup.sh（如需自动化部署）

关键要点：
- 从 `../../config.yaml` 读取模型配置
- 读取 `.agents/{id}/soul.md`、`.agents/{id}/profile.md`、`.agents/{id}/user.md` 作为核心文件
- 读取 `agent-configs/{id}.md` 作为平台层配置
- 在 Agent workspace 中生成 `BOOTSTRAP.md`（首次启动自合并自毁机制）

从 config.yaml 读取模型的 bash 片段：

```bash
CONFIG_YAML="$(dirname "$0")/../../config.yaml"

read_model_from_config() {
  local _key="$1"
  local _fallback="$2"
  if [[ -f "${CONFIG_YAML}" ]]; then
    local _val
    _val=$(grep -A20 '^models:' "${CONFIG_YAML}" | grep "^\s*${_key}:" | head -1 \
           | awk -F': ' '{print $2}' | tr -d ' "')
    echo "${_val:-${_fallback}}"
  else
    echo "${_fallback}"
  fi
}

MODEL_DEFAULT="$(read_model_from_config default  'anthropic/claude-sonnet-4-5')"
MODEL_HOST="$(    read_model_from_config host     'anthropic/claude-opus-4-5')"
```

### 4. 创建 README.md（本文件的平台版本）

说明：
- 平台安装前提条件
- 快速开始步骤
- 配置说明
- 与 config.yaml 的关系

### 5. 在项目 README.md 中登记

在主 `README.md` 的"平台支持"章节追加新平台信息。

---

## 已支持平台

| 平台 | 目录 | 状态 |
|------|------|------|
| OpenClaw | `platforms/openclaw/` | ✅ 完整支持 |
| Claude Code CLI | `platforms/claude-code/` | ✅ 完整支持 |

---

## 注意事项

- Agent ID 在所有平台间保持一致（如 `host`、`philosopher`）
- 如果平台有 ID 冲突风险（如多个项目共用同一平台），建议在 workspace 路径中加入项目名前缀
  - 示例（OpenClaw）：`~/.openclaw/readingclub/workspace-{id}` 而非 `~/.openclaw/workspace-{id}`
- BOOTSTRAP.md 机制是可选的，适用于支持"首次启动自合并"的平台；不支持的平台可直接加载文件
