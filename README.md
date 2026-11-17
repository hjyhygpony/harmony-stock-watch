# Harmony Stock Watch

基于 HarmonyOS / ArkTS 的股票行情与预警应用。项目包含行情列表、股票详情、K 线图、搜索、自选分组、预警规则、通知中心、桌面卡片和 WebSocket 实时行情。

## 功能

- 股票行情列表与市场指数卡片
- 股票搜索和详情页
- K 线图展示
- 自选股分组管理
- 价格、涨跌幅等预警规则
- 预警预设与本地持久化
- 通知中心和震动静默控制
- HarmonyOS Form 桌面卡片
- WebSocket 实时行情订阅
- 模拟器/真机本地服务切换

## 技术栈

| 层 | 技术 |
|---|---|
| 客户端 | HarmonyOS、ArkTS、ArkUI |
| 实时通信 | WebSocket |
| 本地存储 | Preferences |
| 系统能力 | Notification、Form Extension、Vibrator |
| 构建 | DevEco Studio、Hvigor |
| SDK | HarmonyOS 6.0.0 / API 20 |

## 项目结构

```text
harmony-stock-watch/
├─ AppScope/
├─ entry/
│  └─ src/main/
│     ├─ ets/
│     │  ├─ pages/          # 首页、详情、搜索、预警、分组等页面
│     │  ├─ components/     # K 线图、股票列表项、行情卡片
│     │  ├─ common/         # 数据模型、存储、预警引擎、WebSocket
│     │  ├─ entryability/   # 应用入口
│     │  ├─ entryformability/
│     │  └─ widget/
│     └─ resources/
├─ hvigor/
├─ build-profile.json5
├─ oh-package.json5
└─ README.md
```

## 后端依赖

这个仓库只包含 HarmonyOS 客户端。默认后端地址为：

```text
REST:      http://10.0.2.2:8013
WebSocket: ws://10.0.2.2:8013/ws/market/quotes
```

`10.0.2.2` 是 HarmonyOS 模拟器访问宿主机的地址。真机测试时需要替换为电脑的局域网 IP 或可访问的服务器地址。

相关常量分布在这些文件中：

```text
entry/src/main/ets/pages/Index.ets
entry/src/main/ets/pages/HomePage.ets
entry/src/main/ets/pages/DetailPage.ets
entry/src/main/ets/pages/SearchPage.ets
entry/src/main/ets/pages/AlertCenterPage.ets
entry/src/main/ets/pages/GroupPage.ets
entry/src/main/ets/entryformability/EntryFormAbility.ets
entry/src/main/ets/common/WebSocketService.ets
```

如果后端需要认证，可以在对应页面中填写 `API_KEY`；当前源码默认为空。

## 运行

1. 使用 DevEco Studio 打开本目录。
2. 等待 Hvigor 同步依赖。
3. 配置自动签名或自己的调试签名。
4. 启动 HarmonyOS 模拟器或连接真机。
5. 启动行情服务后运行应用。

仓库不包含：

- 机器专属 `local.properties`
- `oh_modules`
- `.hvigor` 缓存
- 系统镜像
- 签名证书和 profile
- 后端服务代码

## 权限

`module.json5` 中声明了：

- `ohos.permission.INTERNET`
- `ohos.permission.VIBRATE`
- `ohos.permission.NOTIFICATION_CONTROLLER`

## 说明

这是课程实践项目，主要用于演示 HarmonyOS ArkTS UI、实时行情订阅、本地状态管理和系统通知能力。行情数据与交易接口需要单独提供，不构成投资建议。
