// GroupManage.ets
import { Store } from '../common/Store';
import { genId } from '../common/Utils';
import router from '@ohos.router';

@Entry
@Component
struct GroupManage {
  @State groups = Store.groups;
  @State newGroupName: string = '';

  aboutToAppear() {
    this.groups = Store.groups;
  }

  createGroup() {
    if (!this.newGroupName) return;
    const g = Store.createGroup(this.newGroupName);
    this.newGroupName = '';
    this.groups = Store.groups;
  }

  build() {
    Column() {
      Row() {
        Button('返回').onClick(() => router.back());
        Text('自选分组').fontSize(18).margin({ left: 12 });
      }.padding(12).backgroundColor(Color.White)

      Row() {
        Input({ placeholder: '新建分组名', value: this.newGroupName, onChange: (e) => { this.newGroupName = e.value; } })
        Button('创建').onClick(() => this.createGroup())
      }.padding(12).backgroundColor(Color.White).margin({ bottom: 8 })

      Scroll() {
        Column() {
          ForEach(this.groups, (g: any) => {
            Column() {
              Row() {
                Text(g.name).fontSize(16).fontWeight(FontWeight.Medium)
              }
              .padding(12)
              .backgroundColor('#FFF')
              .border({ width: { bottom: 1 }, color: '#EEE' })
            }.margin({ bottom: 8 })
          }, (g: any) => g.id)
        }
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#F6F7FB')
  }
}

function Input(arg0: { placeholder: string; value: string; onChange: (e: any) => void; }) {
  throw new Error('Function not implemented.');
}
