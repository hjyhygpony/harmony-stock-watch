// GroupEntry.ets - 分组管理独立入口页面
import { GroupPage } from './GroupPage'

@Entry
@Component
struct GroupEntry {
  build() {
    Column() {
      GroupPage()
    }
  }
}
