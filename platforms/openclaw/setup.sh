#!/usr/bin/env bash
# ============================================================
#  读书会 Agent Group — OpenClaw Setup Script  (v2.0.0)
# ============================================================
#  用法:
#    bash platforms/openclaw/setup.sh               # 交互式
#    bash platforms/openclaw/setup.sh --mode local  # 本地模式
#    bash platforms/openclaw/setup.sh --mode channel --channel feishu --group-id oc_xxx
#
#  频道模式选项:
#    --channel feishu            指定频道类型
#    --group-id oc_xxx           所有 Agent 共享同一群组
#    --group-map 'host=oc_1,writer=oc_2'  每个 Agent 独立群组
#    --require-mention true|false
#
#  模型选项（覆盖 config.yaml）:
#    --model <model>             统一指定所有 Agent 的模型
#    --model-host <model>        单独指定主理人模型
#    --model-writer <model>      单独指定 Writer 模型
#    --model-map 'host=m1,writer=m2'
#
#  其他:
#    --config <path>             openclaw.json 路径
#    --dry-run                   预览，不实际执行
#    -h, --help
#
#  模型配置优先级（高→低）:
#    1. --model / --model-host / --model-map 命令行参数
#    2. ../../config.yaml 中的 models 配置
#    3. 内置默认值（anthropic/claude-sonnet-4-5）
# ============================================================

set -euo pipefail

# ── 颜色 ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()    { echo -e "${BLUE}ℹ${NC}  $*"; }
success() { echo -e "${GREEN}✔${NC}  $*"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
error()   { echo -e "${RED}✖${NC}  $*" >&2; exit 1; }
step()    { echo -e "\n${MAGENTA}▸${NC} ${BOLD}$*${NC}"; }

banner() {
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}  ${BOLD}📚 读书会 Agent Group — OpenClaw Setup${NC}  v2.0.0  ${CYAN}║${NC}"
  echo -e "${CYAN}║${NC}  ${DIM}本地模式 · 频道模式 · 多群组 · 自选嘉宾${NC}         ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
}

# ── 路径 ─────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
AGENTS_DIR="${PROJECT_ROOT}/.agents"
PLATFORM_CONFIGS_DIR="${SCRIPT_DIR}/agent-configs"
CONFIG_YAML="${PROJECT_ROOT}/config.yaml"
OPENCLAW_HOME="${HOME}/.openclaw"
WORKSPACE_ROOT="${OPENCLAW_HOME}/readingclub"    # 避免与其他项目 Agent ID 冲突
OPENCLAW_CONFIG="${OPENCLAW_HOME}/openclaw.json"

# ── 从 config.yaml 读取模型默认值 ─────────────────────────────
read_model_from_config() {
  local _key="$1"
  local _fallback="$2"
  if [[ -f "${CONFIG_YAML}" ]]; then
    local _val
    _val=$(grep -A20 '^models:' "${CONFIG_YAML}" | grep "^\s*${_key}:" | head -1 | awk -F': ' '{print $2}' | tr -d ' "')
    echo "${_val:-${_fallback}}"
  else
    echo "${_fallback}"
  fi
}

# ── 默认参数（优先读 config.yaml，命令行参数可覆盖）────────────
MODE=""
CHANNEL=""
GROUP_ID=""
GROUP_MAP=""
MODEL_DEFAULT="$(read_model_from_config default  'anthropic/claude-sonnet-4-5')"
MODEL_HOST="$(    read_model_from_config host     'anthropic/claude-opus-4-5')"
MODEL_WRITER="$(  read_model_from_config writer   'anthropic/claude-opus-4-5')"
MODEL_REVIEWER="$(read_model_from_config reviewer 'anthropic/claude-opus-4-5')"
MODEL_MAP=""
REQUIRE_MENTION=""
DRY_RUN=false
CONFIG_FILE="${OPENCLAW_CONFIG}"

# ── 使用说明 ─────────────────────────────────────────────────
usage() {
  cat <<EOF

${BOLD}读书会 Agent Group — OpenClaw Setup${NC}

用法:
  bash platforms/openclaw/setup.sh [选项]

模式:
  --mode local             本地工作流模式（agentToAgent）
  --mode channel           频道模式

频道模式选项:
  --channel <type>         频道类型：feishu | whatsapp | telegram | discord | slack
  --group-id <id>          所有 Agent 加入同一群组
  --group-map <map>        per-agent 群组，格式：host=oc_1,writer=oc_2
  --require-mention <bool> 是否需要 @mention 触发（true/false）

模型选项（覆盖 config.yaml）:
  --model <model>          统一指定所有 Agent 的模型
  --model-host <model>     单独指定主理人模型
  --model-writer <model>   单独指定 Writer 模型
  --model-map <map>        per-agent 模型，格式：host=m1,scientist=m2

其他:
  --config <path>          openclaw.json 路径（默认: ~/.openclaw/openclaw.json）
  --dry-run                预览，不实际执行
  -h, --help               显示帮助

示例:
  bash platforms/openclaw/setup.sh
  bash platforms/openclaw/setup.sh --mode local
  bash platforms/openclaw/setup.sh --mode channel --channel feishu --group-id oc_xxxxxxxx
  bash platforms/openclaw/setup.sh --model-map 'host=anthropic/claude-opus-4-5,scientist=google/gemini-2.0-flash'
  bash platforms/openclaw/setup.sh --dry-run

模型配置:
  默认从 config.yaml 读取，也可通过命令行参数覆盖。
  config.yaml 位置: ${CONFIG_YAML}

EOF
}

# ── 参数解析 ─────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)            MODE="$2";            shift 2 ;;
    --channel)         CHANNEL="$2";         shift 2 ;;
    --group-id)        GROUP_ID="$2";        shift 2 ;;
    --group-map)       GROUP_MAP="$2";       shift 2 ;;
    --model)           MODEL_DEFAULT="$2"; MODEL_HOST="$2"; MODEL_WRITER="$2"; MODEL_REVIEWER="$2"; shift 2 ;;
    --model-host)      MODEL_HOST="$2";      shift 2 ;;
    --model-writer)    MODEL_WRITER="$2";    shift 2 ;;
    --model-map)       MODEL_MAP="$2";       shift 2 ;;
    --require-mention) REQUIRE_MENTION="$2"; shift 2 ;;
    --config)          CONFIG_FILE="$2";     shift 2 ;;
    --dry-run)         DRY_RUN=true;         shift ;;
    -h|--help)         usage; exit 0 ;;
    *) echo -e "${RED}✖${NC}  未知参数: $1" >&2; exit 1 ;;
  esac
done

# ── Agent 定义 ───────────────────────────────────────────────
# 格式: "id|emoji|name|model|protected|perspective"
# perspective 为空 = 固定参与（不在选角菜单中），非空 = 可选读者
AGENTS=(
  "host|🎙️|主理人|${MODEL_HOST}|true|"
  "philosopher|🧠|哲学家|${MODEL_DEFAULT}|true|西方哲学 · 追问本质与伦理"
  "economist|📊|经济学家|${MODEL_DEFAULT}|true|激励结构 · 博弈与利益分析"
  "psychologist|🔬|心理学家|${MODEL_DEFAULT}|true|行为认知 · 动机与无意识驱动"
  "historian|📜|历史学家|${MODEL_DEFAULT}|true|历史脉络 · 长周期与类比思维"
  "sociologist|🌐|社会学家|${MODEL_DEFAULT}|true|群体权力 · 制度与结构分析"
  "technologist|💻|技术人|${MODEL_DEFAULT}|true|系统思维 · 第一性原理"
  "literarian|📖|文学家|${MODEL_DEFAULT}|true|叙事隐喻 · 情感与人文关怀"
  "futurist|🔭|未来学家|${MODEL_DEFAULT}|true|趋势预测 · 情景规划与长远推演"
  "scientist|🧬|科学家|${MODEL_DEFAULT}|true|实证方法 · 复杂性与自然规律"
  "writer|✍️|Writer|${MODEL_WRITER}|true|"
  "reviewer|🔍|Reviewer|${MODEL_REVIEWER}|true|"
)

# ── per-agent model map 解析 ─────────────────────────────────
declare -A AGENT_MODELS
if [[ -n "${MODEL_MAP}" ]]; then
  IFS=',' read -ra _MAP_ENTRIES <<< "${MODEL_MAP}"
  for _entry in "${_MAP_ENTRIES[@]}"; do
    AGENT_MODELS["${_entry%%=*}"]="${_entry#*=}"
  done
fi

# 内置默认（可被 model-map 覆盖）
AGENT_MODELS["host"]="${AGENT_MODELS["host"]:-${MODEL_HOST}}"
AGENT_MODELS["writer"]="${AGENT_MODELS["writer"]:-${MODEL_WRITER}}"
AGENT_MODELS["reviewer"]="${AGENT_MODELS["reviewer"]:-${MODEL_REVIEWER}}"

get_model() {
  local _id="$1"
  local _default_model
  for _ae in "${AGENTS[@]}"; do
    IFS='|' read -r _aid _ _ _amodel _ _ <<< "${_ae}"
    if [[ "${_aid}" == "${_id}" ]]; then
      _default_model="${_amodel}"
      break
    fi
  done
  echo "${AGENT_MODELS[${_id}]:-${_default_model:-${MODEL_DEFAULT}}}"
}

# ── per-agent group map 解析 ─────────────────────────────────
declare -A AGENT_GROUPS
if [[ -n "${GROUP_MAP}" ]]; then
  IFS=',' read -ra _MAP_ENTRIES <<< "${GROUP_MAP}"
  for _entry in "${_MAP_ENTRIES[@]}"; do
    AGENT_GROUPS["${_entry%%=*}"]="${_entry#*=}"
  done
fi

get_group() {
  local _id="$1"
  echo "${AGENT_GROUPS[${_id}]:-${GROUP_ID}}"
}

# dry-run 包装
run() {
  if [[ "${DRY_RUN}" == true ]]; then
    echo -e "  ${DIM}\$ $*${NC}"
  else
    eval "$@"
  fi
}

# ── 环境检查 ─────────────────────────────────────────────────
preflight() {
  step "环境检查"

  if ! command -v openclaw &>/dev/null; then
    error "未找到 openclaw 命令。请先安装：https://docs.openclaw.ai"
  fi
  success "openclaw 已安装"

  if ! command -v jq &>/dev/null; then
    error "未找到 jq。请先安装：brew install jq"
  fi
  success "jq 已安装"

  if [[ ! -d "${AGENTS_DIR}" ]]; then
    error "未找到 .agents 目录：${AGENTS_DIR}"
  fi

  if [[ -f "${CONFIG_YAML}" ]]; then
    success "config.yaml 已找到，模型配置已加载"
    info "  default  → ${MODEL_DEFAULT}"
    info "  host     → ${MODEL_HOST}"
    info "  writer   → ${MODEL_WRITER}"
    info "  reviewer → ${MODEL_REVIEWER}"
  else
    warn "config.yaml 未找到（${CONFIG_YAML}），使用内置默认模型"
  fi

  mkdir -p "${OPENCLAW_HOME}" "${WORKSPACE_ROOT}"

  # 备份现有 config
  if [[ -f "${CONFIG_FILE}" ]]; then
    local _backup="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    if [[ "${DRY_RUN}" != true ]]; then
      cp "${CONFIG_FILE}" "${_backup}"
      success "已备份 openclaw.json → ${_backup}"
    else
      info "[DRY] 将备份 openclaw.json"
    fi
  else
    if [[ "${DRY_RUN}" != true ]]; then
      echo '{"agents":{"list":[]},"tools":{}}' > "${CONFIG_FILE}"
      info "已创建空的 openclaw.json"
    fi
  fi
}

# ── 注册 Agent ────────────────────────────────────────────────
register_agents() {
  step "注册 Agent（共 ${#AGENTS[@]} 个）"

  for _ae in "${AGENTS[@]}"; do
    IFS='|' read -r _id _emoji _name _ _ _ <<< "${_ae}"
    local _workspace="${WORKSPACE_ROOT}/workspace-${_id}"
    local _model; _model="$(get_model "${_id}")"
    local _display="${_emoji} ${_name}"

    info "${_display}  →  ${DIM}${_model}${NC}"
    run "openclaw agents add '${_id}' --model '${_model}' --workspace '${_workspace}' 2>/dev/null || true"
    run "openclaw agents set-identity --agent '${_id}' --name '${_display}' 2>/dev/null || true"
    [[ "${DRY_RUN}" != true ]] && mkdir -p "${_workspace}"
  done
}

# ── 部署源文件 ────────────────────────────────────────────────
deploy_source_files() {
  step "部署 Agent 源文件（soul / profile / user）"

  for _ae in "${AGENTS[@]}"; do
    IFS='|' read -r _id _emoji _name _ _ _ <<< "${_ae}"
    local _workspace="${WORKSPACE_ROOT}/workspace-${_id}"
    local _core_src="${AGENTS_DIR}/${_id}"
    local _platform_src="${PLATFORM_CONFIGS_DIR}/${_id}.md"
    local _model; _model="$(get_model "${_id}")"

    if [[ ! -d "${_core_src}" ]]; then
      warn "${_emoji} ${_name}：未找到核心文件目录 ${_core_src}，跳过"
      continue
    fi

    if [[ "${DRY_RUN}" == true ]]; then
      echo -e "  ${DIM}[DRY] 部署 ${_emoji} ${_name} → ${_workspace}${NC}"
      continue
    fi

    # 核心层：soul + user（平台无关）
    [[ -f "${_core_src}/soul.md"    ]] && cp "${_core_src}/soul.md"    "${_workspace}/_soul_source.md"
    [[ -f "${_core_src}/user.md"    ]] && cp "${_core_src}/user.md"    "${_workspace}/_user_source.md"
    [[ -f "${_core_src}/profile.md" ]] && cp "${_core_src}/profile.md" "${_workspace}/_profile_source.md"

    # 平台层：OpenClaw 专属配置（workspace + tools，无模型）
    if [[ -f "${_platform_src}" ]]; then
      cp "${_platform_src}" "${_workspace}/_platform_source.md"
    fi

    # BOOTSTRAP.md（首次启动自合并自毁）
    cat > "${_workspace}/BOOTSTRAP.md" <<BOOTSTRAP
# 📚 读书会 Agent Group — Bootstrap

你是读书会讨论系统中的 **${_emoji} ${_name}**。这是你的首次启动。

## 请按顺序执行以下步骤

### 第一步：合并你的身份定义
读取 \`_soul_source.md\`，将其内容**追加**到你的 \`SOUL.md\` 文件末尾。
如果 SOUL.md 不存在，直接将 _soul_source.md 的内容写入 SOUL.md。

### 第二步：合并用户偏好
读取 \`_user_source.md\`，将其内容**追加**到你的 \`USER.md\` 文件末尾。
如果 USER.md 不存在，直接将 _user_source.md 的内容写入 USER.md。

### 第三步：了解你的角色定义
读取 \`_profile_source.md\`，了解你的角色（role）和行为约束。
这是平台无关的定义，适用于所有平台。

### 第四步：了解平台配置
如果存在 \`_platform_source.md\`，读取它以了解在 OpenClaw 平台上的
workspace 路径、工具权限和文件访问规则。
当前模型由 OpenClaw 在注册时设定，无需手动配置。

### 第五步：了解工作流
工作流文件位于 \`~/.openclaw/readingclub/workflows/\`，阅读对应的工作流说明。

### 第六步：清理
完成以上步骤后，**删除**本文件（BOOTSTRAP.md）以及所有 \`_*_source.md\` 文件。

### 第七步：就绪确认
向调用你的 Agent（或用户）回复：
"✅ ${_emoji} ${_name} 已就绪。"

BOOTSTRAP

    success "${_emoji} ${_name}"
  done

  # 工作流文件部署到共享位置
  if [[ "${DRY_RUN}" != true ]]; then
    local _wf_dir="${WORKSPACE_ROOT}/workflows"
    mkdir -p "${_wf_dir}"
    cp "${AGENTS_DIR}/workflows/"*.md "${_wf_dir}/" 2>/dev/null || true
    success "工作流文件 → ${_wf_dir}"
  fi
}

# ── 生成 roster.md ────────────────────────────────────────────
generate_roster() {
  step "生成 Agent 花名册（roster.md）"

  local _roster="${AGENTS_DIR}/roster.md"
  local _seq=1

  if [[ "${DRY_RUN}" == true ]]; then
    info "[DRY] 生成 .agents/roster.md"
    return
  fi

  cat > "${_roster}" <<ROSTER_HEADER
# Agent 花名册

> 主理人在 Phase 0 中读取此文件，向用户展示可选成员列表。
> 新增 Agent 后，重新运行 bash platforms/openclaw/setup.sh 即可自动更新。
> 主理人、Writer、Reviewer 固定参与，不在此列表中。

## 可选成员

| 序号 | ID | Emoji | 名称 | 视角简介 |
|------|----|----|------|---------|
ROSTER_HEADER

  for _ae in "${AGENTS[@]}"; do
    IFS='|' read -r _id _emoji _name _ _ _perspective <<< "${_ae}"
    if [[ -n "${_perspective}" ]]; then
      echo "| ${_seq} | ${_id} | ${_emoji} | ${_name} | ${_perspective} |" >> "${_roster}"
      (( _seq++ ))
    fi
  done

  cat >> "${_roster}" <<ROSTER_FOOTER

## 新增成员指引

1. 复制 \`.agents/_template/\` 目录，重命名为新 Agent ID
2. 填写 \`soul.md\`、\`profile.md\`、\`user.md\`
3. 在 \`agents.yaml\` 新增记录（\`protected: false\`）
4. 在 \`platforms/openclaw/agent-configs/\` 新增 \`{id}.md\`（workspace + tools）
5. 在本文件 AGENTS 数组添加一行（perspective 非空即可入选角菜单）
6. 重新运行 \`bash platforms/openclaw/setup.sh\`，花名册和 OpenClaw 注册自动更新
ROSTER_FOOTER

  success "花名册已生成（$(( _seq - 1 )) 位可选成员）"
}

# ── 交互式模式与频道选择 ──────────────────────────────────────
prompt_mode_and_channel() {
  # ── 选择模式 ──
  if [[ -z "${MODE}" ]]; then
    echo -e "\n${BOLD}请选择部署模式：${NC}"
    echo -e "  ${CYAN}1${NC}) 频道模式  — 部署到 Feishu / WhatsApp / Telegram 等群聊"
    echo -e "  ${CYAN}2${NC}) 本地模式  — CLI 本地使用（agentToAgent）"
    echo -en "  选择 [1-2]: "
    read -r _m
    case "${_m}" in
      2) MODE="local" ;;
      *) MODE="channel" ;;
    esac
  fi

  if [[ "${MODE}" == "local" ]]; then
    info "已选：本地工作流模式"
    return
  fi

  # ── 选择频道类型 ──
  if [[ -z "${CHANNEL}" ]]; then
    echo -e "\n${BOLD}请选择频道类型：${NC}"
    echo -e "  ${CYAN}1${NC}) feishu    飞书"
    echo -e "  ${CYAN}2${NC}) whatsapp"
    echo -e "  ${CYAN}3${NC}) telegram"
    echo -e "  ${CYAN}4${NC}) discord"
    echo -e "  ${CYAN}5${NC}) slack"
    echo -e "  ${CYAN}s${NC}) 跳过，切换到本地模式"
    echo -en "  选择 [1-5/s]: "
    read -r _ch
    case "${_ch}" in
      1) CHANNEL="feishu" ;;
      2) CHANNEL="whatsapp" ;;
      3) CHANNEL="telegram" ;;
      4) CHANNEL="discord" ;;
      5) CHANNEL="slack" ;;
      *) MODE="local"; info "已切换到本地模式"; return ;;
    esac
  fi

  # ── 配置群组 ID ──
  if [[ -z "${GROUP_ID}" && ${#AGENT_GROUPS[@]} -eq 0 ]]; then
    echo -e "\n${BOLD}群组 ID 分配方式（${CHANNEL}）：${NC}"
    echo -e "  ${CYAN}1${NC}) 所有 Agent 加入同一个群组"
    echo -e "  ${CYAN}2${NC}) 每个 Agent 分配独立群组"
    echo -en "  选择 [1-2]: "
    read -r _gc

    if [[ "${_gc}" == "2" ]]; then
      echo ""
      for _ae in "${AGENTS[@]}"; do
        IFS='|' read -r _id _emoji _name _ _ _ <<< "${_ae}"
        echo -en "  ${BOLD}${_emoji} ${_name}${NC} 的群组 ID（留空跳过）: "
        read -r _gid
        [[ -n "${_gid}" ]] && AGENT_GROUPS["${_id}"]="${_gid}"
      done
      GROUP_ID="per_agent_routing"
    else
      echo -en "\n  ${BOLD}请输入群组 ID：${NC}"
      read -r GROUP_ID
    fi
  fi

  # ── @mention 设置 ──
  if [[ -z "${REQUIRE_MENTION}" ]]; then
    echo -e "\n${BOLD}是否需要 @mention 才能触发 Agent？${NC}"
    echo -e "  ${CYAN}y${NC}) 是，需要 @Agent名 才回复"
    echo -e "  ${CYAN}n${NC}) 否，自动回复群内所有消息"
    echo -en "  选择 [Y/n]: "
    read -r _mc
    case "${_mc}" in
      n|N) REQUIRE_MENTION="false" ;;
      *)   REQUIRE_MENTION="true" ;;
    esac
  fi
}

# ── 配置 openclaw.json ────────────────────────────────────────
configure_openclaw_json() {
  step "配置 openclaw.json（${MODE} 模式）"

  # 构建 agents 数组
  local _agents_json='['
  local _first=true
  for _ae in "${AGENTS[@]}"; do
    IFS='|' read -r _id _emoji _name _ _ _ <<< "${_ae}"
    local _workspace="${WORKSPACE_ROOT}/workspace-${_id}"
    local _model; _model="$(get_model "${_id}")"
    local _display="${_emoji} ${_name}"
    [[ "${_first}" == true ]] && _first=false || _agents_json+=','
    _agents_json+="$(cat <<AJSON
{
      "id": "${_id}",
      "name": "${_id}",
      "workspace": "${_workspace}",
      "model": "${_model}",
      "identity": { "name": "${_display}" },
      "groupChat": {
        "mentionPatterns": ["@${_id}", "${_id}", "@${_name}"],
        "historyLimit": 50
      }
    }
AJSON
)"
  done
  _agents_json+=']'

  # 所有 Agent 的 ID 列表（用于安全替换：先移除旧条目，再插入新条目）
  local _our_ids
  _our_ids="$(printf '%s\n' "${AGENTS[@]}" | cut -d'|' -f1 | jq -R . | jq -s .)"

  local _tmp; _tmp="$(mktemp)"

  if [[ "${MODE}" == "local" ]]; then
    # ── 本地模式：agentToAgent ──
    jq --argjson new_agents "${_agents_json}" \
       --argjson our_ids "${_our_ids}" '
      .agents.list = (
        [(.agents.list // [])[] | select(.id as $id | $our_ids | index($id) | not)]
        + $new_agents
      )
      | .tools = (.tools // {}) * {
          "agentToAgent": {
            "enabled": true,
            "allow": [
              { "from": "host",     "to": "*"        },
              { "from": "*",        "to": "host"     },
              { "from": "writer",   "to": "reviewer" },
              { "from": "reviewer", "to": "writer"   }
            ]
          }
        }
    ' "${CONFIG_FILE}" > "${_tmp}"

  else
    # ── 频道模式：bindings + channels ──
    local _bindings_json='['
    _first=true
    local -a _all_groups=()

    for _ae in "${AGENTS[@]}"; do
      IFS='|' read -r _id _ _ _ _ _ <<< "${_ae}"
      local _grp; _grp="$(get_group "${_id}")"
      [[ "${_first}" == true ]] && _first=false || _bindings_json+=','
      _bindings_json+="$(cat <<BJSON
{
      "agentId": "${_id}",
      "match": {
        "channel": "${CHANNEL}",
        "peer": { "kind": "group", "id": "${_grp}" }
      }
    }
BJSON
)"
      local _found=false
      for _g in "${_all_groups[@]:-}"; do [[ "${_g}" == "${_grp}" ]] && _found=true && break; done
      [[ "${_found}" == false ]] && _all_groups+=("${_grp}")
    done
    _bindings_json+=']'

    local _require_bool=true
    [[ "${REQUIRE_MENTION}" == "false" ]] && _require_bool=false

    local _groups_json="{"
    _first=true
    for _g in "${_all_groups[@]}"; do
      [[ "${_first}" == true ]] && _first=false || _groups_json+=","
      _groups_json+="\"${_g}\": { \"requireMention\": ${_require_bool} }"
    done
    _groups_json+="}"

    jq --argjson new_agents   "${_agents_json}" \
       --argjson new_bindings  "${_bindings_json}" \
       --argjson our_ids       "${_our_ids}" \
       --arg     channel       "${CHANNEL}" \
       --argjson new_groups    "${_groups_json}" '
      .agents.list = (
        [(.agents.list // [])[] | select(.id as $id | $our_ids | index($id) | not)]
        + $new_agents
      )
      | .bindings = (
          [(.bindings // [])[] | select(.agentId as $aid | $our_ids | index($aid) | not)]
          + $new_bindings
        )
      | .channels[$channel] = (
          (.channels[$channel] // {}) * {
            "groupPolicy": "open",
            "groups": ((.channels[$channel].groups // {}) * $new_groups)
          }
        )
      | .messages = (.messages // {}) * {
          "groupChat": { "historyLimit": (.messages.groupChat.historyLimit // 50) }
        }
    ' "${CONFIG_FILE}" > "${_tmp}"
  fi

  if [[ "${DRY_RUN}" == true ]]; then
    echo -e "\n${DIM}--- openclaw.json 预览（部分）---${NC}"
    jq '.agents.list | length, .tools, .bindings' "${_tmp}" 2>/dev/null || cat "${_tmp}"
    echo -e "${DIM}--- 预览结束 ---${NC}"
  else
    cp "${_tmp}" "${CONFIG_FILE}"
    success "openclaw.json 已更新（${CONFIG_FILE}）"
  fi
  rm -f "${_tmp}"
}

# ── 生成示例配置文件 ──────────────────────────────────────────
generate_examples() {
  step "生成示例配置文件"

  local _examples="${SCRIPT_DIR}/examples"
  [[ "${DRY_RUN}" != true ]] && mkdir -p "${_examples}"

  local _local_agents="["
  local _first=true
  for _ae in "${AGENTS[@]}"; do
    IFS='|' read -r _id _emoji _name _ _ _ <<< "${_ae}"
    local _model; _model="$(get_model "${_id}")"
    [[ "${_first}" == true ]] && _first=false || _local_agents+=","
    _local_agents+="
      { \"id\": \"${_id}\", \"name\": \"${_emoji} ${_name}\", \"model\": \"${_model}\", \"workspace\": \"${WORKSPACE_ROOT}/workspace-${_id}\" }"
  done
  _local_agents+="
    ]"

  if [[ "${DRY_RUN}" != true ]]; then
    cat > "${_examples}/openclaw.local.json" <<JSON
{
  "_comment": "读书会 Agent Group — 本地工作流模式配置示例",
  "agents": {
    "list": ${_local_agents}
  },
  "tools": {
    "agentToAgent": {
      "enabled": true,
      "allow": [
        { "from": "host",     "to": "*"        },
        { "from": "*",        "to": "host"     },
        { "from": "writer",   "to": "reviewer" },
        { "from": "reviewer", "to": "writer"   }
      ]
    }
  }
}
JSON
    success "examples/openclaw.local.json"

    cat > "${_examples}/openclaw.feishu.json" <<JSON
{
  "_comment": "读书会 Agent Group — 飞书频道模式配置示例（替换 YOUR_GROUP_ID）",
  "agents": {
    "list": ${_local_agents}
  },
  "bindings": [
    { "agentId": "host",         "match": { "channel": "feishu", "peer": { "kind": "group", "id": "YOUR_GROUP_ID" } } },
    { "agentId": "philosopher",  "match": { "channel": "feishu", "peer": { "kind": "group", "id": "YOUR_GROUP_ID" } } },
    { "agentId": "economist",    "match": { "channel": "feishu", "peer": { "kind": "group", "id": "YOUR_GROUP_ID" } } },
    { "agentId": "psychologist", "match": { "channel": "feishu", "peer": { "kind": "group", "id": "YOUR_GROUP_ID" } } },
    { "agentId": "historian",    "match": { "channel": "feishu", "peer": { "kind": "group", "id": "YOUR_GROUP_ID" } } },
    { "agentId": "sociologist",  "match": { "channel": "feishu", "peer": { "kind": "group", "id": "YOUR_GROUP_ID" } } },
    { "agentId": "technologist", "match": { "channel": "feishu", "peer": { "kind": "group", "id": "YOUR_GROUP_ID" } } },
    { "agentId": "literarian",   "match": { "channel": "feishu", "peer": { "kind": "group", "id": "YOUR_GROUP_ID" } } },
    { "agentId": "futurist",     "match": { "channel": "feishu", "peer": { "kind": "group", "id": "YOUR_GROUP_ID" } } },
    { "agentId": "scientist",    "match": { "channel": "feishu", "peer": { "kind": "group", "id": "YOUR_GROUP_ID" } } },
    { "agentId": "writer",       "match": { "channel": "feishu", "peer": { "kind": "group", "id": "YOUR_GROUP_ID" } } },
    { "agentId": "reviewer",     "match": { "channel": "feishu", "peer": { "kind": "group", "id": "YOUR_GROUP_ID" } } }
  ],
  "channels": {
    "feishu": {
      "groupPolicy": "open",
      "groups": {
        "YOUR_GROUP_ID": { "requireMention": true }
      }
    }
  },
  "messages": {
    "groupChat": { "historyLimit": 50 }
  }
}
JSON
    success "examples/openclaw.feishu.json"
  else
    info "[DRY] 将生成 examples/openclaw.local.json 和 examples/openclaw.feishu.json"
  fi
}

# ── 部署验证 ─────────────────────────────────────────────────
verify_deployment() {
  step "部署验证"
  local _pass=0 _fail=0
  for _ae in "${AGENTS[@]}"; do
    IFS='|' read -r _id _emoji _name _ _ _ <<< "${_ae}"
    local _workspace="${WORKSPACE_ROOT}/workspace-${_id}"
    if [[ -f "${_workspace}/BOOTSTRAP.md" && -f "${_workspace}/_soul_source.md" ]]; then
      success "${_emoji} ${_name}"
      (( _pass++ ))
    else
      warn "${_emoji} ${_name} — 文件缺失，请检查"
      (( _fail++ ))
    fi
  done
  echo ""
  if [[ ${_fail} -eq 0 ]]; then
    success "全部 ${_pass} 个 Agent 部署成功 ✅"
  else
    warn "${_pass} 个成功，${_fail} 个需要检查"
  fi
}

# ── 完成摘要 ─────────────────────────────────────────────────
print_summary() {
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║${NC}  ${BOLD}✅ 读书会 Agent Group 部署完成${NC}                  ${GREEN}║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${BOLD}模式：${NC}$(  [[ "${MODE}" == "local" ]] && echo "本地工作流（agentToAgent）" || echo "频道模式（${CHANNEL}）")"
  echo -e "  ${BOLD}Agent：${NC}${#AGENTS[@]} 个"
  echo -e "  ${BOLD}Workspace：${NC}${WORKSPACE_ROOT}/workspace-{id}"

  if [[ "${MODE}" == "channel" ]]; then
    echo -e "  ${BOLD}@mention：${NC}${REQUIRE_MENTION}"
    echo -e "  ${BOLD}群组绑定：${NC}"
    for _ae in "${AGENTS[@]}"; do
      IFS='|' read -r _id _emoji _name _ _ _ <<< "${_ae}"
      echo "    ${_emoji} ${_name}  →  $(get_group "${_id}")"
    done
  fi

  echo ""
  echo -e "  ${BOLD}下一步：${NC}"
  echo -e "    1. 启动网关：  ${CYAN}openclaw gateway${NC}"
  if [[ "${MODE}" == "channel" ]]; then
    echo -e "    2. 在群内发消息：  ${CYAN}@主理人 我想读《[书名]》${NC}"
  else
    echo -e "    2. 启动主理人：  ${CYAN}openclaw chat --agent host${NC}"
    echo -e "    3. 发起读书会：  「我想读《[书名]》」"
  fi
  echo ""
  echo -e "  ${BOLD}新增 Agent：${NC}"
  echo "    1. 复制 .agents/_template/，填写三个文件"
  echo "    2. 新增 platforms/openclaw/agent-configs/{id}.md"
  echo "    3. 在 AGENTS 数组加一行，重新运行 setup.sh"
  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# ── 主流程 ────────────────────────────────────────────────────
main() {
  banner

  if [[ "${DRY_RUN}" == true ]]; then
    warn "DRY RUN 模式 — 不会实际执行任何操作"
  fi

  preflight
  register_agents
  deploy_source_files
  generate_roster
  prompt_mode_and_channel
  configure_openclaw_json
  generate_examples

  if [[ "${DRY_RUN}" != true ]]; then
    verify_deployment
    openclaw agents list --bindings 2>/dev/null || true
    print_summary
  else
    echo ""
    info "DRY RUN 完成。确认无误后运行 bash platforms/openclaw/setup.sh 执行实际部署。"
  fi
}

main "$@"
