# 署名、许可证与数据来源

## 皮肤及派生部分

原项目：[MontereyRainmeter](https://github.com/creewick/MontereyRainmeter)，作者 Creewick。当前副本包含对日历、天气适配、配色、材质、农历和安装说明的修改；历史变更见 [CHANGELOG.md](CHANGELOG.md)。本项目是独立修改版，不暗示上游作者、Rainmeter 或天气服务提供方背书。

皮肤及派生部分继续使用 **Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International（CC BY-NC-SA 4.0）**。[许可证说明](https://creativecommons.org/licenses/by-nc-sa/4.0/)，[随包完整文本](LICENSE.txt)。`Qingli/LICENSE.txt` 保留原文件；根目录文本是同一文件的副本。

请遵守署名、非商业、修改标记和相同方式共享等原许可证条件，不将整个派生包改为 MIT。它具有非商业限制，因此不能仅因源码可见就宣称符合 [OSI 开源定义](https://opensource.org/osd)。

## 第三方图标

| 资源 | 作者/来源 | 独立许可证与记录 |
| --- | --- | --- |
| 12 张天气 PNG | Bas Milius / [Meteocons](https://github.com/basmilius/meteocons)，3.0.0-next.10 静态 fill | [MIT 原文](Qingli/THIRD-PARTY-METEOCONS-LICENSE.txt)、[逐图来源及哈希](Qingli/METEOCONS-SOURCES.json) |
| location.svg、location.png | [Phosphor Icons](https://github.com/phosphor-icons/core)，map-pin-fill | [MIT 原文](Qingli/THIRD-PARTY-PHOSPHOR-LICENSE.txt)、[修改说明](Qingli/ICON-SOURCE.txt) |

天气图标记录包含 PNG 导出及透明留白归一化；定位图标记录包含白色填充与栅格化。当前整理未改动任何图标。上述资源仍适用各自 MIT 授权，不因整包的非商业条件而更改原始授权。再次分发时保留相应版权和许可文本。

## 运行环境与农历数据

Rainmeter 请从其[官网](https://www.rainmeter.net/)单独获取；本副本不包含其程序或插件二进制。字体仅引用 Windows 的 Segoe UI 和 Microsoft YaHei UI，不附字体文件。Windows PowerShell/.NET 属于可选和风路径的运行环境，不在本包内分发。

`Lunar.lua` 中的离线月历表按原代码说明生成自 Windows .NET ChineseLunisolarCalendar；参考[微软文档](https://learn.microsoft.com/en-us/dotnet/api/system.globalization.chineselunisolarcalendar)。它不是在线农历服务。本次未重生或重新验证全部历表数据。

## 天气和定位服务

- 默认天气：[Open-Meteo](https://open-meteo.com/)。数据采用 [CC BY 4.0](https://open-meteo.com/en/licence)，免费 API 另受[服务条款](https://open-meteo.com/en/terms)约束。界面保留来源文字及链接，文档说明温度取整、天气码图标适配与五日裁剪等显示处理。
- 可选天气：[和风天气 / QWeather](https://www.qweather.com/)。按[归因要求](https://dev.qweather.com/docs/terms/attribution/)保留来源文字和可点击链接；使用者自行确认账号授权、费用、额度与[服务条款](https://dev.qweather.com/docs/terms/)。当前城市 v7 接口有弃用提示，详见 [QWeather.md](docs/QWEATHER.md)。
- IP 定位：[ipwho.is / IPWhois](https://ipwhois.io/)，使用其[API 文档](https://ipwhois.io/documentation)及[服务条款](https://ipwhois.io/terms)。第三方定位数据和服务不随皮肤转授为 CC BY-NC-SA 或 MIT。

服务条款及可用性可能变化。本包不提供天气数据准确度、长期接口可用性或商业使用授权保证。
