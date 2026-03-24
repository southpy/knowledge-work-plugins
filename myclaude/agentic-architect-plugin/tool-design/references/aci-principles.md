# ACI 原则 — 完整规范

## 来源与背景

ACI（Agent-Centric Interface）是针对 LLM Tool Calling 场景提炼的工具设计原则，核心洞察：
**工具的调用者是 LLM，不是人。** 因此工具的描述质量直接影响 Agent 的决策质量。

---

## A — Agent-Centric（面向 Agent 目标）

### 原则
工具的命名、描述和参数设计，必须面向 Agent 能理解的**任务语义**，而非底层技术实现。

### 正确做法
```
工具名：search_customer_orders
参数：customer_id, status_filter, date_range
```
Agent 看到名称就知道：这个工具搜索客户订单。

### 错误做法
```
工具名：db_query_v2
参数：table, where_clause, limit
```
Agent 需要知道数据库结构才能使用。这是给开发者的接口，不是给 Agent 的接口。

### 封装规则
- 把 SQL/API/SDK 调用封装到工具内部
- 工具只暴露业务语义参数
- 复杂查询逻辑在工具实现层处理，不让 Agent 拼 SQL

---

## C — Clear Boundary（边界明确）

### description 必须包含的四要素

1. **适用场景**（什么时候调用）
2. **不适用场景**（什么时候不要调用）— 这条最常被忽略，也最重要
3. **参数语义**（每个参数代表什么，期望格式是什么）
4. **返回值结构**（返回什么，Agent 怎么用这个返回值）

### 示例对比

**❌ 弱描述**：
```
"description": "搜索文档"
```

**✅ 强描述**：
```
"description": "在知识库中全文检索文档片段。适用于：用户询问已有文档的具体内容时。
不适用于：创建新文档、修改文档、或检查文档是否存在（用 check_document_exists）。
返回最多 5 个相关片段，每个片段包含 content、source_id 和 relevance_score。
示例查询：'退款政策'、'API 限流规则'。"
```

### 参数防错设计

**能用 enum 就不用 string**：
```json
❌ "status": {"type": "string", "description": "状态：active/inactive/pending"}
✅ "status": {"type": "string", "enum": ["active", "inactive", "pending"]}
```

**required 显式声明**（不要依赖 default）：
```json
"required": ["customer_id", "action_type"]
```

**参数命名**：snake_case，动词+名词，避免缩写

---

## I — Informative Error（错误可恢复）

### 错误响应必须包含三要素

```json
{
  "error": {
    "type": "PERMISSION_DENIED",           // 错误类型（枚举值）
    "message": "用户 user_123 无权访问订单 order_456",  // 人/Agent 可读原因
    "suggestion": "请先调用 check_user_permissions 确认权限，或联系管理员授权",  // 修正建议
    "retryable": false                     // 是否可重试
  }
}
```

### 错误分类

| 类型 | 特征 | Agent 应对策略 |
|------|------|----------------|
| 可重试（Transient） | 网络超时、限流、临时不可用 | 指数退避重试，最多 3 次 |
| 参数错误（Client） | 参数格式错误、缺少必填字段 | 修正参数后重试 |
| 权限错误（Auth） | 认证失败、权限不足 | 停止，上报人工 |
| 业务错误（Business） | 资源不存在、状态不允许 | 根据 suggestion 调整策略 |

### 禁止的错误响应形式
```
❌ 返回裸 Python traceback
❌ 返回 "Error: NullPointerException at line 42"
❌ 返回空响应（导致 Agent 无法判断是成功还是失败）
❌ 返回 "操作失败" 无任何上下文
```

---

## 工具数量控制

### 约束基准
- 单 Agent 工具集：推荐 5-8 个，硬上限 10 个
- 超过 10 个：强制重新划分 Agent 边界，考虑子 Agent 分工

### 工具数量膨胀的信号
- 出现多个"差不多"的工具（`get_user` + `fetch_user` + `retrieve_user`）
- 存在从未被调用的工具
- Agent 经常选错工具

### 处置方法
1. **合并重叠工具**：`get_user(id)` + `get_user_by_email(email)` → `find_user(id?, email?)`
2. **删除僵尸工具**：统计调用频次，0 调用率工具直接删除
3. **拆分 Agent**：功能超出单 Agent 语义范围时，引入专职子 Agent

---

## 消息隔离原则

### 框架状态 ≠ LLM 上下文

框架层管理的信息不得透传进 LLM 消息流：

| 框架层信息 | 错误做法 | 正确做法 |
|-----------|----------|----------|
| 重试计数 | 在 tool result 中附加 "retry_count: 2" | 框架内部维护，不透传 |
| 会话 ID | 每条消息附加 session metadata | 框架路由，LLM 无感 |
| 中间件延迟 | "响应耗时 234ms" 写入 tool result | 写入独立监控日志 |
| 调试日志 | `console.log` 输出混入返回值 | 单独日志通道 |

### 为什么重要

框架噪声进入上下文会：
1. 消耗宝贵的 token 预算
2. 干扰 Agent 对业务信息的判断
3. 让 Agent 产生不必要的元推理（"为什么这个调用重试了 2 次？"）
