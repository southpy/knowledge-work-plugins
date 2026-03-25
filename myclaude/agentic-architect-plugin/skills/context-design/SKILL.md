---
name: context-design
description: >
  在设计 Agent System Prompt、上下文结构或 Prompt 分层策略时自动加载此 skill。
  触发关键词："设计 system prompt"、"上下文怎么组织"、"context 分层"、"prompt 结构"、
  "context rot"、"token 窗口管理"、"按需加载 skill"、"运行时注入"。
  提供上下文分层原则和 Context Rot 防治策略，作为架构设计的强制检查基线。
metadata:
  version: "0.1.0"
  domain: context-engineering
---

# Context Design 原则

设计任何 Agent 的上下文结构时，强制应用以下分层模型。每层职责不可混用，违反分层是 Context Rot 的直接来源。

## 五层分层模型

参见 `references/context-layers.md` 获取完整规范和反例。

### 层级速查

| 层级 | 内容类型 | 加载方式 | 目标长度 |
|------|----------|----------|----------|
| **常驻层** | 身份定义、项目约定、绝对禁止项 | 每次会话强制注入 | ≤500 tokens |
| **按需加载层** | Skills、领域知识 | 描述符常驻，完整内容触发时注入 | 按 skill 独立计量 |
| **运行时注入层** | 当前时间、渠道 ID、用户偏好等动态信息 | 每轮按需拼入 | ≤200 tokens/轮 |
| **记忆层** | 跨会话经验，MEMORY.md | 需要时读取，不直接进 system prompt | 按需 |
| **系统层** | 确定性逻辑（Hooks、Linter、代码规则） | 完全不进上下文，由 Hook/Tool 执行 | 0 tokens |

## 设计时强制检查

在输出任何 System Prompt 设计前，逐项验证：

1. **常驻层是否精简**：超过 500 tokens 即为警告信号，检查是否有知识类内容混入。
2. **知识是否已 Skill 化**：领域规范、参考文档、操作流程 → 必须移入 Skills，不得硬编码进 system prompt。
3. **动态信息是否运行时注入**：时间戳、用户 ID、当前状态 → 必须运行时拼入，不得写死。
4. **确定性规则是否系统层执行**：可以用代码判断的规则（格式校验、权限检查）→ 必须用 Hook/Tool，不得依赖 LLM 判断。
5. **记忆是否有整合策略**：超过设定 token 阈值时，是否有触发摘要压缩的机制。

## Context Rot 信号

出现以下任一信号，立即触发上下文重构：

- System prompt 超过 2000 tokens
- 长对话（>20 轮）后决策质量明显下降
- 同一约定在 prompt 中出现超过 2 次（重复是遗忘的信号）
- Agent 在新对话中"忘记"项目约定

## 输出格式

在架构文档中，上下文结构必须用以下格式显式呈现：

```
## 上下文结构

### 常驻层（System Prompt）
[内容清单，每项说明保留理由]

### 按需加载层（Skills）
[技能列表，每项说明触发条件]

### 运行时注入层
[动态字段列表，每项说明注入时机]

### 记忆层
[MEMORY.md 结构说明，压缩触发条件]

### 系统层（Hooks/Tools）
[确定性规则列表]
```
