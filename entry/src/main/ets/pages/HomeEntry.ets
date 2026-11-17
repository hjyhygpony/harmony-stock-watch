// HomeEntry.ets - 首页独立入口页面
import { HomePage } from './HomePage'

@Entry
@Component
struct HomeEntry {
  build() {
    Column() {
      HomePage()
    }
  }
}
