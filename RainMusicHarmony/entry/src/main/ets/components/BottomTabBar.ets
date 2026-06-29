import { PlayerViewModel } from '../viewmodel/PlayerViewModel'
import { Song } from '../model/SongModel'
import { AppColors } from '../constants/Colors'

/**
 * 底部药丸 Tab 栏 — 集成迷你播放
 */
@Component
export struct BottomTabBar {
  @Link viewModel: PlayerViewModel
  selectedTab: number = 0 // 0=音乐库, 1=导入音乐
  onTabSelected: (index: number) => void = () => {}
  onOpenPlayer: () => void = () => {}

  build() {
    Column() {
      // 迷你播放区域（有歌曲时显示）
      if (this.viewModel.currentSong) {
        Row() {
          // 小封面
          Stack() {
            if (this.viewModel.currentSong?.albumArtUri) {
              Image(this.viewModel.currentSong.albumArtUri)
                .width(36)
                .height(36)
                .borderRadius(8)
                .objectFit(ImageFit.Cover)
            } else {
              Row()
                .width(36)
                .height(36)
                .borderRadius(8)
                .backgroundColor(AppColors.CoverNavy1)
            }
          }
          .width(36)
          .height(36)

          // 歌曲标题
          Text(this.viewModel.currentSong?.title ?? '')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TextPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
            .margin({ left: 10 })

          // 播放/暂停按钮
          SymbolGlyph(this.viewModel.isPlaying ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'))
            .fontSize(18)
            .fontColor([AppColors.Accent])
            .margin({ left: 8 })
            .onClick(() => { this.viewModel.togglePlayPause() })

          // 下一曲按钮
          SymbolGlyph($r('sys.symbol.forward_end_fill'))
            .fontSize(16)
            .fontColor([AppColors.TextSecondary])
            .margin({ left: 8 })
            .onClick(() => { this.viewModel.playNext() })
        }
        .width('100%')
        .padding({ left: 14, right: 12, top: 8, bottom: 8 })
        .borderRadius(20)
        .backgroundColor(AppColors.BgPill)
        .alignItems(VerticalAlign.Center)
        .onClick(() => this.onOpenPlayer())
        .margin({ bottom: 6 })
      }

      // Tab 栏（药丸形）
      Row() {
        // 音乐库 Tab
        Row() {
          SymbolGlyph($r('sys.symbol.music_fill'))
            .fontSize(16)
          Text('音乐库')
            .fontSize(14)
            .fontWeight(this.selectedTab === 0 ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.selectedTab === 0 ? AppColors.TabSelectedText : AppColors.TabUnselectedText)
            .margin({ left: 6 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .height('100%')
        .borderRadius(36)
        .backgroundColor(this.selectedTab === 0 ? AppColors.TabSelectedBg : Color.Transparent)
        .onClick(() => {
          this.selectedTab = 0
          this.onTabSelected(0)
        })

        // 导入音乐 Tab
        Row() {
          SymbolGlyph($r('sys.symbol.download'))
            .fontSize(16)
          Text('导入音乐')
            .fontSize(14)
            .fontWeight(this.selectedTab === 1 ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.selectedTab === 1 ? AppColors.TabSelectedText : AppColors.TabUnselectedText)
            .margin({ left: 6 })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .height('100%')
        .borderRadius(36)
        .backgroundColor(this.selectedTab === 1 ? AppColors.TabSelectedBg : Color.Transparent)
        .onClick(() => {
          this.selectedTab = 1
          this.onTabSelected(1)
        })
      }
      .width('100%')
      .height(52)
      .borderRadius(36)
      .backgroundColor(AppColors.BgPill)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
  }
}
