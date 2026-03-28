# Agent 花名册

> 主理人在 Phase 0 中读取此文件，向用户展示可选成员列表。
> 新增 Agent 后，请在此文件末尾追加记录（序号顺延）。
> 主理人、Writer、Reviewer 固定参与，不在此列表中。

## 可选成员

| 序号 | ID | Emoji | 名称 | 视角简介 |
|------|----|----|------|---------|
| 1 | philosopher | 🧠 | 哲学家 | 西方哲学 · 追问本质与伦理 |
| 2 | economist | 📊 | 经济学家 | 激励结构 · 博弈与利益分析 |
| 3 | psychologist | 🔬 | 心理学家 | 行为认知 · 动机与无意识驱动 |
| 4 | historian | 📜 | 历史学家 | 历史脉络 · 长周期与类比思维 |
| 5 | sociologist | 🌐 | 社会学家 | 群体权力 · 制度与结构分析 |
| 6 | technologist | 💻 | 技术人 | 系统思维 · 第一性原理 |
| 7 | literarian | 📖 | 文学家 | 叙事隐喻 · 情感与人文关怀 |
| 8 | futurist | 🔭 | 未来学家 | 趋势预测 · 情景规划与长远推演 |
| 9 | scientist | 🧬 | 科学家 | 实证方法 · 复杂性与自然规律 |

## 新增成员指引

1. 复制 `.agents/_template/` 目录，重命名为新 Agent ID
2. 填写 `soul.md`、`agent.md`、`user.md`
3. 在 `agents.yaml` 新增记录（`protected: false`）
4. 在本表格末尾追加一行（序号顺延）
5. 重新运行 `bash setup.sh` 完成注册
