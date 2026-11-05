晴历 Qingli 0.1.0-beta.2 — Beta 预览版
基于 Creewick 的 MontereyRainmeter，沿用 CC BY-NC-SA 4.0；天气及定位图标分别保留 MIT 许可证。

全新安装：使用官方 Rainmeter 打开 .rmskin，确认皮肤根目录为 Qingli。安装后在管理窗口加载 Qingli/Start/Start.ini；它先创建缺失的 Settings.inc、Accent.inc、Material.inc，再显示日历和天气两张卡片。
本包只有 *.defaults.inc 默认模板，不分发或覆盖已有个人配置，也不包含真实 QWeather.local.json。若希望第一次启动前改为手动城市，先将 Settings.defaults.inc 复制为缺失的 Settings.inc，设 LocationMode=Manual 并填写城市和经纬度，再加载 Start。

升级：先备份个人设置和 Rainmeter 布局，不删除旧 Qingli 目录。安装器使用 Merge skins，不附 layout，不自动加载皮肤；它可能重启 Rainmeter。已有 Key、设置、配色和材质文件不在包内。升级后沿用原来的两张卡片，不要再次加载 Start，它会主动重新排列位置。
位置由当前 Rainmeter 实例的 Rainmeter.ini 保存，本包不替换它。Agent 可使用同一 Release 的 skin ZIP 和安装脚本，按 AGENT-INSTALL.md 校验、预览后应用，无需退出整个 Rainmeter。

默认 OpenMeteo、AutoIP、DirectRouteVerified=0、缩放 0.9、经典红与柔透材质。自动定位会访问定位服务，天气查询会发送坐标；手动城市仍需将所选坐标发送给天气服务。项目不修改系统代理、字体、开机启动或其他皮肤。
和风为可选项：自行在本地填写 @Resources/Refined/QWeather.local.json 并选择 QWeather。该模式调用本地 Windows PowerShell 5.1，城市 v7 接口已有弃用提示，本版未迁移；不要分享个人 Key。

本 Beta 已做文件核验、初始化和合成目录安装升级测试，尚未全面验证所有实际安装、DPI 与网络环境。名称“晴历 / Qingli”商标可用性尚未完成核验。
项目与发布：https://github.com/gzhzk/qingli-widgets
上游：https://github.com/creewick/MontereyRainmeter
