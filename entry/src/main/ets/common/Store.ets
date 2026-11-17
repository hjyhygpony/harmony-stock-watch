// Store.ets
import data_preferences from '@ohos.data.preferences';
import type { Context } from '@kit.AbilityKit';
import { Stock, Group, AlertRule } from './StockData';
import { genId } from './Utils';

const PREF_NAME = 'mystockapp';
const KEY_FAVORITES = 'favorites';
const KEY_GROUPS = 'groups';
const KEY_ALERTS = 'alerts';
const KEY_CACHE = 'stock_cache';

export class Store {
  private static abilityContext: Context | null = null;
  private static prefs: data_preferences.Preferences | null = null;

  static favorites: string[] = [];
  static groups: Group[] = [];
  static alerts: AlertRule[] = [];
  static cache: Record<string, Stock> = {};

  // --------- 必须在 EntryAbility 调用 ----------
  static setAbilityContext(ctx: Context): void {
    Store.abilityContext = ctx;
  }

  // --------- 初始化存储 ----------
  static async init(): Promise<void> {
    if (!Store.abilityContext) {
      console.error('[Store] 未设置 abilityContext');
      return;
    }

    try {
      Store.prefs = await data_preferences.getPreferences(Store.abilityContext, PREF_NAME);

      Store.favorites = JSON.parse(await Store.prefs.get(KEY_FAVORITES, '[]') as string);
      Store.groups = JSON.parse(await Store.prefs.get(KEY_GROUPS, '[]') as string);
      Store.alerts = JSON.parse(await Store.prefs.get(KEY_ALERTS, '[]') as string);
      Store.cache = JSON.parse(await Store.prefs.get(KEY_CACHE, '{}') as string);

    } catch (err) {
      console.error('[Store.init] 失败', JSON.stringify(err));
    }
  }

  // ----------- 保存通用函数 -----------
  private static async save(key: string, value: string): Promise<void> {
    if (!Store.prefs) return;
    await Store.prefs.put(key, value);
    await Store.prefs.flush();
  }

  static saveFavorites(): void {
    Store.save(KEY_FAVORITES, JSON.stringify(Store.favorites));
  }

  static saveGroups(): void {
    Store.save(KEY_GROUPS, JSON.stringify(Store.groups));
  }

  static saveAlerts(): void {
    Store.save(KEY_ALERTS, JSON.stringify(Store.alerts));
  }

  static saveCache(): void {
    Store.save(KEY_CACHE, JSON.stringify(Store.cache));
  }

  // ----------- 业务函数 -----------
  static createGroup(name: string): Group {
    const g: Group = {
      id: genId('g'),
      name,
      stockIds: [],
      createdAt: Date.now()
    };

    Store.groups.push(g);
    Store.saveGroups();
    return g;
  }

  // 删除分组
  static deleteGroup(groupId: string): void {
    Store.groups = Store.groups.filter(g => g.id !== groupId);
    Store.saveGroups();
  }

  // 重命名分组
  static renameGroup(groupId: string, newName: string): void {
    const group = Store.groups.find(g => g.id === groupId);
    if (group) {
      group.name = newName;
      Store.saveGroups();
    }
  }

  // 添加股票到分组
  static addStockToGroup(groupId: string, stockId: string): void {
    const group = Store.groups.find(g => g.id === groupId);
    if (group && !group.stockIds.includes(stockId)) {
      group.stockIds.push(stockId);
      Store.saveGroups();
    }
  }

  // 批量添加股票到分组
  static addStocksToGroup(groupId: string, stockIds: string[]): void {
    const group = Store.groups.find(g => g.id === groupId);
    if (group) {
      for (const stockId of stockIds) {
        if (!group.stockIds.includes(stockId)) {
          group.stockIds.push(stockId);
        }
      }
      Store.saveGroups();
    }
  }

  // 从分组移除股票
  static removeStockFromGroup(groupId: string, stockId: string): void {
    const group = Store.groups.find(g => g.id === groupId);
    if (group) {
      group.stockIds = group.stockIds.filter(id => id !== stockId);
      Store.saveGroups();
    }
  }

  // 批量从分组移除股票
  static removeStocksFromGroup(groupId: string, stockIds: string[]): void {
    const group = Store.groups.find(g => g.id === groupId);
    if (group) {
      group.stockIds = group.stockIds.filter(id => !stockIds.includes(id));
      Store.saveGroups();
    }
  }

  // 获取分组
  static getGroup(groupId: string): Group | undefined {
    return Store.groups.find(g => g.id === groupId);
  }

  // 获取所有分组
  static getAllGroups(): Group[] {
    return Store.groups;
  }
}
