import { Want } from '@kit.AbilityKit';
import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import formBindingData from '@ohos.app.form.formBindingData';
import http from '@ohos.net.http';
import formProvider from '@ohos.app.form.formProvider';


/** ----------- 类型定义 ----------- **/

interface StockListDataItem {
  code: string;
  name: string;
}

interface DailyDataPoint {
  code: string;
  date: string;
  close: number;
  pct_change: number;
}

interface FavStockItem {
  id: string;
  name: string;
  code: string;
  price: number;
  changePercent: number;
}

interface WidgetStateData {
  indexName: string;
  indexPrice: string;
  indexChangePercent: number;
  favStocks: FavStockItem[];
}

/** ----------- 配置 ----------- **/

const STOCK_POOL: string[] = ['600519', '000001', '300750'];
const API_HOST: string = 'http://10.0.2.2:8013';
const API_KEY: string = ''; // 可加 Bearer Token

export default class EntryFormAbility extends FormExtensionAbility {

  /** -------- 卡片回调：绑定数据（必须同步返回 FormBindingData） -------- */
  onFormBind(want: Want): formBindingData.FormBindingData {
    const placeholder: WidgetStateData = {
      indexName: '--',
      indexPrice: '--',
      indexChangePercent: 0,
      favStocks: []
    };

    // 异步拉取数据并 updateForm（不阻塞 UI）
    this.loadAndUpdate(want);

    return formBindingData.createFormBindingData(placeholder);
  }

  /** --------- 核心异步逻辑（HTTP 请求 + 更新卡片） --------- */
   private async loadAndUpdate(want: Want): Promise<void> {

     console.error("load start");

     const formId = this.extractFormId(want);
     console.error("formId = ", formId);
     console.error("API_HOST = ", API_HOST);
    if (!formId) return;

    const httpReq = http.createHttp();
    const headers: Record<string, string> =
      API_KEY !== '' ? { "Authorization": `Bearer ${API_KEY}` } : {};

    let stockList: StockListDataItem[] = [];

    /** Step 1：拉取股票列表 */
    try {
      const response = await httpReq.request(`${API_HOST}/api/stocks/list`, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        header: headers
      });

      console.error("listResp = ", response.result);


      if (response.responseCode === 200) {
        const parsed = JSON.parse(response.result as string) as StockListDataItem[];
        stockList = parsed.filter(item => STOCK_POOL.indexOf(item.code) >= 0);
      }

      console.error("stockList = ", stockList);

    } catch (_) {}

    /** Step 2：拉取每只股票行情 */
    const fav: FavStockItem[] = [];
    console.error("fav = ", fav);

     for (let i = 0; i < stockList.length; i++) {
      const item = stockList[i];

      try {
        const response = await httpReq.request(
          `${API_HOST}/api/stocks/daily/${item.code}?limit=1`,
          {
            method: http.RequestMethod.GET,
            expectDataType: http.HttpDataType.STRING,
            header: headers
          }
        );

        if (response.responseCode === 200) {
          const parsed = JSON.parse(response.result as string) as DailyDataPoint[];
          if (parsed.length > 0) {
            const d = parsed[0];

            const one: FavStockItem = {
              id: item.code,
              name: item.name,
              code: item.code,
              price: d.close,
              changePercent: d.pct_change
            };

            fav.push(one);
          }
        }
      } catch (_) {}
    }

    httpReq.destroy();

    /** Step 3：构造最终数据 */
    let result: WidgetStateData;

    if (fav.length > 0) {
      const top = fav[0];
      result = {
        indexName: top.name,
        indexPrice: top.price.toFixed(2),
        indexChangePercent: top.changePercent,
        favStocks: fav.slice(0, 2)
      };
    } else {
      result = {
        indexName: '--',
        indexPrice: '--',
        indexChangePercent: 0,
        favStocks: []
      };
    }

    // 更新卡片
    formBindingData.createFormBindingData(result);
    await this.updateForm(formId, result);
  }


  /** -------- 安全提取 FormId（不使用 unknown/any） -------- */
  private extractFormId(want: Want): string | undefined {
    const params = want.parameters;
    if (!params) return undefined;

    const key: string = 'ohos.extra.param.key.form_identity';
    const id = params[key];

    return typeof id === 'string' ? id : undefined;
  }

  /** -------- 调用 formProvider.updateForm -------- */
  private async updateForm(formId: string, data: WidgetStateData): Promise<void> {
    try {
      await formProvider.updateForm(formId, formBindingData.createFormBindingData(data));
    } catch (_) {}
  }
}
