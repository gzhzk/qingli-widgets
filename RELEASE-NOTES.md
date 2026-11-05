# 晴历 Qingli 0.1.0-beta.2 — Beta 预览版

新增官方 .rmskin 安装包，采用 Merge skins、Do nothing，无全局 layout。默认配置改为模板，Start只初始化缺失的个人配置；已有Key、设置、配色和材质不覆盖。首次安装加载Start；升级不要加载Start，避免主动重排位置。

新增 [Agent 安装说明](AGENT-INSTALL.md)，提供固定版本下载、SHA256 校验、安装预览及保留个人配置的升级步骤。

附件：官方 `.rmskin`、skin ZIP、source ZIP、`AGENT-INSTALL.md` 和 `SHA256SUMS.txt`。人工安装优先使用 `.rmskin`；Agent 使用 skin ZIP 与包内安装脚本。

安装前核对 SHA256。首次加载 Start；升级只沿用原卡片，不重新加载 Start。默认 Open-Meteo 无需个人 Key；可选和风凭据只保存在用户本地。

包内容与隐私检查、Lua 初始化及合成目录安装升级测试已完成。真实电脑上的官方安装器全新安装/升级、DPI 与天气联网尚未全面验收，因此作为预发布 Beta 提供。商标核验未完成，和风城市 v7 接口尚未迁移，全部许可证和上游署名保留。
