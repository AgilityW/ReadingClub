# 读书会工作流 📚

## 触发方式
```
输入：[书名] by [作者]（可附加：重点关注方向、背景说明）
```

---

## Phase 0｜参与确认
**执行者**：host
**输入**：书名 + 用户附加说明
**任务**：主理人读取 `.agents/roster.md`，向用户展示完整成员列表，由用户选择本次参与者

输出到：`shared/session.md`（记录参与成员 ID 列表）

> 详细展示格式见 `host/soul.md` Phase 0 章节。

---

## Phase 1｜独立解读
**执行者**：本次 session 选中的读者 Agent（并行，从 `shared/session.md` 读取名单）
**输入**：书名 + 作者 + 用户附加说明
**任务**：每个 Agent 从自身知识背景出发，独立完成解读，不得查看其他 Agent 的输出

每个 Agent 输出到：`shared/phase1_outputs/{agent_id}.md`

输出格式（见各 Agent soul.md）：
- 核心命题（1句话）
- 三个洞见（各附论证）
- 最想追问的问题（1个）

---

## Phase 2｜主理人整合
**执行者**：host
**输入**：读取所有 `shared/phase1_outputs/*.md`
**任务**：整合分析，提炼讨论议题

输出到：`shared/discussion.md`（第一条记录）

输出结构：
```markdown
## 🎙️ 主理人·Phase 2 整合

### 共识区
[大家都注意到的主题]

### 张力区
**张力 1**：[描述分歧]——[Agent A] 认为……而 [Agent B] 认为……
**张力 2**：[描述分歧]

### 盲点区
[无人提及但值得探讨的角度，如有]

### 第一轮讨论议题
**议题 1**：[具体问题]
**议题 2**：[具体问题]
**议题 3**：[可选]
```

---

## Phase 3｜多轮对话
**执行者**：所有读者 Agent（轮流，每轮并行）
**轮数**：默认 2 轮，可在 host/user.md 中调整

### Round 1
**输入**：读取 `shared/phase1_outputs/` 所有文件 + `shared/discussion.md`（主理人议题）
**任务**：
- 针对主理人提出的议题，发表观点
- **必须**明确回应至少一位其他 Agent 的 Phase 1 观点（直接引用或明确指代）
- 可以支持、补充、质疑或反驳

输出到：`shared/round_outputs/{agent_id}_round1.md`，并追加到 `shared/discussion.md`

### 主理人·Round 1 评估
读取所有 Round 1 输出，判断：
- 如讨论已充分 → 进入 Phase 4
- 如有重要议题未展开 → 发布 Round 2 追问

### Round 2（如需）
**输入**：读取 `shared/discussion.md`（包含所有 Round 1 内容 + 主理人追问）
**任务**：
- 针对主理人追问和 Round 1 中出现的新张力深化回应
- **必须**明确回应至少一位 Round 1 中其他 Agent 的具体观点

输出到：`shared/round_outputs/{agent_id}_round2.md`，并追加到 `shared/discussion.md`

---

## Phase 4｜主理人收束
**执行者**：host
**输入**：`shared/discussion.md`（完整讨论记录）
**任务**：总结讨论成果，为 Writer 提供创作方向

输出到：`shared/host_summary.md`

输出结构：
```markdown
## 🎙️ 主理人·收束摘要

### 本次讨论达成的共识
1. [洞见 + 来自哪些视角]
2. [洞见 + 来自哪些视角]

### 有价值但未解决的分歧
1. [分歧描述 + 各方立场]

### 最值得 Writer 重点呈现的洞见（按重要性排序）
1. [洞见] ——来自 [Agent]，在 [Round X] 提出
2. [洞见] ——在 [Agent A] 和 [Agent B] 的交锋中浮现
3. [洞见]
...

### 给 Writer 的创作建议
- 叙事起点建议：[...]
- 核心结构建议：[...]
- 需要突出的张力：[...]
- 建议规避的内容：[...]
```

---

## Phase 5｜Writer 创作
**执行者**：writer
**输入**：`shared/discussion.md` + `shared/host_summary.md`
**参数**：`--format [essay|report|both]`（默认读取 writer/user.md 配置）

**任务**：
- 整合讨论，产出文章
- 不是复述，而是重新组织、赋形

输出到：`outputs/draft.md`

---

## Phase 6｜Reviewer 评审
**执行者**：reviewer
**输入**：`outputs/draft.md` + `shared/host_summary.md`

**评审维度**（见 reviewer/soul.md）：
- 洞见深度（可调权重）
- 多元融合（可调权重）
- 逻辑严密（可调权重）
- 可读性（可调权重）

输出到：`outputs/review_report.md`

**判定规则**：
- 总分 ≥ 75 且无 Blocker → ✅ 通过，文章完成
- 总分 60-74 或有 Blocker → 🔄 Writer 修改，最多 2 轮
- 总分 < 60 → ⚠️ 主理人介入，讨论是否需要补充对话

---

## 产出文件结构
```
outputs/
├── draft.md            # Writer 初稿
├── revised.md          # 修订稿（如有）
└── review_report.md    # Reviewer 评审报告

shared/
├── session.md          # 本次参与成员名单（Phase 0 生成）
├── input.md            # 本次输入（书名/附加说明）
├── discussion.md       # 完整讨论记录
├── host_summary.md     # 主理人收束摘要
├── phase1_outputs/     # 各 Agent Phase 1 解读（仅本次参与者）
│   ├── {agent_id}.md
│   └── ...
└── round_outputs/      # 各轮对话输出
    ├── {agent_id}_round1.md
    └── ...
```
