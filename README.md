# 晴历 Qingli 0.1.0-beta.2

Rainmeter 日历与天气的公开源码 Beta。仓库名 `qingli-widgets`；当前仅公开源码，尚未发布安装包 Release，名称商标可用性尚未完成核验。

从 [Rainmeter 官网](https://www.rainmeter.net/) 单独安装 Rainmeter。全新试用时，将仓库中的 `Qingli` 文件夹复制到一个独立环境的 `Skins` 目录，刷新皮肤列表，再手动加载 `Qingli/Start/Start.ini`，先创建缺失配置，再显示两卡。已有同名目录时请勿删除或直接覆盖个人配置，先阅读下方升级说明。

本版为保护升级数据，只携带 `Settings.defaults.inc`、`Accent.defaults.inc`、`Material.defaults.inc`。首次启动仅创建不存在的个人配置；已有 Settings.inc、Accent.inc、Material.inc 和 QWeather.local.json 不覆盖。安装器设置 Merge skins，不附布局，不自动加载 Start，也不替换 Rainmeter.ini。

**升级时**先退出虚拟机的 Rainmeter，再安装新版并重新启动。加载原两卡即可保留原位置；不要再次加载 Start，它会主动重排。完整简单验收步骤见 [虚拟机安装测试](docs/VM-INSTALL-TEST.md)。首次加载前希望关闭IP定位时，可将Settings.defaults.inc复制为Settings.inc，改为Manual并填写本人选择的城市坐标。

默认 OpenMeteo，无需个人密钥；默认 AutoIP 会联网估计城市，DirectRouteVerified=0。设置、配色和材质路径仍在 `Qingli/@Resources/Refined/`。可选和风模式仍使用即将弃用的v7城市接口，详见 [和风说明](docs/QWEATHER.md)。

上游 Creewick / [MontereyRainmeter](https://github.com/creewick/MontereyRainmeter)，皮肤及派生部分保留 CC BY-NC-SA 4.0；Meteocons/Phosphor图标分别保留MIT，见 [署名](ATTRIBUTION.md) 和 [许可证](LICENSE.txt)。

当前已做文件级及首次初始化检查，官方安装包也已在本地生成；真实全新安装、升级、字体/DPI及天气连通性尚待虚拟机验收。本仓库先公开源码和已知限制，安装包 Release 另行安排。

源码ZIP及皮肤ZIP可由 `python tools/build.py --output <输出目录>` 重建；`.rmskin` 必须另外使用官方 Skin Packager，选Merge skins、Do nothing，不选layout、不填Variables files。
