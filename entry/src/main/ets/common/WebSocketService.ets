import { webSocket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { checkStrategy, StockTicker } from './Notification';
import { AlertRuleEngine } from './AlertRuleEngine';

/**
 * WebSocket服务 - 严格按照华为官方文档实现
 * 参考: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/websocket-connection
 */
export class WebSocketService {
  private static instance: WebSocketService;
  private ws: webSocket.WebSocket | null = null;
  private serverUrl: string = "ws://10.0.2.2:8013/ws/market/quotes";
  private isConnected: boolean = false;
  private reconnectAttempts: number = 0;
  private maxReconnectAttempts: number = 5;
  private reconnectDelay: number = 3000;
  private messageCallbacks: ((ticker: StockTicker) => void)[] = [];

  private constructor() {}

  public static getInstance(): WebSocketService {
    if (!WebSocketService.instance) {
      WebSocketService.instance = new WebSocketService();
    }
    return WebSocketService.instance;
  }

  /**
   * 注册消息回调
   */
  public onMessage(callback: (ticker: StockTicker) => void): void {
    this.messageCallbacks.push(callback);
  }

  /**
   * 连接到WebSocket服务器
   */
  public connect(): void {
    if (this.isConnected) return;

    // 1. 创建WebSocket连接，返回一个WebSocket对象
    this.ws = webSocket.createWebSocket();

    // 2. 订阅WebSocket的打开事件
    this.ws.on('open', (err: BusinessError, value: Object) => {
      console.info("on open, status:" + JSON.stringify(value));
      if (!err) {
        this.isConnected = true;
        this.reconnectAttempts = 0;
        // 当收到on('open')事件时，可以通过send()方法与服务器进行通信
        this.subscribeToStocks(['600519', '000002', '600000']);
      }
    });

    // 3. 订阅WebSocket的消息接收事件
    this.ws.on('message', (err: BusinessError, value: string | ArrayBuffer) => {
      console.info("on message, message:" + value);
      if (!err && typeof value === 'string') {
        this.handleMessage(value);
      }
    });

    // 4. 订阅WebSocket的关闭事件
    this.ws.on('close', (err: BusinessError, value: webSocket.CloseResult) => {
      console.info("on close, code is " + value.code + ", reason is " + value.reason);
      this.isConnected = false;
      this.attemptReconnect();
    });

    // 5. 订阅WebSocket的Error事件
    this.ws.on('error', (err: BusinessError) => {
      console.error("on error, error:" + JSON.stringify(err));
      this.isConnected = false;
    });

    // 6. 根据URL地址，发起WebSocket连接
    this.ws.connect(this.serverUrl, (err: BusinessError, value: boolean) => {
      if (!err) {
        console.info("Connected successfully");
      } else {
        console.error("Connection failed. Err:" + JSON.stringify(err));
        this.attemptReconnect();
      }
    });
  }

  /**
   * 订阅股票
   */
  public subscribeToStocks(symbols: string[]): void {
    const msg = JSON.stringify({
      action: 'subscribe',
      symbols: symbols
    });
    this.sendMessage(msg);
  }

  /**
   * 发送消息 - 严格按照官方文档的send()方法
   */
  public sendMessage(msg: string): void {
    if (this.ws && this.isConnected) {
      this.ws.send(msg, (err: BusinessError, value: boolean) => {
        if (!err) {
          console.info("Message send successfully");
        } else {
          console.error("Failed to send the message. Err:" + JSON.stringify(err));
        }
      });
    }
  }

  /**
   * 断开连接 - 严格按照官方文档的close()方法
   */
  public disconnect(): void {
    if (this.ws) {
      this.ws.close((err: BusinessError, value: boolean) => {
        if (!err) {
          console.info("Connection closed successfully");
        } else {
          console.error("Failed to close the connection. Err: " + JSON.stringify(err));
        }
      });
      this.isConnected = false;
    }
  }

  /**
   * 尝试重新连接
   */
  private attemptReconnect(): void {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++;
      console.info(`Attempting to reconnect... (${this.reconnectAttempts}/${this.maxReconnectAttempts})`);
      setTimeout(() => {
        this.connect();
      }, this.reconnectDelay);
    } else {
      console.error("Max reconnect attempts reached");
    }
  }

  /**
   * 处理接收到的行情数据
   */
  private handleMessage(jsonStr: string): void {
    try {
      const data = JSON.parse(jsonStr) as Record<string, Object>;

      if (data.type === 'TICKER' || data.type === 'quote') {
        const ticker: StockTicker = {
          symbol: (data.symbol || data.code) as string,
          name: (data.name || data.symbol) as string,
          price: parseFloat(data.price as string) || 0
        };

        // 触发所有注册的回调
        this.messageCallbacks.forEach(callback => {
          try {
            callback(ticker);
          } catch (e) {
            console.error("Callback error: " + JSON.stringify(e));
          }
        });

        // 调用预设策略检查
        checkStrategy(ticker);

        // 调用规则引擎检查
        const engine = AlertRuleEngine.getInstance();
        const triggeredRules = engine.updatePrice(ticker);
        triggeredRules.forEach(rule => {
          console.info("Rule triggered: " + rule.name);
        });
      }
    } catch (e) {
      console.error("JSON Parse Error or Message Format Invalid");
    }
  }

  /**
   * 获取连接状态
   */
  public isConnectedStatus(): boolean {
    return this.isConnected;
  }
}
