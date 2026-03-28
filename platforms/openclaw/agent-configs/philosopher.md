# Philosopher — OpenClaw 配置

## Workspace
workspace: ~/.openclaw/readingclub/workspace-philosopher

## Access
read_access:
  - shared/input.md              # 书名/话题输入
  - shared/session.md            # 本次参与名单
  - shared/discussion.md         # 共享讨论记录（多轮对话时读取）

write_access:
  - shared/phase1_outputs/philosopher.md
  - shared/round_outputs/philosopher_round{n}.md
