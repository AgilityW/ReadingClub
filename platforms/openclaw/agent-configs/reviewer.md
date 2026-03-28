# Reviewer — OpenClaw 配置

## Workspace
workspace: ~/.openclaw/readingclub/workspace-reviewer

## Access
read_access:
  - outputs/draft.md             # Writer 初稿
  - outputs/revised.md           # Writer 修订稿
  - shared/host_summary.md       # 主理人收束摘要（评审参考）
  - shared/discussion.md         # 讨论记录（验证观点真实性）

write_access:
  - outputs/review.md            # 评审报告
  - outputs/final.md             # 通过评审后的最终稿（由 Writer 写入）
