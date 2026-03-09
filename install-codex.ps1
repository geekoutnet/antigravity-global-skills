# ========================================================
# Antigravity Global Skills - Codex CLI 一键安装器 (Windows)
# ========================================================
# 适用于 OpenAI Codex CLI (https://github.com/openai/codex)
# Codex 通过 ~/.codex/AGENTS.md 读取全局自定义指令
#
# 支持两种模式:
#   远程一键安装 (直连):  irm https://raw.githubusercontent.com/geekoutnet/antigravity-global-skills/master/install-codex.ps1 | iex
#   远程一键安装 (代理1): irm https://gh-raw.988669.xyz/anti-skills/install-codex.ps1 | iex
#   远程一键安装 (代理2): irm https://gh-raw.966788.xyz/anti-skills/install-codex.ps1 | iex
#   本地安装:             右键 install-codex.ps1 → 使用 PowerShell 运行
# ========================================================

$ErrorActionPreference = "Stop"

# --- 编码设置 (关键！防止中文 Windows 上输出 GBK 乱码) ---
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8'
$PSDefaultParameterValues['Add-Content:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- 配置 ---
$REPO_OWNER = "geekoutnet"
$REPO_NAME  = "antigravity-global-skills"
$GITHUB_API = "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest"

# --- 代理配置 (国内加速) ---
$PROXY_PREFIXES = @(
    ""                                  # 直连 (无前缀)
    "https://edge-proxy.988669.xyz/"    # 代理线路1
    "https://edge-proxy.966788.xyz/"    # 代理线路2
)

# --- 路径定义 (Codex CLI 专用) ---
$globalConfigDir = "$env:USERPROFILE\.codex"
$agentsMdFile    = "$globalConfigDir\AGENTS.md"
$skillsCacheDir  = "$globalConfigDir\skills-cache"  # 缓存 skills 原始文件

# ========================================================
# 函数: 获取已安装版本
# ========================================================
function Get-InstalledVersion {
    $versionFile = "$globalConfigDir\.skills-version"
    if (Test-Path $versionFile) {
        return (Get-Content $versionFile -Raw -Encoding UTF8).Trim()
    }
    return $null
}

# ========================================================
# 函数: 保存版本号
# ========================================================
function Save-InstalledVersion {
    param([string]$Version)
    $versionFile = "$globalConfigDir\.skills-version"
    [System.IO.File]::WriteAllText($versionFile, $Version, (New-Object System.Text.UTF8Encoding $false))
}

# ========================================================
# 函数: 从 GitHub Release 下载最新版本
# ========================================================
function Install-FromRemote {
    Write-Host "`n🌐 远程安装模式 - 正在从 GitHub 获取最新版本..." -ForegroundColor Cyan

    $release = $null
    $headers = @{ "Accept" = "application/vnd.github.v3+json"; "User-Agent" = "Antigravity-Installer" }
    $usedProxy = ""

    foreach ($proxy in $PROXY_PREFIXES) {
        $apiUrl = "${proxy}${GITHUB_API}"
        $label = if ($proxy) { "代理 ($proxy)" } else { "直连" }
        try {
            Write-Host "   🔗 尝试 ${label}..." -ForegroundColor Gray -NoNewline
            $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 15
            $usedProxy = $proxy
            Write-Host " ✅" -ForegroundColor Green
            break
        } catch {
            Write-Host " ❌" -ForegroundColor Red
        }
    }

    if (-not $release) {
        Write-Host "❌ 所有线路均无法连接 GitHub API" -ForegroundColor Red
        Write-Host "💡 提示: 请检查网络连接，或手动下载 Release 包安装。" -ForegroundColor Yellow
        return $false
    }

    $latestTag  = $release.tag_name
    $releaseName = $release.name
    $installedVersion = Get-InstalledVersion

    Write-Host "📌 最新版本: $latestTag ($releaseName)" -ForegroundColor White

    # 版本比对
    if ($installedVersion -eq $latestTag -and (Test-Path $skillsCacheDir)) {
        Write-Host "✅ 当前已经是最新版本 ($latestTag)，无需更新。" -ForegroundColor Green
        return $true
    }

    if ($installedVersion -eq $latestTag -and -not (Test-Path $skillsCacheDir)) {
        Write-Host "⚠️  版本号匹配但缓存目录缺失，将重新部署..." -ForegroundColor Yellow
    }

    if ($installedVersion) {
        Write-Host "⬆️  发现新版本! $installedVersion → $latestTag" -ForegroundColor Yellow
    } else {
        Write-Host "🆕 首次安装，版本: $latestTag" -ForegroundColor Yellow
    }

    # 查找 zip 资源
    $zipAsset = $release.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
    if (-not $zipAsset) {
        Write-Host "❌ Release 中没有找到 zip 文件！" -ForegroundColor Red
        return $false
    }

    $downloadUrl = "${usedProxy}$($zipAsset.browser_download_url)"
    $zipName     = $zipAsset.name
    $fileSize    = [math]::Round($zipAsset.size / 1MB, 2)
    Write-Host "📦 下载: $zipName ($fileSize MB)" -ForegroundColor White

    $tempDir  = Join-Path $env:TEMP "antigravity-codex-install"
    $zipPath  = Join-Path $tempDir $zipName
    $extractDir = Join-Path $tempDir "extracted"

    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

    try {
        Write-Host "⬇️  正在下载..." -ForegroundColor Yellow -NoNewline
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -TimeoutSec 120
        $ProgressPreference = 'Continue'
        Write-Host " 完成!" -ForegroundColor Green

        Write-Host "📂 正在解压..." -ForegroundColor Yellow -NoNewline
        Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
        Write-Host " 完成!" -ForegroundColor Green

        # 查找解压后的 skills 目录
        $extractedSkills = Get-ChildItem -Path $extractDir -Directory -Recurse -Filter "skills" | Select-Object -First 1
        if (-not $extractedSkills) {
            $extractedSkills = Get-Item "$extractDir\skills" -ErrorAction SilentlyContinue
        }

        if (-not $extractedSkills) {
            Write-Host "❌ zip 中未找到 skills 目录结构！" -ForegroundColor Red
            return $false
        }

        # 缓存 skills 原始文件到 ~/.codex/skills-cache/
        Deploy-SkillsCache -SourcePath $extractedSkills.FullName

        # 保存版本号
        Save-InstalledVersion -Version $latestTag
        Write-Host "💾 版本记录已更新: $latestTag" -ForegroundColor Gray

    } catch {
        Write-Host "`n❌ 下载或解压失败: $_" -ForegroundColor Red
        return $false
    } finally {
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    return $true
}

# ========================================================
# 函数: 从本地 skills/ 目录安装
# ========================================================
function Install-FromLocal {
    param([string]$LocalSkillsPath)

    Write-Host "`n📁 本地安装模式 - 使用本地 skills 目录" -ForegroundColor Cyan
    Deploy-SkillsCache -SourcePath $LocalSkillsPath
}

# ========================================================
# 函数: 缓存 Skills 原始文件
# ========================================================
function Deploy-SkillsCache {
    param([string]$SourcePath)

    Write-Host "📦 正在缓存 Skills 原始文件..." -ForegroundColor Yellow

    if (-not (Test-Path $skillsCacheDir)) {
        New-Item -ItemType Directory -Force -Path $skillsCacheDir | Out-Null
        Write-Host "✅ 创建缓存目录: $skillsCacheDir" -ForegroundColor Green
    }

    Copy-Item -Path "$SourcePath\*" -Destination $skillsCacheDir -Recurse -Force

    $skillFolders = Get-ChildItem -Path $skillsCacheDir -Directory
    $skillCount = $skillFolders.Count
    Write-Host "✅ Skills 已缓存 ($skillCount 个技能模块):" -ForegroundColor Green
    foreach ($skill in $skillFolders) {
        Write-Host "   📘 $($skill.Name)" -ForegroundColor Gray
    }
}

# ========================================================
# 固定默认头部内容 (AGENTS.md 格式)
# ========================================================
$DEFAULT_HEADER = @"
# Antigravity Global Skills — Codex CLI Agent Instructions

> 本文件由 Antigravity Global Skills 自动生成，为 OpenAI Codex CLI 提供全局指令配置。
> 请勿手动修改自动生成的技能配置段落。

---

## 核心行为准则

- **语言要求**：所有回复、思考过程及任务清单，均须使用 **中文**。
- **简洁至上**：恪守 KISS 原则，崇尚简洁与可维护性，避免过度工程化。
- **深度分析**：立足于第一性原理 (First Principles Thinking) 剖析问题。
- **事实为本**：以事实为最高准则。若有任何谬误，坦率斧正。
- 每次都用审视的目光，仔细看我输入的潜在问题，指出问题，并给出明显在我思考框架之外的建议。
- 如果我说的太离谱了，直接骂回来，帮我瞬间清醒。

## 开发工作流

- **渐进式开发**：通过多轮次迭代，明确并实现需求。在着手任何设计或编码工作前，必须完成前期调研并厘清所有疑点。
- **结构化流程**：严格遵循"构思方案 → 提请审核 → 分解为具体任务"的作业顺序。
- Implementation Plan, Task List and The entire process must be written in Chinese.
"@

# ========================================================
# 技能说明的元数据映射表
# ========================================================
$skillMeta = @{
    "git-master" = @{
        Icon = "🏆"; Title = "超级Git管理大师"
        Trigger = "当用户提到 git、提交、commit、push、pull、分支、branch、merge、合并、rebase、冲突、tag、回滚、revert、reset、stash、cherry-pick、diff、日志、log、帮我提交、代码推上去、切分支、合过来、gitignore、blame 等 Git 相关操作时"
        Role = "以专业的超级Git管理大师身份，提供安全、规范的Git操作服务"
    }
    "code-reviewer" = @{
        Icon = "🔍"; Title = "代码审查专家"
        Trigger = "当用户提到 review、审查、代码检查、CR、code review、帮我看看、优化、改进、性能分析、安全检查、漏洞扫描、代码质量、规范检查、code smell、linter、eslint、best practice 等相关意图时"
        Role = "以专业的代码审查专家身份，提供安全、性能、架构、可读性、可测试性、可维护性六维度深度代码分析报告"
    }
    "tech-writer" = @{
        Icon = "📝"; Title = "技术文档专家"
        Trigger = "当用户提到 README、说明书、API文档、接口文档、注释、comment、JSDoc、docstring、架构图、mermaid、流程图、UML、时序图、开发文档、CHANGELOG、变更日志、贡献指南、Markdown 等相关意图时"
        Role = "以专业的技术文档专家身份，生成结构化、清晰且易维护的文档，包含README、API文档、代码注释、Mermaid架构图和变更日志"
    }
    "test-master" = @{
        Icon = "🧪"; Title = "测试驱动大师"
        Trigger = "当用户提到 test、测试、TDD、BDD、单元测试、unit test、e2e、端到端、集成测试、Jest、Vitest、Pytest、Playwright、Cypress、coverage、覆盖率、mock、fixture、snapshot、flaky test 等相关意图时"
        Role = "以专业的测试驱动大师身份，精通测试金字塔策略，编写可靠、全覆盖的单元/集成/E2E测试用例"
    }
    "architect" = @{
        Icon = "🏗️"; Title = "系统架构师"
        Trigger = "当用户提到 架构、structure、目录结构、scaffold、脚手架、设计模式、design pattern、技术选型、stack、重构、refactor、解耦、DDD、领域驱动、Monorepo、Clean Architecture、ADR、C4模型、怎么组织代码 等相关意图时"
        Role = "以专业的系统架构师身份，基于C4模型和ADR决策记录，提供项目初始化、技术选型或架构重构建议"
    }
    "debug-detective" = @{
        Icon = "🐞"; Title = "调试侦探"
        Trigger = "当用户提到 debug、调试、报错、error、Exception、崩溃、crash、fix、修复、bug、日志、log、排查、troubleshoot、不工作了、白屏、500、超时、timeout、卡住了、数据不对、偶发、为什么 等相关意图时"
        Role = "以专业的调试侦探身份，采用OODA循环和科学假设验证法，提供全链路分层诊断和根因分析"
    }
    "super-backend" = @{
        Icon = "🚀"; Title = "超级后端开发"
        Trigger = "当用户提到 后端、backend、服务端、API开发、Java、Go、Python、Node.js、Rust、微服务、分布式、高并发、Redis、消息队列、Kafka、Spring、NestJS、FastAPI、Gin、写个接口、写个服务、登录注册、熔断限流 等相关意图时"
        Role = "以全能型超级后端开发专家身份，精通Java/Go/Python/Node.js/Rust，提供高性能、高可用、高扩展的企业级后端解决方案"
    }
    "super-frontend" = @{
        Icon = "✨"; Title = "超级前端开发"
        Trigger = "当用户提到 前端、frontend、UI、React、Vue、Angular、Svelte、Next.js、TypeScript、CSS、Tailwind、动画、WebGL、Three.js、组件、写个页面、样式、布局、响应式、暗黑模式、状态管理、Vite、Storybook、SEO 等相关意图时"
        Role = "以全能型超级前端开发专家身份，精通三大框架和Web Vitals优化，提供极致用户体验和性能优化的前端方案"
    }
    "fullstack-architect" = @{
        Icon = "🏛️"; Title = "全栈架构师"
        Trigger = "当用户提到 全栈、fullstack、系统设计、System Design、技术选型、云原生、K8s、微服务拆分、Monolith、SOA、事件驱动、Service Mesh、Serverless、CAP、高并发系统、系统怎么设计、扛不住了、怎么扩展 等相关意图时"
        Role = "以顶级全栈架构师身份，具备上帝视角，提供从前端到后端到基础设施的全局系统规划和技术治理建议"
    }
    "database-expert" = @{
        Icon = "💾"; Title = "全栈数据库专家"
        Trigger = "当用户提到 数据库、database、MySQL、PostgreSQL、Redis、MongoDB、Elasticsearch、TiDB、SQL优化、慢查询、索引、分库分表、ORM、Prisma、表结构、建表、查询太慢了、连接池、死锁、数据迁移 等相关意图时"
        Role = "以全栈数据库专家身份，精通RDBMS/NoSQL/NewSQL，提供专业的数据库设计、SQL优化、高可用架构和数据迁移方案"
    }
    "security-guard" = @{
        Icon = "🛡️"; Title = "安全卫士"
        Trigger = "当用户提到 安全、security、漏洞、vulnerability、XSS、CSRF、SQL注入、认证、授权、JWT、OAuth、OWASP、加密、密钥管理、依赖审计、CORS、CSP、限流防刷、日志脱敏、GDPR、安全吗、会不会被攻击 等相关意图时"
        Role = "以全方位安全防护专家身份，实施零信任和纵深防御理念，提供代码级安全分析、OWASP防御和安全加固方案"
    }
    "perf-optimizer" = @{
        Icon = "⚡"; Title = "性能优化师"
        Trigger = "当用户提到 性能、performance、慢查询、内存泄漏、Lighthouse、Web Vitals、FPS、延迟、吞吐量、QPS、压测、profiling、火焰图、打开太慢了、包太大了、并发上不去、CPU高、wrk、k6、benchmark 等相关意图时"
        Role = "以全栈性能优化专家身份，用数据说话，提供从前端渲染到后端服务到数据库的全链路性能精准诊断和调优方案"
    }
    "devops-engineer" = @{
        Icon = "🐳"; Title = "DevOps工程师"
        Trigger = "当用户提到 DevOps、运维、部署、deploy、Docker、容器、K8s、Kubernetes、CI/CD、流水线、GitHub Actions、Terraform、Ansible、Nginx、监控、Prometheus、Grafana、云服务、AWS、怎么部署、上线、SSL、蓝绿部署、ArgoCD、GitOps 等相关意图时"
        Role = "以全能DevOps工程师身份，提供从容器化构建到CI/CD流水线到监控告警的全流程自动化方案"
    }
    "prompt-engineer" = @{
        Icon = "🤖"; Title = "AI提示词工程师"
        Trigger = "当用户提到 提示词、prompt、Prompt Engineering、AI、LLM、大模型、GPT、Claude、Gemini、RAG、向量数据库、Agent、智能体、function calling、微调、CoT、思维链、MCP、LangChain、Cursor Rules、SKILL.md、AI效果不好 等相关意图时"
        Role = "以专业AI提示词与Agent编排专家身份，提供基于COSTAR公式的高质量提示词设计、RAG系统架构和多Agent编排方案"
    }
    "api-designer" = @{
        Icon = "📐"; Title = "API设计师"
        Trigger = "当用户提到 API设计、RESTful、GraphQL、gRPC、OpenAPI、Swagger、接口规范、API版本管理、接口文档、endpoint、设计个接口、错误码、分页、webhook、API Gateway、tRPC、联调、mock 等相关意图时"
        Role = "以专业API设计与治理专家身份，提供高质量的RESTful/GraphQL/gRPC API设计方案和接口规范"
    }
    "refactor-master" = @{
        Icon = "🔄"; Title = "重构大师"
        Trigger = "当用户提到 重构、refactor、代码异味、code smell、技术债务、tech debt、遗留代码、legacy、屎山、烂代码、Clean Code、SOLID、模块化拆分、代码太乱了、改不动了、太复杂了、耦合太严重、圈复杂度 等相关意图时"
        Role = "以代码重构与技术债务治理专家身份，提供安全、渐进式的重构策略和实施方案"
    }
    "windows-shell" = @{
        Icon = "🛡️"; Title = "Windows Shell 兼容性守卫"
        Trigger = "【全局自动生效 alwaysApply】在 Windows 系统上执行任何 Shell 命令时始终激活。禁止使用 && 连接符、禁止生成 BOM 编码文件、禁止 bash 特有语法"
        Role = "以 Windows Shell 兼容性守卫身份，自动拦截并修正所有不兼容 PowerShell 5.x 的命令语法和编码问题"
    }
}

# ========================================================
# 函数: 构建并更新 AGENTS.md
#   Codex CLI 的 AGENTS.md 是一个扁平化的 Markdown 文件
#   将所有 SKILL.md 的内容整合到一个文件中
# ========================================================
function Update-AgentsMd {
    Write-Host "`n⚙️  正在构建 AGENTS.md 配置..." -ForegroundColor Yellow

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false

    # --- 构建完整的 AGENTS.md 内容 ---
    $content = $DEFAULT_HEADER

    # 添加技能配置索引段落
    $content += "`r`n`r`n---`r`n`r`n## 全局 Skills 技能配置`r`n`r`n"
    $content += "以下技能会根据用户的意图自动激活。当检测到对应触发条件时，切换到该专家角色执行任务。`r`n"

    # --- 扫描已缓存的技能目录 ---
    if (-not (Test-Path $skillsCacheDir)) {
        Write-Host "⚠️  技能缓存目录不存在: $skillsCacheDir，跳过技能配置。" -ForegroundColor Yellow
        return
    }

    $skillFolders = Get-ChildItem -Path $skillsCacheDir -Directory | Sort-Object Name

    if ($skillFolders.Count -eq 0) {
        Write-Host "⚠️  未找到任何技能模块，跳过技能配置。" -ForegroundColor Yellow
        return
    }

    # --- 生成技能索引表 ---
    $content += "`r`n| 技能 | 角色 | 触发条件 |`r`n"
    $content += "| :--- | :--- | :--- |`r`n"

    foreach ($folder in $skillFolders) {
        $name = $folder.Name
        if ($skillMeta.ContainsKey($name)) {
            $meta = $skillMeta[$name]
            $content += "| $($meta.Icon) $($meta.Title) | $($meta.Role) | $($meta.Trigger) |`r`n"
        }
    }

    # --- 将每个 SKILL.md 的完整内容追加到 AGENTS.md ---
    $content += "`r`n---`r`n`r`n## 技能详细指令`r`n`r`n"
    $content += "> 以下是每个技能的完整操作规范。当对应技能被激活时，严格遵循该技能的指令执行。`r`n"

    $skillCount = 0
    foreach ($folder in $skillFolders) {
        $name = $folder.Name
        $skillMdPath = Join-Path $folder.FullName "SKILL.md"

        if (-not (Test-Path $skillMdPath)) {
            Write-Host "   ⚠️  跳过 $name (缺少 SKILL.md)" -ForegroundColor Yellow
            continue
        }

        # 读取 SKILL.md 内容
        $skillContent = [System.IO.File]::ReadAllText($skillMdPath, $utf8NoBom)

        # 移除 YAML frontmatter (---...---)
        $skillContent = $skillContent -replace '(?ms)^---\s*\n.*?\n---\s*\n', ''
        $skillContent = $skillContent.Trim()

        # 获取元数据
        if ($skillMeta.ContainsKey($name)) {
            $meta = $skillMeta[$name]
            $icon  = $meta.Icon
            $title = $meta.Title
        } else {
            $icon  = "🔧"
            $title = $name
        }

        # 追加到内容
        $content += "`r`n---`r`n`r`n"
        $content += "<!-- SKILL: $name -->`r`n"
        $content += $skillContent + "`r`n"

        $skillCount++
        Write-Host "   ✅ $icon $title" -ForegroundColor Green
    }

    # --- 写入 AGENTS.md ---
    [System.IO.File]::WriteAllText($agentsMdFile, $content, $utf8NoBom)

    Write-Host ""
    Write-Host "📊 已整合 $skillCount 个技能到 AGENTS.md" -ForegroundColor Cyan
}

# ========================================================
# 主流程
# ========================================================
Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  🚀 Antigravity Global Skills — Codex CLI 安装器" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""
Write-Host "  📋 目标平台: OpenAI Codex CLI" -ForegroundColor White
Write-Host "  📂 配置目录: $globalConfigDir" -ForegroundColor White
Write-Host "  📄 配置文件: AGENTS.md" -ForegroundColor White
Write-Host ""

# 检查 / 创建 .codex 目录
if (-not (Test-Path $globalConfigDir)) {
    Write-Host "📁 创建 Codex 配置目录: $globalConfigDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $globalConfigDir | Out-Null
    Write-Host "✅ 目录已创建" -ForegroundColor Green
}

# 判断运行模式: 本地 or 远程
$localSkillsDir = if ($PSScriptRoot) { Join-Path $PSScriptRoot "skills" } else { $null }

if ($localSkillsDir -and (Test-Path $localSkillsDir)) {
    Install-FromLocal -LocalSkillsPath $localSkillsDir
} else {
    $success = Install-FromRemote
    if (-not $success) {
        Write-Host "`n❌ 安装失败！请检查网络连接或手动下载安装。" -ForegroundColor Red
        Write-Host "📎 手动下载: https://github.com/$REPO_OWNER/$REPO_NAME/releases/latest" -ForegroundColor Gray
        Write-Host "按任意键退出..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

# 构建 AGENTS.md
Update-AgentsMd

# 完成
Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  🎉 Codex CLI 技能包安装完成！" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  📂 配置目录:   $globalConfigDir" -ForegroundColor White
Write-Host "  📄 指令文件:   $agentsMdFile" -ForegroundColor White
Write-Host "  📦 技能缓存:   $skillsCacheDir" -ForegroundColor White
$currentVer = Get-InstalledVersion
if ($currentVer) {
    Write-Host "  🏷️  当前版本:   $currentVer" -ForegroundColor White
}
Write-Host ""
Write-Host "  💡 Codex CLI 会自动读取 ~/.codex/AGENTS.md 全局指令。" -ForegroundColor Yellow
Write-Host "  👉 请重启 Codex CLI 以使配置生效。" -ForegroundColor Yellow
Write-Host ""

# 如果是交互式运行，等待用户按键
if ($Host.Name -eq "ConsoleHost" -and -not $env:ANTIGRAVITY_SILENT) {
    Write-Host "按任意键退出..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
