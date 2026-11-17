// MarketIndexCard.ets
@Component
export struct MarketIndexCard {
  @Prop name: string;
  @Prop value: string;
  @Prop change: string;

  build() {
    Column() {
      Text(this.name).fontSize(13).fontColor('#666');
      Text(this.value).fontSize(18).fontWeight(FontWeight.Medium);
      Text(this.change).fontSize(12).fontColor('#E53935')
    }
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(8)
  }
}
