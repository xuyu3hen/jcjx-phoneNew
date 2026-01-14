# PowerShell 乱码问题解决方案

## 问题描述

在 Windows PowerShell 中运行批处理脚本时，中文显示为乱码（如：`鑷姩鍖栧彂甯冩祦绋?`）。

## 原因

Windows 控制台默认使用 GBK 编码，而脚本中的中文字符是 UTF-8 编码，导致显示乱码。

## 解决方案

### 方案一：在脚本中设置编码（已修复）

所有批处理脚本（`.bat`）已在开头添加了编码设置：

```batch
@echo off
chcp 65001 >nul
```

这会将控制台代码页设置为 UTF-8（65001），从而正确显示中文。

**已修复的脚本：**
- `scripts\release.bat`
- `scripts\build.bat`
- `scripts\migrate_to_github.bat`

### 方案二：手动设置 PowerShell 编码

在运行脚本前，先执行：

```powershell
chcp 65001
```

或者设置 PowerShell 输出编码：

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
```

### 方案三：永久设置 PowerShell 编码

在 PowerShell 配置文件中添加（推荐）：

1. 打开 PowerShell 配置文件：
   ```powershell
   notepad $PROFILE
   ```

2. 如果文件不存在，创建它：
   ```powershell
   New-Item -Path $PROFILE -Type File -Force
   notepad $PROFILE
   ```

3. 添加以下内容：
   ```powershell
   # 设置控制台编码为 UTF-8
   chcp 65001 | Out-Null
   [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
   $OutputEncoding = [System.Text.Encoding]::UTF8
   ```

4. 保存并重新打开 PowerShell

### 方案四：使用 CMD 而不是 PowerShell

如果 PowerShell 仍有问题，可以使用传统的 CMD：

```cmd
cmd /c scripts\release.bat
```

## 验证修复

运行脚本，检查中文是否正常显示：

```powershell
# 测试 release 脚本
scripts\release.bat

# 应该看到：
# ========================================
# 自动化发布流程
# ========================================
# 
# [1/6] 检查 Git 工作区...
# ✓ 工作区干净
```

## 常见问题

### Q: 设置编码后仍然乱码？

**解决方法：**
1. 确保脚本文件本身是 UTF-8 编码（不是 UTF-8 BOM）
2. 检查字体是否支持中文（建议使用 Consolas 或 Microsoft YaHei Mono）
3. 尝试使用 CMD 而不是 PowerShell

### Q: 如何检查文件编码？

使用 PowerShell：
```powershell
Get-Content scripts\release.bat -Encoding UTF8 | Out-File -Encoding UTF8 test.bat
```

### Q: 如何修改 PowerShell 字体？

1. 右键点击 PowerShell 标题栏
2. 选择 **属性** → **字体**
3. 选择支持中文的字体（如：Consolas、Microsoft YaHei Mono）

## 推荐配置

对于 Windows 用户，推荐：

1. **使用修复后的脚本**（已添加 `chcp 65001`）
2. **设置 PowerShell 配置文件**（方案三）
3. **使用支持中文的字体**

这样就能在所有情况下正确显示中文了。

## 相关资源

- [Windows 代码页列表](https://docs.microsoft.com/zh-cn/windows/win32/intl/code-page-identifiers)
- [PowerShell 编码设置](https://docs.microsoft.com/zh-cn/powershell/module/microsoft.powershell.core/about/about_character_encoding)
