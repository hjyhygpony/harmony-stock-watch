import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { wantAgent, Want } from '@kit.AbilityKit';
import type { WantAgent } from '@kit.AbilityKit';

/**
 * 股票行情通知模块 - 严格按照华为官方文档实现
 * 功能：
 * 1. 预设条件检查（支持复杂逻辑表达式）
 * 2. 系统通知栏消息推送
 * 3. 点击消息跳转到对应股票行情
 * 4. 冷却期机制防止频繁提醒
 */

// 定义通知冷却时间（单位：毫秒）。300秒 = 5分钟
const COOLDOWN_PERIOD = 300 * 1000;

// --- 数据结构定义 ---

export interface StockTicker {
  symbol: string;
  name: string;
  price: number;
}

// 策略条件定义（支持复杂逻辑）
interface StrategyCondition {
  id: number;
  name: string;
  condition: (latestPrices: Map<string, StockTicker>) => boolean;
  title: string;
  message: string;
  symbols: string[];
  lastTriggerTime: number;
}

// --- 策略和数据存储 ---

// 存储所有股票的最新价格 (用于多股联动的条件判断)
const latestMarketPrices: Map<string, StockTicker> = new Map();

// 预设策略列表 - 演示复杂逻辑表达式
const strategies: StrategyCondition[] = [
  {
    id: 1,
    name: '茅台单股高价预警',
    symbols: ['600519'],
    // 逻辑表达式： 价格 > 1755
    condition: (prices: Map<string, StockTicker>): boolean => {
      const maotai = prices.get('600519');
      return maotai ? maotai.price > 1755 : false;
    },
    title: '【高价预警】茅台',
    message: '贵州茅台价格突破 1755.00！',
    lastTriggerTime: 0
  },
  {
    id: 2,
    name: '多股联动交易信号',
    symbols: ['600519', '000002'],
    // 逻辑表达式： (茅台 > 1750) AND (万科 < 10.5)
    condition: (prices: Map<string, StockTicker>): boolean => {
      const maotai = prices.get('600519');
      const wanke = prices.get('000002');
      return maotai && wanke ? (maotai.price > 1750 && wanke.price < 10.5) : false;
    },
    title: '【联动提醒】市场异动',
    message: '茅台突破 1750 且万科跌破 10.5，注意市场风险！',
    lastTriggerTime: 0
  }
];

// --- 核心业务逻辑：策略检查 ---

export function checkStrategy(ticker: StockTicker): void {
  // 1. 更新最新价格
  latestMarketPrices.set(ticker.symbol, ticker);

  const currentTime = new Date().getTime();

  // 2. 遍历所有策略进行检查
  strategies.forEach((strategy: StrategyCondition) => {
    // 仅检查依赖当前更新股票的策略
    if (strategy.symbols.includes(ticker.symbol)) {

      // 3. 执行策略的逻辑表达式判断
      const isConditionMet = strategy.condition(latestMarketPrices);
      const isCooldownOver = (currentTime - strategy.lastTriggerTime) > COOLDOWN_PERIOD;

      if (isConditionMet && isCooldownOver) {
        // 条件满足 且 冷却期已过
        console.info("Strategy matched and Cooldown over: " + strategy.name);

        // 触发通知
        const targetTicker = latestMarketPrices.get(strategy.symbols[0]);
        if (targetTicker) {
          triggerNotification(strategy.title, strategy.message, targetTicker, strategy.id);
        }

        // 更新上次触发时间，开始冷却
        strategy.lastTriggerTime = currentTime;
      }
    }
  });
}

// --- 通知中心：系统通知 ---

function triggerNotification(title: string, msg: string, ticker: StockTicker, strategyId: number): void {
  // 计算通知ID
  const notificationId = strategyId * 10000 + ticker.symbol.charCodeAt(0);

  // 构造 WantAgentInfo - 严格按照官方文档
  const wantAgentInfo: wantAgent.WantAgentInfo = {
    wants: [
      {
        deviceId: '',
        bundleName: 'com.example.myfirstapplication', // 实际的包名
        abilityName: 'EntryAbility',
        parameters: {
          page: 'DetailPage',
          symbol: ticker.symbol
        }
      } as Want
    ],
    actionType: wantAgent.OperationType.START_ABILITY,
    requestCode: notificationId,
    wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
  };

  // 创建WantAgent - 使用Promise方式
  wantAgent.getWantAgent(wantAgentInfo).then((agent: WantAgent) => {
    // 构造通知Request对象 - 严格按照官方文档
    const notificationRequest: notificationManager.NotificationRequest = {
      id: notificationId,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: title,
          text: msg + " 当前 " + ticker.symbol + ": " + ticker.price.toFixed(2),
          additionalText: ticker.name
        }
      },
      wantAgent: agent
    };

    // 发布通知 - 使用Promise方式
    notificationManager.publish(notificationRequest).then(() => {
      console.info("Succeeded in publishing notification.");
    }).catch((err: BusinessError) => {
      console.error("Failed to publish notification. Code is " + err.code + ", message is " + err.message);
    });

  }).catch((err: BusinessError) => {
    console.error("getWantAgent failed, code: " + err.code + ", message: " + err.message);
  });
}