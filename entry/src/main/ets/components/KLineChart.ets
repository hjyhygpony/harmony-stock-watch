import { KLinePoint } from '../common/StockData';

@Component
export struct KLineChart {
  @Prop @Watch('onDataChanged') data: KLinePoint[] = [];
  // Canvas 配置
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  // 画布尺寸
  private chartWidth: number = 0;
  private chartHeight: number = 0;
  // 选中的K线索引和数据（用于显示悬浮信息）
  @State selectedIndex: number = -1;
  @State selectedData: KLinePoint | null = null;
  @State tooltipX: number = 0;
  @State tooltipY: number = 0;
  // 样式配置
  private readonly COLOR_UP: string = '#E53935'; // 涨：红
  private readonly COLOR_DOWN: string = '#00B066'; // 跌：绿
  private readonly COLOR_GRID: string = '#EEEEEE'; // 网格线颜色
  private readonly COLOR_LABEL: string = '#999999'; // 标签颜色
  private readonly COLOR_CROSSHAIR: string = '#666666'; // 十字线颜色
  private readonly PADDING_TOP: number = 20;
  private readonly PADDING_BOTTOM: number = 20;
  private readonly LABEL_LEFT_MARGIN: number = 50; // 预留左侧空间给 Y 轴价格标签

  build() {
    Stack() {
      Canvas(this.context)
        .width('100%')
        .height('100%')
        .onAreaChange((oldValue, newValue) => {
          this.chartWidth = Number(newValue.width);
          this.chartHeight = Number(newValue.height);
          this.draw();
        })
        .onReady(() => {
          this.draw();
        })
        .onTouch((event: TouchEvent) => {
          this.handleTouch(event);
        })

      // 悬浮信息框
      if (this.selectedData !== null) {
        this.TooltipView()
      }
    }
    .width('100%')
    .height('100%')
  }

  // 处理触摸事件
  handleTouch(event: TouchEvent) {
    if (event.type === TouchType.Down || event.type === TouchType.Move) {
      const touchX = event.touches[0].x;
      const touchY = event.touches[0].y;

      // 计算点击的是哪根K线
      const count = this.data.length;
      if (count === 0) {
        return;
      }

      const effectiveWidth = this.chartWidth - this.LABEL_LEFT_MARGIN;
      const itemWidth = effectiveWidth / count;

      // 计算索引
      const relativeX = touchX - this.LABEL_LEFT_MARGIN;
      if (relativeX < 0) {
        this.selectedIndex = -1;
        this.selectedData = null;
        this.draw();
        return;
      }

      const index = Math.floor(relativeX / itemWidth);
      if (index >= 0 && index < count) {
        this.selectedIndex = index;
        this.selectedData = this.data[index];

        // 计算tooltip位置
        const candleX = this.LABEL_LEFT_MARGIN + index * itemWidth + itemWidth / 2;
        // tooltip显示在点击位置附近，但确保不超出边界
        this.tooltipX = Math.min(Math.max(candleX, 100), this.chartWidth - 100);
        this.tooltipY = Math.max(touchY, 80);

        this.draw();
      }
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      // 手指抬起时隐藏信息框
      this.selectedIndex = -1;
      this.selectedData = null;
      this.draw();
    }
  }

  // 悬浮信息框组件
  @Builder
  TooltipView() {
    if (this.selectedData !== null) {
      Column() {
        // 日期
        Text(this.formatDate(this.selectedData.time))
          .fontSize(12)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 6 })

        Row() {
          Text('开: ')
            .fontSize(11)
            .fontColor('#CCCCCC')
          Text(this.selectedData.open.toFixed(2))
            .fontSize(11)
            .fontColor(this.selectedData.close >= this.selectedData.open ? this.COLOR_UP : this.COLOR_DOWN)
        }
        .width('100%')

        Row() {
          Text('高: ')
            .fontSize(11)
            .fontColor('#CCCCCC')
          Text(this.selectedData.high.toFixed(2))
            .fontSize(11)
            .fontColor(this.COLOR_UP)
        }
        .width('100%')

        Row() {
          Text('低: ')
            .fontSize(11)
            .fontColor('#CCCCCC')
          Text(this.selectedData.low.toFixed(2))
            .fontSize(11)
            .fontColor(this.COLOR_DOWN)
        }
        .width('100%')

        Row() {
          Text('收: ')
            .fontSize(11)
            .fontColor('#CCCCCC')
          Text(this.selectedData.close.toFixed(2))
            .fontSize(11)
            .fontColor(this.selectedData.close >= this.selectedData.open ? this.COLOR_UP : this.COLOR_DOWN)
        }
        .width('100%')

        Row() {
          Text('量: ')
            .fontSize(11)
            .fontColor('#CCCCCC')
          Text(this.selectedData.volume !== undefined ? this.formatVolume(this.selectedData.volume) : '--')
            .fontSize(11)
            .fontColor('#FFFFFF')
        }
        .width('100%')
      }
      .padding(10)
      .backgroundColor('rgba(0, 0, 0, 0.8)')
      .borderRadius(8)
      .position({
        x: this.tooltipX - 60,
        y: Math.max(10, this.tooltipY - 120)
      })
    }
  }

  // 格式化日期
  formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  // 格式化成交量
  formatVolume(volume: number): string {
    if (volume >= 100000000) {
      return (volume / 100000000).toFixed(2) + '亿';
    } else if (volume >= 10000) {
      return (volume / 10000).toFixed(2) + '万';
    }
    return volume.toString();
  }

  onDataChanged() {
    this.draw();
  }

  // 核心绘制逻辑
  draw() {
    if (!this.data || this.data.length === 0 || this.chartWidth === 0 || this.chartHeight === 0) {
      return;
    }

    // 清空画布
    this.context.clearRect(0, 0, this.chartWidth, this.chartHeight);

    // 1. 计算价格极值和缩放比例
    let maxPrice = -Infinity;
    let minPrice = Infinity;

    this.data.forEach(p => {
      maxPrice = Math.max(maxPrice, p.high);
      minPrice = Math.min(minPrice, p.low);
    });

    if (maxPrice === minPrice) {
      maxPrice += 1;
      minPrice -= 1;
    }

    const count = this.data.length;
    // 绘图区域宽度需要减去左侧标签预留空间
    const effectiveWidth = this.chartWidth - this.LABEL_LEFT_MARGIN;
    const itemWidth = effectiveWidth / count;
    const candleWidth = itemWidth * 0.7;
    const gap = itemWidth * 0.15;
    const priceRange = maxPrice - minPrice;
    const drawHeight = this.chartHeight - this.PADDING_TOP - this.PADDING_BOTTOM;

    // Y 轴坐标映射函数
    // 所有的 X 坐标都从 LABEL_LEFT_MARGIN 开始
    const getY = (price: number) => {
      return this.PADDING_TOP + (maxPrice - price) / priceRange * drawHeight;
    };

    // --- 2. 绘制网格线和 Y 轴价格标签 ---
    // 调用普通的成员方法
    this.drawGrid(drawHeight, getY, maxPrice, minPrice, effectiveWidth);

    // --- 3. 循环绘制 K 线实体和影线 ---
    this.data.forEach((item, index) => {
      // 计算 X 轴坐标 (注意加上左侧预留空间)
      const x = this.LABEL_LEFT_MARGIN + index * itemWidth + gap;
      const centerX = x + candleWidth / 2;

      // Y 轴坐标
      const yOpen = getY(item.open);
      const yClose = getY(item.close);
      const yHigh = getY(item.high);
      const yLow = getY(item.low);

      // 判断涨跌颜色
      const isUp = item.close >= item.open;
      const color = isUp ? this.COLOR_UP : this.COLOR_DOWN;

      this.context.fillStyle = color;
      this.context.strokeStyle = color;
      this.context.lineWidth = 1;

      // A. 绘制影线
      this.context.beginPath();
      this.context.moveTo(centerX, yHigh);
      this.context.lineTo(centerX, yLow);
      this.context.stroke();

      // B. 绘制实体
      const rectY = Math.min(yOpen, yClose);
      const rectH = Math.abs(yClose - yOpen);
      const finalRectH = Math.max(rectH, 1);

      this.context.fillRect(x, rectY, candleWidth, finalRectH);

      // C. 绘制 X 轴日期标签
      const labelInterval = Math.floor(count / 5);
      if (index % labelInterval === 0 || index === count - 1) {
        // 调用普通的成员方法
        this.drawXAxisLabel(centerX, item.time, index, count);
      }
    });

    // --- 4. 绘制选中K线的十字线 ---
    if (this.selectedIndex >= 0 && this.selectedIndex < count) {
      this.drawCrosshair(this.selectedIndex, itemWidth, getY);
    }
  }

  // 绘制十字线
  drawCrosshair(index: number, itemWidth: number, getY: (price: number) => number) {
    const item = this.data[index];
    const x = this.LABEL_LEFT_MARGIN + index * itemWidth + itemWidth / 2;
    const y = getY(item.close);

    this.context.strokeStyle = this.COLOR_CROSSHAIR;
    this.context.lineWidth = 1;
    this.context.setLineDash([4, 4]);

    // 垂直线
    this.context.beginPath();
    this.context.moveTo(x, this.PADDING_TOP);
    this.context.lineTo(x, this.chartHeight - this.PADDING_BOTTOM);
    this.context.stroke();

    // 水平线
    this.context.beginPath();
    this.context.moveTo(this.LABEL_LEFT_MARGIN, y);
    this.context.lineTo(this.chartWidth, y);
    this.context.stroke();

    this.context.setLineDash([]);

    // 绘制选中点
    this.context.fillStyle = this.COLOR_CROSSHAIR;
    this.context.beginPath();
    this.context.arc(x, y, 4, 0, Math.PI * 2);
    this.context.fill();
  }

  // 绘制网格线和中间价格标签 (移除 @Builder)
  drawGrid(drawHeight: number, getY: (price: number) => number, maxPrice: number, minPrice: number,
    effectiveWidth: number) {
    this.context.strokeStyle = this.COLOR_GRID;
    this.context.lineWidth = 1;
    this.context.setLineDash([4, 2]); // 设置虚线

    // 绘制 5 条水平网格线 (0%, 25%, 50%, 75%, 100%)
    const numLines = 5;
    for (let i = 0; i < numLines; i++) {
      const y = this.PADDING_TOP + i * (drawHeight / (numLines - 1));

      this.context.beginPath();
      // 网格线从 LABEL_LEFT_MARGIN 处开始绘制
      this.context.moveTo(this.LABEL_LEFT_MARGIN, y);
      this.context.lineTo(this.chartWidth, y);
      this.context.stroke();

      // 绘制价格标签 (Y 轴标签)
      if (i < numLines) {
        const interpolatedPrice = maxPrice - i / (numLines - 1) * (maxPrice - minPrice);

        this.context.fillStyle = this.COLOR_LABEL;
        this.context.font = '10vp sans-serif';
        this.context.textAlign = 'right'; // 标签右对齐，贴近图表区域

        // 绘制在 LABEL_LEFT_MARGIN 之前
        this.context.fillText(interpolatedPrice.toFixed(2), this.LABEL_LEFT_MARGIN - 5, y - 5);
      }
    }

    this.context.setLineDash([]); // 恢复实线
    this.context.textAlign = 'left'; // 恢复默认对齐
  }

  // 绘制 X 轴日期标签 (移除 @Builder)
  drawXAxisLabel(x: number, timestamp: number, index: number, count: number) {
    const date = new Date(timestamp);
    // 格式化为 MM/DD (月/日)
    const dateStr = `${date.getMonth() + 1}/${date.getDate()}`;

    this.context.fillStyle = this.COLOR_LABEL;
    this.context.font = '10vp sans-serif';

    // 修正最右侧标签溢出问题
    if (index === count - 1) {
      this.context.textAlign = 'right';
      // 绘制在图表底部，并偏移到画布右边缘
      this.context.fillText(dateStr, this.chartWidth - 5, this.chartHeight - 5);
    } else {
      this.context.textAlign = 'center';
      this.context.fillText(dateStr, x, this.chartHeight - 5);
    }
    this.context.textAlign = 'left'; // 恢复默认对齐
  }

  // 绘制最高价/最低价标签（不再需要，但保留函数签名）(移除 @Builder)
  drawYAxisLabels(maxPrice: number, minPrice: number) {
    // 逻辑已合并到 drawGrid
  }
}