# 🚀 Antigravity Global Skills (反重力全局开发技能包)

这是专为 **Antigravity 开发工具** 打造的全局技能增强包。集成后，你的 AI 助手将进化为拥有 **10 大全能专家** 的超级开发团队。只需一键安装，即可永久拥有。

---

## 🌟 包含的 Skills (The A-Team)

| Skill 名称 | 角色定位 | 核心超能力与触发词 |
| :--- | :--- | :--- |
| **🏆 超级Git管理大师** | 仓库管理员 | **触发**: `git`, `commit`, `push`, `pull`<br>**能力**: 自动诊断仓库状态，生成规范提交信息，安全拉取/推送，智能解决冲突建议。 |
| **🚀 超级后端开发** | 后端专家 | **触发**: `backend`, `Java`, `Go`, `Redis`<br>**能力**: 高并发架构设计，数据库调优，分布式系统解决方案，高性能 API 开发。 |
| **✨ 超级前端开发** | 前端专家 | **触发**: `frontend`, `React`, `Vue`, `动画`<br>**能力**: 极致性能优化 (FPS/LCP)，复杂交互实现，WebGL/Three.js 动效，像素级 UI 还原。 |
| **🏛️ 全栈架构师** | 架构顾问 | **触发**: `全栈`, `DevOps`, `K8s`, `系统设计`<br>**能力**: 前后端 + 基础设施全局规划，技术选型，技术债务治理，微服务拆分。 |
| **💾 全栈数据库专家** | 数据库DBA | **触发**: `database`, `SQL`, `MongoDB`, `索引`<br>**能力**: Schema 设计，慢查询优化，索引调优，高可用架构，数据迁移方案。 |
| **🔍 代码审查专家** | 代码审查员 | **触发**: `review`, `CR`, `优化`, `检查`<br>**能力**: 5D 标准审查 (安全/性能/架构/规范/测试性)，杜绝"屎山"代码。 |
| **📝 技术文档专家** | 文档工程师 | **触发**: `README`, `API文档`, `注释`<br>**能力**: 自动生成标准化 README、API 文档、Mermaid 架构图和代码注释。 |
| **🧪 测试驱动大师** | 测试工程师 | **触发**: `test`, `TDD`, `coverage`<br>**能力**: 自动编写全覆盖单元测试、集成测试和 E2E 测试，提升代码健壮性。 |
| **🏗️ 系统架构师** | 脚手架专家 | **触发**: `架构`, `structure`, `设计模式`<br>**能力**: 项目目录结构规划，设计模式建议，技术栈选型与初始化。 |
| **🐞 调试侦探** | 问题排查员 | **触发**: `debug`, `报错`, `log`, `修复`<br>**能力**: 使用 OODA 循环深度排查疑难杂症，通过日志和堆栈定位根因。 |

---

## ⚡ 一键远程安装 (推荐)

打开 **PowerShell**，粘贴以下命令即可全自动安装最新版本：

```powershell
irm https://raw.githubusercontent.com/geekoutnet/antigravity-global-skills/master/install.ps1 | iex
```

> **它会自动完成以下所有步骤：**
> 1. 🌐 从 GitHub Releases 获取最新版本的 zip 包
> 2. 📦 下载并解压到 `~/.gemini/skills/` 目录
> 3. ⚙️ 动态扫描所有 Skill 并更新 `~/.gemini/GEMINI.md` 配置
> 4. 🏷️ 记录当前版本号，支持增量更新

**更新到最新版？再执行一次同样的命令即可！** 脚本会自动判断版本，跳过不必要的下载。

---

## 📦 本地手动安装

### Windows 用户

1.  [点击下载最新 Release 包](https://github.com/geekoutnet/antigravity-global-skills/releases/latest)
2.  解压后进入文件夹，右键点击 `install.ps1`，选择 **"使用 PowerShell 运行"**。
3.  脚本会自动：
    *   将 `skills` 复制到你的全局配置目录 (`~/.gemini/skills`)。
    *   自动更新 `~/.gemini/GEMINI.md` 配置文件。
4.  重启 Antigravity (或 VS Code) 即可生效！

### Mac / Linux 用户

如有需求，可以手动将 `skills` 目录复制到 `~/.gemini/skills`，并将 `install.ps1` 中的配置段落手动复制到 `~/.gemini/GEMINI.md` 末尾。

---

## 🔄 自动发布机制

本项目配置了 **GitHub Actions** 自动发布：

- **每次推送**到 `main`/`master` 分支时，自动打包 `skills/` 和 `install.ps1` 为 zip
- **自动创建 Release** 并上传 zip 到 Assets，版本号格式为 `v年.月.日-短SHA`
- **支持手动触发**：在 Actions 页面点击 "Run workflow" 即可手动发布

---

## 🛠️ 使用方法

安装完成后，在 Antigravity 的任意对话中，只需提及相关关键词即可召唤专家。

**示例：**
> "帮我 review 一下这段代码，看看有没有性能问题"  👉 **代码审查专家** 登场
> "我要做一个高并发秒杀系统，用什么数据库？" 👉 **全栈数据库专家** 登场
> "帮我提交一下代码" 👉 **超级Git管理大师** 登场

---

## 🤝 贡献指南

欢迎提交 PR 添加更多实用的 Skills！

1. 在 `skills/` 目录下创建新的 Skill 文件夹。
2. 编写 `SKILL.md`，包含 `name`, `description` 和详细的 Prompt。
3. 提交 Pull Request，合并后会自动发布新版本。
