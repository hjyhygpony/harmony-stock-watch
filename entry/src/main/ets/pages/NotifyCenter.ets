// NotifyCenter.ets
import { AlertRule } from '../common/StockData';
import { Store } from '../common/Store';
import router from '@ohos.router';

@Entry
@Component
struct NotifyCenter {
  @State rules: AlertRule[] = Store.alerts || [];

  aboutToAppear() {
    this.rules = Store.alerts || [];
  }

  addSampleRule() {
    const r: AlertRule = {
      id: `rule_${Date.now()}`,
      name: `示例：任意股票涨幅超过3%`,
      root: { type: 'condition', condition: { stockId: '600001', op: 'gt', value: 0 } },
      enabled: true,
      createdAt: Date.now(),
      suppressMs: 60000
    };
    Store.alerts.push(r);
    Store.saveAlerts();
    this.rules = Store.alerts;
  }

  build() {
    Column() {
      Row() {
        Button('返回').onClick(() => router.back());
        Text('行情通知中心').fontSize(18).margin({ left: 12 });
      }.padding(12).backgroundColor(Color.White)

      Button('新增示例规则').onClick(() => this.addSampleRule()).margin({ top: 10 }).padding(12)

      Scroll() {
        Column() {
          ForEach(this.rules, (r: AlertRule) => {
            Row() {
              Column() {
                Text(r.name).fontSize(15);
                Text(r.enabled ? '已启用' : '已关闭').fontSize(12).fontColor('#888')
              }
              .layoutWeight(1)
            }
            .padding(12)
            .backgroundColor(Color.White)
            .margin({ bottom: 8 })
          }, (r: AlertRule) => r.id)
        }
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#F6F7FB')
  }
}
