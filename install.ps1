
# ========================================================
# Antigravity Global Skills - Auto Installer (Windows)
# ========================================================

$ErrorActionPreference = "Stop"

# --- 1. 定义路径 ---
$globalConfigDir = "$env:USERPROFILE\.gemini"
$geminiFile = "$globalConfigDir\GEMINI.md"
$targetSkillsDir = "$globalConfigDir\skills"
$sourceSkillsDir = "$PSScriptRoot\skills"

Write-Host "`n🚀 开始安装 Antigravity Global Skills..." -ForegroundColor Cyan

# --- 2. 检查 .gemini 目录是否存在 ---
if (-not (Test-Path $globalConfigDir)) {
    Write-Host "❌ 未找到全局配置目录: $globalConfigDir" -ForegroundColor Red
    Write-Host "请先运行一次 Antigravity 工具以自动生成配置文件。"
    exit 1
}

# --- 3. 复制 Skills 文件夹 ---
Write-Host "📦正在部署 Skills..." -ForegroundColor Yellow
if (-not (Test-Path $targetSkillsDir)) {
    New-Item -ItemType Directory -Force -Path $targetSkillsDir | Out-Null
    Write-Host "✅ Created directory: $targetSkillsDir" -ForegroundColor Green
}

# 复制所有子文件夹
if (Test-Path $sourceSkillsDir) {
    Copy-Item -Path "$sourceSkillsDir\*" -Destination $targetSkillsDir -Recurse -Force
    Write-Host "✅ Skills copied to: $targetSkillsDir" -ForegroundColor Green
} else {
    Write-Host "❌ 错误: 当前目录下找不到 'skills' 文件夹！请确认安装包完整。" -ForegroundColor Red
    exit 1
}

# --- 4. 自动配置 GEMINI.md ---
Write-Host "⚙️ 正在配置 GEMINI.md..." -ForegroundColor Yellow

if (-not (Test-Path $geminiFile)) {
    # 如果文件不存在，创建一个基本的
    Set-Content -Path $geminiFile -Value "**trigger: always_on**`r`n**alwaysApply: true**`r`n`r`n## Global Config"
    Write-Host "✅ Created new GEMINI.md" -ForegroundColor Green
}

$currentContent = Get-Content -Path $geminiFile -Raw
$marker = "## **全局 Skills 技能配置**"

# 检查是否已经配置过
if ($currentContent -match [regex]::Escape($marker)) {
    Write-Host "ℹ️ GEMINI.md 似乎已经包含 Skills 配置，跳过更新以避免重复。" -ForegroundColor Yellow
    Write-Host "👉 如果需要强制更新配置，请手动编辑或删除 GEMINI.md 中的旧配置段落。" -ForegroundColor Gray
} else {
    # 追加新的配置块
    $newConfigBlock = @"

$marker

### 🏆 超级Git管理大师
- **技能路径**: `~/.gemini/skills/git-master/SKILL.md`
- **触发条件**: 当用户提到 git、提交、commit、push、pull、拉取、推送、分支、branch、merge、合并、rebase、冲突、tag、回滚、revert、reset、stash、cherry-pick、diff、日志、log 等 Git 相关操作时
- **角色说明**: 以专业的超级Git管理大师身份，提供安全、规范的Git操作服务
- **使用方式**: 检测到 Git 相关意图时，先读取 `~/.gemini/skills/git-master/SKILL.md` 获取完整操作规范，然后按照规范执行操作

### 🔍 代码审查专家
- **技能路径**: `~/.gemini/skills/code-reviewer/SKILL.md`
- **触发条件**: 当用户提到 review、审查、代码检查、CR、优化、改进、refactor、重构建议、性能分析、安全检查、漏洞扫描、代码质量、规范检查 等相关意图时
- **角色说明**: 以专业的代码审查专家身份，提供深度、多维度的代码分析报告
- **使用方式**: 检测到相关意图时，先读取 `~/.gemini/skills/code-reviewer/SKILL.md` 获取完整操作规范，然后按照规范执行操作

### 📝 技术文档专家
- **技能路径**: `~/.gemini/skills/tech-writer/SKILL.md`
- **触发条件**: 当用户提到 README、说明书、API文档、接口文档、注释、comment、架构图、流程图、开发文档 等相关意图时
- **角色说明**: 以专业的技术文档专家身份，生成结构化、清晰且易维护的文档
- **使用方式**: 检测到相关意图时，先读取 `~/.gemini/skills/tech-writer/SKILL.md` 获取完整操作规范，然后按照规范执行操作

### 🧪 测试驱动大师
- **技能路径**: `~/.gemini/skills/test-master/SKILL.md`
- **触发条件**: 当用户提到 test、测试、TDD、单元测试、unit tests、e2e、integration tests、集成测试、Jest、Pytest、coverage、覆盖率 等相关意图时
- **角色说明**: 以专业的测试驱动大师身份，编写可靠、全覆盖的测试用例
- **使用方式**: 检测到相关意图时，先读取 `~/.gemini/skills/test-master/SKILL.md` 获取完整操作规范，然后按照规范执行操作

### 🏗️ 系统架构师
- **技能路径**: `~/.gemini/skills/architect/SKILL.md`
- **触发条件**: 当用户提到 架构、structure、目录结构、scaffold、设计模式、design pattern、技术选型、stack、重构、refactor、解耦 等相关意图时
- **角色说明**: 以专业的系统架构师身份，提供项目初始化、技术选型或架构重构建议
- **使用方式**: 检测到相关意图时，先读取 `~/.gemini/skills/architect/SKILL.md` 获取完整操作规范，然后按照规范执行操作

### 🐞 调试侦探
- **技能路径**: `~/.gemini/skills/debug-detective/SKILL.md`
- **触发条件**: 当用户提到 debug、调试、报错、error、Exception、崩溃、fix、修复、bug、日志、log、排查、troubleshoot 等相关意图时
- **角色说明**: 以专业的调试侦探身份，提供深度日志分析和假设验证法排查思路
- **使用方式**: 检测到相关意图时，先读取 `~/.gemini/skills/debug-detective/SKILL.md` 获取完整操作规范，然后按照规范执行操作

### 🚀 超级后端开发
- **技能路径**: `~/.gemini/skills/super-backend/SKILL.md`
- **触发条件**: 当用户提到 后端、backend、Java、Go、Python、Node.js、微服务、分布式、高并发、数据库、Redis、中间件 等相关意图时
- **角色说明**: 以全能型超级后端开发专家身份，提供高性能、高可用的后端解决方案
- **使用方式**: 检测到相关意图时，先读取 `~/.gemini/skills/super-backend/SKILL.md` 获取完整操作规范，然后按照规范执行操作

### ✨ 超级前端开发
- **技能路径**: `~/.gemini/skills/super-frontend/SKILL.md`
- **触发条件**: 当用户提到 前端、frontend、React、Vue、Angular、CSS、性能优化、动画、WebGL、Three.js、Tailwind 等相关意图时
- **角色说明**: 以全能型超级前端开发专家身份，提供极致用户体验和性能优化的前端方案
- **使用方式**: 检测到相关意图时，先读取 `~/.gemini/skills/super-frontend/SKILL.md` 获取完整操作规范，然后按照规范执行操作

### 🏛️ 全栈架构师
- **技能路径**: `~/.gemini/skills/fullstack-architect/SKILL.md`
- **触发条件**: 当用户提到 全栈、fullstack、架构、architecture、系统设计、技术选型、云原生、K8s、DevOps、CI/CD 等相关意图时
- **角色说明**: 以顶级全栈架构师身份，提供全局视野的系统规划和技术治理建议
- **使用方式**: 检测到相关意图时，先读取 `~/.gemini/skills/fullstack-architect/SKILL.md` 获取完整操作规范，然后按照规范执行操作

### 💾 全栈数据库专家
- **技能路径**: `~/.gemini/skills/database-expert/SKILL.md`
- **触发条件**: 当用户提到 数据库、database、MySQL、PostgreSQL、Redis、MongoDB、SQL优化、索引、分库分表 等相关意图时
- **角色说明**: 以全栈数据库专家身份，提供专业的数据库设计、优化和运维建议
- **使用方式**: 检测到相关意图时，先读取 `~/.gemini/skills/database-expert/SKILL.md` 获取完整操作规范，然后按照规范执行操作

"@
    Add-Content -Path $geminiFile -Value $newConfigBlock
    Write-Host "✅ 成功向 GEMINI.md 添加了 Skills 配置！" -ForegroundColor Green
}

Write-Host "`n🎉 安装完成！" -ForegroundColor Cyan
Write-Host "现在，你的 Antigravity 工具已经获得了 10 位顶级技术专家的加持。" -ForegroundColor Cyan
Write-Host "请重启工具或重新加载窗口以确保配置生效。" -ForegroundColor Cyan
Write-Host "按任意键退出..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
