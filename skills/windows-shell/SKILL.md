---
name: Windows Shell 兼容性守卫
description: |
  【全局自动激活】Windows 环境下的 Shell 命令执行兼容性守卫。
  自动拦截并修正 bash 风格命令（如 && 连接符）、BOM 编码问题、路径分隔符问题等。
  此 Skill 在 Windows 系统上执行任何 Shell 命令时始终生效，无需手动触发。
alwaysApply: true
---

# 🛡️ Windows Shell 兼容性守卫 — 全局 Skill

> **角色定位**：我是 Windows 环境下的**命令执行守卫**，确保所有 Shell 命令在 PowerShell 环境中正确执行，杜绝跨平台命令兼容性问题。

> **⚠️ 此 Skill 为全局自动生效，无需手动触发。**

---

## 🎯 适用范围

**始终生效**：当操作系统为 Windows 时，在调用 `run_command` 工具执行任何 Shell 命令之前，必须先经过以下规则检查和转换。

---

## 🚫 绝对禁止规则（Zero Tolerance）

### 规则 1：禁止使用 `&&` 连接多条命令

**问题根因**：Windows PowerShell 5.x 不支持 `&&` 操作符（仅 PowerShell 7+ 支持），使用会导致 `ParserError` 报错。

**❌ 绝对禁止：**
```powershell
# 以下写法全部禁止！
git add . && git commit -m "message"
cd src && npm install
mkdir build && cd build && cmake ..
command1 && command2 && command3
```

**✅ 正确替代方案（按优先级排序）：**

#### 方案 A：分号 `;` 连接（简单顺序执行，最常用）
```powershell
git add .; git commit -m "message"
cd src; npm install
```

#### 方案 B：独立执行（推荐，更安全、更清晰）
```powershell
# 分为多次 run_command 调用，每次只执行一条命令
# 第 1 次调用
git add .
# 第 2 次调用
git commit -m "message"
```

#### 方案 C：`-and` 逻辑运算符（需要前一条成功才执行下一条时）
```powershell
# PowerShell 条件执行：只有前一条成功才执行下一条
if ($?) { git commit -m "message" }
```

#### 方案 D：脚本块（复杂逻辑时）
```powershell
& {
    git add .
    if ($LASTEXITCODE -eq 0) {
        git commit -m "message"
    }
}
```

**⚡ 快速转换参考表：**

| Bash/CMD 写法 | PowerShell 等价写法 |
|---|---|
| `cmd1 && cmd2` | `cmd1; cmd2` 或分两次执行 |
| `cmd1 \|\| cmd2` | `cmd1; if (-not $?) { cmd2 }` |
| `cmd1 & cmd2`（并行） | 不适用，分别执行 |
| `cmd1 && cmd2 && cmd3` | `cmd1; cmd2; cmd3` |

---

### 规则 2：禁止使用 `||` 作为命令分隔符

**❌ 禁止：**
```powershell
command1 || command2   # PowerShell 5.x 不支持
```

**✅ 正确写法：**
```powershell
command1; if (-not $?) { command2 }
```

---

### 规则 3：禁止其他 Bash 特有语法

**❌ 禁止列表：**
```bash
# 以下 bash 语法在 PowerShell 中不可用
export VAR=value           # ❌ bash 导出环境变量
source ~/.bashrc           # ❌ bash 加载配置
$(command)                 # ⚠️ 在 PowerShell 中意义不同
command > /dev/null 2>&1   # ❌ bash 重定向
rm -rf folder              # ❌ bash 删除命令
chmod +x script.sh         # ❌ bash 权限命令
grep pattern file          # ⚠️ 应使用 Select-String
sed/awk                    # ❌ 应使用 PowerShell 命令
```

**✅ PowerShell 等价写法：**

| Bash 语法 | PowerShell 等价 |
|---|---|
| `export VAR=value` | `$env:VAR = "value"` |
| `source file` | `. .\file.ps1` |
| `command > /dev/null 2>&1` | `command *> $null` |
| `rm -rf folder` | `Remove-Item -Recurse -Force folder` |
| `grep pattern file` | `Select-String -Pattern "pattern" file` |
| `cat file` | `Get-Content file` |
| `echo text > file` | `Set-Content -Path file -Value "text"` |
| `which command` | `Get-Command command` |
| `ls -la` | `Get-ChildItem -Force` |

---

## 📄 文件编码规则（BOM 问题防护）

### 规则 4：文件编码必须使用 UTF-8 无 BOM

**问题根因**：PowerShell 5.x 的 `Out-File`、`Set-Content`、`>` 重定向默认使用 UTF-16 LE 或 UTF-8 with BOM 编码。带 BOM 的文件在很多工具中会导致：
- 脚本文件首行出现 `ï»¿` 乱码（BOM 三字节标记）
- JSON 解析失败
- Shell 脚本无法识别 shebang
- Git diff 显示异常

**✅ 正确的文件写入方式：**

```powershell
# ✅ 方式 1：使用 .NET 类直接写入 UTF-8 无 BOM（最推荐）
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("path\to\file.txt", $content, $utf8NoBom)

# ✅ 方式 2：使用 [System.IO.File]::WriteAllLines
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines("path\to\file.txt", $lines, $utf8NoBom)

# ✅ 方式 3：PowerShell 7+ 可用 -Encoding utf8NoBOM
Set-Content -Path "file.txt" -Value $content -Encoding utf8NoBOM  # 仅 PS 7+
```

**❌ 禁止的文件写入方式（会产生 BOM 或错误编码）：**
```powershell
# ❌ 以下写法会产生 BOM 或非 UTF-8 编码
$content | Out-File "file.txt"                    # 默认 UTF-16 LE
$content | Out-File "file.txt" -Encoding utf8     # UTF-8 WITH BOM
Set-Content "file.txt" -Value $content            # 可能非 UTF-8
$content > "file.txt"                             # 等同于 Out-File，UTF-16 LE
Add-Content "file.txt" -Value $content -Encoding utf8  # UTF-8 WITH BOM
```

### 规则 5：读取文件时指定编码

```powershell
# ✅ 正确：显式指定 UTF-8
Get-Content -Path "file.txt" -Encoding UTF8

# ✅ 使用 .NET 读取（确保无 BOM 问题）
[System.IO.File]::ReadAllText("path\to\file.txt", [System.Text.Encoding]::UTF8)
```

---

## 🔤 中文字符处理

### 规则 6：命令行中的中文字符串

**问题根因**：PowerShell 控制台在某些环境下对中文字符的处理可能出错，尤其在 commit message 等场景中。

**✅ 最佳实践：**

```powershell
# ✅ Git commit 中文信息 — 使用双引号包裹
git commit -m "feat(auth): 添加用户认证模块"

# ✅ 如果中文消息包含特殊字符，使用单引号
git commit -m 'fix(api): 修复"导出"功能空指针异常'

# ✅ 设置 Git 不对中文文件名转义
git config --global core.quotepath false

# ✅ 设置控制台编码为 UTF-8（在脚本开头执行）
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001
```

---

## 📁 路径规则

### 规则 7：路径分隔符

```powershell
# ✅ Windows 路径使用反斜杠或正斜杠均可
"C:\Users\Administrator\project"
"C:/Users/Administrator/project"

# ✅ 使用 Join-Path 构建路径（跨平台安全）
Join-Path $env:USERPROFILE "project" "src"

# ❌ 禁止使用 ~ 扩展（PowerShell 中行为与 bash 不同）
# cd ~/project  # ⚠️ 行为不一致
# ✅ 使用 $env:USERPROFILE 或 $HOME
Set-Location (Join-Path $env:USERPROFILE "project")
```

---

## ⚡ 命令执行检查清单

**在调用 `run_command` 之前，必须心中过一遍以下检查项：**

1. ☐ 命令中是否包含 `&&`？→ 替换为 `;` 或拆分为多次调用
2. ☐ 命令中是否包含 `||`？→ 替换为 `if (-not $?) { ... }`
3. ☐ 是否使用了 bash 特有命令（`export`, `source`, `rm -rf` 等）？→ 替换为 PowerShell 等价命令
4. ☐ 文件写入操作是否会产生 BOM？→ 使用 `[System.IO.File]::WriteAllText` 或工具的 `write_to_file`
5. ☐ 路径是否使用了正确的格式？→ 使用绝对路径或 `Join-Path`
6. ☐ 中文字符串是否正确包裹？→ 使用引号并确认控制台编码

---

## 🔧 常见场景速查

### 场景 1：Git 多步骤操作
```powershell
# ❌ 错误
git add . && git commit -m "update" && git push

# ✅ 正确（分号连接）
git add .; git commit -m "update"; git push

# ✅ 最佳（分步执行，每步可检查结果）
# 第 1 步
git add .
# 第 2 步
git commit -m "chore: 更新配置"
# 第 3 步
git push
```

### 场景 2：创建目录并进入
```powershell
# ❌ 错误
mkdir build && cd build

# ✅ 正确
New-Item -ItemType Directory -Force -Path "build"; Set-Location "build"

# ✅ 或者使用 run_command 的 Cwd 参数指定工作目录
```

### 场景 3：条件安装依赖
```powershell
# ❌ 错误（bash 风格）
npm install || yarn install

# ✅ 正确
npm install; if (-not $?) { yarn install }
```

### 场景 4：生成配置文件（避免 BOM）
```powershell
# ❌ 错误（会产生 BOM）
@"
{
  "name": "project",
  "version": "1.0.0"
}
"@ | Out-File "package.json" -Encoding utf8

# ✅ 正确（无 BOM）
$json = @"
{
  "name": "project",
  "version": "1.0.0"
}
"@
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText("$(Get-Location)\package.json", $json, $utf8NoBom)

# ✅ 最佳（直接使用 write_to_file 工具，由编辑器处理编码）
```

---

## 📝 注意事项

- 此 Skill 在 Windows 操作系统上**始终自动生效**
- 所有命令示例均基于 **Windows PowerShell 5.1**（最大兼容性）
- 如果检测到 PowerShell 7+，部分限制可以适当放宽，但仍建议遵循最大兼容性原则
- 优先使用编辑器工具（`write_to_file`、`replace_file_content` 等）而非 PowerShell 命令来创建/修改文件，从根源上避免编码问题
- 当需要执行多个关联命令时，**优先拆分为多次 `run_command` 调用**，这样每步都可以检查执行结果
