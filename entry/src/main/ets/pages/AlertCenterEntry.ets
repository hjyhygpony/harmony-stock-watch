// AlertCenterEntry.ets - 预警中心独立入口页面
import { AlertCenterPage } from './AlertCenterPage'

@Entry
@Component
struct AlertCenterEntry {
  build() {
    Column() {
      AlertCenterPage()
    }
  }
}
