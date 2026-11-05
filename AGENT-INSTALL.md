# 供 Agent 使用的安装说明

适用于用户明确要求安装或升级晴历的 Windows 电脑。固定版本：**0.1.0-beta.2**；唯一项目来源：[gzhzk/qingli-widgets](https://github.com/gzhzk/qingli-widgets)。

## 安装原则

- 先确认已安装 Rainmeter 4.5.28.3936 或更新版本，以及当前实例实际使用的 `Skins` 绝对路径。标准安装和便携安装可能不同；存在多个实例或目录无法确认时，先问清目标，不猜测。
- 自动化安装使用本 Release 的 **skin ZIP + `tools/Install-Upgrade.ps1`**。无需管理员权限，不执行联网脚本管道，不修改系统执行策略，不退出整个 Rainmeter。
- 只安装到已确认的 `Skins/Qingli`，不改其他皮肤、开机启动、代理、字体或全局布局。不卸载旧目录，不把默认模板复制到已有个人配置上。
- 不读取、打印、上传或索要用户的天气 Key。默认 Open-Meteo 无需个人 Key；和风凭据由用户在本地单独填写。

## 1. 下载固定版本并校验

将 `$SkinsDirectory` 赋值为已确认的实际 `Skins` 绝对路径，然后运行以下 PowerShell。下载在新临时目录进行，不写入皮肤目录。

```powershell
# 由 Agent 根据当前 Rainmeter 实例设置 $SkinsDirectory，不使用猜测路径。
if (-not $SkinsDirectory -or -not [IO.Path]::IsPathRooted($SkinsDirectory)) {
    throw 'Set the confirmed absolute Skins directory first.'
}
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$version = '0.1.0-beta.2'
$baseUrl = "https://github.com/gzhzk/qingli-widgets/releases/download/v$version"
$asset = "Qingli-v$version-skin.zip"
$stage = Join-Path ([IO.Path]::GetTempPath()) ('qingli-install-' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $stage
$zipPath = Join-Path $stage $asset
$sumPath = Join-Path $stage 'SHA256SUMS.txt'
Invoke-WebRequest -UseBasicParsing -Uri "$baseUrl/$asset" -OutFile $zipPath
Invoke-WebRequest -UseBasicParsing -Uri "$baseUrl/SHA256SUMS.txt" -OutFile $sumPath
$pattern = '^([a-fA-F0-9]{64})  ' + [regex]::Escape($asset) + '$'
$lines = @(Get-Content -LiteralPath $sumPath | Where-Object { $_ -match $pattern })
if ($lines.Count -ne 1) { throw 'Missing or duplicate checksum entry.' }
$expected = [regex]::Match($lines[0], $pattern).Groups[1].Value
$sha256 = [Security.Cryptography.SHA256]::Create()
$stream = [IO.File]::OpenRead($zipPath)
try { $actual = [BitConverter]::ToString($sha256.ComputeHash($stream)).Replace('-', '') }
finally { $stream.Dispose(); $sha256.Dispose() }
if ($actual -ine $expected) {
    throw 'SHA256 mismatch. Do not install.'
}
$package = Join-Path $stage 'package'
$null = [Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
$archive = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    foreach ($entry in $archive.Entries) {
        $name = $entry.FullName
        if ($name.StartsWith('/') -or $name.Contains('\') -or $name.Contains(':') -or
            ($name.Split('/') -contains '..') -or ($name.Split('/') -contains '.') -or
            (($entry.ExternalAttributes -shr 16) -band 61440) -eq 40960) {
            throw 'Unsafe archive entry. Do not extract.'
        }
    }
} finally { $archive.Dispose() }
[IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $package)
$installer = Join-Path $package 'tools/Install-Upgrade.ps1'
if (-not (Test-Path -LiteralPath $installer -PathType Leaf)) { throw 'Installer missing.' }
$hadQingli = Test-Path -LiteralPath (Join-Path $SkinsDirectory 'Qingli')
& powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $installer -SkinsDirectory $SkinsDirectory
if ($LASTEXITCODE -ne 0) { throw 'Install preview failed.' }
```

核对预览目标确实是所选实例的 `Skins/Qingli`。SHA256 用于检测下载损坏或不一致，不是作者数字签名；下载地址和校验文件均须来自上面的官方仓库及固定版本。

## 2. 应用安装或升级

在写入前备份已有 `Qingli` 目录及当前实例的 Rainmeter 配置/布局，备份只留本地。若用户已经授权安装或升级、且预览目标正确，继续运行：

```powershell
& powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $installer -SkinsDirectory $SkinsDirectory -Apply
if ($LASTEXITCODE -ne 0) { throw 'Installation failed. Keep backups and inspect locally.' }
```

`Bypass` 仅作用于本次子进程。脚本验证皮肤文件清单与哈希，拒绝路径逃逸、链接及不支持的文件；只复制受管理文件，更新前将旧代码备份到 `Qingli/@UpgradeBackup/`，不会删除额外用户文件。它不会启动、关闭或刷新 Rainmeter。

必须保留这些个人文件原字节：

```text
Qingli/@Resources/Refined/Settings.inc
Qingli/@Resources/Refined/Accent.inc
Qingli/@Resources/Refined/Material.inc
Qingli/@Resources/Refined/QWeather.local.json
```

发布包不携带这些文件，只携带默认模板和空凭据示例。位置由当前 Rainmeter 实例的配置保存，不在上述四个文件中；不要替换 Rainmeter.ini 或套用全局布局。

## 3. 加载与验收

- **全新安装**（`$hadQingli` 为 false）：在管理 Rainmeter 中刷新皮肤列表，只加载 `Qingli/Start/Start.ini`。Start 创建缺失配置并初次排列两张卡片。也可用已确认的当前实例 Rainmeter.exe 执行 `!ActivateConfig "Qingli\Start" "Start.ini"`。
- **已有 Qingli**（`$hadQingli` 为 true）：不要加载 Start，它会重新排列位置。仅刷新原来已加载的 Qingli 日历和天气；未加载的保持未加载，不刷新其他皮肤。
- 第一次激活天气会按默认设置访问 IP 定位和天气服务。用户不希望 IP 定位时，先从 `Settings.defaults.inc` 创建缺失的 `Settings.inc`，设置 `LocationMode=Manual` 及其选择的城市坐标；已有配置不覆盖。手动坐标仍会发给天气服务。
- 确认卡片显示；升级后检查原 Key 文件、设置、配色、材质没有被改写，卡片位置保持。仅报告文件是否存在或一致，不展示文件内容或 Key。

遇到缺失依赖、哈希不一致、目标不明确或安装错误时停止，不改用删除目录、强制覆盖个人配置或全局重置。回滚时先备份当前文件，再恢复对应受管理代码；保留全部个人配置和布局。

## 已知范围

这是 Beta 预览版。已做包内容/隐私检查、Lua 初始化检查及合成目录安装升级测试；这些不等于所有电脑上的官方安装器、DPI 和天气联网均已实装验证。和风天气的城市 v7 接口已有弃用提示，默认使用 Open-Meteo。

许可证和上游署名见 [README](README.md) 与 [ATTRIBUTION](ATTRIBUTION.md)。
