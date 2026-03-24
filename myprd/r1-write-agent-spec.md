## 一、`/write-spec` 本身需要什么输入

PM 插件的 feature-spec skill 能生成包含问题陈述、用户故事、MoSCoW 需求优先级、成功指标和范围管理的结构化 PRD。

当你触发 `/write-spec` 时，Claude 会通过一系列追问来收集信息。Claude 会询问目标用户、约束条件和成功指标，然后生成包含问题陈述、用户故事、需求、成功指标和开放问题的完整 PRD。

所以 `/write-spec` 本质上是一个**结构化采访 + 生成**流程。`/synthesize-research` 的输出提供了"问题空间"的理解，但 `/write-spec` 还需要以下这些**它不会自动获取的信息**：

## 二、必须补齐的六项依赖

### 依赖 1：Harness 四象限定位（最关键）

这是你的原创框架，原生插件里没有。你在 `/synthesize-research` 里已经约束它输出了"哪些环节适合 Agent 接管"的判断，但 `/write-spec` 需要更精确的输入：这些被判定适合 Agent 的环节，在四象限里具体落在哪个位置？

具体做法：在调 `/write-spec` 之前，手动在 Cowork 里跑一轮对话（或者如果你创建了自定义的 Harness 评估 skill，直接调用），把 synthesize-research 输出的每个"候选 Agent 接管环节"打分。**只有落在右上角（目标明确 + 验证可自动化）的环节才进入 PRD 的核心范围**。左上角的环节作为"需要 HITL 的限制条件"写入 PRD，右下角作为"风险项"标注。

### 依赖 2：技术约束与现有系统边界

`/synthesize-research` 输出的是业务洞察，不包含技术栈信息。但 Agent PRD 必须知道：现有系统有哪些 API 可调用？数据在哪里？延迟和吞吐量的硬约束是什么？

具体做法：如果你的 Cowork 已连接了项目追踪器（Linear、Jira 等），连接你的项目管理和沟通工具可以获得最佳体验。没有它们的话，需要手动提供上下文。如果没连接，你需要手动把技术约束作为文本输入。建议准备一份简要的"系统现状清单"：已有 API 列表、数据源、关键延迟约束、安全合规要求。

### 依赖 3：可量化的验收标准（Harness 的核心）

原生 `/write-spec` 会生成"成功指标"，但那是产品层面的（如 DAU、转化率）。Agent PRD 需要的是**Agent 层面的验收标准**：任务成功率目标、幻觉容忍度、响应时间 SLA、需要人工审查的比例。

具体做法：在调用 `/write-spec` 时，在你的补充说明里明确要求——"成功指标必须包含 Agent 任务成功率、端到端延迟、人工干预率、误判率（false positive rate）的目标值"。

### 依赖 4：HITL（Human-in-the-Loop）节点设计

哪些决策 Agent 可以自主执行，哪些必须等人确认？这直接决定了系统的吞吐量天花板——你笔记里写的"吞吐量天花板是人的审查速度"。

具体做法：从 `/synthesize-research` 的机会点列表中，按风险等级（如果决策出错，后果有多严重？）分级。高风险决策 = 强制 HITL，中风险 = 异步审查，低风险 = 自主执行 + 事后抽检。

### 依赖 5：工具链草案

Agent 需要调用哪些工具？你的 tool 设计原则说"少而精"，所以不是列出所有可能的 API，而是**只列出完成核心流程最少需要的工具集**，并给每个工具标注：输入/输出格式、幂等性、错误恢复方式。

### 依赖 6：Connector 可用性检查

Skills 通过 `~~category` 占位符引用工具类别（如 `~~literature`、`~~crm`），`.mcp.json` 文件将这些解析为实际的 MCP 服务器。如果你的 Agent 需要读写某个数据源，但 Cowork 里还没配好对应的 connector，那 `/write-spec` 生成的 PRD 会包含无法实际执行的工具引用。

具体做法：在 Cowork 的 Customize 面板里确认当前已连接的 connectors 列表，把"尚未连接但 Agent 必须使用的"作为 PRD 里的"前置依赖"章节。

## 三、实操 SOP：从 synthesize-research 到 write-spec

**第一步：输出物整理**。把 `/synthesize-research` 的结果文件保存到 Cowork 的工作目录。确认它包含：主题提取、用户画像、机会点、Agent 适配判断。

**第二步：Harness 评估**。对每个候选 Agent 环节运行四象限打分。如果你有自定义 skill，直接在对话中触发；如果没有，把四象限框架作为上下文粘贴进去，要求 Claude 逐项评估。

**第三步：准备技术输入**。创建或粘贴一份简要文档，包含：现有系统 API 列表、数据源位置、安全/合规硬约束、团队技术栈偏好。

**第四步：调用 `/write-spec`**。在触发时，显式追加约束条件。例如：

> `/write-spec` 
> 基于已完成的 synthesize-research 输出（见工作目录 research-synthesis.md），为 [业务场景名] 编写 Agent PRD。
> 
> 额外要求：
> 1. 必须包含 Harness 评估结论（见 harness-assessment.md）
> 2. 成功指标必须包含 Agent 任务成功率、端到端延迟、人工干预率的量化目标
> 3. 每个 Agent 工作流步骤标注 HITL 等级（自主/异步审查/强制等待）
> 4. 工具链章节按 ACI 原则设计：单一职责、含正反用例、含错误恢复策略
> 5. 标注所有尚未连接的 connector 为"前置依赖"

**第五步：输出评审**。用你的反模式清单（8 条）逐条 review 生成的 PRD。如果你建了 `/review-agent` 命令，直接调用。

## 四、需要特别关注的陷阱

**陷阱 1：`/write-spec` 的 feature-spec skill 是为传统软件功能设计的**。feature-spec skill 使用问题陈述、用户故事、MoSCoW 需求和成功指标来编写 PRD。它的默认模板不包含 Agent 特有的章节（Harness、HITL、工具链、上下文设计）。你需要通过显式约束来"改造"它的输出结构，或者**直接 fork feature-spec skill 的 markdown 文件，在里面加上 Agent PRD 的专用章节模板**。这才是最彻底的解法。

**陷阱 2：Connector 缺失时的静默失败**。如果 skill 里引用了 `~~project_tracker` 但你没配 Linear/Jira 的 connector，Claude 不会报错，而是默默跳过从项目追踪器拉取数据的步骤。你可能拿到一份看起来完整但缺少关键上下文的 PRD。**解法：在调用前确认 connector 状态，或在约束条件里加一句"如果任何数据源不可用，请显式标注为[数据缺失]"。**

**陷阱 3：synthesize-research 的输出 ≠ 上下文自动继承**。Cowork 的文件系统是持久的，但 Claude 的上下文窗口不是。如果你在一个新会话里调 `/write-spec`，它不会自动"记得" `/synthesize-research` 的输出。**你必须显式指向文件路径**，让 Claude 在执行 `/write-spec` 时先读取那份文件。

**陷阱 4：产品级指标 vs Agent 级指标混淆**。原生 `/write-spec` 倾向于生成 DAU、NPS 这类产品指标。但 Agent PRD 更需要的是运行指标——Pass@k（能力边界）、Pass^k（上线稳定性）、幻觉率、工具调用成功率。你必须在约束条件里强制要求这两层指标都有。

## 五、长期建议：fork 并定制

这些插件是通用的起点。当你为公司的实际工作方式定制它们时，它们会变得更有用：将你的术语、组织结构和流程添加到 skill 文件中。

最值得投入的一步是：**fork product-management 插件的 `feature-spec` skill，创建一个 `agent-spec` skill**。在里面内嵌你的 Harness 四象限框架、上下文分层原则、tool 设计原则和反模式检查清单。这样以后每次调 `/write-spec`（或你自定义的 `/write-agent-spec`），这些框架会自动作为 Claude 的 skill 被激活，不需要每次手动粘贴约束条件。