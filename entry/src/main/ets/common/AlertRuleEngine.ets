import { Condition, RuleNode, AlertRule, ComparisonOp, LogicalOp } from './StockData';
import { StockTicker } from './Notification';
import { NotificationManagerService } from './NotificationManager';

/**
 * 预设条件引擎
 * 支持复杂的逻辑表达式，如：
 * - 单个条件：股票600519价格 > 1750
 * - AND逻辑：(600519 > 1750) AND (000002 < 10.5)
 * - OR逻辑：(600519 > 1750) OR (000002 < 10.5)
 * - NOT逻辑：NOT (600519 > 1750)
 * - 复杂表达式：((600519 > 1750) AND (000002 < 10.5)) OR (600000 between 100, 200)
 */

// 冷却期（毫秒），防止同一规则频繁触发
const RULE_COOLDOWN_PERIOD = 300 * 1000; // 5分钟

export class AlertRuleEngine {
  private static instance: AlertRuleEngine;
  private rules: Map<string, AlertRule> = new Map();
  private latestPrices: Map<string, number> = new Map();
  private latestTickers: Map<string, StockTicker> = new Map();

  private constructor() {
  }

  public static getInstance(): AlertRuleEngine {
    if (!AlertRuleEngine.instance) {
      AlertRuleEngine.instance = new AlertRuleEngine();
    }
    return AlertRuleEngine.instance;
  }

  /**
   * 添加预设规则
   */
  public addRule(rule: AlertRule): void {
    this.rules.set(rule.id, rule);
    console.info("Rule added: " + rule.name);
  }

  /**
   * 删除规则
   */
  public removeRule(ruleId: string): void {
    this.rules.delete(ruleId);
    console.info("Rule removed: " + ruleId);
  }

  /**
   * 获取所有规则
   */
  public getAllRules(): AlertRule[] {
    return Array.from(this.rules.values());
  }

  /**
   * 更新股票价格并检查所有规则
   */
  public updatePrice(ticker: StockTicker): AlertRule[] {
    this.latestPrices.set(ticker.symbol, ticker.price);
    this.latestTickers.set(ticker.symbol, ticker);
    const triggeredRules: AlertRule[] = [];
    const currentTime = new Date().getTime();

    this.rules.forEach((rule: AlertRule) => {
      if (!rule.enabled) {
        return;
      }

      // 检查冷却期
      const lastTriggered = rule.lastTriggeredAt || 0;
      if ((currentTime - lastTriggered) < RULE_COOLDOWN_PERIOD) {
        return;
      }

      // 评估规则
      if (this.evaluateRule(rule)) {
        triggeredRules.push(rule);
        rule.lastTriggeredAt = currentTime;

        // 发送通知
        this.sendRuleNotification(rule, ticker);
      }
    });

    return triggeredRules;
  }

  /**
   * 发送规则触发通知
   */
  private sendRuleNotification(rule: AlertRule, ticker: StockTicker): void {
    const notificationManager = NotificationManagerService.getInstance();
    notificationManager.sendNotification({
      title: "【行情预警】" + rule.name,
      text: "规则触发: " + ticker.symbol + " 当前价格: " + ticker.price.toFixed(2),
      additionalText: ticker.name,
      symbol: ticker.symbol
    });
    console.info("Rule notification sent: " + rule.name);
  }

  /**
   * 评估规则是否满足条件
   */
  private evaluateRule(rule: AlertRule): boolean {
    return this.evaluateNode(rule.root);
  }

  /**
   * 递归评估规则节点
   */
  private evaluateNode(node: RuleNode): boolean {
    if (node.type === 'condition' && node.condition) {
      return this.evaluateCondition(node.condition);
    }

    if (node.type === 'logic' && node.op && node.children) {
      return this.evaluateLogic(node.op, node.children);
    }

    return false;
  }

  /**
   * 评估单个条件
   */
  private evaluateCondition(condition: Condition): boolean {
    const price = this.latestPrices.get(condition.stockId);
    if (price === undefined) {
      return false;
    }

    switch (condition.op) {
      case 'gt':
        return price > (condition.value as number);
      case 'gte':
        return price >= (condition.value as number);
      case 'lt':
        return price < (condition.value as number);
      case 'lte':
        return price <= (condition.value as number);
      case 'eq':
        return price === (condition.value as number);
      case 'between':
        const range = condition.value as [number, number];
        const min = range[0];
        const max = range[1];
        return price >= min && price <= max;
      default:
        return false;
    }
  }

  /**
   * 评估逻辑操作
   */
  private evaluateLogic(op: LogicalOp, children: RuleNode[]): boolean {
    switch (op) {
      case 'and':
        return children.every(child => this.evaluateNode(child));
      case 'or':
        return children.some(child => this.evaluateNode(child));
      case 'not':
        return !this.evaluateNode(children[0]);
      default:
        return false;
    }
  }

  /**
   * 创建简单的单条件规则
   */
  public createSimpleRule(
    id: string,
    name: string,
    stockId: string,
    op: ComparisonOp,
    value: number | [number, number]
  ): AlertRule {
    return {
      id,
      name,
      enabled: true,
      root: {
        type: 'condition',
        condition: {
          stockId,
          op,
          value
        }
      }
    };
  }

  /**
   * 创建AND规则
   */
  public createAndRule(id: string, name: string, conditions: Condition[]): AlertRule {
    return {
      id,
      name,
      enabled: true,
      root: {
        type: 'logic',
        op: 'and',
        children: conditions.map(cond => ({
          type: 'condition',
          condition: cond
        } as RuleNode))
      }
    };
  }

  /**
   * 创建OR规则
   */
  public createOrRule(id: string, name: string, conditions: Condition[]): AlertRule {
    return {
      id,
      name,
      enabled: true,
      root: {
        type: 'logic',
        op: 'or',
        children: conditions.map(cond => ({
          type: 'condition',
          condition: cond
        } as RuleNode))
      }
    };
  }
}
