import router from '@ohos.router';
import { Stock } from '../common/StockData';

// 模拟数据：使用上次增加后的数据量，确保 HistoryAndTags 纵向长度足够
const hotSearchTags: Array<string> = [
  '半导体', '新能源车', '高股息', '人工智能', '医药生物', '沪深300',
  '消费电子', '军工概念', '周期股', '科技龙头', '大金融', '创业板'
];
const searchHistory: Array<string> = [
  '000001', '美的集团', '工'
];

// **************************** I. 顶部广告模块 ****************************
@Component
struct TopAdBlock {
  build() {
    Column() {
      Text('🔥 热门投资机会推荐 [广告]')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#CC0000')
        .margin({ top: 10, bottom: 5 })

      Divider().strokeWidth(1).color('#FFEEEE').width('90%')

      Text('【特惠】VIP研报服务免费领取 >')
        .fontSize(14)
        .fontColor('#333333')
        .padding({ bottom: 10 })
    }
    .width('98%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#FFF5F5') // 浅红色背景，吸引注意
    .borderRadius(10)
    .margin({ top: 10, left: '1%', right: '1%' })
    .shadow({ radius: 3, color: 'rgba(204,0,0,0.1)', offsetY: 2 })
  }
}


// **************************** II. 底部告诫模块 ****************************
@Component
struct BottomCautionBlock {
  private readonly CAUTION_COLOR = '#996600'; // 深棕色，稳重警示

  build() {
    Column({space: 8}) {
      Text('⚠️ 投资风险提示与重要告诫')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.CAUTION_COLOR)
        .margin({ top: 15 })

      Text('市场有风险，投资需谨慎。本平台不提供任何投资建议，所有信息仅供参考。')
        .fontSize(14)
        .fontColor('#666666')
        .lineHeight(20)
        .textAlign(TextAlign.Center)
        .width('90%')

      Text('请根据自身风险承受能力和财务状况进行独立决策。')
        .fontSize(14)
        .fontColor('#888888')
        .margin({ bottom: 15 })
        .textAlign(TextAlign.Center)
        .width('90%')
    }
    .width('98%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#FFFBE6') // 浅黄色/米色背景，强警告色
    .borderRadius(10)
    .margin({ top: 20, bottom: 40, left: '1%', right: '1%' }) // 增加底部边距，防止空旷
    .shadow({ radius: 5, color: 'rgba(0,0,0,0.1)', offsetY: 2 })
  }
}

// **************************** III. 历史记录/热门搜索 组件 (保持上次的优化) ****************************
@Component
struct HistoryAndTags {
  private readonly PRIMARY_BLUE = '#4A90E2';
  private readonly LIGHT_BLUE = '#7CBBFF';
  private readonly ACCENT_COLOR = '#99B3D6';

  onHistoryClick: (text: string) => void = (text: string) => {};

  build() {
    Column() {
      this.HistorySection()

      Divider().strokeWidth(1).color('#F0F5FA').margin({ top: 15, bottom: 15 })

      this.HotTagsSection()

    }
    .width('98%')
    .alignItems(HorizontalAlign.Start)
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(15)
    .border({ width: 1, color: '#E0F0FF' })
    .shadow({ radius: 8, color: '#104A90E2', offsetY: 4 })
    .margin({ top: 15, bottom: 20, left: '1%', right: '1%' })
  }

  @Builder HistorySection() {
    // ... (内容不变) ...
    Column() {
      Row() {
        Text('🕘 搜索历史')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.PRIMARY_BLUE)
          .margin({ bottom: 10 })

        Text('清空')
          .fontSize(14)
          .fontColor(this.ACCENT_COLOR)
          .onClick(() => { console.log('清空历史记录'); })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
        ForEach(searchHistory, (tag: string) => {
          Text(tag)
            .fontSize(14)
            .fontColor(Color.Black)
            .padding({ left: 15, right: 15, top: 8, bottom: 8 })
            .margin({ right: 10, bottom: 10 })
            .backgroundColor('#F5F7FA')
            .borderRadius(20)
            .onClick(() => this.onHistoryClick(tag))
            .stateStyles({
              pressed: {
                .backgroundColor('#E8F4FF')
                .scale({ x: 0.95, y: 0.95 })
              }
            })
        }, (tag: string) => tag)
      }
    }
    .alignItems(HorizontalAlign.Start)
  }

  @Builder HotTagsSection() {
    // ... (内容不变) ...
    Column() {
      Text('🔥 热门搜索')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.PRIMARY_BLUE)
        .margin({ bottom: 10 })

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
        ForEach(hotSearchTags, (tag: string, index: number) => {
          Row() {
            Text(`${index + 1}`)
              .fontSize(12)
              .fontColor(index < 3 ? '#FFFFFF' : this.PRIMARY_BLUE)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .backgroundColor(index < 3 ? '#F56C6C' : '#E8F4FF')
              .borderRadius(15)
              .margin({ right: 8 })

            Text(tag)
              .fontSize(15)
              .fontWeight(index < 3 ? FontWeight.Medium : FontWeight.Normal)
              .fontColor(Color.Black)
          }
          .padding({ left: 5, right: 15, top: 8, bottom: 8 })
          .margin({ right: 10, bottom: 10 })
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .border({ width: 1, color: '#E0F0FF' })

        }, (tag: string) => tag)
      }
    }
    .alignItems(HorizontalAlign.Start)
  }
}


// **************************** IV. SearchPage 主体 (整合模块) ****************************
@Entry
@Component
struct SearchPage {
  @State searchText: string = '';
  @State allStocks: Array<Stock> = [];
  @State searchResults: Array<Stock> = [];
  @State favoriteIds: Array<string> = [];

  private readonly PRIMARY_BLUE = '#4A90E2';
  private readonly LIGHT_BLUE = '#7CBBFF';
  private readonly SHADOW_COLOR = '#1A4A90E2';
  private readonly BACKGROUND_GRAY = '#F5F7FA';

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['stockList']) {
      this.allStocks = params['stockList'] as Array<Stock>;
      this.searchResults = [];
    }
    if (params && params['favoriteIds']) {
      this.favoriteIds = params['favoriteIds'] as Array<string>;
    }
  }

  handleSearch(text: string) {
    this.searchText = text.trim();
    if (this.searchText === '') {
      this.searchResults = [];
      return;
    }

    const lowerText = this.searchText.toLowerCase();
    this.searchResults = this.allStocks.filter(item =>
    item.code.startsWith(lowerText) ||
    item.name.toLowerCase().includes(lowerText)
    );
  }

  handleTagClick(tag: string) {
    this.searchText = tag;
    this.handleSearch(tag);
  }

  goToDetail(item: Stock) {
    router.pushUrl({
      url: 'pages/DetailPage',
      params: { name: item.name, id: item.id, code: item.code }
    });
  }

  build() {
    Column() {
      // 1. 顶部搜索栏 (保持不变)
      Row() {
        Text('✕')
          .fontSize(24)
          .fontColor(this.PRIMARY_BLUE)
          .margin({ right: 15 })
          .onClick(() => router.back())

        TextInput({ placeholder: '输入股票代码或名称快速查找', text: this.searchText })
          .layoutWeight(1)
          .height(45)
          .placeholderColor('#99B3D6')
          .placeholderFont({ size: 16 })
          .backgroundColor('#F7FBFF')
          .borderColor(this.LIGHT_BLUE)
          .borderWidth(1)
          .borderRadius(25)
          .padding({ left: 15, right: 15 })
          .shadow({ radius: 2, color: '#057CBBFF', offsetX: 0, offsetY: 1 })
          .onChange((value: string) => {
            this.handleSearch(value);
          })
      }
      .width('100%')
      .padding({ top: 20, bottom: 15, left: 15, right: 15 })
      .backgroundColor(Color.White)
      .shadow({ radius: 10, color: this.SHADOW_COLOR, offsetY: 5 })

      // 2. 结果列表 或 三层结构 (广告 + 历史/热点 + 告诫)

        Column() {
          if (this.searchText.length === 0) {
            // 顶部：广告
            TopAdBlock()

            // 中部：历史记录/热门搜索
            HistoryAndTags({ onHistoryClick: (tag): void => this.handleTagClick(tag) })

            // 底部：投资告诫
            BottomCautionBlock()

          } else {
            // 搜索结果列表 (保持不变)
            List({ space: 1 }) {
              if (this.searchResults.length === 0) {
                // 搜索无结果时，仅显示提示和告诫
                ListItem() {
                  Column({space: 20}) {
                    Text(`🔎 找不到代码或名称包含 "${this.searchText}" 的股票。`)
                      .fontColor('#999999')
                      .fontSize(16)
                      .margin({ top: 30 })

                    Divider().strokeWidth(1).color('#E0E0E0').width('90%')
                  }.width('100%').justifyContent(FlexAlign.Center).padding({ bottom: 20 })
                }

                // 搜索无结果时，仍然显示告诫信息
                ListItem() {
                  Column() {
                    Text('⚠️ 投资告诫:')
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#CC0000')
                      .margin({ top: 10, bottom: 5 })
                      .alignSelf(ItemAlign.Start)

                    Text('投资有风险，入市须谨慎。')
                      .fontSize(14)
                      .fontColor('#666666')
                      .margin({ bottom: 15 })

                  }
                  .width('98%')
                  .alignItems(HorizontalAlign.Center)
                  .backgroundColor(Color.White)
                  .borderRadius(10)
                  .padding({ top: 10, bottom: 10, left: '1%', right: '1%' })
                  .margin({ top: 10, bottom: 10, left: '1%', right: '1%' })
                }

              } else {
                ForEach(this.searchResults, (item: Stock) => {
                  ListItem() {
                    Row() {
                      Column() {
                        Text(item.name).fontSize(17).fontWeight(FontWeight.Medium).fontColor(Color.Black)
                        Text(item.code).fontSize(13).fontColor('#888888').margin({ top: 4 })
                      }.alignItems(HorizontalAlign.Start).layoutWeight(1)

                      Column() {
                        Text(item.price.toFixed(2)).fontSize(18).fontWeight(FontWeight.Bold)
                          .fontColor(item.changePercent >= 0 ? '#E74C3C' : '#2ECC71')
                        Text(`${item.changePercent >= 0 ? '+' : ''}${item.changePercent.toFixed(2)}%`)
                          .fontSize(13).fontColor(item.changePercent >= 0 ? '#E74C3C' : '#2ECC71').margin({ top: 4 })
                          .backgroundColor(item.changePercent >= 0 ? '#FFEFEF' : '#EFFFF5')
                          .borderRadius(8).padding({ left: 10, right: 10, top: 3, bottom: 3 })
                      }.alignItems(HorizontalAlign.End)
                    }
                    .width('100%').padding({ left: 20, right: 20, top: 18, bottom: 18 })
                    .backgroundColor(Color.White)
                  }
                  .onClick(() => { this.goToDetail(item); })
                  .stateStyles({
                    pressed: {
                      .backgroundColor('#F0F8FF')
                      .scale({ x: 0.99, y: 0.99 })
                    }
                  })
                }, (item: Stock) => item.id)
              }
            }
            .width('100%')
            .margin({ top: 5 })
          }
        }
        .width('100%')

      .width('100%')
      .layoutWeight(1)
      .backgroundColor(this.BACKGROUND_GRAY)
    }
    .width('100%').height('100%')
    .backgroundColor(Color.White).clip(true)
  }
}