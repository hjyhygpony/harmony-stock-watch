import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window, router } from '@kit.ArkUI';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Store } from '../common/Store';
import { AppInitializer } from '../common/AppInitializer';

const DOMAIN = 0x0000;

interface NavigationParams {
  page?: string;
  symbol?: string;
}

export default class EntryAbility extends UIAbility {
  // 保存待跳转的参数
  private pendingNavigation: NavigationParams | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 处理通知点击启动
    this.handleWantParams(want);
    try {
      this.context.getApplicationContext().setColorMode(
        ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
      );
    } catch (err) {
      const e = err as Error;
      hilog.error(
        DOMAIN,
        'testTag',
        'Failed to set colorMode. Cause: %{public}s',
        e.message
      );
    }

    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // ---- 初始化 Store ----
    Store.setAbilityContext(this.context);

    Store.init()
      .then((): void => {
        hilog.info(DOMAIN, 'testTag', '[Store] 初始化完成');
      })
      .catch((err: Error): void => {
        hilog.error(
          DOMAIN,
          'testTag',
          '[Store] 初始化失败: %{public}s',
          err.message
        );
      });

    // ---- 初始化股票推送系统 ----
    // 包名来自 AppScope/app.json5 中的 bundleName
    AppInitializer.initialize('com.example.myfirstapplication');
    hilog.info(DOMAIN, 'testTag', '[StockAlert] 股票推送系统初始化完成');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');

    // ---- 销毁股票推送系统 ----
    AppInitializer.destroy();
    hilog.info(DOMAIN, 'testTag', '[StockAlert] 股票推送系统已销毁');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/MainPage', (err) => {
      if (err.code) {
        hilog.error(
          DOMAIN,
          'testTag',
          'Failed to load the content. Cause: %{public}s',
          JSON.stringify(err)
        );
        return;
      }

      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');

      // ---- 请求通知权限 ----
      // 必须在 loadContent 成功后调用
      notificationManager.requestEnableNotification(this.context).then(() => {
        hilog.info(DOMAIN, 'testTag', '[ANS] requestEnableNotification success');
      }).catch((error: BusinessError) => {
        hilog.error(DOMAIN, 'testTag',
          '[ANS] requestEnableNotification failed, code is %{public}d, message is %{public}s',
          error.code, error.message);
      });

      // 延迟执行跳转，确保页面加载完成
      setTimeout(() => {
        this.navigateIfNeeded();
      }, 500);
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  // 处理从通知点击启动时的参数
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onNewWant');
    this.handleWantParams(want);
    this.navigateIfNeeded();
  }

  // 解析Want参数
  private handleWantParams(want: Want): void {
    if (want.parameters) {
      const page = want.parameters['page'] as string;
      const symbol = want.parameters['symbol'] as string;
      if (page || symbol) {
        this.pendingNavigation = { page, symbol } as NavigationParams;
        hilog.info(DOMAIN, 'testTag', 'Notification params: page=%{public}s, symbol=%{public}s', page, symbol);
      }
    }
  }

  // 执行页面跳转
  private navigateIfNeeded(): void {
    if (this.pendingNavigation) {
      const page = this.pendingNavigation.page;
      const symbol = this.pendingNavigation.symbol;
      this.pendingNavigation = null;

      if (page === 'DetailPage' && symbol) {
        // 跳转到股票详情页
        router.pushUrl({
          url: 'pages/DetailPage',
          params: { symbol: symbol }
        }).catch((err: Error) => {
          hilog.error(DOMAIN, 'testTag', 'Router push failed: %{public}s', err.message);
        });
      }
    }
  }
}
