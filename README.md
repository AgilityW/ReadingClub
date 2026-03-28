# 读书会 Agent Group 📚

> 给一本书或一个话题，9 位来自不同学科的 AI 嘉宾从各自视角深度解读，经过主理人组织的多轮真实对话，最终产出一篇融合多元智慧的洞见文章。

**支持两种使用方式：**
- 🤖 **OpenClaw 模式** — 部署到 Feishu / Telegram 等群聊频道，像真实读书会一样运转
- 💻 **Claude Code CLI 模式** — 本地直接运行，无需任何平台

---

## 目录

- [项目简介](#项目简介)
- [快速开始](#快速开始)
- [方式一：OpenClaw 部署](#方式一openclaw-部署)
- [方式二：Claude Code CLI 本地使用](#方式二claude-code-cli-本地使用)
- [模型配置](#模型配置)
- [Agent 构成](#agent-构成)
- [工作流说明](#工作流说明)
- [自定义与扩展](#自定义与扩展)
- [文件结构](#文件结构)

---

## 项目简介

### 它能做什么

**读书会**：给一本书，9 位 AI 嘉宾（哲学家、经济学家、历史学家等）各自独立解读，随后展开 2 轮真实互动讨论，最终整合成一篇深度文章。

**话题讨论**：给一个命题（如"AI 会取代创意工作吗？"），各角色先独立立论，再针锋相对辩论，最终产出多元视角的分析文章。

### 核心设计理念

- **真实互动**：每位 Agent 必须读取其他人的发言，明确回应，不是各说各话
- **主理人选角**：每次开始前，主理人向你展示成员菜单，由你决定谁参与
- **可扩展**：9 位核心成员固定，随时可以新增自定义角色
- **双格式输出**：深度叙事长文（essay）+ 结构化洞见报告（report），两者都要也行

---

## 快速开始

### 前置条件

| 条件 | OpenClaw 模式 | Claude Code CLI 模式 |
|------|:---:|:---:|
| Git | ✅ | ✅ |
| OpenClaw CLI | ✅ | ❌ |
| jq | ✅ | ❌ |
| Claude Code | ❌ | ✅ |

### 克隆项目

```bash
git clone https://github.com/your-org/readingclub-agents.git
cd readingclub-agents
```

---

## 方式一：OpenClaw 部署

OpenClaw 是一个多 Agent 编排平台，支持将 Agent 群组部署到 Feishu、Telegram、WhatsApp、Discord 等频道。

### 第一步：安装 OpenClaw

```bash
# 参考官方文档
https://docs.openclaw.ai
```

### 第二步：配置模型（可选）

模型配置统一在 `config.yaml` 中修改：

```yaml
models:
  default:  anthropic/claude-sonnet-4-5   # 9 位读者 Agent 默认模型
  host:     anthropic/claude-opus-4-5     # 主理人
  writer:   anthropic/claude-opus-4-5     # Writer
  reviewer: anthropic/claude-opus-4-5     # Reviewer
```

### 第三步：运行 setup.sh

**不带参数运行，自动交互式引导：**

```bash
bash platforms/openclaw/setup.sh
```

运行后会依次询问：部署模式（本地/频道）→ 频道类型 → 群组 ID → 是否需要 @mention。

**也可以全部用参数指定，非交互运行：**

```bash
# 本地工作流模式
bash platforms/openclaw/setup.sh --mode local

# 飞书频道模式（所有 Agent 同一群组）
bash platforms/openclaw/setup.sh --mode channel --channel feishu --group-id oc_xxxxxxxxxxxxxxxx

# 飞书频道模式（每个 Agent 独立群组）
bash platforms/openclaw/setup.sh --mode channel --channel feishu \
  --group-map 'host=oc_111,philosopher=oc_222,writer=oc_333'

# 不需要 @mention 自动回复
bash platforms/openclaw/setup.sh --mode channel --channel feishu \
  --group-id oc_xxx --require-mention false

# 命令行覆盖 config.yaml 中的模型（临时使用）
bash platforms/openclaw/setup.sh --model-map 'host=anthropic/claude-opus-4-5,scientist=anthropic/claude-haiku-3-5'

# 预览，不实际执行
bash platforms/openclaw/setup.sh --dry-run
```

> **模型优先级**（高→低）：命令行 `--model*` 参数 → `config.yaml` → 内置默认值

**setup.sh 自动完成：**
1. 向 OpenClaw 注册全部 12 个 Agent（已存在的自动更新）
2. 设置各 Agent 的 emoji + 名称（workspace 在 `~/.openclaw/readingclub/`）
3. 将 soul.md / profile.md / user.md（核心层）+ agent-configs/{id}.md（平台层）部署到各 Agent 的 workspace
4. 写入 BOOTSTRAP.md（Agent 首次启动时自动合并、自毁）
5. 自动更新 `~/.openclaw/openclaw.json`（备份后安全写入）
6. 生成 `platforms/openclaw/examples/openclaw.local.json` 和 `openclaw.feishu.json` 配置示例

### 第三步：启动对话

```bash
# 启动 OpenClaw 网关
openclaw gateway

# 本地模式：直接与主理人对话
openclaw chat --agent host

# 发起读书会
我想读《思考，快与慢》

# 发起话题讨论
讨论一个话题：为什么好的制度总是难以持续？
```

频道模式下，在 Feishu / Telegram 群内直接 `@主理人 我想读《[书名]》` 即可触发。

---

## 方式二：Claude Code CLI 本地使用

无需 OpenClaw，直接在 Claude Code 中使用。适合个人使用、快速测试、或 OpenClaw 不可用时。

### 使用方法

打开 Claude Code（在项目根目录），直接对话：

```
请读取 .agents/host/soul.md 和 .agents/roster.md，
作为主理人角色，我想开始一个读书会：《人类简史》by 尤瓦尔·赫拉利
```

主理人会展示成员菜单，你选择参与者后，Claude Code 将依次模拟各 Agent 完成讨论流程。

### 更结构化的启动方式

项目已在 `platforms/claude-code/CLAUDE.md` 中提供了完整的上下文文件，
将其复制到项目根目录即可让 Claude Code 自动加载：

```bash
cp platforms/claude-code/CLAUDE.md ./CLAUDE.md
```

然后打开 Claude Code，直接发起读书会即可。详细说明见 `platforms/claude-code/CLAUDE.md`。

### 单独调用某位 Agent

如果只想听某一位 Agent 的视角：

```
请读取 .agents/futurist/soul.md，
作为未来学家，谈谈你对《第三次浪潮》的解读。
```

### 本地工作流提示

- Claude Code 单次对话有 context 限制，成员建议选 4-5 位
- Phase 3 对话轮数建议设为 1 轮（在 `.agents/host/user.md` 中调整）
- 每个 Phase 结束后可手动保存输出到 `shared/` 目录，方便跨对话延续

---

## 模型配置

### 配置文件：config.yaml

模型配置统一写在项目根目录的 `config.yaml`，供所有平台的 setup 脚本读取：

```yaml
models:
  default:  anthropic/claude-sonnet-4-5   # 9 位读者 Agent 默认模型
  host:     anthropic/claude-opus-4-5     # 主理人
  writer:   anthropic/claude-opus-4-5     # Writer
  reviewer: anthropic/claude-opus-4-5     # Reviewer

discussion:
  rounds: 2          # 对话轮数（1-4）

output:
  format: both       # essay | report | both
  length: medium     # short | medium | long
  style: 知识分子通俗
```

### 默认模型分配

| 角色类型 | 默认模型 | 说明 |
|---------|---------|------|
| 主理人 | `claude-opus-4-5` | 需要综合协调和提炼能力 |
| 9 位读者 | `claude-sonnet-4-5` | 平衡质量与成本 |
| Writer | `claude-opus-4-5` | 需要较强语言整合能力 |
| Reviewer | `claude-opus-4-5` | 需要严格的评审判断力 |

### 通过命令行临时覆盖模型

```bash
# 统一使用同一模型（覆盖 config.yaml）
bash platforms/openclaw/setup.sh --model anthropic/claude-opus-4-5

# 只调整主理人和 Writer
bash platforms/openclaw/setup.sh --model-host anthropic/claude-opus-4-5 \
              --model-writer anthropic/claude-opus-4-5
```

### 支持的模型格式

OpenClaw 使用 `provider/model-name` 格式：

```bash
# Anthropic
anthropic/claude-opus-4-5
anthropic/claude-sonnet-4-5
anthropic/claude-haiku-3-5

# OpenAI
openai/gpt-4o
openai/gpt-4o-mini

# Google
google/gemini-2.0-flash
google/gemini-2.5-pro

# 其他（视 OpenClaw 支持情况而定）
deepseek/deepseek-chat
```

> Claude Code CLI 模式下模型由 Claude Code 本身决定，config.yaml 中的模型配置不生效。

### 成本优化建议

如果想控制成本，可以把读者 Agent 调成较小的模型，主理人和 Writer 保持强模型：

```bash
bash setup.sh \
  --model-host anthropic/claude-opus-4-5 \
  --model-writer anthropic/claude-opus-4-5 \
  --model anthropic/claude-haiku-3-5
```

---

## Agent 构成

### 固定成员（12 位，不可删减）

**主持与产出（固定参与）**

| Agent | Emoji | 角色 |
|-------|-------|------|
| 主理人 | 🎙️ | 选角、组织对话、收束、协调 Writer/Reviewer |
| Writer | ✍️ | 整合全部讨论，产出文章（essay / report / both） |
| Reviewer | 🔍 | 四维度评审，打分，提出修改意见 |

**可选读者（每次由你选择参与）**

| Agent | Emoji | 视角 |
|-------|-------|------|
| 哲学家 | 🧠 | 西方哲学 · 追问本质与伦理 |
| 经济学家 | 📊 | 激励结构 · 博弈与利益分析 |
| 心理学家 | 🔬 | 行为认知 · 动机与无意识驱动 |
| 历史学家 | 📜 | 历史脉络 · 长周期与类比思维 |
| 社会学家 | 🌐 | 群体权力 · 制度与结构分析 |
| 技术人 | 💻 | 系统思维 · 第一性原理 |
| 文学家 | 📖 | 叙事隐喻 · 情感与人文关怀 |
| 未来学家 | 🔭 | 趋势预测 · 情景规划与长远推演 |
| 科学家 | 🧬 | 实证方法 · 复杂性与自然规律 |

### 每位 Agent 包含三个核心文件（平台无关）

```
.agents/{id}/
├── soul.md      # 身份定义：知识背景、思维特征、互动风格、典型表达
├── profile.md   # 角色定义：role 类型、行为约束（不含模型/工具/路径）
└── user.md      # 用户偏好：专业侧重、讨论深度、特殊要求
```

平台专属配置（如 OpenClaw workspace + tools）在 `platforms/openclaw/agent-configs/{id}.md` 中。
模型配置在 `config.yaml` 中，与 Agent 定义完全解耦。

---

## 工作流说明

### Phase 0｜选角（每次必做）

主理人展示菜单 → 你选择参与者 → 确认名单写入 `shared/session.md`

**✍️ Writer 和 🔍 Reviewer 默认每次都参与**，负责最终的产出和质量把关，不在选角菜单中出现。你只需要从 9 位读者中选择参与讨论的嘉宾。

建议人数：**4-6 位**。人太少视角单一，人太多讨论容易分散。

### Phase 1｜独立解读/立论

选中的读者 Agent 并行工作，互不参考，各自输出：
- 核心命题（1 句话）
- 3 个洞见（各附论证）
- 最想追问的问题

### Phase 2｜主理人整合

读取全部 Phase 1 输出，识别：
- **共识区**：大家都注意到的主题
- **张力区**：视角之间的分歧（讨论的最好素材）
- **盲点区**：无人提及但值得探讨的角度

然后抛出 2-3 个具体的讨论议题。

### Phase 3｜多轮对话（默认 2 轮）

每位 Agent 读取所有其他人的输出，**必须**明确回应至少 1 位其他 Agent，可以支持、补充、质疑或反驳。主理人在每轮后评估，决定是否继续。

### Phase 4｜主理人收束

总结：共识、有价值的未解分歧、最值得 Writer 呈现的洞见，并给出创作方向建议。

### Phase 5｜Writer 创作

整合全部讨论，按选定格式产出：
- `--format essay`：有叙事弧线的深度长文
- `--format report`：层级清晰的结构化洞见报告
- `--format both`：两种都产出

### Phase 6｜Reviewer 评审

四维度打分（满分 100）：
- 洞见深度 · 多元融合 · 逻辑严密 · 可读性

总分 ≥ 75 且无 Blocker → 通过；否则 Writer 修改，最多 2 轮。

---

## 自定义与扩展

### 调整讨论轮数

编辑 `.agents/host/user.md`：
```yaml
对话轮数: 2    # 可设为 1-4，Claude Code 本地模式建议用 1
```

### 调整输出格式

编辑 `.agents/writer/user.md`：
```yaml
默认格式: both    # essay / report / both
长度偏好: 中       # 短(800-1200字) / 中(1500-2500字) / 长(3000字以上)
风格: 知识分子通俗  # 严肃学术 / 知识分子通俗 / 大众易读
```

### 调整 Reviewer 评审权重

编辑 `.agents/reviewer/user.md`：
```yaml
洞见深度: 30    # 四项权重总和保持 100
多元融合: 25
逻辑严密: 25
可读性: 20
```

### 新增自定义 Agent

1. **复制模板目录**
   ```bash
   cp -r .agents/_template .agents/investor
   ```

2. **填写三个核心文件**（参考现有 Agent 的写法）
   - `soul.md`：身份、知识背景、思维特征、互动风格
   - `profile.md`：role 类型（reader）、行为约束（Phase 参与方式、字数限制等）
   - `user.md`：用户偏好

3. **新增 OpenClaw 平台配置**（如使用 OpenClaw）
   在 `platforms/openclaw/agent-configs/` 新增 `investor.md`：
   ```markdown
   # Investor — OpenClaw 配置
   ## Workspace
   workspace: ~/.openclaw/readingclub/workspace-investor
   ## Access
   read_access:
     - shared/input.md
     - shared/discussion.md
   write_access:
     - shared/phase1_outputs/investor.md
     - shared/round_outputs/investor_round{n}.md
   ```

4. **在 `agents.yaml` 添加记录**
   ```yaml
   investor:
     id: investor
     name: "投资人"
     emoji: "💰"
     protected: false          # 自定义 Agent 不受保护
     role: reader
     perspective: "资本/风险/回报"
     files:
       soul: .agents/investor/soul.md
       profile: .agents/investor/profile.md
       user: .agents/investor/user.md
   ```

5. **在 `platforms/openclaw/setup.sh` 的 AGENTS 数组添加一行**
   ```bash
   "investor|💰|投资人|${MODEL_DEFAULT}|false|资本/风险/回报视角"
   ```

6. **重新运行 setup.sh**（花名册自动更新，OpenClaw 自动注册）
   ```bash
   bash platforms/openclaw/setup.sh
   ```

新 Agent 会自动出现在主理人 Phase 0 的选角菜单中。

---

## 文件结构

```
readingclub-agents/
├── agents.yaml                     # Agent 注册表（核心配置）
├── config.yaml                     # 用户配置：模型选择、输出格式等（在此修改）
├── README.md                       # 本文档
│
├── .agents/                        # 核心层（平台无关）
│   ├── roster.md                   # 可选成员花名册（Phase 0 读取，setup.sh 自动维护）
│   ├── host/                       # 🎙️ 主理人
│   │   ├── soul.md                 # 身份定义（知识背景、风格）
│   │   ├── profile.md              # 角色定义（role、行为约束）
│   │   └── user.md                 # 用户偏好
│   ├── philosopher/                # 🧠 哲学家（同上三个文件）
│   ├── economist/                  # 📊 经济学家
│   ├── psychologist/               # 🔬 心理学家
│   ├── historian/                  # 📜 历史学家
│   ├── sociologist/                # 🌐 社会学家
│   ├── technologist/               # 💻 技术人
│   ├── literarian/                 # 📖 文学家
│   ├── futurist/                   # 🔭 未来学家
│   ├── scientist/                  # 🧬 科学家
│   ├── writer/                     # ✍️ Writer
│   ├── reviewer/                   # 🔍 Reviewer
│   ├── _template/                  # 新增 Agent 模板
│   │   ├── soul.md
│   │   ├── profile.md
│   │   └── user.md
│   └── workflows/
│       ├── book-club.md            # 读书会工作流（Phase 0-6）
│       └── topic-discussion.md     # 话题讨论工作流
│
└── platforms/                      # 平台适配层
    ├── openclaw/                   # OpenClaw 平台
    │   ├── setup.sh                # 一键部署脚本（读取 config.yaml 中的模型）
    │   ├── agent-configs/          # OpenClaw 专属配置（workspace + tools，无模型）
    │   │   ├── host.md
    │   │   ├── philosopher.md
    │   │   └── ...（每个 Agent 一个）
    │   └── examples/               # 配置示例（setup.sh 自动生成）
    │       ├── openclaw.local.json
    │       └── openclaw.feishu.json
    ├── claude-code/                # Claude Code CLI 平台
    │   └── CLAUDE.md              # 上下文加载文件（复制到项目根目录使用）
    └── _template/                  # 新增平台的指导文档
        └── README.md
```

---

## 常见问题

**Q：每次都要选角吗？**
A：是的，Phase 0 是必须步骤。主理人会展示菜单，你也可以直接回复「全部」跳过选择。

**Q：可以只运行部分 Phase 吗？**
A：可以。告诉主理人"跳过对话，直接让 Writer 整合"即可跳到 Phase 5。

**Q：输出文章保存在哪里？**
A：OpenClaw 模式下保存在 `~/.openclaw/readingclub/workspace-writer/outputs/`；Claude Code CLI 模式下在当前目录的 `outputs/` 或由你指定位置。

**Q：新增的 Agent 下次 setup.sh 会被覆盖吗？**
A：不会。`platforms/openclaw/setup.sh` 使用安全合并策略，只追加不存在的 Agent，不覆盖已有配置。

**Q：Claude Code CLI 模式下如何延续上次的讨论？**
A：把上次的 `shared/discussion.md` 内容粘贴到新对话开头，告诉主理人"继续上次的讨论，从 Phase X 继续"即可。

---

## 许可证

MIT License
