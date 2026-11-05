# 维护与再次打包

本副本包含源码和资源，不含构建出的可执行程序；无需编译即可作为Rainmeter皮肤源码阅读。上游基准提交未随原快照保存，来源限制见 SOURCE-NOTES.json。

INI、Settings.inc 和部分主Lua脚本为UTF-16LE BOM；部分模块和配色文件为UTF-8/ASCII。应按各文件现有编码编辑，不能批量统一编码；改动后检查中文和dofile模块加载。

保留根目录与皮肤内许可证、第三方版权及图标来源记录。新增依赖或素材要补充来源、版本和授权；独立的MIT素材不应被重新声明为仅限非商业。

公开版本不带 QWeather.local.json、*-cache*.json、.bak、.tmp、.log、Rainmeter.ini、快捷方式、字体、EXE/DLL或个人安装器。文件白名单和内容脱敏都需要检查；.gitignore 不能代替压缩包检查或Git历史清理。

两个清单采用文件原始字节的SHA-256：

- 先生成 `Qingli/MANIFEST.json`：键为相对皮肤目录的路径，统一使用 `/`，值为小写SHA-256；包含皮肤全部文件，排除MANIFEST.json自身。
- 再生成根目录 `FILES.sha256`：每行 `小写哈希 + 两个空格 + 相对根目录路径`，覆盖源码白名单中的交付文件，排除FILES.sha256自身、dist与work；其中包含刚生成的MANIFEST.json。皮肤ZIP另由SHA256SUMS.txt和包内MANIFEST核验。
- 修改任何文件后重新生成并独立核验；清单不能作为作者签名。

使用 `python tools/build.py --output <本地输出目录>` 自动生成上述清单与附件。源码默认配置与用户实际安装目录分开维护，不能直接从运行目录出包。

对外打包前重复脱敏、默认配置、原始许可证字节、资源路径、压缩包内容及哈希核验；将真实运行验收与静态检查分开记录。最终包的 Qingli 载荷必须逐文件匹配当前源码，再生成发布附件的 SHA256SUMS.txt；不能从正在运行的皮肤目录出包。当前发布为 Beta，具体测试范围见 ../VALIDATION.md。
