# ========================================================
# Antigravity Global Skills - 智能安装器 (Windows)
# ========================================================
# 支持两种模式:
#   远程一键安装: irm https://raw.githubusercontent.com/geekoutnet/antigravity-global-skills/master/install.ps1 | iex
#   本地安装:     右键 install.ps1 → 使用 PowerShell 运行
# ========================================================

$ErrorActionPreference = "Stop"

# --- 编码设置 (关键！防止中文 Windows 上输出 GBK 乱码) ---
# PowerShell 5.x 默认使用系统本地编码 (中文=GBK)，必须强制 UTF-8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8'
$PSDefaultParameterValues['Add-Content:Encoding'] = 'utf8'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- 配置 ---
$REPO_OWNER = "geekoutnet"
$REPO_NAME  = "antigravity-global-skills"
$GITHUB_API = "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest"

# --- 路径定义 ---
$globalConfigDir = "$env:USERPROFILE\.gemini"
$geminiFile      = "$globalConfigDir\GEMINI.md"
$targetSkillsDir = "$globalConfigDir\skills"

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
    # 使用 .NET 方法写入 UTF-8 无 BOM (PowerShell 5.x 的 -Encoding UTF8 会加 BOM)
    [System.IO.File]::WriteAllText($versionFile, $Version, (New-Object System.Text.UTF8Encoding $false))
}

# ========================================================
# 函数: 从 GitHub Release 下载最新版本
# ========================================================
function Install-FromRemote {
    Write-Host "`n🌐 远程安装模式 - 正在从 GitHub 获取最新版本..." -ForegroundColor Cyan

    # 获取最新 Release 信息
    try {
        $headers = @{ "Accept" = "application/vnd.github.v3+json"; "User-Agent" = "Antigravity-Installer" }
        $release = Invoke-RestMethod -Uri $GITHUB_API -Headers $headers -TimeoutSec 30
    } catch {
        Write-Host "❌ 无法连接 GitHub API: $_" -ForegroundColor Red
        Write-Host "💡 提示: 如果网络受限，请手动下载 Release 包安装。" -ForegroundColor Yellow
        return $false
    }

    $latestTag  = $release.tag_name
    $releaseName = $release.name
    $installedVersion = Get-InstalledVersion

    Write-Host "📌 最新版本: $latestTag ($releaseName)" -ForegroundColor White

    # 版本比对
    if ($installedVersion -eq $latestTag) {
        Write-Host "✅ 当前已经是最新版本 ($latestTag)，无需更新。" -ForegroundColor Green
        return $true
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

    $downloadUrl = $zipAsset.browser_download_url
    $zipName     = $zipAsset.name
    $fileSize    = [math]::Round($zipAsset.size / 1MB, 2)
    Write-Host "📦 下载: $zipName ($fileSize MB)" -ForegroundColor White

    # 下载到临时目录
    $tempDir  = Join-Path $env:TEMP "antigravity-skills-install"
    $zipPath  = Join-Path $tempDir $zipName
    $extractDir = Join-Path $tempDir "extracted"

    # 清理旧的临时文件
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

    try {
        # 下载 zip
        Write-Host "⬇️  正在下载..." -ForegroundColor Yellow -NoNewline
        $ProgressPreference = 'SilentlyContinue'  # 加速下载 (关闭进度条)
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -TimeoutSec 120
        $ProgressPreference = 'Continue'
        Write-Host " 完成!" -ForegroundColor Green

        # 解压
        Write-Host "📂 正在解压..." -ForegroundColor Yellow -NoNewline
        Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
        Write-Host " 完成!" -ForegroundColor Green

        # 查找解压后的 skills 目录
        $extractedSkills = Get-ChildItem -Path $extractDir -Directory -Recurse -Filter "skills" | Select-Object -First 1
        if (-not $extractedSkills) {
            # skills 可能在顶层
            $extractedSkills = Get-Item "$extractDir\skills" -ErrorAction SilentlyContinue
        }

        if (-not $extractedSkills) {
            Write-Host "❌ zip 中未找到 skills 目录结构！" -ForegroundColor Red
            return $false
        }

        # 部署 Skills
        Deploy-Skills -SourcePath $extractedSkills.FullName

        # 保存版本号
        Save-InstalledVersion -Version $latestTag
        Write-Host "💾 版本记录已更新: $latestTag" -ForegroundColor Gray

    } catch {
        Write-Host "`n❌ 下载或解压失败: $_" -ForegroundColor Red
        return $false
    } finally {
        # 清理临时文件
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
    Deploy-Skills -SourcePath $LocalSkillsPath
}

# ========================================================
# 函数: 部署 Skills 到目标目录
# ========================================================
function Deploy-Skills {
    param([string]$SourcePath)

    Write-Host "📦 正在部署 Skills..." -ForegroundColor Yellow

    # 确保目标目录存在
    if (-not (Test-Path $targetSkillsDir)) {
        New-Item -ItemType Directory -Force -Path $targetSkillsDir | Out-Null
        Write-Host "✅ 创建目录: $targetSkillsDir" -ForegroundColor Green
    }

    # 复制所有技能模块
    Copy-Item -Path "$SourcePath\*" -Destination $targetSkillsDir -Recurse -Force
    
    # 统计已部署的技能
    $skillFolders = Get-ChildItem -Path $targetSkillsDir -Directory
    $skillCount = $skillFolders.Count
    Write-Host "✅ Skills 已部署 ($skillCount 个技能模块):" -ForegroundColor Green
    foreach ($skill in $skillFolders) {
        Write-Host "   📘 $($skill.Name)" -ForegroundColor Gray
    }
}

# ========================================================
# 固定默认头部内容 (宪法级 - 每次确保存在且正确)
# ========================================================
$DEFAULT_HEADER = @"
**trigger: always_on**
**alwaysApply: true**

* **语言要求**：所有回复、思考过程及任务清单，均须使用中文   **中文**。

## **核心理念与原则**

* **简洁至上**：恪守 KISS (Keep It Simple, Stupid) 原则，崇尚简洁与可维护性，避免过度工程化与不必要的防御性设计。
* **深度分析**：立足于第一性原理 (First Principles Thinking) 剖析问题，并善用工具以提升效率。
* **事实为本**：以事实为最高准则。若有任何谬误，恳请坦率斧正，助我精进。
* 每次都用审视的目光，仔细看我输入的潜在问题，你要指出我的问题，并给出明显在我思考框架之外的建议
* 如果你觉得我说的太离谱了，你就骂回来，帮我瞬间清醒

## **开发工作流**

* **渐进式开发**：通过多轮次迭代，明确并实现需求。在着手任何设计或编码工作前，必须完成前期调研并厘清所有疑点。
* **结构化流程**：严格遵循"构思方案 → 提请审核 → 分解为具体任务"的作业顺序。

## **输出规范**

💡
* **语言要求**：所有回复、思考过程及任务清单，均须使用中文   **中文**。
* **固定指令**：``Implementation Plan, Task List and The entire process must be written in Chinese``
"@

# ========================================================
# 函数: 智能更新 GEMINI.md 配置
#   1. 确保固定默认头部存在
#   2. 动态扫描已部署的 skills，逐项检查并增补技能配置
# ========================================================
function Update-GeminiConfig {
    Write-Host "`n⚙️  正在更新 GEMINI.md 配置..." -ForegroundColor Yellow

    # UTF-8 无 BOM 编码器 (关键！避免 PowerShell 5.x 默认的 GBK 或 UTF-8 BOM)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false

    # --- STEP 1: 确保文件存在，且包含固定默认头部 ---
    if (-not (Test-Path $geminiFile)) {
        [System.IO.File]::WriteAllText($geminiFile, $DEFAULT_HEADER, $utf8NoBom)
        Write-Host "✅ 创建新的 GEMINI.md (含默认头部)" -ForegroundColor Green
    } else {
        # 文件已存在，检查头部是否完整
        $currentContent = [System.IO.File]::ReadAllText($geminiFile, $utf8NoBom)
        # 用 "核心理念与原则" 作为头部完整性标志
        if ($currentContent -notmatch '核心理念与原则') {
            # 头部不完整或被损坏，在文件顶部插入默认头部
            $updatedContent = $DEFAULT_HEADER + "`r`n`r`n" + $currentContent
            [System.IO.File]::WriteAllText($geminiFile, $updatedContent, $utf8NoBom)
            Write-Host "🔧 GEMINI.md 默认头部已修复" -ForegroundColor Yellow
        } else {
            Write-Host "✅ 默认头部完整，无需修改" -ForegroundColor Gray
        }
    }

    # --- STEP 2: 扫描已部署的技能目录 ---
    $skillFolders = Get-ChildItem -Path $targetSkillsDir -Directory | Sort-Object Name

    if ($skillFolders.Count -eq 0) {
        Write-Host "⚠️  未找到任何技能模块，跳过技能配置更新。" -ForegroundColor Yellow
        return
    }

    # 技能说明的元数据映射表（以目录名为 key）
    $skillMeta = @{
        "git-master" = @{
            Icon = "🏆"; Title = "超级Git管理大师"
            Trigger = "当用户提到 git、提交、commit、push、pull、拉取、推送、分支、branch、merge、合并、rebase、冲突、tag、回滚、revert、reset、stash、cherry-pick、diff、日志、log 等 Git 相关操作时"
            Role = "以专业的超级Git管理大师身份，提供安全、规范的Git操作服务"
        }
        "code-reviewer" = @{
            Icon = "🔍"; Title = "代码审查专家"
            Trigger = "当用户提到 review、审查、代码检查、CR、优化、改进、refactor、重构建议、性能分析、安全检查、漏洞扫描、代码质量、规范检查 等相关意图时"
            Role = "以专业的代码审查专家身份，提供深度、多维度的代码分析报告"
        }
        "tech-writer" = @{
            Icon = "📝"; Title = "技术文档专家"
            Trigger = "当用户提到 README、说明书、API文档、接口文档、注释、comment、架构图、流程图、开发文档 等相关意图时"
            Role = "以专业的技术文档专家身份，生成结构化、清晰且易维护的文档"
        }
        "test-master" = @{
            Icon = "🧪"; Title = "测试驱动大师"
            Trigger = "当用户提到 test、测试、TDD、单元测试、unit tests、e2e、integration tests、集成测试、Jest、Pytest、coverage、覆盖率 等相关意图时"
            Role = "以专业的测试驱动大师身份，编写可靠、全覆盖的测试用例"
        }
        "architect" = @{
            Icon = "🏗️"; Title = "系统架构师"
            Trigger = "当用户提到 架构、structure、目录结构、scaffold、设计模式、design pattern、技术选型、stack、重构、refactor、解耦 等相关意图时"
            Role = "以专业的系统架构师身份，提供项目初始化、技术选型或架构重构建议"
        }
        "debug-detective" = @{
            Icon = "🐞"; Title = "调试侦探"
            Trigger = "当用户提到 debug、调试、报错、error、Exception、崩溃、fix、修复、bug、日志、log、排查、troubleshoot 等相关意图时"
            Role = "以专业的调试侦探身份，提供深度日志分析和假设验证法排查思路"
        }
        "super-backend" = @{
            Icon = "🚀"; Title = "超级后端开发"
            Trigger = "当用户提到 后端、backend、Java、Go、Python、Node.js、微服务、分布式、高并发、数据库、Redis、中间件 等相关意图时"
            Role = "以全能型超级后端开发专家身份，提供高性能、高可用的后端解决方案"
        }
        "super-frontend" = @{
            Icon = "✨"; Title = "超级前端开发"
            Trigger = "当用户提到 前端、frontend、React、Vue、Angular、CSS、性能优化、动画、WebGL、Three.js、Tailwind 等相关意图时"
            Role = "以全能型超级前端开发专家身份，提供极致用户体验和性能优化的前端方案"
        }
        "fullstack-architect" = @{
            Icon = "🏛️"; Title = "全栈架构师"
            Trigger = "当用户提到 全栈、fullstack、架构、architecture、系统设计、技术选型、云原生、K8s、DevOps、CI/CD 等相关意图时"
            Role = "以顶级全栈架构师身份，提供全局视野的系统规划和技术治理建议"
        }
        "database-expert" = @{
            Icon = "💾"; Title = "全栈数据库专家"
            Trigger = "当用户提到 数据库、database、MySQL、PostgreSQL、Redis、MongoDB、SQL优化、索引、分库分表 等相关意图时"
            Role = "以全栈数据库专家身份，提供专业的数据库设计、优化和运维建议"
        }
    }

    # --- STEP 3: 重新读取文件内容，确保拿到最新版本 ---
    $currentContent = [System.IO.File]::ReadAllText($geminiFile, $utf8NoBom)

    # --- STEP 4: 确保 "## **全局 Skills 技能配置**" 段落标题存在 ---
    $sectionMarker = "## **全局 Skills 技能配置**"
    if ($currentContent -notmatch [regex]::Escape($sectionMarker)) {
        # 首次添加技能配置段落
        $currentContent = $currentContent.TrimEnd() + "`r`n`r`n$sectionMarker`r`n"
        Write-Host "📌 添加技能配置段落标题" -ForegroundColor Gray
    }

    # --- STEP 5: 逐项检查每个技能，动态增补 ---
    $addedCount = 0
    $updatedCount = 0
    $skippedCount = 0

    foreach ($folder in $skillFolders) {
        $name = $folder.Name
        $skillMdPath = Join-Path $folder.FullName "SKILL.md"

        # 检查 SKILL.md 是否存在
        if (-not (Test-Path $skillMdPath)) {
            Write-Host "   ⚠️  跳过 $name (缺少 SKILL.md)" -ForegroundColor Yellow
            continue
        }

        # 获取技能元数据
        if ($skillMeta.ContainsKey($name)) {
            $meta = $skillMeta[$name]
            $icon    = $meta.Icon
            $title   = $meta.Title
            $trigger = $meta.Trigger
            $role    = $meta.Role
        } else {
            # 未知技能: 尝试从 SKILL.md frontmatter 读取
            $icon    = "🔧"
            $title   = $name
            $trigger = "当用户提到 $name 相关意图时"
            $role    = "以 $name 专家身份提供专业服务"

            $mdContent = Get-Content $skillMdPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($mdContent -match '(?ms)^---\s*\n(.*?)\n---') {
                $frontmatter = $Matches[1]
                if ($frontmatter -match 'name:\s*(.+)') { $title = $Matches[1].Trim() }
                if ($frontmatter -match 'description:\s*(.+)') { $role = $Matches[1].Trim() }
            }
        }

        # 构建该技能的配置块
        $skillBlock = @(
            "### $icon $title"
            "- **技能路径**: ``~/.gemini/skills/$name/SKILL.md``"
            "- **触发条件**: $trigger"
            "- **角色说明**: $role"
            "- **使用方式**: 检测到相关意图时，先读取 ``~/.gemini/skills/$name/SKILL.md`` 获取完整操作规范，然后按照规范执行操作"
        ) -join "`r`n"

        # 检查该技能是否已经配置 (通过技能路径唯一标识)
        $skillPathPattern = [regex]::Escape("~/.gemini/skills/$name/SKILL.md")
        if ($currentContent -match $skillPathPattern) {
            # 已存在：用正则替换整个技能块 (从 ### 标题到下一个 ### 或文件末尾)
            $blockPattern = "### .+\r?\n- \*\*技能路径\*\*: ``~/.gemini/skills/$([regex]::Escape($name))/SKILL\.md``\r?\n- \*\*触发条件\*\*: .+\r?\n- \*\*角色说明\*\*: .+\r?\n- \*\*使用方式\*\*: .+"
            if ($currentContent -match $blockPattern) {
                $currentContent = $currentContent -replace $blockPattern, $skillBlock
                $updatedCount++
                Write-Host "   🔄 $icon $title  (已更新)" -ForegroundColor DarkGray
            } else {
                $skippedCount++
                Write-Host "   ✅ $icon $title  (已存在，格式不同，保留原样)" -ForegroundColor Gray
            }
        } else {
            # 不存在：追加到文件末尾
            $currentContent = $currentContent.TrimEnd() + "`r`n`r`n" + $skillBlock + "`r`n"
            $addedCount++
            Write-Host "   ➕ $icon $title  (新增)" -ForegroundColor Green
        }
    }

    # --- STEP 6: 写回文件 ---
    [System.IO.File]::WriteAllText($geminiFile, $currentContent, $utf8NoBom)

    # 输出汇总
    Write-Host ""
    if ($addedCount -gt 0) {
        Write-Host "📊 新增 $addedCount 个技能配置" -ForegroundColor Green
    }
    if ($updatedCount -gt 0) {
        Write-Host "📊 更新 $updatedCount 个技能配置" -ForegroundColor Cyan
    }
    if ($addedCount -eq 0 -and $updatedCount -eq 0) {
        Write-Host "✅ 所有技能配置已是最新，无需变更" -ForegroundColor Green
    }
}

# ========================================================
# 主流程
# ========================================================
Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  🚀 Antigravity Global Skills - 智能安装器" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan

# 检查 .gemini 目录
if (-not (Test-Path $globalConfigDir)) {
    Write-Host "❌ 未找到全局配置目录: $globalConfigDir" -ForegroundColor Red
    Write-Host "请先运行一次 Antigravity (或 Gemini CLI) 以自动生成配置目录。"
    Write-Host "按任意键退出..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# 判断运行模式: 本地 or 远程
$localSkillsDir = if ($PSScriptRoot) { Join-Path $PSScriptRoot "skills" } else { $null }

if ($localSkillsDir -and (Test-Path $localSkillsDir)) {
    # 本地模式: 当前目录有 skills/ 文件夹
    Install-FromLocal -LocalSkillsPath $localSkillsDir
} else {
    # 远程模式: 从 GitHub Release 下载
    $success = Install-FromRemote
    if (-not $success) {
        Write-Host "`n❌ 安装失败！请检查网络连接或手动下载安装。" -ForegroundColor Red
        Write-Host "📎 手动下载: https://github.com/$REPO_OWNER/$REPO_NAME/releases/latest" -ForegroundColor Gray
        Write-Host "按任意键退出..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

# 更新 GEMINI.md 配置
Update-GeminiConfig

# 完成
Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  🎉 安装完成！" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  📂 技能目录: $targetSkillsDir" -ForegroundColor White
Write-Host "  📄 配置文件: $geminiFile" -ForegroundColor White
$currentVer = Get-InstalledVersion
if ($currentVer) {
    Write-Host "  🏷️  当前版本: $currentVer" -ForegroundColor White
}
Write-Host ""
Write-Host "  👉 请重启 Antigravity (或 VS Code) 以使配置生效。" -ForegroundColor Yellow
Write-Host ""

# 如果是交互式运行 (非 pipeline)，等待用户按键
if ($Host.Name -eq "ConsoleHost" -and -not $env:ANTIGRAVITY_SILENT) {
    Write-Host "按任意键退出..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
