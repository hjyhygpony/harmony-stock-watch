// import notificationManager from '@ohos.notificationManager';
// import wantAgent, { WantAgent } from '@ohos.app.ability.wantAgent';
// import { BusinessError } from '@ohos.base';
//
// export class NotificationService {
//
//   static async push(title: string, text: string, params?: Record<string, string>) {
//     try {
//       const stockId = params?.['id'] ?? '';
//
//       // 1. 构造点击通知后的跳转行为 (WantAgent)
//       // HarmonyOS NEXT Stage 模型标准写法
//       let wantInfo: wantAgent.WantAgentInfo = {
//         wants: [
//           {
//             // 🔴 重点：请务必确保这里与你的 app.json5 / module.json5 一致
//             bundleName: 'com.example.myfirstapplication',
//             abilityName: 'EntryAbility',
//             moduleName: 'entry',
//             parameters: {
//               'targetPage': 'pages/DetailPage',
//               'stockId': stockId
//             }
//           }
//         ],
//         operationType: wantAgent.OperationType.START_ABILITY,
//         requestCode: 0,
//         wantAgentFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG]
//       };
//
//       // 获取 WantAgent 实例
//       let want: WantAgent = await wantAgent.getWantAgent(wantInfo);
//
//       // 2. 构造通知请求对象
//       // 关键点：变量类型必须显式指定为 notificationManager 下的类型
//       let notificationRequest: notificationManager.NotificationRequest = {
//         id: Math.floor(Date.now() / 1000), // ID 需为数字
//
//         // API 20/NEXT 中，推荐使用 SOCIAL_COMMUNICATION 以获得较高的提醒优先级（横幅+声音）
//         // 如果你的 IDE 提示 SERVICE_INFORMATION 可用，也可以换回 SERVICE_INFORMATION
//         slotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
//
//         content: {
//           // 类型必须匹配 notificationManager.ContentType
//           contentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
//
//           // 普通文本通知内容
//           normal: {
//             title: title,
//             text: text,
//             additionalText: '行情异动'
//           }
//         },
//
//         // 绑定点击跳转动作
//         wantAgent: want
//       };
//
//       // 3. 发布通知
//       await notificationManager.publish(notificationRequest);
//       console.info('Notification: 推送成功');
//
//     } catch (err) {
//       // 捕获 BusinessError
//       let error = err as BusinessError;
//       console.error(`Notification push 失败: code=${error.code}, message=${error.message}`);
//     }
//   }
// }