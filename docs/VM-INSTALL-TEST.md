# 晴历 Beta：虚拟机安装测试

只在Windows虚拟机中操作，先创建虚拟机快照。准备官方Rainmeter和本次Qingli-v0.1.0-beta.2.rmskin，不要复制宿主机个人Key。以下尚待你执行，不是已通过的实机报告。

**一、全新安装**

1. 虚拟机内正常安装并运行一次官方Rainmeter，再退出它。双击本包；若文件关联未建立，用该实例的SkinInstaller.exe打开包。核对名称Qingli、版本0.1.0-beta.2、皮肤目录Qingli；安装不应要求替换全局layout或安装额外插件。
2. 安装后启动Rainmeter，刷新皮肤列表，手动加载 `Qingli/Start/Start.ini`。确认两卡显示，经典红、周一开头、六行日历、当天农历及默认天气来源Open-Meteo。
3. 检查 `Skins/Qingli/@Resources/Refined/`：三个 `.defaults.inc` 模板保留，并已创建 Settings.inc、Accent.inc、Material.inc；不应自动创建 QWeather.local.json。

**二、重复安装/升级，检查四项保留**

1. 先随意拖动两张卡片，修改缩放（例如1.1），选择一种非红配色和“清晰”材质。退出虚拟机Rainmeter，让位置写入主配置。
2. 在 Refined 目录新建 QWeather.local.json，填入 `{"testMarker":"VM_ONLY_NOT_A_REAL_KEY"}`。这只是文件保留标记，保持Open-Meteo模式；不要用它查询和风，也不要放入真实Key。
3. 将 QWeather.local.json、Settings.inc、Accent.inc、Material.inc 和该实例主 Rainmeter.ini 复制到虚拟机临时备份目录。也可记录前四个文件的SHA256。不要把这些用户文件重新打进公开包。
4. 再安装一次同一个.rmskin即可验证覆盖重装；如已有beta.1，也可直接从beta.1升级至本包。不要先删除Qingli目录，不要运行清理脚本，不要加载Start。
5. **先不要启动Rainmeter**，比较前四个文件，应逐字节/哈希一致；主Rainmeter.ini不应被安装包替换，其Qingli两卡WindowX/WindowY等位置值应保留。
6. 再启动Rainmeter，原两卡若未加载就分别加载 Widgets/Calendar/Refined.ini 和 Widgets/Weather/Refined.ini。确认原位置、缩放、配色、材质不变；再退出重启一次。此时Rainmeter自身可能更新主配置的其他字段，以两卡位置和实际显示为准。

**三、结束判断**

四个用户文件保持、两卡位置与外观保持、无其他皮肤/字体/代理/启动项变化，即通过这轮安装保留检查。若任何一项丢失，保留虚拟机快照及前后文件，不发布这个包；反馈时只报告通过/失败，勿发真实Key或完整私人配置。

测试后可删除虚拟机内的假Key文件。首次启动未出两卡、出现配置错误、位置变化等情况也请记录。天气真实连通性、长时间刷新和DPI可另行试用，不影响本轮先检查安装与保留行为。
