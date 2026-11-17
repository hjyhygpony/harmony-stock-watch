// GroupPage.ets - 分组管理页面
import { Stock, Group } from '../common/StockData'
import { Store } from '../common/Store'
import { genId } from '../common/Utils'
import router from '@ohos.router'
import http from '@ohos.net.http'

interface StockListDataItem {
  code: string
  name: string
}

interface DailyDataPoint {
  close: number
  pct_change: number
}

// 分组统计信息
interface GroupStats {
  totalStocks: number
  avgChange: number
  maxChange: number
  minChange: number
  totalValue: number
}

const API_HOST: string = "http://10.0.2.2:8013"

@Component
export struct GroupPage {
  @State groups: Group[] = []
  @State selectedGroupId: string = ''
  @State stocksInGroup: Stock[] = []
  @State allStocks: Stock[] = []
  @State showCreateDialog: boolean = false
  @State showAddStockDialog: boolean = false
  @State newGroupName: string = ''
  @State isLoading: boolean = false
  @State groupStats: GroupStats | null = null
  @State overallStats: GroupStats | null = null
  @State selectedStockIds: string[] = []

  aboutToAppear() {
    this.loadGroups()
    this.fetchAllStocks()
  }

  loadGroups() {
    this.groups = Store.groups || []
    if (this.groups.length > 0 && !this.selectedGroupId) {
      this.selectedGroupId = this.groups[0].id
    }
    // 不在这里调用 updateGroupStocksAndStats，等 allStocks 加载完成后再调用
  }

  async fetchAllStocks(): Promise<void> {
    this.isLoading = true
    const httpRequest = http.createHttp()
    try {
      const listResp = await httpRequest.request(`${API_HOST}/api/stocks/list`, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        readTimeout: 10000,
        connectTimeout: 10000
      })

      if (listResp.responseCode === 200) {
        const stockItems = JSON.parse(listResp.result as string) as StockListDataItem[]
        const stocks: Stock[] = []

        for (const item of stockItems.slice(0, 30)) {
          try {
            const dailyResp = await httpRequest.request(
              `${API_HOST}/api/stocks/daily/${item.code}?limit=1`,
              { method: http.RequestMethod.GET, expectDataType: http.HttpDataType.STRING }
            )
            if (dailyResp.responseCode === 200) {
              const dailyData = JSON.parse(dailyResp.result as string) as DailyDataPoint[]
              if (dailyData.length > 0) {
                stocks.push({
                  id: item.code,
                  code: item.code,
                  name: item.name,
                  price: dailyData[0].close,
                  changePercent: dailyData[0].pct_change,
                  timestamp: Date.now()
                })
              }
            }
          } catch (e) { /* ignore */ }
        }
        this.allStocks = stocks
        // 数据加载完成后，更新当前分组的股票和统计
        this.updateGroupStocksAndStats()
        this.calculateOverallStats()
      }
    } catch (err) {
      console.error('获取股票列表失败:', JSON.stringify(err))
    } finally {
      httpRequest.destroy()
      this.isLoading = false
    }
  }

  // 切换分组
  switchToGroup(groupId: string): void {
    if (this.selectedGroupId === groupId) return

    this.selectedGroupId = groupId
    // 切换时先清空，再重新计算
    this.stocksInGroup = []
    this.groupStats = null
    this.updateGroupStocksAndStats()
  }

  // 同步更新分组股票和统计
  updateGroupStocksAndStats(): void {
    if (!this.selectedGroupId) {
      this.stocksInGroup = []
      this.groupStats = null
      return
    }

    const group = this.groups.find(g => g.id === this.selectedGroupId)
    if (!group) {
      this.stocksInGroup = []
      this.groupStats = null
      return
    }

    // 如果 allStocks 还没加载完，先不处理
    if (this.allStocks.length === 0 && group.stockIds.length > 0) {
      // 数据还在加载中，保持 loading 状态
      return
    }

    // 获取分组内的股票
    const stocks: Stock[] = []
    for (const stockId of group.stockIds) {
      const cached = this.allStocks.find(s => s.id === stockId)
      if (cached) {
        stocks.push(cached)
      }
    }

    // 强制更新 stocksInGroup
    this.stocksInGroup = [...stocks]

    // 立即计算统计数据
    if (stocks.length === 0) {
      this.groupStats = null
    } else {
      const changes = stocks.map(s => s.changePercent)
      // 强制创建新对象以触发 UI 更新
      this.groupStats = {
        totalStocks: stocks.length,
        avgChange: changes.reduce((a, b) => a + b, 0) / changes.length,
        maxChange: Math.max(...changes),
        minChange: Math.min(...changes),
        totalValue: stocks.reduce((sum, s) => sum + s.price, 0)
      }
    }
  }

  async loadGroupStocks(): Promise<void> {
    this.isLoading = true
    this.updateGroupStocksAndStats()
    this.isLoading = false
  }

  calculateOverallStats() {
    if (this.groups.length === 0) {
      this.overallStats = null
      return
    }

    let totalStocks = 0
    let allChanges: number[] = []

    for (const group of this.groups) {
      totalStocks += group.stockIds.length
      for (const stockId of group.stockIds) {
        const stock = this.allStocks.find(s => s.id === stockId)
        if (stock) {
          allChanges.push(stock.changePercent)
        }
      }
    }

    if (allChanges.length > 0) {
      this.overallStats = {
        totalStocks,
        avgChange: allChanges.reduce((a, b) => a + b, 0) / allChanges.length,
        maxChange: Math.max(...allChanges),
        minChange: Math.min(...allChanges),
        totalValue: 0
      }
    }
  }

  createGroup() {
    if (!this.newGroupName.trim()) return

    const newGroup: Group = {
      id: genId('g'),
      name: this.newGroupName.trim(),
      stockIds: [],
      createdAt: Date.now()
    }

    Store.groups.push(newGroup)
    Store.saveGroups()
    this.groups = [...Store.groups]
    this.selectedGroupId = newGroup.id
    this.newGroupName = ''
    this.showCreateDialog = false
    this.updateGroupStocksAndStats()
  }

  deleteGroup(groupId: string) {
    Store.groups = Store.groups.filter(g => g.id !== groupId)
    Store.saveGroups()
    this.groups = [...Store.groups]

    if (this.selectedGroupId === groupId) {
      this.selectedGroupId = this.groups.length > 0 ? this.groups[0].id : ''
      this.updateGroupStocksAndStats()
    }
    this.calculateOverallStats()
  }

  addStocksToGroup() {
    if (this.selectedStockIds.length === 0 || !this.selectedGroupId) return

    const group = Store.groups.find(g => g.id === this.selectedGroupId)
    if (!group) return

    for (const stockId of this.selectedStockIds) {
      if (!group.stockIds.includes(stockId)) {
        group.stockIds.push(stockId)
      }
    }

    Store.saveGroups()
    this.groups = [...Store.groups]
    this.selectedStockIds = []
    this.showAddStockDialog = false
    this.updateGroupStocksAndStats()
    this.calculateOverallStats()
  }

  removeStockFromGroup(stockId: string) {
    const group = Store.groups.find(g => g.id === this.selectedGroupId)
    if (!group) return

    group.stockIds = group.stockIds.filter(id => id !== stockId)
    Store.saveGroups()
    this.groups = [...Store.groups]
    this.updateGroupStocksAndStats()
    this.calculateOverallStats()
  }

  toggleStockSelection(stockId: string) {
    if (this.selectedStockIds.includes(stockId)) {
      this.selectedStockIds = this.selectedStockIds.filter(id => id !== stockId)
    } else {
      this.selectedStockIds = [...this.selectedStockIds, stockId]
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('自选分组')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        Blank()
        Button('+ 新建分组')
          .fontSize(12)
          .height(32)
          .onClick(() => {
            this.showCreateDialog = true
          })
      }
      .padding(16)
      .width('100%')
      .backgroundColor('#FFFFFF')

      // 整体统计
      if (this.overallStats) {
        this.OverallStatsCard()
      }

      // 分组选择器
      if (this.groups.length > 0) {
        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.groups, (group: Group) => {
              this.GroupTab(group)
            }, (g: Group) => g.id)
          }
          .padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .height(50)
        .width('100%')
      }

      // 当前分组统计
      if (this.groupStats !== null && this.selectedGroupId) {
        Column() {
          Text('当前分组统计')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#666666')
            .margin({ bottom: 8 })
          Row() {
            Column() {
              Text(this.groupStats.totalStocks.toString())
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
              Text('股票数')
                .fontSize(11)
                .fontColor('#999999')
                .margin({ top: 2 })
            }

            Column() {
              Text(`${this.groupStats.avgChange.toFixed(2)}%`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.groupStats.avgChange < 0 ? '#67C23A' : '#F56C6C')
              Text('平均涨跌')
                .fontSize(11)
                .fontColor('#999999')
                .margin({ top: 2 })
            }

            Column() {
              Text(`${this.groupStats.maxChange.toFixed(2)}%`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.groupStats.maxChange < 0 ? '#67C23A' : '#F56C6C')
              Text('最高')
                .fontSize(11)
                .fontColor('#999999')
                .margin({ top: 2 })
            }

            Column() {
              Text(`${this.groupStats.minChange.toFixed(2)}%`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.groupStats.minChange < 0 ? '#67C23A' : '#F56C6C')
              Text('最低')
                .fontSize(11)
                .fontColor('#999999')
                .margin({ top: 2 })
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
        }
        .padding(12)
        .margin({ left: 16, right: 16, top: 8 })
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
      }

      // 操作按钮
      if (this.selectedGroupId) {
        Row() {
          Button('添加股票')
            .fontSize(12)
            .height(32)
            .backgroundColor('#4CAF50')
            .onClick(() => {
              this.selectedStockIds = []
              this.showAddStockDialog = true
            })
          Button('删除分组')
            .fontSize(12)
            .height(32)
            .backgroundColor('#FF5252')
            .margin({ left: 8 })
            .onClick(() => {
              this.deleteGroup(this.selectedGroupId)
            })
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .width('100%')
        .justifyContent(FlexAlign.End)
      }

      // 股票列表
      if (this.groups.length === 0) {
        Column() {
          Text('📁').fontSize(48).margin({ bottom: 12 })
          Text('暂无分组').fontSize(14).fontColor('#999999')
          Text('点击右上角创建分组').fontSize(12).fontColor('#CCCCCC').margin({ top: 4 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40)
          Text('加载中...').fontSize(14).fontColor('#999999').margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.stocksInGroup.length === 0) {
        Column() {
          Text('📊').fontSize(48).margin({ bottom: 12 })
          Text('该分组暂无股票').fontSize(14).fontColor('#999999')
          Text('点击"添加股票"按钮添加').fontSize(12).fontColor('#CCCCCC').margin({ top: 4 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 8 }) {
          ForEach(this.stocksInGroup, (stock: Stock) => {
            ListItem() {
              this.StockCard(stock)
            }
          }, (s: Stock) => s.id)
        }
        .layoutWeight(1)
        .padding({ left: 16, right: 16, bottom: 16 })
      }

      // 创建分组弹窗
      if (this.showCreateDialog) {
        this.CreateGroupDialog()
      }

      // 添加股票弹窗
      if (this.showAddStockDialog) {
        this.AddStockDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  GroupTab(group: Group) {
    Row() {
      Text(group.name)
        .fontSize(13)
        .fontColor(this.selectedGroupId === group.id ? '#FFFFFF' : '#666666')
      Text(`(${group.stockIds.length})`)
        .fontSize(11)
        .fontColor(this.selectedGroupId === group.id ? '#FFFFFF' : '#999999')
        .margin({ left: 4 })
    }
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor(this.selectedGroupId === group.id ? '#4A90E2' : '#FFFFFF')
    .borderRadius(16)
    .onClick(() => {
      this.switchToGroup(group.id)
    })
  }

  @Builder
  OverallStatsCard() {
    Column() {
      Text('全部分组统计')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#666666')
        .margin({ bottom: 8 })
      Row() {
        Column() {
          Text(this.groups.length.toString())
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Text('分组数')
            .fontSize(11)
            .fontColor('#999999')
            .margin({ top: 2 })
        }

        Column() {
          Text(this.overallStats!.totalStocks.toString())
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Text('股票总数')
            .fontSize(11)
            .fontColor('#999999')
            .margin({ top: 2 })
        }

        Column() {
          Text(`${this.overallStats!.avgChange.toFixed(2)}%`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.overallStats!.avgChange < 0 ? '#67C23A' : '#F56C6C')
          Text('平均涨跌')
            .fontSize(11)
            .fontColor('#999999')
            .margin({ top: 2 })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
    }
    .padding(12)
    .margin({ left: 16, right: 16, top: 8 })
    .backgroundColor('#E3F2FD')
    .borderRadius(8)
  }



  @Builder
  StockCard(stock: Stock) {
    Row() {
      Column() {
        Text(stock.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
        Text(stock.code)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Column() {
        Text(`¥${stock.price.toFixed(2)}`)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
        Text(`${stock.changePercent >= 0 ? '+' : ''}${stock.changePercent.toFixed(2)}%`)
          .fontSize(13)
          .fontColor(stock.changePercent >= 0 ? '#F56C6C' : '#67C23A')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.End)

      Button('移除')
        .fontSize(11)
        .height(28)
        .backgroundColor('#FF5252')
        .margin({ left: 12 })
        .onClick(() => {
          this.removeStockFromGroup(stock.id)
        })
    }
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .width('100%')
    .onClick(() => {
      router.pushUrl({
        url: 'pages/DetailPage',
        params: { name: stock.name, id: stock.id, code: stock.code }
      })
    })
  }

  @Builder
  CreateGroupDialog() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000066')
        .position({ x: 0, y: 0 })
        .onClick(() => { this.showCreateDialog = false })

      Column() {
        Text('新建分组')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        TextInput({ placeholder: '请输入分组名称', text: this.newGroupName })
          .onChange((value: string) => { this.newGroupName = value })
          .width('100%')
          .margin({ bottom: 16 })

        Row() {
          Button('取消')
            .layoutWeight(1)
            .backgroundColor('#E0E0E0')
            .fontColor('#666666')
            .onClick(() => {
              this.showCreateDialog = false
              this.newGroupName = ''
            })
          Button('创建')
            .layoutWeight(1)
            .margin({ left: 8 })
            .onClick(() => { this.createGroup() })
        }
        .width('100%')
      }
      .width('85%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .position({ x: '7.5%', y: '30%' })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  @Builder
  AddStockDialog() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000066')
        .position({ x: 0, y: 0 })
        .onClick(() => { this.showAddStockDialog = false })

      Column() {
        Text('添加股票到分组')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 })

        Text(`已选择 ${this.selectedStockIds.length} 只股票`)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ bottom: 12 })

        List({ space: 4 }) {
          ForEach(this.allStocks, (stock: Stock) => {
            ListItem() {
              Row() {
                Checkbox()
                  .select(this.selectedStockIds.includes(stock.id))
                  .onChange((checked: boolean) => {
                    this.toggleStockSelection(stock.id)
                  })
                Column() {
                  Text(stock.name).fontSize(14)
                  Text(stock.code).fontSize(11).fontColor('#999999')
                }
                .alignItems(HorizontalAlign.Start)
                .margin({ left: 8 })
                .layoutWeight(1)

                Text(`${stock.changePercent >= 0 ? '+' : ''}${stock.changePercent.toFixed(2)}%`)
                  .fontSize(13)
                  .fontColor(stock.changePercent >= 0 ? '#F56C6C' : '#67C23A')
              }
              .padding(8)
              .width('100%')
              .onClick(() => { this.toggleStockSelection(stock.id) })
            }
          }, (s: Stock) => s.id)
        }
        .height(300)
        .width('100%')

        Row() {
          Button('取消')
            .layoutWeight(1)
            .backgroundColor('#E0E0E0')
            .fontColor('#666666')
            .onClick(() => {
              this.showAddStockDialog = false
              this.selectedStockIds = []
            })
          Button(`添加(${this.selectedStockIds.length})`)
            .layoutWeight(1)
            .margin({ left: 8 })
            .onClick(() => { this.addStocksToGroup() })
        }
        .width('100%')
        .margin({ top: 12 })
      }
      .width('90%')
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .position({ x: '5%', y: '10%' })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }
}
