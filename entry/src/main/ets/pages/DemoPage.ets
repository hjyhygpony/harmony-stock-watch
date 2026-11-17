import { WebSocketService } from '../common/WebSocketService';
import { AlertRuleEngine } from '../common/AlertRuleEngine';
import { NotificationManagerService } from '../common/NotificationManager';
import { StockTicker } from '../common/Notification';
import { AlertRule } from '../common/StockData';

/**
 * 演示页面 - 测试WebSocket股票推送系统
 */

@Entry
@Component
export struct DemoPage {
  @State wsConnected: boolean = false;
  @State lastTicker: string = '等待行情数据...';
  @State testStockCode: string = '000001';
  @State testPrice: string = '10.50';
  @State testStockName: string = '平安银行';
  @State logMessages: string[] = [];

  private wsService: WebSocketService = WebSocketService.getInstance();
  private notificationManager: NotificationManagerService = NotificationManagerService.getInstance();
  private engine: AlertRuleEngine = AlertRuleEngine.getInstance();

  aboutToAppear() {
    this.checkConnection();
    this.setupWebSocketListener();
  }

  private checkConnection(): void {
    this.wsConnected = this.wsService.isConnectedStatus();
  }

  private setupWebSocketListener(): void {
    this.wsService.onMessage((ticker: StockTicker) => {
      this.lastTicker = ticker.symbol + ' (' + ticker.name + '): ¥' + ticker.price.toFixed(2);
      this.addLog('收到行情: ' + ticker.symbol + ' = ' + ticker.price.toString());
    });
  }

  private addLog(message: string): void {
    const timestamp = new Date().toLocaleTimeString();
    this.logMessages.unshift('[' + timestamp + '] ' + message);
    if (this.logMessages.length > 20) {
      this.logMessages.pop();
    }
  }

  private connectWebSocket(): void {
    this.wsService.connect();
    this.addLog('正在连接WebSocket...');
    setTimeout(() => {
      this.checkConnection();
    }, 1000);
  }

  private disconnectWebSocket(): void {
    this.wsService.disconnect();
    this.wsConnected = false;
    this.addLog('已断开WebSocket连接');
  }

  private subscribeStocks(): void {
    // 订阅测试输入框中的股票
    this.wsService.subscribeToStocks([this.testStockCode]);
    this.addLog('已订阅股票: ' + this.testStockCode);
  }

  private sendTestNotification(): void {
    this.notificationManager.sendNotification({
      title: '【测试通知】行情异动',
      text: this.testStockName + '(' + this.testStockCode + ')价格突破 ' + this.testPrice,
      additionalText: this.testStockName,
      symbol: this.testStockCode
    });
    this.addLog('已发送测试通知: ' + this.testStockName);
  }

  private simulateMarketData(): void {
    // 使用测试输入框中的股票信息模拟行情
    const ticker: StockTicker = {
      symbol: this.testStockCode,
      name: this.testStockName,
      price: parseFloat(this.testPrice) + (Math.random() - 0.5) * 2
    };

    const rules: AlertRule[] = this.engine.updatePrice(ticker);
    this.lastTicker = ticker.symbol + ' (' + ticker.name + '): ¥' + ticker.price.toFixed(2);
    this.addLog('模拟行情: ' + ticker.symbol + ' = ' + ticker.price.toFixed(2));

    if (rules.length > 0) {
      rules.forEach((rule: AlertRule) => {
        this.addLog('✓ 规则触发: ' + rule.name);
      });
    }
  }

  private showAllRules(): void {
    const rules: AlertRule[] = this.engine.getAllRules();
    this.addLog('共有 ' + rules.length.toString() + ' 条规则');
    rules.forEach((rule: AlertRule) => {
      this.addLog('- ' + rule.name + ' (' + (rule.enabled ? '启用' : '禁用') + ')');
    });
  }

  private clearLogs(): void {
    this.logMessages = [];
    this.addLog('日志已清空');
  }

  build() {
    Column() {
      // 标题
      Text('WebSocket 股票推送系统演示')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .padding(16)

      // 连接状态
      Row() {
        Circle()
          .width(12)
          .height(12)
          .fill(this.wsConnected ? '#4CAF50' : '#F44336')
        Text(this.wsConnected ? '已连接' : '未连接')
          .fontSize(14)
          .margin({ left: 8 })
      }
      .padding(12)
      .backgroundColor(this.wsConnected ? '#E8F5E9' : '#FFEBEE')
      .borderRadius(4)
      .margin({ left: 16, right: 16, bottom: 16 })

      // 最新行情
      Column() {
        Text('最新行情')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ bottom: 8 })
        Text(this.lastTicker)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F5F5F5')
      .borderRadius(4)
      .margin({ left: 16, right: 16, bottom: 16 })

      // 操作按钮
      Column() {
        Text('WebSocket 操作')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ bottom: 8 })

        Row() {
          Button(this.wsConnected ? '断开连接' : '连接')
            .layoutWeight(1)
            .onClick(() => {
              if (this.wsConnected) {
                this.disconnectWebSocket();
              } else {
                this.connectWebSocket();
              }
            })
          Button('订阅股票')
            .layoutWeight(1)
            .margin({ left: 8 })
            .onClick(() => {
              this.subscribeStocks();
            })
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Button('模拟行情')
            .layoutWeight(1)
            .onClick(() => {
              this.simulateMarketData();
            })
          Button('查看规则')
            .layoutWeight(1)
            .margin({ left: 8 })
            .onClick(() => {
              this.showAllRules();
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F5F5F5')
      .borderRadius(4)
      .margin({ left: 16, right: 16, bottom: 16 })

      // 测试通知
      Column() {
        Text('测试通知')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ bottom: 8 })

        TextInput({ placeholder: '股票代码', text: this.testStockCode })
          .onChange((value: string) => {
            this.testStockCode = value;
          })
          .margin({ bottom: 8 })

        TextInput({ placeholder: '股票名称', text: this.testStockName })
          .onChange((value: string) => {
            this.testStockName = value;
          })
          .margin({ bottom: 8 })

        TextInput({ placeholder: '价格', text: this.testPrice })
          .onChange((value: string) => {
            this.testPrice = value;
          })
          .margin({ bottom: 8 })

        Button('发送测试通知')
          .width('100%')
          .onClick(() => {
            this.sendTestNotification();
          })
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F5F5F5')
      .borderRadius(4)
      .margin({ left: 16, right: 16, bottom: 16 })

      // 日志
      Column() {
        Row() {
          Text('操作日志')
            .fontSize(12)
            .fontColor('#999999')
          Blank()
          Button('清空')
            .fontSize(11)
            .height(24)
            .onClick(() => {
              this.clearLogs();
            })
        }
        .width('100%')
        .margin({ bottom: 8 })

        List() {
          ForEach(this.logMessages, (log: string, index: number) => {
            ListItem() {
              Text(log)
                .fontSize(11)
                .fontColor('#666666')
            }
            .padding(8)
          }, (log: string, index: number) => index.toString())
        }
        .layoutWeight(1)
        .backgroundColor('#FFFFFF')
        .borderRadius(4)
      }
      .layoutWeight(1)
      .width('100%')
      .padding(12)
      .backgroundColor('#F5F5F5')
      .borderRadius(4)
      .margin({ left: 16, right: 16, bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
