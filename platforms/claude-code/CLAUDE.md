# 读书会 Agent Group — Claude Code CLI 使用指南

## 概述

本文件放置于项目根目录（或 Claude Code 工作目录）时，Claude Code CLI
会自动读取，让你可以在本地直接模拟完整的读书会流程。

---

## 项目结构

```
readingclub-agents/
├── config.yaml                    ← 用户配置（模型选择、输出格式等）
├── agents.yaml                    ← Agent 注册表
├── .agents/
│   ├── roster.md                  ← 可选嘉宾花名册（Phase 0 使用）
│   ├── host/                      ← 主理人（soul.md / profile.md / user.md）
│   ├── philosopher/               ← 哲学家
│   ├── economist/                 ← 经济学家
│   ├── psychologist/              ← 心理学家
│   ├── historian/                 ← 历史学家
│   ├── sociologist/               ← 社会学家
│   ├── technologist/              ← 技术人
│   ├── literarian/                ← 文学家
│   ├── futurist/                  ← 未来学家
│   ├── scientist/                 ← 科学家
│   ├── writer/                    ← Writer（固定参与）
│   ├── reviewer/                  ← Reviewer（固定参与）
│   └── workflows/
│       ├── book-club.md           ← 读书会工作流（6个Phase）
│       └── topic-discussion.md    ← 话题讨论工作流（6个Phase）
└── platforms/
    └── claude-code/
        └── CLAUDE.md              ← 本文件
```

---

## 使用前准备

### 1. 配置模型（可选）

编辑 `config.yaml`，设置你想使用的模型：

```yaml
models:
  default:  anthropic/claude-sonnet-4-5   # 读者 Agent 默认模型
  host:     anthropic/claude-opus-4-5     # 主理人
  writer:   anthropic/claude-opus-4-5     # Writer
  reviewer: anthropic/claude-opus-4-5     # Reviewer
```

> 说明：在 Claude Code CLI 模式下，模型配置仅供参考，实际使用的模型
> 由你在 Claude Code 中选择的会话模型决定。

### 2. 配置输出格式（可选）

```yaml
output:
  format: both    # essay（叙事长文）| report（结构报告）| both（两种都要）
  length: medium  # short | medium | long
  style: 知识分子通俗
```

---

## 启动方式

在 Claude Code CLI 中，打开项目根目录，然后输入：

```
我想读《[书名]》
```

或

```
我想讨论这个话题：[话题]
```

Claude 会自动扮演主理人（🎙️）的角色，按照以下流程推进：

---

## 工作流（6个Phase）

### Phase 0 — 参与确认
主理人展示可选嘉宾列表（来自 `.agents/roster.md`），你选择参与的 Agent。
Writer 和 Reviewer 固定参与，无需选择。

### Phase 1 — 独立解读
各选中的读者 Agent **独立**发表解读（400-600字），不互相参考。

### Phase 2 — 主理人合成
主理人提炼各方核心观点，发现张力与交叉点，生成 3-5 个讨论议题。

### Phase 3 — 多轮对话
各 Agent 围绕议题展开真实互动，必须明确引用其他 Agent 的具体观点（支持/质疑/补充/反驳）。
可配置 1-3 轮（在 `config.yaml` 中设置 `discussion.rounds`）。

### Phase 4 — 主理人收束
主理人整合讨论精华，形成 `shared/host_summary.md`。

### Phase 5 — Writer 创作
Writer 读取讨论记录和主理人摘要，撰写整合文章（essay 和/或 report）。

### Phase 6 — Reviewer 评审
Reviewer 对初稿进行评审（满分100，≥75通过），提供修改建议。
Writer 根据建议修改，最多 2 轮，超出由主理人仲裁。

---

## Claude Code 模拟模式说明

在 Claude Code CLI 中，单个 Claude 实例**依次扮演**各个 Agent 的角色。
每次角色切换时，Claude 会：

1. 读取该 Agent 的 `.agents/{id}/soul.md`（身份和知识背景）
2. 读取 `.agents/{id}/profile.md`（行为约束）
3. 读取 `.agents/{id}/user.md`（用户偏好设置）
4. 按照对应角色的视角和风格输出内容

这与 OpenClaw 多 Agent 并发运行的模式不同，但内容质量等价。

---

## 输出文件（运行时生成）

Claude Code 模式下，建议在项目根目录创建 `shared/` 和 `outputs/` 目录：

```
shared/
├── session.md          ← Phase 0 确认的参与名单
├── input.md            ← 书名或话题
├── discussion.md       ← 讨论记录（主理人维护）
├── host_summary.md     ← 主理人收束摘要
├── phase1_outputs/
│   └── {id}.md         ← 各 Agent 的 Phase 1 解读
└── round_outputs/
    └── {id}_round{n}.md ← 各轮次的对话记录

outputs/
├── draft.md            ← Writer 初稿
├── revised.md          ← Writer 修订稿
├── review.md           ← Reviewer 评审报告
└── final.md            ← 最终定稿
```

---

## 新增 Agent

1. 复制 `.agents/_template/` 目录，重命名为新 Agent ID
2. 填写 `soul.md`、`profile.md`、`user.md`
3. 在 `agents.yaml` 新增记录（`protected: false`）
4. 在 `.agents/roster.md` 追加一行
5. 下次运行 `bash platforms/openclaw/setup.sh` 时会自动同步（OpenClaw 模式）

---

## 提示词技巧

- **限定讨论深度**：「请以中等深度展开，每个 Agent 约 400 字」
- **指定焦点**：「重点关注哲学家和经济学家的视角」
- **跳过某些阶段**：「直接从 Phase 3 多轮对话开始」
- **调整轮次**：「对话只进行 1 轮，然后直接输出文章」
