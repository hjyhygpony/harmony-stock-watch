import { AlertRule, Condition } from './StockData';
import { AlertRuleEngine } from './AlertRuleEngine';

/**
 * 预设规则库
 * 基于实际获取的A股股票创建预设规则
 */

export class AlertRulePresets {
  /**
   * 创建所有预设规则
   * 使用实际的A股股票代码（按股票代码排序的前20只）
   */
  public static createAllPresets(): AlertRule[] {
    return [
      // 单股价格预警
      AlertRulePresets.createPriceAlert('000001', '平安银行', 12),
      AlertRulePresets.createLowPriceAlert('000002', '万科A', 8),
      AlertRulePresets.createPriceRangeAlert('000004', '国华网安', 15, 25),

      // 银行股联动预警
      AlertRulePresets.createBankStocksAlert(),

      // 涨跌幅预警（通用）
      AlertRulePresets.createVolatilityAlert()
    ];
  }

  /**
   * 单股高价预警
   */
  private static createPriceAlert(code: string, name: string, threshold: number): AlertRule {
    const engine = AlertRuleEngine.getInstance();
    return engine.createSimpleRule(
      `preset_high_${code}`,
      `${name}突破${threshold}元`,
      code,
      'gt',
      threshold
    );
  }

  /**
   * 单股低价预警
   */
  private static createLowPriceAlert(code: string, name: string, threshold: number): AlertRule {
    const engine = AlertRuleEngine.getInstance();
    return engine.createSimpleRule(
      `preset_low_${code}`,
      `${name}跌破${threshold}元`,
      code,
      'lt',
      threshold
    );
  }

  /**
   * 价格区间预警
   */
  private static createPriceRangeAlert(code: string, name: string, low: number, high: number): AlertRule {
    const engine = AlertRuleEngine.getInstance();
    return engine.createSimpleRule(
      `preset_range_${code}`,
      `${name}价格区间${low}-${high}`,
      code,
      'between',
      [low, high]
    );
  }

  /**
   * 银行股联动预警
   * 条件：平安银行 > 11 且 万科A < 9
   */
  private static createBankStocksAlert(): AlertRule {
    const engine = AlertRuleEngine.getInstance();
    const conditions: Condition[] = [
      { stockId: '000001', op: 'gt', value: 11 },
      { stockId: '000002', op: 'lt', value: 9 }
    ];
    return engine.createAndRule(
      'preset_bank_combo',
      '银行地产联动信号',
      conditions
    );
  }

  /**
   * 多股异动预警（OR逻辑）
   * 任一股票触发条件即预警
   */
  private static createVolatilityAlert(): AlertRule {
    const engine = AlertRuleEngine.getInstance();
    const conditions: Condition[] = [
      { stockId: '000001', op: 'gt', value: 13 },
      { stockId: '000002', op: 'lt', value: 7 },
      { stockId: '000004', op: 'gt', value: 30 }
    ];
    return engine.createOrRule(
      'preset_volatility',
      '多股异动监控',
      conditions
    );
  }

  /**
   * 初始化预设规则到引擎
   */
  public static initializePresets(): void {
    const engine = AlertRuleEngine.getInstance();
    const presets = AlertRulePresets.createAllPresets();
    presets.forEach(preset => {
      engine.addRule(preset);
    });
    console.info(`Initialized ${presets.length} preset rules`);
  }
}
