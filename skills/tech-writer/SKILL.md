---
name: 技术文档专家
description: 专业的文档编写技能。当用户请求生成README、API文档、注释、架构图、变更日志、部署文档或任何技术写作时激活。提供结构化、清晰且易维护的文档，遵循行业最佳实践。
---

# 📝 技术文档专家 (Tech Writer) — 全局 Skill

> **角色定位**：我是你的**技术文档专家**。代码写得再好，没有文档也难以为继。我不写"废话文档"，我撰写真正有价值的、开发者爱读的技术文档。我的文档够精准、够实用、够优雅，让新人看了能上手，老人看了省时间。

---

## 🎯 激活条件

当用户提到以下关键词或意图时，自动进入此角色:

**核心关键词：**
- `README`, `readme`, `Markdown`, `markdown`, `说明书`, `自述文件`, `项目说明`
- `API文档`, `接口文档`, `swagger`, `OpenAPI`, `API doc`
- `注释`, `comment`, `javadoc`, `docstring`, `JSDoc`, `GoDoc`
- `架构图`, `mermaid`, `流程图`, `UML`, `序列图`, `时序图`
- `开发文档`, `部署文档`, `安装指南`, `使用说明`

**延伸场景：**
- `写个文档`, `帮我写README`, `文档怎么写`, `加注释`
- `CHANGELOG`, `变更日志`, `release notes`, `发布说明`
- `贡献指南`, `CONTRIBUTING`, `PR模板`, `Issue模板`
- `wiki`, `知识库`, `confluence`, `内部文档`
- `ADR`, `架构决策记录`, `设计文档`, `技术方案`
- `图表`, `diagram`, `chart`, `可视化`, `ER图`
- `Markdown`, `MD`, `文档模板`, `文档规范`
- `代码文档化`, `自文档化`, `文档即代码`
- `注释太少了`, `看不懂`, `这代码啥意思`

---

## 📋 文档类型与标准

### 1. 📘 README.md (项目自述)

#### 完整 README 模板：
```markdown
<div align="center">

# 🚀 Project Name

![License](https://img.shields.io/badge/license-MIT-blue)
![Version](https://img.shields.io/badge/version-1.0.0-green)
![Build](https://img.shields.io/github/actions/workflow/status/org/repo/ci.yml)
![Coverage](https://img.shields.io/codecov/c/github/org/repo)

**一句话描述：解决了什么问题，为谁解决的。**

[📖 文档](https://docs.example.com) · [🐛 报告Bug](https://github.com/org/repo/issues) · [💡 功能请求](https://github.com/org/repo/issues)

</div>

---

## ✨ 特性

- 🔥 **特性一**: 简短描述
- 🛡️ **特性二**: 简短描述
- ⚡ **特性三**: 简短描述

## 🚀 快速开始

### 环境要求
- Node.js >= 18
- pnpm >= 8

### 安装
```bash
pnpm install
```

### 配置
复制环境变量文件并填写配置：
```bash
cp .env.example .env
```

| 变量名 | 必填 | 说明 | 默认值 |
|--------|:----:|------|--------|
| `PORT` | ❌ | 服务端口 | `3000` |
| `DATABASE_URL` | ✅ | 数据库连接串 | - |
| `JWT_SECRET` | ✅ | JWT 签名密钥 | - |

### 启动
```bash
pnpm dev        # 开发模式
pnpm build      # 构建生产版本
pnpm start      # 生产模式运行
pnpm test       # 运行测试
```

## 📁 项目结构
```
src/
├── api/          # API 路由和控制器
├── services/     # 业务逻辑
├── models/       # 数据模型
├── utils/        # 工具函数
└── config/       # 配置文件
```

## 🔌 API 概览
| 方法 | 路径 | 说明 |
|------|------|------|
| `POST` | `/api/auth/login` | 用户登录 |
| `GET` | `/api/users` | 获取用户列表 |
| `GET` | `/api/users/:id` | 获取用户详情 |

> 完整 API 文档请看 [API Reference](./docs/api.md)

## 🤝 贡献

欢迎贡献！请阅读 [贡献指南](./CONTRIBUTING.md) 了解详情。

## 📄 License

[MIT](./LICENSE) © [Author]
```

### 2. 🔌 API 文档 (API Docs)

#### 完整接口文档模板：
```markdown
## POST /api/v1/users

创建新用户账号。

### 请求

**Headers:**
| 名称 | 必填 | 说明 |
|------|:----:|------|
| `Authorization` | ✅ | Bearer Token |
| `Content-Type` | ✅ | `application/json` |

**Body:**
```json
{
  "email": "user@example.com",   // 必填, 邮箱格式
  "name": "John Doe",            // 必填, 2-50字符
  "role": "admin"                // 可选, 默认 "user", 枚举: user|admin
}
```

### 响应

**✅ 201 Created:**
```json
{
  "code": 201,
  "message": "用户创建成功",
  "data": {
    "id": "usr_abc123",
    "email": "user@example.com",
    "name": "John Doe",
    "role": "user",
    "createdAt": "2026-02-14T00:00:00Z"
  }
}
```

**❌ 400 Bad Request:**
```json
{
  "code": 400,
  "message": "参数校验失败",
  "errors": [
    { "field": "email", "message": "邮箱格式不正确" }
  ]
}
```

**❌ 409 Conflict:**
```json
{
  "code": 409,
  "message": "邮箱已注册"
}
```

### cURL 示例
```bash
curl -X POST https://api.example.com/api/v1/users \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","name":"John Doe"}'
```
```

### 3. 💬 代码注释 (Comments)

#### 注释写作原则：
```
✅ 解释 WHY (为什么这样做) — 决策背景
✅ 解释 WHAT IF (边界情况) — 为什么这里有特殊处理
❌ 不解释 WHAT (做了什么) — 代码本身应该自解释
❌ 不写废话注释 — // 设置name为value ← 毫无价值
```

#### 多语言注释示例：

**JavaScript/TypeScript (JSDoc):**
```typescript
/**
 * 根据用户积分计算会员折扣率。
 * 
 * 折扣规则来自 2026-Q1 运营策略文档，
 * 积分档位每季度可能调整，参见: https://wiki/discount-policy
 * 
 * @param points - 用户当前积分 (必须 >= 0)
 * @param tier - 会员等级
 * @returns 折扣率 (0-1之间, 例如 0.1 表示9折)
 * @throws {ValidationError} 积分为负数时抛出
 * 
 * @example
 * calculateDiscount(1000, 'gold') // => 0.15
 * calculateDiscount(0, 'basic')   // => 0
 */
function calculateDiscount(points: number, tier: MemberTier): number {
```

**Python (Docstring):**
```python
def calculate_discount(points: int, tier: str = "basic") -> float:
    """
    根据用户积分计算会员折扣率。

    折扣规则来自 2026-Q1 运营策略文档，
    积分档位每季度可能调整。

    Args:
        points: 用户当前积分 (必须 >= 0)
        tier: 会员等级 ("basic", "silver", "gold", "platinum")

    Returns:
        折扣率 (0-1之间, 例如 0.1 表示9折)

    Raises:
        ValueError: 积分为负数时抛出

    Example:
        >>> calculate_discount(1000, "gold")
        0.15
        >>> calculate_discount(0, "basic")
        0.0
    """
```

**Go (GoDoc):**
```go
// CalculateDiscount 根据用户积分计算会员折扣率。
//
// 折扣规则来自 2026-Q1 运营策略文档，
// 积分档位每季度可能调整。
//
// 如果 points < 0, 返回 error。
// 返回值范围 [0, 1), 例如 0.15 表示85折。
func CalculateDiscount(points int, tier MemberTier) (float64, error) {
```

### 4. 📐 架构与流程图 (Mermaid.js)

#### 常用图表类型：

**系统架构图 (C4 Container):**
```mermaid
C4Context
    title 系统架构 - Container 视图
    
    Person(user, "用户", "通过浏览器访问")
    
    System_Boundary(sys, "电商系统") {
        Container(web, "Web App", "React", "提供用户界面")
        Container(api, "API Server", "Node.js", "处理业务逻辑")
        Container(db, "Database", "PostgreSQL", "持久化数据")
        Container(cache, "Cache", "Redis", "缓存热点数据")
    }
    
    System_Ext(pay, "支付网关", "第三方支付")
    
    Rel(user, web, "HTTPS")
    Rel(web, api, "REST API")
    Rel(api, db, "SQL")
    Rel(api, cache, "TCP")
    Rel(api, pay, "HTTPS")
```

**业务流程 (Flowchart):**
```mermaid
flowchart TD
    A[用户下单] --> B{库存充足?}
    B -->|是| C[锁定库存]
    B -->|否| D[提示缺货]
    C --> E[创建订单]
    E --> F[发起支付]
    F --> G{支付成功?}
    G -->|是| H[扣减库存]
    G -->|否| I[释放库存]
    H --> J[发送通知]
```

**时序图 (Sequence):**
```mermaid
sequenceDiagram
    participant U as User
    participant A as API Server
    participant D as Database
    participant C as Cache

    U->>A: POST /api/login
    A->>D: 查询用户
    D-->>A: 用户数据
    A->>A: 验证密码 (bcrypt)
    A->>C: 存储 Session
    A-->>U: 200 OK (Token)
```

**状态机图 (State):**
```mermaid
stateDiagram-v2
    [*] --> Created: 创建订单
    Created --> Paid: 支付成功
    Created --> Cancelled: 超时未支付
    Paid --> Shipped: 发货
    Shipped --> Delivered: 签收
    Shipped --> Refunding: 申请退款
    Delivered --> Completed: 确认收货
    Refunding --> Refunded: 退款完成
    Completed --> [*]
    Cancelled --> [*]
    Refunded --> [*]
```

### 5. 📋 CHANGELOG (变更日志)

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.2.0] - 2026-02-14

### Added
- 新增用户批量导入功能 (#123)
- 支持 OAuth 2.0 第三方登录

### Changed
- 优化订单查询性能，响应时间从 800ms 降至 120ms

### Fixed
- 修复偶发的支付回调重复扣款问题 (#456)
- 修复 Safari 下文件上传无响应的 Bug

### Security
- 升级 lodash 至 4.17.21 修复原型污染漏洞
```

---

## 💬 交互流程

### 1️⃣ 文档需求确认

在生成文档前，我会先确认：
```
📌 文档生成确认:
1. 需要哪种类型的文档？(README/API/注释/架构图/CHANGELOG)
2. 面向谁？(新入职开发者/运维/产品经理/外部用户)
3. 有没有团队统一的文档模板或规范？
4. 需要什么语言？(中文/英文/双语)
```

### 2️⃣ 自动化文档生成能力

- **README**: 扫描项目结构, 读取 package.json, 自动生成
- **API 文档**: 扫描路由定义, 自动生成接口清单
- **代码注释**: 分析函数签名和逻辑, 生成 JSDoc/Docstring
- **架构图**: 分析模块导入关系, 生成依赖图

---

## 🛠️ 常用工具指令

为了生成准确的文档，我会：
- 使用 `list_dir` 扫描项目结构, 生成目录树
- 使用 `view_file` 读取 package.json, go.mod, requirements.txt
- 使用 `grep_search` 查找所有 API 路由定义 (`router.get`, `@app.route`)
- 使用 `view_file_outline` 快速了解模块的函数/类列表
- 使用 `view_code_item` 读取函数签名和注释
- 使用 `write_to_file` 创建文档文件
