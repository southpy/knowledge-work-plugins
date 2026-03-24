---
name: tool-design
description: >
  在设计 Agent 工具链、MCP Tools、Function Calling 接口或评审工具定义时自动加载。
  触发关键词："设计工具"、"tool schema"、"function calling"、"MCP tool"、"工具链设计"、
  "工具描述怎么写"、"ACI 原则"、"工具数量"、"工具接口"。
  提供 ACI 设计原则和工具链质量校验标准，作为工具设计的强制规范。
metadata:
  version: "0.1.0"
  domain: tool-engineering
---

# Tool Design 原则

设计任何 Agent 工具链时，强制应用 ACI 原则并通过以下质量门控。

## 核心原则：少而精、描述即规范、错误可恢复、框架噪声不透传

完整规范见 `references/aci-principles.md`。

## ACI 原则速查

**A — Agent-Centric（面向 Agent 目标，不是底层 API）**
- 工具名称和参数命名面向任务语义，不是技术实现
- 一个工具完成一个 Agent 可理解的原子操作
- 不暴露底层 API 的技术复杂性给 Agent

**C — Clear Boundary（边界明确）**
- description 必须包含：适用场景 + 不适用场景（负例同样重要）
- 参数做防错设计：enum 替代 string、required 字段显式声明
- 返回值结构固定，不随条件变化

**I — Informative Error（错误可恢复）**
- 错误响应必须包含：错误类型 + 错误原因 + 修正建议
- 禁止返回裸 exception 或技术堆栈
- 区分可重试错误（网络超时）和不可重试错误（权限拒绝）

## 工具设计质量门控

在输出任何工具定义前，逐项检查：

### 接口设计检查
- [ ] 工具名称是否为动词短语（`search_documents` 而非 `docs`）？
- [ ] description 是否说明了"什么时候用"和"什么时候不用"？
- [ ] 参数是否有具体示例值（`examples` 字段或 description 内）？
- [ ] 是否有枚举约束替代开放 string（能 enum 的必须 enum）？
- [ ] 返回结构是否固定（不因分支产生不同 schema）？

### 数量约束检查
- [ ] 单 Agent 工具数是否 ≤ 10？超出则重新划分工具边界
- [ ] 是否有功能重叠的工具（同类操作合并为带参数的单一工具）？
- [ ] 是否有从未调用的工具（占用描述 token，增加选择噪声）？

### 消息隔离检查
- [ ] 框架层状态（重试计数、会话 ID、中间件状态）是否未透传给 LLM？
- [ ] 工具返回的错误是否已转化为 Agent 可理解的语义错误？
- [ ] 日志、调试信息是否已从工具返回值中剥离？

## 工具 Schema 模板

```json
{
  "name": "动词_名词",
  "description": "用于[场景]时调用。输入[参数A]和[参数B]，返回[结果结构]。不适用于[排除场景]。示例：[具体调用示例]。",
  "input_schema": {
    "type": "object",
    "properties": {
      "param_a": {
        "type": "string",
        "description": "具体说明含义和格式，提供示例值：例如 'user_123'",
        "enum": ["option1", "option2"]
      }
    },
    "required": ["param_a"]
  }
}
```

## 调试优先级

工具调用失败时，调试顺序：

1. **先检查工具 description**（80% 的选错工具来自描述不清）
2. 检查参数约束（enum 缺失导致 Agent 猜测参数值）
3. 检查返回值结构（不固定的 schema 导致解析错误）
4. 最后才怀疑模型能力

> 工具描述质量 > 模型能力 > Prompt 长度
