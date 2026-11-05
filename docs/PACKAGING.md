# 官方打包设置

使用官方Rainmeter 4.5.28.3936 Skin Packager，来源为本机现有签名程序的独立副本。名称Qingli，作者Creewick; Qingli adaptation，版本0.1.0-beta.2。只选Qingli根皮肤，不加插件或layout；After installation=Do nothing；Advanced=Merge skins；Variables files留空。

包内不能含Settings.inc、Accent.inc、Material.inc或QWeather.local.json，只有各自.defaults.inc模板和空凭据示例。Start在首次加载时调用Bootstrap.lua，只初始化缺失inc；不读取或创建Key。升级保留旧文件，模板可以更新。

官方包创建后核对rmskin.ini、完整包内文件和官方格式尾部，计算SHA256；不要改写已生成包内内容。真实安装/升级仍由虚拟机执行。
