# ========================================================
# Antigravity Global Skills - Claude Code 一键安装器 (Windows)
# ========================================================
# 适用于 Claude Code CLI (https://docs.anthropic.com/en/docs/claude-code)
# Claude Code 通过以下方式读取自定义指令:
#   - ~/.claude/CLAUDE.md     → 全局自定义指令
#   - ~/.claude/commands/     → 全局自定义斜杠命令
#   - ~/.claude/settings.json → 全局设置
#
# 支持两种模式:
#   远程一键安装 (直连):  irm https://raw.githubusercontent.com/geekoutnet/antigravity-global-skills/master/install-claude.ps1 | iex
#   远程一键安装 (代理1): irm https://gh-raw.988669.xyz/anti-skills/install-claude.ps1 | iex
#   远程一键安装 (代理2): irm https://gh-raw.966788.xyz/anti-skills/install-claude.ps1 | iex
#   本地安装:             右键 install-claude.ps1 → 使用 PowerShell 运行
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

# --- 路径定义 (Claude Code 专用) ---
$globalConfigDir = "$env:USERPROFILE\.claude"
$claudeMdFile    = "$globalConfigDir\CLAUDE.md"
$commandsDir     = "$globalConfigDir\commands"
$settingsFile    = "$globalConfigDir\settings.json"
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

    $tempDir  = Join-Path $env:TEMP "antigravity-claude-install"
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

        # 缓存 skills 原始文件
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
# 固定默认头部内容 (CLAUDE.md 格式)
# ========================================================
$DEFAULT_HEADER = @"
# Antigravity Global Skills — Claude Code 全局指令

> 本文件由 Antigravity Global Skills 自动生成，为 Claude Code 提供全局自定义指令。
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
        Trigger = "当用户提到 git、提交、commit、push、pull、分支、branch、merge、合并、rebase、冲突、tag、回滚、revert、reset、stash、cherry-pick、diff、日志、log 等 Git 相关操作时"
        Role = "以专业的超级Git管理大师身份，提供安全、规范的Git操作服务"
    }
    "code-reviewer" = @{
        Icon = "🔍"; Title = "代码审查专家"
        Trigger = "当用户提到 review、审查、代码检查、CR、code review、帮我看看、代码质量、best practice 等代码审查相关意图时"
        Role = "以专业的代码审查专家身份，提供六维度深度代码分析报告"
    }
    "tech-writer" = @{
        Icon = "📝"; Title = "技术文档专家"
        Trigger = "当用户提到 README、API文档、注释、mermaid、CHANGELOG 等文档相关意图时"
        Role = "以专业的技术文档专家身份，生成结构化、清晰且易维护的文档"
    }
    "test-master" = @{
        Icon = "🧪"; Title = "测试驱动大师"
        Trigger = "当用户提到 test、测试、TDD、单元测试、Jest、Playwright、coverage 等测试相关意图时"
        Role = "以专业的测试驱动大师身份，编写可靠、全覆盖的测试用例"
    }
    "architect" = @{
        Icon = "🏗️"; Title = "系统架构师"
        Trigger = "当用户提到 架构、目录结构、设计模式、技术选型、DDD、Monorepo 等架构相关意图时"
        Role = "以专业的系统架构师身份，提供架构设计与技术选型建议"
    }
    "debug-detective" = @{
        Icon = "🐞"; Title = "调试侦探"
        Trigger = "当用户提到 debug、报错、bug、修复、不工作了、白屏、超时 等调试相关意图时"
        Role = "以专业的调试侦探身份，提供全链路分层诊断和根因分析"
    }
    "super-backend" = @{
        Icon = "🚀"; Title = "超级后端开发"
        Trigger = "当用户提到 后端、backend、API开发、微服务、高并发、写个接口 等后端相关意图时"
        Role = "以超级后端开发专家身份，提供高性能企业级后端解决方案"
    }
    "super-frontend" = @{
        Icon = "✨"; Title = "超级前端开发"
        Trigger = "当用户提到 前端、React、Vue、CSS、动画、组件、写个页面 等前端相关意图时"
        Role = "以超级前端开发专家身份，提供极致用户体验的前端方案"
    }
    "fullstack-architect" = @{
        Icon = "🏛️"; Title = "全栈架构师"
        Trigger = "当用户提到 全栈、系统设计、技术选型、微服务拆分、Serverless 等全栈相关意图时"
        Role = "以全栈架构师身份，提供从前端到后端到基础设施的全局规划"
    }
    "database-expert" = @{
        Icon = "💾"; Title = "全栈数据库专家"
        Trigger = "当用户提到 数据库、MySQL、Redis、慢查询、索引、建表 等数据库相关意图时"
        Role = "以全栈数据库专家身份，提供专业的数据库设计和SQL优化方案"
    }
    "security-guard" = @{
        Icon = "🛡️"; Title = "安全卫士"
        Trigger = "当用户提到 安全、漏洞、XSS、JWT、OWASP、加密 等安全相关意图时"
        Role = "以安全防护专家身份，提供代码级安全分析和加固方案"
    }
    "perf-optimizer" = @{
        Icon = "⚡"; Title = "性能优化师"
        Trigger = "当用户提到 性能、慢查询、Lighthouse、压测、打开太慢了 等性能相关意图时"
        Role = "以性能优化专家身份，提供全链路性能诊断和调优方案"
    }
    "devops-engineer" = @{
        Icon = "🐳"; Title = "DevOps工程师"
        Trigger = "当用户提到 Docker、K8s、CI/CD、部署、Nginx、上线 等运维相关意图时"
        Role = "以DevOps工程师身份，提供全流程自动化部署方案"
    }
    "prompt-engineer" = @{
        Icon = "🤖"; Title = "AI提示词工程师"
        Trigger = "当用户提到 prompt、AI、LLM、RAG、Agent、CoT 等AI相关意图时"
        Role = "以AI提示词专家身份，提供高质量提示词设计和Agent编排方案"
    }
    "api-designer" = @{
        Icon = "📐"; Title = "API设计师"
        Trigger = "当用户提到 API设计、RESTful、GraphQL、接口规范、设计个接口 等API相关意图时"
        Role = "以API设计专家身份，提供高质量的API设计方案和接口规范"
    }
    "refactor-master" = @{
        Icon = "🔄"; Title = "重构大师"
        Trigger = "当用户提到 重构、代码异味、技术债务、屎山、Clean Code、SOLID 等重构相关意图时"
        Role = "以重构专家身份，提供安全、渐进式的重构策略"
    }
}

# ========================================================
# 函数: 构建并更新 CLAUDE.md
#   Claude Code 的 CLAUDE.md 是全局指令文件
#   将核心准则 + 技能索引写入 CLAUDE.md
#   同时将每个 SKILL.md 生成为独立的自定义斜杠命令
# ========================================================
function Update-ClaudeMd {
    Write-Host "`n⚙️  正在构建 Claude Code 配置..." -ForegroundColor Yellow

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false

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

    # ==============================
    # PART 1: 构建 CLAUDE.md
    # ==============================
    Write-Host "`n📄 [1/3] 构建 CLAUDE.md 全局指令..." -ForegroundColor Cyan

    $content = $DEFAULT_HEADER

    # 添加技能配置索引段落
    $content += "`r`n`r`n---`r`n`r`n## 全局 Skills 技能配置`r`n`r`n"
    $content += "以下技能以自定义斜杠命令的方式可用。你可以在 Claude Code 中输入 ``/user:技能名`` 来激活对应技能。`r`n"
    $content += "同时，当检测到对应的触发条件时，也应主动切换到该专家角色执行任务。`r`n"

    # 技能索引表
    $content += "`r`n| 技能 | 斜杠命令 | 角色 | 触发条件 |`r`n"
    $content += "| :--- | :--- | :--- | :--- |`r`n"

    foreach ($folder in $skillFolders) {
        $name = $folder.Name
        if ($skillMeta.ContainsKey($name)) {
            $meta = $skillMeta[$name]
            $content += "| $($meta.Icon) $($meta.Title) | ``/user:$name`` | $($meta.Role) | $($meta.Trigger) |`r`n"
        }
    }

    # 添加技能完整内容到 CLAUDE.md (Claude Code 也支持在 CLAUDE.md 中写长指令)
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

        $skillContent = [System.IO.File]::ReadAllText($skillMdPath, $utf8NoBom)

        # 移除 YAML frontmatter
        $skillContent = $skillContent -replace '(?ms)^---\s*\n.*?\n---\s*\n', ''
        $skillContent = $skillContent.Trim()

        if ($skillMeta.ContainsKey($name)) {
            $meta = $skillMeta[$name]
            $icon  = $meta.Icon
            $title = $meta.Title
        } else {
            $icon  = "🔧"
            $title = $name
        }

        $content += "`r`n---`r`n`r`n"
        $content += "<!-- SKILL: $name -->`r`n"
        $content += $skillContent + "`r`n"

        $skillCount++
        Write-Host "   ✅ $icon $title" -ForegroundColor Green
    }

    # 写入 CLAUDE.md
    [System.IO.File]::WriteAllText($claudeMdFile, $content, $utf8NoBom)
    Write-Host "📊 已整合 $skillCount 个技能到 CLAUDE.md" -ForegroundColor Cyan

    # ==============================
    # PART 2: 生成自定义斜杠命令
    # ==============================
    Write-Host "`n🔧 [2/3] 生成自定义斜杠命令 (~/.claude/commands/)..." -ForegroundColor Cyan

    if (-not (Test-Path $commandsDir)) {
        New-Item -ItemType Directory -Force -Path $commandsDir | Out-Null
        Write-Host "✅ 创建 commands 目录: $commandsDir" -ForegroundColor Green
    }

    $cmdCount = 0
    foreach ($folder in $skillFolders) {
        $name = $folder.Name
        $skillMdPath = Join-Path $folder.FullName "SKILL.md"

        if (-not (Test-Path $skillMdPath)) { continue }

        $skillContent = [System.IO.File]::ReadAllText($skillMdPath, $utf8NoBom)

        # 移除 YAML frontmatter
        $skillContent = $skillContent -replace '(?ms)^---\s*\n.*?\n---\s*\n', ''
        $skillContent = $skillContent.Trim()

        # 写入为斜杠命令文件: ~/.claude/commands/<name>.md
        $cmdFile = Join-Path $commandsDir "$name.md"
        [System.IO.File]::WriteAllText($cmdFile, $skillContent, $utf8NoBom)

        if ($skillMeta.ContainsKey($name)) {
            $meta = $skillMeta[$name]
            Write-Host "   📌 /user:$name → $($meta.Icon) $($meta.Title)" -ForegroundColor Gray
        } else {
            Write-Host "   📌 /user:$name" -ForegroundColor Gray
        }
        $cmdCount++
    }

    Write-Host "📊 已生成 $cmdCount 个自定义斜杠命令" -ForegroundColor Cyan

    # ==============================
    # PART 3: 确保 settings.json 基本配置
    # ==============================
    Write-Host "`n⚙️  [3/3] 检查 settings.json..." -ForegroundColor Cyan

    if (Test-Path $settingsFile) {
        Write-Host "✅ settings.json 已存在，保留用户自定义配置。" -ForegroundColor Gray
    } else {
        # 创建基础 settings.json
        $defaultSettings = @{
            "permissions" = @{
                "allow" = @()
                "deny"  = @()
            }
            "env" = @{}
        }
        $settingsJson = $defaultSettings | ConvertTo-Json -Depth 4
        [System.IO.File]::WriteAllText($settingsFile, $settingsJson, $utf8NoBom)
        Write-Host "✅ 已创建基础 settings.json" -ForegroundColor Green
    }
}

# ========================================================
# 主流程
# ========================================================
Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host "  🚀 Antigravity Global Skills — Claude Code 安装器" -ForegroundColor DarkCyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  📋 目标平台: Claude Code CLI" -ForegroundColor White
Write-Host "  📂 配置目录: $globalConfigDir" -ForegroundColor White
Write-Host "  📄 全局指令: CLAUDE.md" -ForegroundColor White
Write-Host "  🔧 斜杠命令: commands/" -ForegroundColor White
Write-Host ""

# 检查 / 创建 .claude 目录
if (-not (Test-Path $globalConfigDir)) {
    Write-Host "📁 创建 Claude Code 配置目录: $globalConfigDir" -ForegroundColor Yellow
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

# 构建 Claude Code 配置
Update-ClaudeMd

# 完成
Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  🎉 Claude Code 技能包安装完成！" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  📂 配置目录:     $globalConfigDir" -ForegroundColor White
Write-Host "  📄 全局指令:     $claudeMdFile" -ForegroundColor White
Write-Host "  🔧 斜杠命令目录: $commandsDir" -ForegroundColor White
Write-Host "  ⚙️  全局设置:     $settingsFile" -ForegroundColor White
Write-Host "  📦 技能缓存:     $skillsCacheDir" -ForegroundColor White
$currentVer = Get-InstalledVersion
if ($currentVer) {
    Write-Host "  🏷️  当前版本:     $currentVer" -ForegroundColor White
}
Write-Host ""
Write-Host "  💡 使用方式:" -ForegroundColor Yellow
Write-Host "     1. Claude Code 启动时会自动加载 ~/.claude/CLAUDE.md" -ForegroundColor White
Write-Host "     2. 在对话中输入 /user:<技能名> 可手动激活技能" -ForegroundColor White
Write-Host "     3. 提到触发关键词时，技能会自动激活" -ForegroundColor White
Write-Host ""
Write-Host "  📌 可用的斜杠命令:" -ForegroundColor Yellow

# 列出所有可用的斜杠命令
if (Test-Path $commandsDir) {
    $cmdFiles = Get-ChildItem -Path $commandsDir -Filter "*.md"
    foreach ($cmd in $cmdFiles) {
        $cmdName = [System.IO.Path]::GetFileNameWithoutExtension($cmd.Name)
        if ($skillMeta.ContainsKey($cmdName)) {
            $meta = $skillMeta[$cmdName]
            Write-Host "     /user:$cmdName  →  $($meta.Icon) $($meta.Title)" -ForegroundColor Gray
        } else {
            Write-Host "     /user:$cmdName" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "  👉 请重启 Claude Code 以使配置生效。" -ForegroundColor Yellow
Write-Host ""

# 如果是交互式运行，等待用户按键
if ($Host.Name -eq "ConsoleHost" -and -not $env:ANTIGRAVITY_SILENT) {
    Write-Host "按任意键退出..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
