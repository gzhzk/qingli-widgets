# 安装与升级

本版.rmskin使用官方Skin Packager，Merge skins开启，安装后Do nothing，不附layout。三个可写inc文件和Key不在包内，首次加载Start时仅创建缺失配置。已有文件与旧备份优先保留；初始化失败时不激活天气和日历。

首次安装加载Start；升级不加载Start，避免主动重排位置。本包不写主Rainmeter.ini，位置由原Rainmeter实例保存。切勿先删除旧Qingli目录，也不要将整个运行目录压缩为分发包。

简单步骤见 [虚拟机安装测试](VM-INSTALL-TEST.md)。官方安装器在安装时可能退出Rainmeter，请只在虚拟机测试，不在宿主机尝试。
