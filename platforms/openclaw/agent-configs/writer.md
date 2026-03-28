# Writer — OpenClaw 配置

## Workspace
workspace: ~/.openclaw/readingclub/workspace-writer

## Access
read_access:
  - shared/discussion.md         # 完整讨论记录
  - shared/host_summary.md       # 主理人收束摘要
  - shared/phase1_outputs/       # 所有 Phase 1 解读（备查）

write_access:
  - outputs/draft.md             # 初稿
  - outputs/revised.md           # 修订稿

## Output Formats
# 由 config.yaml 中 output.format 控制
# essay   → 深度叙事长文
# report  → 结构化洞见报告
# both    → 两种都产出（默认）
