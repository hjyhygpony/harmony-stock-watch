// /components/StockListItem.ets

import { Stock } from '../common/StockData'



@Component
export struct StockListItem { // export 关键字允许外部文件导入它
  // 1. 使用 @Prop 接收一个 Stock 对象
  // @Prop 是单向绑定的 (父 -> 子)，父组件数据改变，这里会更新
  @Prop stock: Stock;
  @Prop isFavorite: boolean;    // 接收一个回调函数，当点击收藏时调用

  onToggleFavorite: () => void = () => {};   //=> void 表示一个没有参数也没有返回值的函数

  // 辅助函数：根据涨跌幅决定颜色
  private getPriceColor(change: number): ResourceColor {
    if (change > 0) {
      return $r('app.color.stock_red'); // 假设你在 resources/base/element/color.json 定义了
    } else if (change < 0) {
      return $r('app.color.stock_green'); // 假设你定义了
    }
    return Color.Gray; // 不涨不跌
  }

  build() {
    Row() {
      // 1. 左侧：股票名称和代码
      Column() {
        Text(this.stock.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.Black)
        Text(this.stock.code)
          .fontSize(13)
          .fontColor(Color.Gray)
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1) // 占据剩余空间，把价格挤到右边

      // 2. 右侧：价格和涨跌幅
      Column() {
        Text(this.stock.price.toFixed(2))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getPriceColor(this.stock.changePercent))

        Text(`${this.stock.changePercent > 0 ? '+' : ''}${this.stock.changePercent.toFixed(2)}%`)
          .fontSize(14)
          .fontColor(this.getPriceColor(this.stock.changePercent))
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.End)
      .width(100) // 给一个固定宽度，让排版更整齐

      // 3. 末尾：收藏按钮
      Image(this.isFavorite ? $r('app.media.ic_star_filled') : $r('app.media.ic_star_empty'))
        .width(28)
        .height(28)
        .fillColor(this.isFavorite ? Color.Yellow : Color.Gray)
        .margin({ left: 16 }) // 与价格区域隔开
        .onClick((event: ClickEvent) => {
          // // 阻止事件冒泡 (防止点击星星也触发了ListItem的路由跳转)
          // event.stopPropagation();
          // 调用父组件传来的回调函数
          this.onToggleFavorite();
        })
    }
    .width('100%')
    .padding({ top: 15, bottom: 15, left: 15, right: 15 })
    .borderRadius(12)
    .backgroundColor(Color.White)
  }
}