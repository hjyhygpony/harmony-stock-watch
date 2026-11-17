import { WebSocketService } from './WebSocketService';
import { AlertRulePresets } from './AlertRulePresets';
import { NotificationManagerService } from './NotificationManager';
import { AlertRuleEngine } from './AlertRuleEngine';
import { StockTicker } from './Notification';

/**
 * 应用初始化器
 * 负责初始化所有系统组件
 */

export class AppInitializer {
  private static initialized: boolean = false;

  /**
   * 初始化应用
   * 应在EntryAbility的onCreate中调用
   */
  public static initialize(bundleName: string): void {
    if (AppInitializer.initialized) {
      return;
    }

    console.info("Initializing stock alert system...");

    // 1. 初始化通知管理器
    const notificationManager = NotificationManagerService.getInstance();
    notificationManager.setBundleName(bundleName);
    console.info("NotificationManager initialized");

    // 2. 初始化预设规则
    AlertRulePresets.initializePresets();
    console.info("AlertRulePresets initialized");

    // 3. 初始化WebSocket服务
    const wsService = WebSocketService.getInstance();

    // 注册消息回调
    wsService.onMessage((ticker: StockTicker) => {
      console.info("Received ticker: " + ticker.symbol + " = " + ticker.price);
    });

    // 连接WebSocket
    wsService.connect();
    console.info("WebSocketService initialized and connected");

    AppInitializer.initialized = true;
    console.info("Stock alert system initialized successfully");
  }

  /**
   * 销毁应用
   * 应在EntryAbility的onDestroy中调用
   */
  public static destroy(): void {
    const wsService = WebSocketService.getInstance();
    wsService.disconnect();
    console.info("Stock alert system destroyed");
    AppInitializer.initialized = false;
  }

  /**
   * 添加自定义规则
   * 用户可以通过行情通知中心界面添加规则
   */
  public static addCustomRules(): void {
    // 不再预设任何规则，用户可以在行情通知中心自行添加
    console.info("Custom rules can be added via AlertCenterPage");
  }

  /**
   * 获取初始化状态
   */
  public static isInitialized(): boolean {
    return AppInitializer.initialized;
  }
}
