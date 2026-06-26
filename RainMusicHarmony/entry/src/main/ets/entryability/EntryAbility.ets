import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { window } from '@kit.ArkUI'

/**
 * 应用入口 Ability
 */
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'RainMusic', 'EntryAbility onCreate')
  }

  onDestroy(): void {
    hilog.info(0x0000, 'RainMusic', 'EntryAbility onDestroy')
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'RainMusic', 'EntryAbility onWindowStageCreate')

    // 设置全屏显示
    windowStage.getMainWindow((err, win) => {
      if (err) {
        hilog.error(0x0000, 'RainMusic', '获取窗口失败: %{public}s', JSON.stringify(err))
        return
      }
      // 设置状态栏和导航栏样式
      win.setWindowSystemBarEnable(['status', 'navigation'])
      win.setWindowLayoutFullScreen(false)
    })

    // 加载首页
    windowStage.loadContent('pages/Index', (err) => {
      if (err) {
        hilog.error(0x0000, 'RainMusic', '加载页面失败: %{public}s', JSON.stringify(err))
        return
      }
      hilog.info(0x0000, 'RainMusic', '页面加载成功')
    })
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'RainMusic', 'EntryAbility onWindowStageDestroy')
  }

  onForeground(): void {
    hilog.info(0x0000, 'RainMusic', 'EntryAbility onForeground')
  }

  onBackground(): void {
    hilog.info(0x0000, 'RainMusic', 'EntryAbility onBackground')
  }
}
