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

### 各类型错误完整响应模板

**Transient（可重试：网络超时、限流）**

```json
{
  "error": {
    "type": "TRANSIENT_ERROR",
    "message": "下游服务暂时不可用（HTTP 503）",
    "suggestion": "等待 2 秒后重试，最多重试 3 次",
    "retryable": true,
    "retry_after_seconds": 2
  }
}
```

Agent 侧处理：指数退避重试（1s → 2s → 4s），超过 3 次停止并上报。

**Client（参数错误：格式错误、缺少必填字段）**

```json
{
  "error": {
    "type": "INVALID_PARAMETER",
    "message": "参数 date_range 格式错误：期望 ISO 8601（2024-01-01/2024-01-31），收到 '01/01/2024'",
    "suggestion": "将 date_range 改为 ISO 8601 格式后重试",
    "retryable": true,
    "invalid_fields": ["date_range"]
  }
}
```

Agent 侧处理：修正参数后立即重试（不需要等待），若仍错误则停止。

**Auth（认证/权限错误）**

```json
{
  "error": {
    "type": "PERMISSION_DENIED",
    "message": "用户 user_123 无权访问订单 order_456（属于其他用户）",
    "suggestion": "请先调用 check_user_permissions 确认权限范围，或通知用户联系管理员授权",
    "retryable": false
  }
}
```

Agent 侧处理：立即停止，不得重试，向用户说明权限不足。

**Business（业务错误：资源不存在、状态不允许）**

```json
{
  "error": {
    "type": "BUSINESS_RULE_VIOLATION",
    "message": "订单 order_789 当前状态为"已发货"，无法取消",
    "suggestion": "已发货订单只能申请退货，请改用 request_return 工具",
    "retryable": false,
    "current_state": "shipped",
    "allowed_actions": ["request_return", "track_shipment"]
  }
}
```

Agent 侧处理：根据 suggestion 调整策略，调用 allowed_actions 中的工具。

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

### 消息隔离好/坏对比

**❌ 错误做法：框架噪声透传进 tool result**

```json
{
  "status": "success",
  "data": {"order_id": "order_123", "amount": 99.00},
  "retry_count": 2,
  "session_id": "sess_abc123",
  "latency_ms": 234,
  "debug_info": "DB query: SELECT * FROM orders WHERE id=123, rows=1"
}
```

Agent 收到这个响应后会产生无用推理："这个调用重试了 2 次，是否系统不稳定？下一步是否需要换一个工具？"

**✅ 正确做法：仅返回业务语义**

```json
{
  "order_id": "order_123",
  "amount": 99.00,
  "status": "active"
}
```

**❌ 错误做法：裸异常透传**

```
Traceback (most recent call last):
  File "order_service.py", line 42, in get_order
    result = db.query(f"SELECT * FROM orders WHERE id={order_id}")
sqlalchemy.exc.OperationalError: (psycopg2.OperationalError) could not connect to server
```

**✅ 正确做法：转换为语义错误**

```json
{
  "error": {
    "type": "TRANSIENT_ERROR",
    "message": "订单服务暂时不可用",
    "suggestion": "等待 2 秒后重试",
    "retryable": true,
    "retry_after_seconds": 2
  }
}
```

### 为什么重要

框架噪声进入上下文会：
1. 消耗宝贵的 token 预算
2. 干扰 Agent 对业务信息的判断
3. 让 Agent 产生不必要的元推理（"为什么这个调用重试了 2 次？"）

---

## ACI 全维度好/坏对比速查

### A 原则：命名

| ❌ 错误 | ✅ 正确 | 问题所在 |
|--------|--------|---------|
| `db_query_v2` | `search_customer_orders` | 暴露技术实现，Agent 需要知道数据库结构 |
| `api_call_put` | `cancel_subscription` | 暴露 HTTP 方法，不是业务语义 |
| `update_status_v2` | `assign_ticket_to_agent` | 过于泛化，Agent 无法判断何时使用 |
| `util_helper` | `format_date_for_display` | 无意义名称，Agent 无从选择 |

### C 原则：描述

| ❌ 错误 | ✅ 正确 | 缺失要素 |
|--------|--------|---------|
| `"搜索文档"` | `"全文检索知识库文档片段。适用于：用户询问已有文档内容时。不适用于：创建文档或检查文档是否存在（用 check_document_exists）。返回最多 5 个片段，含 content 和 relevance_score。"` | 缺少负例、返回值说明 |
| `"获取用户信息，传入 user_id"` | `"通过用户 ID 获取用户档案。适用于：需要展示用户信息时。不适用于：查询用户权限（用 check_user_permissions）。返回 name、email、created_at。示例：user_id='user_123'"` | 缺少负例、返回结构、示例 |

### C 原则：参数

| ❌ 错误 | ✅ 正确 | 问题所在 |
|--------|--------|---------|
| `"status": {"type": "string"}` | `"status": {"type": "string", "enum": ["active", "inactive", "pending"]}` | 开放 string 导致 Agent 猜测值 |
| `{"customer_id": {}, "email": {}}` 无 required | `"required": ["customer_id"]` | Agent 不知道哪些字段必须提供 |
| `{"dt": "string"}` | `{"invoice_date": "string", "description": "发票日期，ISO 8601 格式，如 2024-01-15"}` | 缩写 + 无格式说明 |

### I 原则：错误响应

| ❌ 错误 | ✅ 正确 | 问题所在 |
|--------|--------|---------|
| `{"error": "failed"}` | `{"error": {"type": "...", "message": "...", "suggestion": "...", "retryable": ...}}` | Agent 无法判断如何恢复 |
| `{"error": "Permission denied"}` | `{"error": {"type": "PERMISSION_DENIED", "message": "无权访问...", "suggestion": "...", "retryable": false}}` | 缺少是否可重试信息 |
| 返回 HTTP 500 裸异常 | 转换为 `TRANSIENT_ERROR` 并包含 `retry_after_seconds` | 框架错误透传给 Agent |

### 返回值：结构固定

| ❌ 错误 | ✅ 正确 | 问题所在 |
|--------|--------|---------|
| 成功时返回 `{"orders": [...]}`, 失败时返回 `{"error": "..."}` 但不含订单字段 | 始终返回固定 schema，成功时 `orders` 为列表，失败时 `orders` 为 `[]` 且 `error` 字段存在 | Schema 不固定导致 Agent 解析出错 |
| 有数据时返回完整对象，无数据时返回 `null` | 有数据时返回完整对象，无数据时返回有所有字段的对象（`count: 0, items: []`） | null 返回导致 Agent 无法区分"空结果"和"调用失败" |

---

## 质量门控判定标准

`tool-design/SKILL.md` 中 11 项检查清单的判定标准和修复动作：

| 检查项 | 通过标准 | 失败时修复动作 |
|--------|---------|--------------|
| 工具名是动词短语 | 格式为 `动词_名词`，如 `search_orders`, `create_invoice` | 重命名为 `{action}_{resource}` 格式 |
| description 含正负例 | 同时包含"适用于"和"不适用于" | 补充"不适用于：{排除场景}"段落 |
| 参数有示例值 | description 或 examples 字段含具体值 | 在 description 中加"示例：{具体值}" |
| enum 替代 open string | 有限集合的参数使用 enum 类型 | 枚举所有合法值，删除 type:string |
| 返回结构固定 | 成功和失败路径的字段集相同（失败时字段为空/零值） | 重构返回值，统一 schema |
| 工具数量 ≤ 10 | 单 Agent 工具总数 ≤ 10 | 合并重叠工具 or 拆分 Agent |
| 无功能重叠工具 | 没有两个工具的适用场景重叠 | 合并为带可选参数的单一工具 |
| 无僵尸工具 | 所有工具在近期有实际调用记录 | 删除 0 调用率工具 |
| 框架状态未透传 | tool result 中无 retry_count/session_id/latency | 从返回值中删除框架信息 |
| 错误已语义化 | 错误响应含 type/message/suggestion/retryable | 实现错误转换层，拦截裸异常 |
| 日志已剥离 | tool result 中无 debug_info/log/trace | 将调试信息重定向到独立日志通道 |
