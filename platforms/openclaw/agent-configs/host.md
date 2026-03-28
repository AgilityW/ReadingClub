# Host — OpenClaw 配置

## Workspace
workspace: ~/.openclaw/readingclub/workspace-host

## Access
# 主理人可读取所有 Agent 的输出，可写入讨论主文档
read_access:
  - shared/session.md            # Phase 0 确认的参与名单
  - shared/discussion.md         # 共享讨论记录
  - shared/phase1_outputs/       # 所有 Agent 的 Phase 1 解读
  - shared/round_outputs/        # 所有轮次的对话记录

write_access:
  - shared/session.md            # 写入本次参与名单
  - shared/input.md              # 写入书名/话题
  - shared/discussion.md         # 写入整合分析和议题
  - shared/host_summary.md       # 最终收束摘要

## Tools (OpenClaw)
tools:
  agentToAgent:
    enabled: true
    # 主理人可以与所有 Agent 通信
    allow:
      - { from: host,     to: "*"        }
      - { from: "*",      to: host       }
      - { from: writer,   to: reviewer   }
      - { from: reviewer, to: writer     }
