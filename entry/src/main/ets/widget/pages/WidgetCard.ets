// entry/src/main/ets/widget/pages/WidgetCard.ets

// 卡片内部定义简化的股票接口（避免跨模块依赖问题）
interface WidgetStock {
  id: string;
  code: string;
  name: string;
  price: number;
  changePercent: number;
}

@Entry
@Component
export struct WidgetCard {
  // 标题（只读）
  readonly title: string = '自选行情';

  // 顶部指数信息 - 使用默认示例数据
  @State indexName: string = '贵州茅台';
  @State indexPrice: string = '1755.80';
  @State indexChangePercent: number = 1.25;

  // 自选股列表 - 使用默认示例数据（最多显示两只）
  @State favStocks: WidgetStock[] = [
    {
      id: '600519',
      code: '600519',
      name: '贵州茅台',
      price: 1755.80,
      changePercent: 1.25
    },
    {
      id: '000001',
      code: '000001',
      name: '平安银行',
      price: 11.52,
      changePercent: -0.86
    }
  ];

  // 工具：格式化百分比（带符号）
  private formatPercent(pct: number): string {
    const sign: string = pct > 0 ? '+' : (pct < 0 ? '' : '');
    return `${sign}${pct.toFixed(2)}%`;
  }

  // 工具：涨跌颜色
  private changeColor(pct: number): string {
    if (pct > 0) return '#E53935'; // 红涨
    if (pct < 0) return '#2E7D32'; // 绿跌
    return '#333333';
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.title)
          .fontSize(13)
          .fontColor('#666666')
        Text('📈')
          .fontSize(12)
          .margin({ left: 4 })
      }
      .width('100%')
      .margin({ bottom: 8 })

      // 主要股票信息（第一只）
      Column() {
        Text(this.indexName)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Row() {
          Text(this.indexPrice)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.changeColor(this.indexChangePercent))

          Text(this.formatPercent(this.indexChangePercent))
            .fontSize(13)
            .fontColor(this.changeColor(this.indexChangePercent))
            .margin({ left: 8 })
        }
        .margin({ top: 4 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 分割线
      Row()
        .width('100%')
        .height(1)
        .backgroundColor('#EEEEEE')
        .margin({ top: 8, bottom: 6 })

      // 自选股列表（显示第二只及之后）
      ForEach(this.favStocks.slice(1, 2), (s: WidgetStock) => {
        Row() {
          Column() {
            Text(s.name)
              .fontSize(13)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .fontColor('#333333')
            Text(s.code)
              .fontSize(10)
              .fontColor('#999999')
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Column() {
            Text(s.price.toFixed(2))
              .fontSize(13)
              .fontColor(this.changeColor(s.changePercent))
              .fontWeight(FontWeight.Medium)

            Text(this.formatPercent(s.changePercent))
              .fontSize(10)
              .fontColor(this.changeColor(s.changePercent))
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .padding({ top: 4, bottom: 4 })
      }, (s: WidgetStock) => s.id)

    }
    .width('100%')
    .height('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }
}
