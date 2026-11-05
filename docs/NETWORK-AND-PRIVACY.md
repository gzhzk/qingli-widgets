# 联网与隐私

默认 WeatherProvider=OpenMeteo、LocationMode=AutoIP。只要加载天气皮肤，自动定位和天气查询就可能发出请求；如果希望不查询 IP，先切换 Manual 并填写自己的城市坐标，再加载。

| 对象 | 发送内容和对方可见信息 | 本地行为 |
| --- | --- | --- |
| ipwho.is（仅AutoIP） | 请求来源IP；返回城市级估计与坐标 | 保存选定城市、国别、坐标、时间，不保存完整IP响应 |
| api.open-meteo.com（OpenMeteo） | 查询坐标、天气字段等参数，来源IP | 保存通过校验的天气响应及获取时间 |
| 用户配置的 *.qweatherapi.com（QWeather） | 查询坐标、语言；X-QW-Api-Key 请求头，来源IP | 凭据仅本地读取，保存天气响应及获取时间 |

定位默认每3600秒、失败约900秒重试；Open-Meteo 合并天气请求约900秒；和风当前天气900秒、每日预报3600秒。启动、手动刷新、切换来源和位置变化可能额外请求。额度与费用遵守提供方当时条款。

定位的 ProxyServer=/none 仅针对普通 HTTP 代理设置，不会绕过 VPN/TUN 系统路由。Open-Meteo 使用 WebParser 的 /auto，和风助手使用系统代理；具体出口应在实际设备独立核验。DirectRouteVerified=0 是公共默认值，改为1只是用户人工记录，不是程序自动验证。

本包不修改代理、VPN、DNS、路由、防火墙或网卡，不要求关闭安全软件。若不希望自动定位，选择 Manual；手动天气模式仍会把查询坐标发给所选天气服务。

和风模式调用 Windows PowerShell 5.1，命令指向固定包内 FetchQWeather.ps1，参数包含固定枚举及数值坐标。助手从 QWeather.local.json 读取凭据，不将密钥写到进程参数或主动日志中。-ExecutionPolicy Bypass 是子进程参数，不修改全局执行策略。运行日志、异常诊断和截图仍应由分享者复核，不能据此承诺整个系统不会留存信息。

正常运行会写入 Widgets/Weather 下的 *-cache*.json 和 .bak/.tmp，以及皮肤内的配色、材质、天气来源设置。Rainmeter 自身还可能维护独立的主配置和日志；其更新检查等通信应与皮肤请求区分。

再次分享时不要包含 QWeather.local.json、缓存、日志、备份、临时文件、个人坐标或网络出口记录。.gitignore 只影响未跟踪文件的 Git 操作，不会阻止压缩软件打入个人文件，也不会清理已经提交的历史。

ipwho.is 城市定位是估计；VPN出口城市、模型网格、城市天气产品可能各不相同。缓存保留不等于数据实时。来源名称和链接不应被移除或遮挡。
