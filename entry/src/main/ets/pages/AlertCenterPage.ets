import { AlertRule, Condition, ComparisonOp, RuleNode, LogicalOp } from '../common/StockData';
import { AlertRuleEngine } from '../common/AlertRuleEngine';
import { WebSocketService } from '../common/WebSocketService';
import { router } from '@kit.ArkUI';
import http from '@ohos.net.http';

/**
 * 行情通知中心页面
 * 功能：
 * 1. 管理预设规则（增删改查）
 * 2. 支持单条件和复杂逻辑表达式
 * 3. 规则触发时振铃提醒+系统通知
 * 4. 点击通知跳转到对应股票行情
 */

// 条件编辑项
interface ConditionItem {
  stockId: string;
  stockName: string;
  op: ComparisonOp;
  value: string;
  valueMax?: string;
}

// 股票信息接口
interface StockInfo {
  code: string;
  name: string;
}

// Select组件选项接口
interface SelectOption {
  value: string;
}

// API响应接口
interface StockListItem {
  code: string;
  name: string;
}

const API_HOST: string = "http://10.0.2.2:8013";

@Component
export struct AlertCenterPage {
  @State rules: AlertRule[] = [];
  @State showAddDialog: boolean = false;
  @State editMode: 'simple' | 'complex' = 'simple';
  // 简单规则表单
  @State newRuleName: string = '';
  @State newStockCode: string = '';
  @State newOp: ComparisonOp = 'gt';
  @State newValue: string = '';
  @State newValueMax: string = '';
  // 复杂规则表单
  @State logicOp: LogicalOp = 'and';
  @State conditions: ConditionItem[] = [];
  // 动态股票列表
  @State stockList: StockInfo[] = [];
  @State isLoadingStocks: boolean = false;
  private engine: AlertRuleEngine = AlertRuleEngine.getInstance();
  private wsService: WebSocketService = WebSocketService.getInstance();

  aboutToAppear() {
    this.loadRules();
    this.fetchStockList();
    if (!this.wsService.isConnectedStatus()) {
      this.wsService.connect();
    }
  }

  // 从API获取股票列表
  async fetchStockList(): Promise<void> {
    this.isLoadingStocks = true;
    const httpRequest = http.createHttp();

    try {
      const response = await httpRequest.request(`${API_HOST}/api/stocks/list`, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        readTimeout: 10000,
        connectTimeout: 10000
      });

      if (response.responseCode === 200) {
        const data = JSON.parse(response.result as string) as StockListItem[];
        this.stockList = data.map(item => ({
          code: item.code,
          name: item.name
        } as StockInfo));

        // 设置默认选中第一只股票
        if (this.stockList.length > 0 && !this.newStockCode) {
          this.newStockCode = this.stockList[0].code;
        }
      }
    } catch (err) {
      console.error('获取股票列表失败:', JSON.stringify(err));
    } finally {
      httpRequest.destroy();
      this.isLoadingStocks = false;
    }
  }

  private loadRules(): void {
    this.rules = this.engine.getAllRules();
  }

  private toggleRule(rule: AlertRule): void {
    rule.enabled = !rule.enabled;
    this.rules = [...this.rules];
  }

  private deleteRule(ruleId: string): void {
    this.engine.removeRule(ruleId);
    this.loadRules();
  }

  private getOpDisplay(op: ComparisonOp): string {
    const opMap: Record<string, string> = {
      'gt': '>',
      'gte': '≥',
      'lt': '<',
      'lte': '≤',
      'eq': '=',
      'between': '区间'
    };
    return opMap[op] || op;
  }

  private getStockName(code: string): string {
    const stock = this.stockList.find(s => s.code === code);
    return stock ? stock.name : code;
  }

  private resetForm(): void {
    this.newRuleName = '';
    this.newStockCode = this.stockList.length > 0 ? this.stockList[0].code : '';
    this.newOp = 'gt';
    this.newValue = '';
    this.newValueMax = '';
    this.logicOp = 'and';
    this.conditions = [];
    this.editMode = 'simple';
  }

  private addCondition(): void {
    const defaultStock = this.stockList.length > 0 ? this.stockList[0] : { code: '', name: '' } as StockInfo;
    this.conditions.push({
      stockId: defaultStock.code,
      stockName: defaultStock.name,
      op: 'gt',
      value: ''
    } as ConditionItem);
  }

  private removeCondition(index: number): void {
    this.conditions.splice(index, 1);
    this.conditions = [...this.conditions];
  }

  private createSimpleRule(): void {
    if (!this.newRuleName || !this.newValue) {
      return;
    }
    let value: number | [number, number];
    if (this.newOp === 'between') {
      value = [parseFloat(this.newValue), parseFloat(this.newValueMax)];
    } else {
      value = parseFloat(this.newValue);
    }

    const rule = this.engine.createSimpleRule(
      'rule_' + Date.now().toString(),
      this.newRuleName,
      this.newStockCode,
      this.newOp,
      value
    );
    this.engine.addRule(rule);
    this.loadRules();
    this.showAddDialog = false;
    this.resetForm();
  }

  private createComplexRule(): void {
    if (!this.newRuleName || this.conditions.length < 2) {
      return;
    }
    const conditionNodes: Condition[] = this.conditions.map(c => ({
      stockId: c.stockId,
      op: c.op,
      value: c.op === 'between'
        ? [parseFloat(c.value), parseFloat(c.valueMax || '0')] as [number, number]
        : parseFloat(c.value)
    } as Condition));

    let rule: AlertRule;
    if (this.logicOp === 'and') {
      rule = this.engine.createAndRule('rule_' + Date.now().toString(), this.newRuleName, conditionNodes);
    } else {
      rule = this.engine.createOrRule('rule_' + Date.now().toString(), this.newRuleName, conditionNodes);
    }

    this.engine.addRule(rule);
    this.loadRules();
    this.showAddDialog = false;
    this.resetForm();
  }

  private getRuleDescription(rule: AlertRule): string {
    return this.describeNode(rule.root);
  }

  private describeNode(node: RuleNode): string {
    if (node.type === 'condition' && node.condition) {
      const c = node.condition;
      const stockName = this.getStockName(c.stockId);
      if (c.op === 'between') {
        const range = c.value as [number, number];
        return `${stockName} 在 ${range[0]}-${range[1]}`;
      }
      return `${stockName} ${this.getOpDisplay(c.op)} ${c.value}`;
    }
    if (node.type === 'logic' && node.children) {
      const childDescs = node.children.map(child => this.describeNode(child));
      const opStr = node.op === 'and' ? ' 且 ' : (node.op === 'or' ? ' 或 ' : '非');
      if (node.op === 'not') {
        return `非(${childDescs[0]})`;
      }
      return `(${childDescs.join(opStr)})`;
    }
    return '';
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('行情通知中心')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        Blank()
        Button('+ 新增规则')
          .fontSize(12)
          .onClick(() => {
            this.resetForm();
            this.showAddDialog = true;
          })
      }
      .padding(16)
      .width('100%')

      // 连接状态
      Row() {
        Circle()
          .width(10)
          .height(10)
          .fill(this.wsService.isConnectedStatus() ? '#4CAF50' : '#F44336')
        Text(this.wsService.isConnectedStatus() ? '行情已连接' : '行情未连接')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ left: 6 })

        Text(`  |  可选股票: ${this.stockList.length}只`)
          .fontSize(12)
          .fontColor('#999999')
      }
      .padding({ left: 16, bottom: 12 })
      .width('100%')

      // 规则列表
      if (this.rules.length === 0) {
        Column() {
          Text('📋')
            .fontSize(48)
            .margin({ bottom: 12 })
          Text('暂无预设规则')
            .fontSize(14)
            .fontColor('#999999')
          Text('点击右上角添加规则')
            .fontSize(12)
            .fontColor('#CCCCCC')
            .margin({ top: 4 })
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.rules, (rule: AlertRule) => {
            ListItem() {
              Column() {
                Row() {
                  Column() {
                    Text(rule.name)
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                    Text(this.getRuleDescription(rule))
                      .fontSize(12)
                      .fontColor('#666666')
                      .margin({ top: 4 })
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  Toggle({ type: ToggleType.Switch, isOn: rule.enabled })
                    .onChange(() => {
                      this.toggleRule(rule);
                    })
                }
                .width('100%')

                Row() {
                  Text(rule.lastTriggeredAt
                    ? '上次触发: ' + new Date(rule.lastTriggeredAt).toLocaleString()
                    : '未触发')
                    .fontSize(11)
                    .fontColor('#999999')
                  Blank()
                  Button('删除')
                    .fontSize(11)
                    .height(26)
                    .backgroundColor('#FF5252')
                    .onClick(() => {
                      this.deleteRule(rule.id);
                    })
                }
                .width('100%')
                .margin({ top: 8 })
              }
              .padding(12)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
            }
            .margin({ left: 16, right: 16, bottom: 8 })
          }, (rule: AlertRule) => rule.id)
        }
        .layoutWeight(1)
      }

      // 新增规则弹窗
      if (this.showAddDialog) {
        this.AddRuleDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  AddRuleDialog() {
    Column() {
      // 遮罩层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000066')
        .position({ x: 0, y: 0 })
        .onClick(() => {
          this.showAddDialog = false;
        })

      // 弹窗内容
      Column() {
        Text('新增预设规则')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        // 模式切换
        Row() {
          Button(this.editMode === 'simple' ? '● 简单规则' : '○ 简单规则')
            .fontSize(12)
            .backgroundColor(this.editMode === 'simple' ? '#1976D2' : '#E0E0E0')
            .fontColor(this.editMode === 'simple' ? '#FFFFFF' : '#666666')
            .onClick(() => {
              this.editMode = 'simple';
            })
          Button(this.editMode === 'complex' ? '● 复杂规则' : '○ 复杂规则')
            .fontSize(12)
            .backgroundColor(this.editMode === 'complex' ? '#1976D2' : '#E0E0E0')
            .fontColor(this.editMode === 'complex' ? '#FFFFFF' : '#666666')
            .margin({ left: 8 })
            .onClick(() => {
              this.editMode = 'complex';
            })
        }
        .margin({ bottom: 16 })

        // 规则名称
        TextInput({ placeholder: '规则名称', text: this.newRuleName })
          .onChange((value: string) => {
            this.newRuleName = value;
          })
          .margin({ bottom: 12 })

        if (this.editMode === 'simple') {
          this.SimpleRuleForm()
        } else {
          this.ComplexRuleForm()
        }

        // 按钮
        Row() {
          Button('取消')
            .layoutWeight(1)
            .backgroundColor('#E0E0E0')
            .fontColor('#666666')
            .onClick(() => {
              this.showAddDialog = false;
              this.resetForm();
            })
          Button('确定')
            .layoutWeight(1)
            .margin({ left: 8 })
            .onClick(() => {
              if (this.editMode === 'simple') {
                this.createSimpleRule();
              } else {
                this.createComplexRule();
              }
            })
        }
        .width('100%')
        .margin({ top: 16 })
      }
      .width('90%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .position({ x: '5%', y: '15%' })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  @Builder
  SimpleRuleForm() {
    Column() {
      // 股票选择
      Text('选择股票')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ bottom: 4 })

      if (this.isLoadingStocks) {
        Row() {
          LoadingProgress().width(20).height(20)
          Text('加载股票列表...').fontSize(12).fontColor('#999999').margin({ left: 8 })
        }
        .margin({ bottom: 12 })
      } else if (this.stockList.length === 0) {
        Text('暂无可选股票，请检查网络连接')
          .fontSize(12)
          .fontColor('#FF5252')
          .margin({ bottom: 12 })
      } else {
        Select(this.stockList.map(s => ({ value: s.name + ' (' + s.code + ')' } as SelectOption)))
          .value(this.getStockName(this.newStockCode) + ' (' + this.newStockCode + ')')
          .onSelect((index: number) => {
            this.newStockCode = this.stockList[index].code;
          })
          .width('100%')
          .margin({ bottom: 12 })
      }

      // 条件选择
      Text('条件')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ bottom: 4 })
      Row() {
        Select([
          { value: '>' }, { value: '≥' }, { value: '<' }, { value: '≤' }, { value: '=' }, { value: '区间' }
        ])
          .value(this.getOpDisplay(this.newOp))
          .onSelect((index: number) => {
            const ops: ComparisonOp[] = ['gt', 'gte', 'lt', 'lte', 'eq', 'between'];
            this.newOp = ops[index];
          })
          .layoutWeight(1)

        TextInput({ placeholder: '价格', text: this.newValue })
          .onChange((value: string) => {
            this.newValue = value;
          })
          .layoutWeight(2)
          .margin({ left: 8 })
          .type(InputType.Number)

        if (this.newOp === 'between') {
          Text('-')
            .margin({ left: 4, right: 4 })
          TextInput({ placeholder: '最大值', text: this.newValueMax })
            .onChange((value: string) => {
              this.newValueMax = value;
            })
            .layoutWeight(2)
            .type(InputType.Number)
        }
      }
      .width('100%')
    }
  }

  @Builder
  ComplexRuleForm() {
    Column() {
      // 逻辑运算符选择
      Text('逻辑关系')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ bottom: 4 })
      Row() {
        Button(this.logicOp === 'and' ? '● 全部满足(AND)' : '○ 全部满足(AND)')
          .fontSize(11)
          .backgroundColor(this.logicOp === 'and' ? '#4CAF50' : '#E0E0E0')
          .fontColor(this.logicOp === 'and' ? '#FFFFFF' : '#666666')
          .onClick(() => {
            this.logicOp = 'and';
          })
        Button(this.logicOp === 'or' ? '● 任一满足(OR)' : '○ 任一满足(OR)')
          .fontSize(11)
          .backgroundColor(this.logicOp === 'or' ? '#FF9800' : '#E0E0E0')
          .fontColor(this.logicOp === 'or' ? '#FFFFFF' : '#666666')
          .margin({ left: 8 })
          .onClick(() => {
            this.logicOp = 'or';
          })
      }
      .margin({ bottom: 12 })

      // 条件列表
      Text('条件列表 (至少2个)')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ bottom: 4 })

      List() {
        ForEach(this.conditions, (item: ConditionItem, index: number) => {
          ListItem() {
            Row() {
              Text((index + 1).toString() + '.')
                .fontSize(12)
                .width(20)
              Select(this.stockList.map(s => ({ value: s.code } as SelectOption)))
                .value(item.stockId)
                .onSelect((idx: number) => {
                  item.stockId = this.stockList[idx].code;
                  item.stockName = this.stockList[idx].name;
                  this.conditions = [...this.conditions];
                })
                .width(80)
              Select([{ value: '>' }, { value: '≥' }, { value: '<' }, { value: '≤' }, { value: '=' }] as SelectOption[])
                .value(this.getOpDisplay(item.op))
                .onSelect((idx: number) => {
                  const ops: ComparisonOp[] = ['gt', 'gte', 'lt', 'lte', 'eq'];
                  item.op = ops[idx];
                  this.conditions = [...this.conditions];
                })
                .width(50)
                .margin({ left: 4 })

              TextInput({ placeholder: '价格', text: item.value })
                .onChange((value: string) => {
                  item.value = value;
                })
                .layoutWeight(1)
                .margin({ left: 4 })
                .type(InputType.Number)

              Button('×')
                .fontSize(14)
                .width(28)
                .height(28)
                .backgroundColor('#FF5252')
                .margin({ left: 4 })
                .onClick(() => {
                  this.removeCondition(index);
                })
            }
            .width('100%')
            .padding(4)
          }
        }, (item: ConditionItem, index: number) => index.toString())
      }
      .height(this.conditions.length > 0 ? Math.min(this.conditions.length * 50, 150) : 0)

      Button('+ 添加条件')
        .fontSize(12)
        .width('100%')
        .margin({ top: 8 })
        .backgroundColor('#E3F2FD')
        .fontColor('#1976D2')
        .onClick(() => {
          this.addCondition();
        })
    }
  }
}
