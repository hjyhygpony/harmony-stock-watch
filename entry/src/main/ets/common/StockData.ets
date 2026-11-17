// StockData.ets
export interface KLinePoint {
  time: number;
  open: number;
  high: number;
  low: number;
  close: number;
  volume?: number;
}

interface KLineData {
  daily?: KLinePoint[];
  weekly?: KLinePoint[];
  monthly?: KLinePoint[];
}

export interface Stock {
  id: string;
  code: string;
  name: string;
  price: number;
  changePercent: number;
  change?: number;
  timestamp?: number;
  kline?: KLineData;
}

export interface Group {
  id: string;
  name: string;
  stockIds: string[];
  createdAt?: number;
}

export type ComparisonOp = 'gt'|'gte'|'lt'|'lte'|'eq'|'between';

export interface Condition {
  stockId: string;
  op: ComparisonOp;
  value: number | [number, number];
}

export type LogicalOp = 'and'|'or'|'not';

export interface RuleNode {
  type: 'condition' | 'logic';
  condition?: Condition;
  op?: LogicalOp;
  children?: RuleNode[];
}

export interface AlertRule {
  id: string;
  name: string;
  root: RuleNode;
  enabled: boolean;
  createdAt?: number;
  lastTriggeredAt?: number;
  suppressMs?: number;
}

export interface ApiTodoItem {
  userId: number;
  id: number;
  title: string;
  completed: boolean;
}
