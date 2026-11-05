# 可选和风天气配置

默认 OpenMeteo 不需要和风凭据。只有主动选择 QWeather 时才需要以下步骤。

1. 在皮肤目录中找到 `@Resources/Refined/QWeather.local.example.json`，复制为同目录的 `QWeather.local.json`。
2. 填写本人账号的 `apiHost` 和 `apiKey`。`apiHost` 只填主机名，不带 `https://` 或路径；当前校验接受 `*.qweatherapi.com`。空示例不是可用凭据，不要将实际凭据提交到仓库或放入发布包。
3. 编辑 `@Resources/Refined/Settings.inc`，设 `WeatherProvider=QWeather`，再刷新天气皮肤；也可使用天气右键菜单主动选择来源。
4. 需要恢复默认时，改为 `WeatherProvider=OpenMeteo` 或用右键菜单切换，再确认来源文字。

当前适配只支持 API Key（`X-QW-Api-Key` 请求头），没有实现 JWT；实际账号可用的认证方式、产品权限、额度和费用需要按和风控制台及当前文档确认。不要把 JWT 私钥填入 apiKey。

当前实现使用城市 `/v7/weather/now` 和 `/v7/weather/7d`，由本地 Windows PowerShell 5.1 / .NET 助手处理 HTTPS 与 gzip。Rainmeter 使用自带 RunCommand 插件启动助手，参数有 `-NoProfile -NonInteractive -ExecutionPolicy Bypass -File`。它不是纯 Lua 联网模式，也不需要另装插件DLL。

官方[城市实时天气 v7](https://dev.qweather.com/docs/api/weather/weather-now-webapi-v7/)和[城市每日预报 v7](https://dev.qweather.com/docs/api/weather/weather-daily-forecast-webapi-v7/)已有弃用提示。本次整理不迁移端点，也不保证旧接口长期可用；不能只换请求 URL 而忽略响应结构、时区、归因与缓存兼容性。

请求周期约为当前天气15分钟、每日预报1小时；启动、位置变化和手动操作可能额外请求。和风失败不自动跨提供方回退；缺失或无效凭据会显示配置错误，需要修正后刷新。

若配置有误，请检查完整路径、JSON语法、主机名、API Key、账号产品权限、系统时间、网络和独立运行环境中的PowerShell可用性。不要把含凭据的配置文件发给他人排查。界面必须保留“和风天气”和可点击来源链接，参见[官方归因要求](https://dev.qweather.com/docs/terms/attribution/)。

本Beta在首次加载Start后才创建Settings.inc；若首次加载前就需选择QWeather，可先将Settings.defaults.inc复制为Settings.inc，再填写配置。
