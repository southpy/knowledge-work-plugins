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

工具调用失败时，按以下顺序诊断（80% 的问题在前两步解决）：

**第 1 步：检查 description**（选错工具的首要原因）
- 诊断：description 是否同时说明了"用"和"不用"的场景？
- 信号：Agent 在两个相似工具间反复切换 → 负例缺失
- 修复：补充"不适用于：{具体排除场景}"

**第 2 步：检查参数约束**（参数格式错误的根因）
- 诊断：有限集合的参数是否使用了 enum？required 是否显式声明？
- 信号：Agent 传入了不合法的参数值（如 `status: "Active"` 而非 `"active"`）
- 修复：将 `type: string` 改为 `enum: [...]`，明确 required 字段

**第 3 步：检查返回值结构**（解析错误的根因）
- 诊断：成功和失败路径的返回 schema 是否一致？错误是否已语义化？
- 信号：Agent 无法判断调用是否成功，或错误后不知道下一步
- 修复：统一返回 schema，将裸异常转换为结构化错误（见 references/aci-principles.md）

**第 4 步：检查工具数量和重叠**
- 诊断：工具总数是否 ≤ 10？是否有功能相近的工具？
- 信号：Agent 随机选择工具，准确率随工具数增加而下降
- 修复：合并重叠工具，删除 0 调用率工具，必要时拆分 Agent

> 完整判定标准和修复动作见 `references/aci-principles.md` 质量门控部分
