晴历 Qingli 0.1.0-beta.2 — 本地 Beta 测试包，未发布
基于 Creewick 的 MontereyRainmeter，保留 CC BY-NC-SA 4.0；天气及定位图标分别保留随包MIT许可证。

全新安装：使用官方 Rainmeter 打开 .rmskin，确认皮肤根目录是 Qingli。安装后在管理窗口加载 Qingli/Start/Start.ini，它会先创建缺失的 Settings.inc、Accent.inc、Material.inc，再显示并排列两卡。
包内只有 *.defaults.inc 默认模板，不分发或覆盖以上个人配置，也不包含实际 QWeather.local.json。若需在第一次联网前改为手动城市，先将 Settings.defaults.inc 复制为 Settings.inc，设 LocationMode=Manual 并填写城市和坐标，再加载 Start。

升级：安装器使用 Merge skins，不附 layout，不自动加载皮肤。已有 Key、设置、配色和材质文件不在包内，安装时不会被同名默认文件覆盖。安装前最好退出虚拟机内的 Rainmeter；安装后启动并加载原来的两张卡片即可。不要再加载 Start，否则它会主动重新排列位置。
位置由该 Rainmeter 实例的主 Rainmeter.ini 保存，本包不替换它。此保留方案已做文件级及首次初始化检查，实际官方安装器的全新安装/升级请在虚拟机验收。

默认 OpenMeteo、AutoIP、DirectRouteVerified=0、缩放0.9、经典红和柔透。AutoIP会向定位服务发请求，天气查询发送坐标；/none不保证绕过VPN/TUN。本包不修改代理、字体、系统启动项或其他皮肤。
和风为可选项：本人填写 @Resources/Refined/QWeather.local.json 后选择QWeather。该模式调用本地Windows PowerShell 5.1；城市v7接口已被官方标记即将弃用，本版未迁移。不要分享个人Key。

名称“晴历/Qingli”的商标可用性尚未完成核验。本包没有发布。完整来源：https://github.com/creewick/MontereyRainmeter
