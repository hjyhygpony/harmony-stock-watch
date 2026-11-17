import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { wantAgent, Want } from '@kit.AbilityKit';
import type { WantAgent } from '@kit.AbilityKit';
import { vibrator } from '@kit.SensorServiceKit';

/**
 * 通知管理器 - 严格按照华为官方文档实现
 * 功能：
 * 1. 系统通知栏消息推送
 * 2. 点击消息跳转到对应股票行情
 * 3. 振铃提醒（振动）
 */

export interface NotificationOptions {
  title: string;
  text: string;
  additionalText?: string;
  symbol?: string;
  enableVibration?: boolean; // 是否启用振动
  enableSound?: boolean;     // 是否启用声音
}

export class NotificationManagerService {
  private static instance: NotificationManagerService;
  private notificationId: number = 1000;
  private bundleName: string = 'com.example.myfirstapplication';
  private abilityName: string = 'EntryAbility';

  private constructor() {}

  public static getInstance(): NotificationManagerService {
    if (!NotificationManagerService.instance) {
      NotificationManagerService.instance = new NotificationManagerService();
    }
    return NotificationManagerService.instance;
  }

  /**
   * 设置应用包名（需要在初始化时调用）
   */
  public setBundleName(bundleName: string): void {
    this.bundleName = bundleName;
  }

  /**
   * 触发振动提醒
   */
  private triggerVibration(): void {
    try {
      vibrator.startVibration({
        type: 'time',
        duration: 500
      }, {
        id: 0,
        usage: 'notification'
      }, (error: BusinessError) => {
        if (error) {
          console.error('Vibration failed: ' + JSON.stringify(error));
        } else {
          console.info('Vibration started');
        }
      });
    } catch (err) {
      console.error('Vibration error: ' + JSON.stringify(err));
    }
  }

  /**
   * 发送通知 - 严格按照官方文档
   */
  public sendNotification(options: NotificationOptions): void {
    const notificationId = this.notificationId++;

    // 触发振动提醒（默认启用）
    if (options.enableVibration !== false) {
      this.triggerVibration();
    }

    // 构造 WantAgentInfo - 严格按照官方文档
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          deviceId: '',
          bundleName: this.bundleName,
          abilityName: this.abilityName,
          parameters: {
            page: 'DetailPage',
            symbol: options.symbol || ''
          }
        } as Want
      ],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: notificationId,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };

    // 创建WantAgent
    wantAgent.getWantAgent(wantAgentInfo).then((agent: WantAgent) => {
      // 构造通知Request对象 - 严格按照官方文档
      const notificationRequest: notificationManager.NotificationRequest = {
        id: notificationId,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: options.title,
            text: options.text,
            additionalText: options.additionalText || ''
          }
        },
        wantAgent: agent,
        notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION // 使用社交通知槽，支持声音
      };

      // 发布通知
      notificationManager.publish(notificationRequest).then(() => {
        console.info("Succeeded in publishing notification.");
      }).catch((err: BusinessError) => {
        console.error("Failed to publish notification. Code is " + err.code + ", message is " + err.message);
      });

    }).catch((err: BusinessError) => {
      console.error("getWantAgent failed, code: " + err.code + ", message: " + err.message);
    });
  }

  /**
   * 取消通知 - 严格按照官方文档
   */
  public cancelNotification(notificationId: number): void {
    notificationManager.cancel(notificationId).then(() => {
      console.info("Succeeded in canceling notification.");
    }).catch((err: BusinessError) => {
      console.error("Failed to cancel notification. Code is " + err.code + ", message is " + err.message);
    });
  }

  /**
   * 取消所有通知 - 严格按照官方文档
   */
  public cancelAllNotifications(): void {
    notificationManager.cancelAll().then(() => {
      console.info("Succeeded in canceling all notification.");
    }).catch((err: BusinessError) => {
      console.error("Failed to cancel all notification. Code is " + err.code + ", message is " + err.message);
    });
  }
}
