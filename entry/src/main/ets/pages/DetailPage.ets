import router from '@ohos.router';
import http from '@ohos.net.http';
import { KLineChart } from '../components/KLineChart';
import { KLinePoint } from '../common/StockData';

const API_HOST: string = "http://10.0.2.2:8013";

interface DailyDataPoint {
  code: string;
  date: string;
  open: number;
  high: number;
  low: number;
  close: number;
  volume: number;
  amount: number;
  pct_change: number;
  turnover: number;
}

// 【新增/更新】新闻数据模型，匹配后端
interface NewsItemModel {
  title: string;
  uri: string;
  date: string; // 包含时间
  source: string; // 增加来源
}

@Entry
@Component
struct DetailPage {
  @State stockName: string = '加载中...';
  @State stockCode: string = '';
  @State stockId: string = '';

  @State kType: string = '日K';
  @State isLoading: boolean = true;
  @State isKLineLoading: boolean = false;
  @State isNewsLoading: boolean = false; // 新增新闻加载状态

  @State latestPrice: number = 0.00;
  @State changePercent: number = 0.00;
  @State open: number = 0.00;
  @State high: number = 0.00;
  @State low: number = 0.00;
  @State volume: number = 0;
  @State turnover: number = 0.00;
  @State date: string = '--';

  @State kLineData: KLinePoint[] = [];
  @State newsList: NewsItemModel[] = []; // 【新增】新闻列表数据源

  private dailyDataCache: KLinePoint[] | null = null;
  private weeklyDataCache: KLinePoint[] | null = null;
  private monthlyDataCache: KLinePoint[] | null = null;


  aboutToAppear() {
    try {
      const params = router.getParams() as Record<string, string>;
      if (params) {
        // 兼容两种参数格式：
        // 1. 从列表页跳转: { name, code, id }
        // 2. 从通知跳转: { symbol }
        this.stockCode = params.code ?? params.symbol ?? '--';
        this.stockName = params.name ?? this.stockCode;
        this.stockId = params.id ?? '';

        if (this.stockCode && this.stockCode !== '--') {
          this.fetchLatestDailyData();
          this.fetchKlineData('日K');
          this.fetchNewsData();
        }
      }
    } catch (err) {
      console.error('获取路由参数失败：' + JSON.stringify(err));
    }
  }

  // 提取公共的数据转换逻辑 (保持不变)
  private transformToKLinePoint(dataArray: DailyDataPoint[]): KLinePoint[] {
    return dataArray.map((item) => {
      return {
        time: new Date(item.date).getTime(),
        open: item.open,
        high: item.high,
        low: item.low,
        close: item.close,
        volume: item.volume
      } as KLinePoint;
    });
  }

  // 【删除】getDateKey 和 aggregateKLineData 逻辑，由后端处理 K 线聚合

  // 独立用于获取最新价格面板数据的逻辑 (保持不变)
  async fetchLatestDailyData() {
    this.isLoading = true;
    const httpRequest = http.createHttp();
    const url = `${API_HOST}/api/stocks/daily/${this.stockCode}?period=D&limit=1`;

    try {
      const resp = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        readTimeout: 5000,
        connectTimeout: 5000
      });

      if (resp.responseCode === 200) {
        const dataArray = JSON.parse(resp.result as string) as DailyDataPoint[];

        if (Array.isArray(dataArray) && dataArray.length > 0) {
          const latest = dataArray[dataArray.length - 1];
          this.latestPrice = latest.close;
          this.changePercent = latest.pct_change;
          this.open = latest.open;
          this.high = latest.high;
          this.low = latest.low;
          this.volume = latest.volume;
          this.turnover = latest.turnover;
          this.date = latest.date;
        }
      } else {
        console.error(`请求最新价格失败: ${resp.responseCode}`);
      }
    } catch (err) {
      console.error(`网络异常 (最新价格): ${JSON.stringify(err)}`);
    } finally {
      this.isLoading = false;
      httpRequest.destroy();
    }
  }

  // 【新增】新闻数据请求
  async fetchNewsData() {
    this.isNewsLoading = true;
    const httpRequest = http.createHttp();
    const url = `${API_HOST}/api/stocks/news/${this.stockCode}`;

    try {
      const resp = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        readTimeout: 5000,
        connectTimeout: 5000
      });

      if (resp.responseCode === 200) {
        this.newsList = JSON.parse(resp.result as string) as NewsItemModel[];
      } else {
        console.error(`请求新闻失败: ${resp.responseCode}`);
      }
    } catch (err) {
      console.error(`网络异常 (新闻): ${JSON.stringify(err)}`);
    } finally {
      this.isNewsLoading = false;
      httpRequest.destroy();
    }
  }

  // 【修正和统一】统一的K线数据请求和切换逻辑 (调用新的 /kline 接口)
  async fetchKlineData(type: string) {
    let cachedData: KLinePoint[] | null = null;
    let period: string = 'daily'; // 后端期待的参数

    switch (type) {
      case '日K':
        cachedData = this.dailyDataCache;
        period = 'daily';
        break;
      case '周K':
        cachedData = this.weeklyDataCache;
        period = 'weekly';
        break;
      case '月K':
        cachedData = this.monthlyDataCache;
        period = 'monthly';
        break;
      default:
        return;
    }

    if (cachedData) {
      this.kLineData = cachedData;
      return;
    }

    this.isKLineLoading = true;
    this.kLineData = [];
    const httpRequest = http.createHttp();

    // *** 关键修改：调用新的 /kline 接口 ***
    const url = `${API_HOST}/api/stocks/kline/${this.stockCode}?period=${period}`;

    console.log(`[DetailPage] Requesting KLine Data. Type: ${type}, Period: ${period}, URL: ${url}`);

    try {
      const resp = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        readTimeout: 5000,
        connectTimeout: 5000
      });

      if (resp.responseCode === 200) {
        let dataArray = JSON.parse(resp.result as string) as DailyDataPoint[];

        if (Array.isArray(dataArray) && dataArray.length > 0) {
          const convertedData = this.transformToKLinePoint(dataArray);
          this.kLineData = convertedData;

          if (type === '日K') {
            this.dailyDataCache = convertedData;
          } else if (type === '周K') {
            this.weeklyDataCache = convertedData;
          } else if (type === '月K') {
            this.monthlyDataCache = convertedData;
          }
        } else {
          this.kLineData = [];
        }
      } else {
        console.error(`请求 K 线数据失败 (${type}): ${resp.responseCode}`);
        this.kLineData = [];
      }
    } catch (err) {
      console.error(`网络异常 (K线数据): ${JSON.stringify(err)}`);
      this.kLineData = [];
    } finally {
      this.isKLineLoading = false;
      httpRequest.destroy();
    }
  }

  private getPrevClose(): number {
    const divisor = 1 + this.changePercent / 100;
    return divisor === 0 ? this.latestPrice : this.latestPrice / divisor;
  }

  private getChangeAmount(): number {
    return this.latestPrice - this.getPrevClose();
  }

  private getSign(): string {
    return this.changePercent > 0 ? '+' : '';
  }

  getColor(val: number): string {
    if (val > 0) return '#E53935'; // 红色 (涨)
    if (val < 0) return '#00B066'; // 绿色 (跌)
    return '#333333'; // 黑色/灰色
  }

  build() {
    Column() {
      this.NavBar();

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color('#1976D2')
          Text('正在获取行情...').fontSize(14).fontColor('#999').margin({ top: 10 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({space: 10}) { // 增加卡片间距
            this.PricePanel();
            this.KTabs();
            this.NewsCard(); // 【替换】旧的 MoreInfo
          }
          .padding({bottom: 20})
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F7FB') // 整体背景色
  }

  @Builder
  NavBar() {
    // 保持不变
    Row() {
      Image($r('app.media.ic_back'))
        .width(26)
        .height(26)
        .onClick(() => router.back())
        .margin({ right: 10 })

      Column() {
        Text(this.stockName)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        Text(this.stockCode)
          .fontSize(14)
          .fontColor('#999')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: '#EEE' })
  }

  @Builder
  PricePanel() {
    // 增加卡片设计元素：圆角、阴影、外边距
    Column() {
      Text(this.latestPrice.toFixed(2))
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getColor(this.changePercent))

      Row() {
        Text(`${this.getSign()}${this.getChangeAmount().toFixed(2)}   ${this.getSign()}${this.changePercent.toFixed(2)}%`)
          .fontSize(16)
          .fontColor(this.getColor(this.changePercent))
      }
      .margin({ top: 4 })

      Text(`数据日期: ${this.date}`)
        .fontSize(12)
        .fontColor('#999')
        .margin({top: 4})

      Row() {
        this.MiniStat('最高', this.high.toFixed(2), this.high > this.getPrevClose() ? '#E53935' : '#00B066')
        this.MiniStat('最低', this.low.toFixed(2), this.low < this.getPrevClose() ? '#00B066' : '#E53935')
        this.MiniStat('成交量', (this.volume / 100).toFixed(0) + '手', '#333')
        this.MiniStat('换手率', this.turnover.toFixed(2) + '%', '#333')
      }
      .margin({ top: 12 })
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 10, left: 10, right: 10 }) // 增加外边距
    .borderRadius(12) // 增加圆角
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)' }) // 增加阴影
  }

  @Builder
  MiniStat(label: string, value: string, color: string) {
    // 保持不变
    Column() {
      Text(label)
        .fontSize(13)
        .fontColor('#777')
      Text(value)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(color)
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  KTabs() {
    // 增加卡片设计元素：圆角、阴影、外边距
    Column() {
      Row() {
        this.KTabItem('日K')
        this.KTabItem('周K')
        this.KTabItem('月K')
      }
      .padding({ left: 20, right: 20, top: 10, bottom: 10 })
      .width('100%')
      .justifyContent(FlexAlign.Start) // 左对齐

      this.KLineView()
    }
    .backgroundColor('#FFFFFF')
    .margin({ left: 10, right: 10 }) // 增加外边距
    .borderRadius(12) // 增加圆角
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)' }) // 增加阴影
  }

  @Builder
  KTabItem(type: string) {
    // 增加间距
    Column() {
      Text(type)
        .fontSize(15)
        .fontColor(this.kType === type ? '#1976D2' : '#666')
        .padding({ bottom: 6 })

      if (this.kType === type) {
        Row()
          .width(20)
          .height(2)
          .backgroundColor('#1976D2')
      }
    }
    .width(60)
    .margin({ right: 20 }) // 增加右侧间距
    .onClick(() => {
      if (this.kType !== type) {
        this.kType = type;
        this.fetchKlineData(type);
      }
    })
  }

  @Builder
  KLineView() {
    // 保持不变，但移除占位图逻辑，使用简单文本提示
    Column() {
      if (this.isKLineLoading) {
        Column() {
          LoadingProgress().width(30).height(30).color('#1976D2')
          Text('K线数据加载中...').fontSize(14).fontColor('#999').margin({ top: 10 })
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)
      } else if (this.kLineData.length > 0) {
        KLineChart({ data: this.kLineData })
          .width('100%')
          .height(300)
      } else {
        Stack() {
          Text(`暂无${this.kType}数据`)
            .textAlign(TextAlign.Center)
            .fontSize(16)
            .fontColor('#666')
        }
        .height(300)
        .width('100%')
        .backgroundColor('#F9F9F9') // 浅色背景
        // .justifyContent(FlexAlign.Center)
      }
    }
    .padding({top: 10, bottom: 10, left: 5, right: 5})
  }

  // 【新】新闻卡片容器
  @Builder
  NewsCard() {
    Column() {
      // 标题和加载状态
      Row() {
        Text('市场资讯')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')

        Blank()

        if (this.isNewsLoading) {
          LoadingProgress().width(16).height(16).color('#1976D2')
        } else if (this.newsList.length > 0) {
          Text(`共 ${this.newsList.length} 条`).fontSize(13).fontColor('#999')
        }
      }
      .padding({ top: 16, bottom: 10, left: 16, right: 16 })
      .width('100%')

      // 列表或空状态
      if (this.newsList.length === 0 && !this.isNewsLoading) {
        Text('暂无最新资讯')
          .fontSize(14)
          .fontColor('#999')
          .padding(20)
          .width('100%')
          .textAlign(TextAlign.Center)
      } else {
        List() {
          ForEach(this.newsList, (item: NewsItemModel) => {
            ListItem() {
              this.NewsItem(item)
            }
          })
        }
        // 列表分隔线
        .divider({ strokeWidth: 1, color: '#F0F0F0', startMargin: 16, endMargin: 16 })
      }
    }
    .backgroundColor('#FFFFFF')
    .margin({ left: 10, right: 10 })
    .borderRadius(12)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)' })
  }


  // 【新】新闻单项组件，使用真实数据和美观布局
  @Builder
  NewsItem(item: NewsItemModel) {
    Column() {
      // 标题
      Text(item.title)
        .width('100%')
        .fontSize(16)
        .fontColor('#333')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(22)

      // 来源和时间
      Row() {
        // 来源标签
        Text(item.source)
          .fontSize(11)
          .fontColor('#1976D2')
          .backgroundColor('#EAF2FF') // 浅蓝色背景
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
          .margin({ right: 8 })

        // 时间
        Text(item.date)
          .fontSize(12)
          .fontColor('#AAA')

        Blank()
      }
      .margin({ top: 8 })
      .width('100%')

    }
    .padding({ top: 12, bottom: 12, left: 16, right: 16 })
    .width('100%')
    .onClick(() => {
      // 点击跳转逻辑
      if (item.uri) {
        console.log(`Opening news link: ${item.uri}`);
      }
    })
  }
}