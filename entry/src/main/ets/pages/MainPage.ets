// MainPage.ets - 主框架页面，包含底部导航
import { HomePage } from './HomePage'
import { AlertCenterPage } from './AlertCenterPage'
import { GroupPage } from './GroupPage'

@Entry
@Component
struct MainPage {
  @State currentTab: number = 0

  build() {
    Column() {
      // 内容区域
      Stack() {
        if (this.currentTab === 0) {
          HomePage()
        } else if (this.currentTab === 1) {
          AlertCenterPage()
        } else {
          GroupPage()
        }
      }
      .layoutWeight(1)
      .width('100%')

      // 底部导航栏
      Row() {
        this.TabItem(0, '首页', '🏠')
        this.TabItem(1, '通知', '🔔')
        this.TabItem(2, '分组', '📁')
      }
      .width('100%')
      .height(60)
      .backgroundColor('#FFFFFF')
      .borderWidth({ top: 1 })
      .borderColor('#E5E5E5')
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }

  @Builder
  TabItem(index: number, label: string, icon: string) {
    Column() {
      Text(icon)
        .fontSize(22)
      Text(label)
        .fontSize(12)
        .fontColor(this.currentTab === index ? '#4A90E2' : '#999999')
        .margin({ top: 4 })
    }
    .width('33%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentTab = index
    })
  }
}
