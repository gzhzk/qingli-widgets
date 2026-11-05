# 安装与升级

本版 .rmskin 使用官方 Skin Packager，Merge skins 开启，安装后 Do nothing，不附 layout。三个可写 inc 文件和 Key 不在包内，首次加载 Start 时仅创建缺失配置。已有文件与旧备份优先保留；初始化失败时不激活天气和日历。

首次安装加载Start；升级不加载Start，避免主动重排位置。本包不写主Rainmeter.ini，位置由原Rainmeter实例保存。切勿先删除旧Qingli目录，也不要将整个运行目录压缩为分发包。

人工安装先从 [Release](https://github.com/gzhzk/qingli-widgets/releases/tag/v0.1.0-beta.2) 下载 .rmskin 与 SHA256SUMS.txt，核对 SHA256，再使用官方 Rainmeter 安装器。安装器可能重启 Rainmeter，先保存布局和备份个人设置。

Agent 安装或不希望退出整个 Rainmeter 时，使用 skin ZIP 与包内的 Install-Upgrade.ps1，按[仓库根目录的 Agent 安装说明](https://github.com/gzhzk/qingli-widgets/blob/main/AGENT-INSTALL.md)先校验和预览，再应用。该脚本只写所选 Skins/Qingli，不控制 Rainmeter 进程；升级仅刷新原已加载的晴历卡片。
