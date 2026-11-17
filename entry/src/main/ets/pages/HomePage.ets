// HomePage.ets - 首页组件（从Index.ets重构）
import { StockListItem } from '../components/StockListItem'
import { Stock } from '../common/StockData'
import router from '@ohos.router'
import http from '@ohos.net.http'
import data_preferences from '@ohos.data.preferences'

interface StockListDataItem {
  code: string
  name: string
}
type StockListResp = StockListDataItem[]

interface DailyDataPoint {
  code: string
  date: string
  open: number
  high: number
  low: number
  close: number
  pct_change: number
  volume: number
  amount: number
  turnover: number
}
type DailyDataResp = DailyDataPoint[]

const API_HOST: string = "http://10.0.2.2:8013"
const API_KEY: string = ""
const PREF_KEY = 'user_favorite_ids'
const PREF_NAME = 'mystockapp'

@Component
export struct HomePage {
  @State stockList: Array<Stock> = []
  @State favoriteIds: Array<string> = []
  @State isLoading: boolean = true
  @State isRefreshing: boolean = false

  private preferences: data_preferences.Preferences | null = null

  aboutToAppear() {
    this.initData()
  }

  async initData(): Promise<void> {
    this.isLoading = true
    try {
      await this.initPreferences()
      await this.fetchStockData()
    } catch (e) {
      console.error('初始化数据失败:', JSON.stringify(e))
    } finally {
      this.isLoading = false
    }
  }

  async initPreferences(): Promise<void> {
    try {
      this.preferences = await data_preferences.getPreferences(getContext(this), PREF_NAME)
      const jsonStr: string = (await this.preferences.get(PREF_KEY, '[]')) as string
      this.favoriteIds = JSON.parse(jsonStr) as Array<string>
    } catch (err) {
      console.error('初始化 Preferences 失败:', JSON.stringify(err))
    }
  }

  async fetchStockData(): Promise<void> {
    const httpRequest = http.createHttp()
    const listUrl: string = `${API_HOST}/api/stocks/list`
    let requestHeaders: Record<string, string> = API_KEY ? { "Authorization": `Bearer ${API_KEY}` } : {}

    let stockItems: StockListResp = []

    try {
      const listResp = await httpRequest.request(listUrl, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        readTimeout: 10000,
        connectTimeout: 10000,
        header: requestHeaders
      })

      if (listResp.responseCode === 200) {
        stockItems = JSON.parse(listResp.result as string) as StockListResp
      } else {
        httpRequest.destroy()
        return
      }
    } catch (err) {
      httpRequest.destroy()
      return
    }

    const newStocks: Array<Stock> = []
    const limitItems = stockItems.slice(0, 20)

    for (const item of limitItems) {
      const dailyUrl = `${API_HOST}/api/stocks/daily/${item.code}?limit=1`
      try {
        const dailyResp = await httpRequest.request(dailyUrl, {
          method: http.RequestMethod.GET,
          expectDataType: http.HttpDataType.STRING,
          header: requestHeaders
        })

        if (dailyResp.responseCode === 200) {
          const dailyJson: DailyDataResp = JSON.parse(dailyResp.result as string) as DailyDataResp
          if (Array.isArray(dailyJson) && dailyJson.length > 0) {
            const latestData = dailyJson[dailyJson.length - 1]
            newStocks.push({
              id: item.code,
              code: item.code,
              name: item.name,
              price: latestData.close,
              changePercent: latestData.pct_change,
              timestamp: Date.now()
            } as Stock)
          }
        }
      } catch (e) {
        // ignore
      }
    }

    this.stockList = newStocks
    httpRequest.destroy()
  }

  toggleFavorite(id: string): void {
    if (this.favoriteIds.includes(id)) {
      this.favoriteIds = this.favoriteIds.filter((x) => x !== id)
    } else {
      this.favoriteIds = this.favoriteIds.concat(id)
    }
    this.saveFavorites()
  }

  async saveFavorites(): Promise<void> {
    if (!this.preferences) return
    await this.preferences.put(PREF_KEY, JSON.stringify(this.favoriteIds))
    await this.preferences.flush()
  }

  goToSearch() {
    router.pushUrl({
      url: 'pages/SearchPage',
      params: {
        stockList: this.stockList,
        favoriteIds: this.favoriteIds
      }
    }, router.RouterMode.Single)
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column()
        .width('100%')
        .height(280)
        .linearGradient({
          angle: 180,
          colors: [[0x4A90E2, 0.0], [0xF5F7FA, 1.0]]
        })

      Column() {
        Column() {
          Text('Market Overview')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 15, left: 5 })

          Row() {
            Text('🔍')
              .fontSize(18)
              .margin({ right: 10 })
            Text('搜索股票代码/名称...')
              .fontSize(14)
              .fontColor('#999999')
          }
          .width('100%')
          .height(45)
          .backgroundColor(Color.White)
          .borderRadius(22)
          .padding({ left: 15, right: 15 })
          .shadow({ radius: 10, color: '#20000000', offsetY: 5 })
          .onClick(() => {
            this.goToSearch()
          })
        }
        .padding(20)
        .width('100%')

        // 指数卡片 - 横向排列，均分宽度
        Row({ space: 8 }) {
          this.IndexCard("上证指数", "3086.5", "+1.2%")
          this.IndexCard("深证成指", "10890.1", "+0.8%")
          this.IndexCard("创业板指", "2350.2", "-0.5%")
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
        .justifyContent(FlexAlign.SpaceBetween)

        Text('股票列表')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .padding({ left: 20, top: 10, bottom: 10 })
          .width('100%')

        if (this.isLoading) {
          Column() {
            LoadingProgress().width(40).height(40).color(Color.Blue)
            Text('行情加载中...').fontSize(14).fontColor(Color.Gray).margin({ top: 10 })
          }.height(200).justifyContent(FlexAlign.Center).width('100%')
        } else {
          Refresh({ refreshing: this.isRefreshing }) {
            List({ space: 12 }) {
              ForEach(this.stockList, (item: Stock) => {
                ListItem() {
                  Column() {
                    StockListItem({
                      stock: item,
                      isFavorite: this.favoriteIds.includes(item.id),
                      onToggleFavorite: () => { this.toggleFavorite(item.id) }
                    })
                  }
                  .backgroundColor(Color.White)
                  .borderRadius(12)
                  .padding(5)
                  .shadow({ radius: 5, color: '#10000000', offsetY: 2 })
                }
                .onClick(() => {
                  router.pushUrl({
                    url: 'pages/DetailPage',
                    params: { name: item.name, id: item.id, code: item.code }
                  })
                })
              }, (item: Stock) => item.id)
            }
            .width('100%')
            .layoutWeight(1)
            .padding({ left: 20, right: 20, bottom: 20 })
          }
          .onRefreshing(() => {
            this.isRefreshing = true
            this.fetchStockData().then(() => this.isRefreshing = false)
          })
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }

  @Builder IndexCard(name: string, value: string, change: string) {
    Column() {
      Text(name)
        .fontSize(12)
        .fontColor('#666666')
        .maxLines(1)
      Text(value)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 4 })
        .maxLines(1)
      Text(change)
        .fontSize(12)
        .fontColor(change.startsWith('+') ? '#F56C6C' : '#67C23A')
        .margin({ top: 2 })
    }
    .width('31%')
    .height(75)
    .backgroundColor(Color.White)
    .borderRadius(10)
    .justifyContent(FlexAlign.Center)
    .shadow({ radius: 5, color: '#10000000', offsetY: 2 })
  }
}
