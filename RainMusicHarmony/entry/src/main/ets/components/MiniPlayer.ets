import { PlayerViewModel } from '../viewmodel/PlayerViewModel'
import { AppColors } from '../constants/Colors'

@Component
export struct MiniPlayer {
  @Link viewModel: PlayerViewModel
  onOpenPlayer: () => void = () => {}
  @State playScale: number = 1.0

  private handlePlayClick() {
    this.playScale = 0.92
    setTimeout(() => {
      this.playScale = 1.0
    }, 100)
    this.viewModel.togglePlayPause()
  }

  build() {
    if (this.viewModel.currentSong) {
      Column() {
        Stack({ alignContent: Alignment.TopStart }) {
          Row()
            .width('100%')
            .height(4)
            .borderRadius(2)
            .backgroundColor(AppColors.BgBorder + '99')

          Row()
            .width(`${this.viewModel.duration > 0 ? (this.viewModel.currentTime / this.viewModel.duration) * 100 : 0}%`)
            .height(4)
            .borderRadius(2)
            .linearGradient({
              direction: GradientDirection.Right,
              colors: [[AppColors.Accent, 0], [AppColors.Accent + 'B3', 1]]
            })
        }
        .width('100%')
        .height(4)
        .margin({ top: 2 })

        Row() {
          Stack() {
            if (this.viewModel.currentSong?.albumArtUri) {
              Image(this.viewModel.currentSong.albumArtUri)
                .width(48)
                .height(48)
                .borderRadius(12)
                .objectFit(ImageFit.Cover)
            } else {
              Column() {
                Image($r('app.media.icon'))
                  .width(22)
                  .height(22)
                  .fillColor(AppColors.TextSecondary)
              }
              .width(48)
              .height(48)
              .borderRadius(12)
              .linearGradient({
                direction: GradientDirection.RightBottom,
                colors: [[AppColors.CoverNavy1, 0], [AppColors.BgBorder, 1]]
              })
              .justifyContent(FlexAlign.Center)
            }
          }
          .width(48)
          .height(48)
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.15)', offsetY: 2 })

          Column() {
            Text(this.viewModel.currentSong?.title ?? '')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TextPrimary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Text(this.viewModel.currentSong?.artist ?? '')
              .fontSize(12)
              .fontColor(AppColors.TextSecondary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .margin({ left: 14 })
          .alignItems(HorizontalAlign.Start)

          Stack() {
            SymbolGlyph(this.viewModel.isPlaying ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'))
              .fontSize(20)
              .fontColor([AppColors.BgDark])
          }
          .width(44)
          .height(44)
          .borderRadius(22)
          .linearGradient({
            direction: GradientDirection.RightBottom,
            colors: [[AppColors.Accent, 0], [AppColors.AccentDark, 1]]
          })
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .scale({ x: this.playScale, y: this.playScale })
          .animation({
            duration: 150,
            curve: Curve.EaseInOut,
            delay: 0
          })
          .onClick(() => this.handlePlayClick())
          .margin({ left: 14 })
          .shadow({ radius: 10, color: AppColors.Accent + '66', offsetY: 4 })

          SymbolGlyph($r('sys.symbol.forward_end_fill'))
            .fontSize(20)
            .fontColor([AppColors.TextSecondary])
            .margin({ left: 6 })
            .width(36)
            .height(36)
            .onClick(() => { this.viewModel.playNext() })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .margin({ top: 10 })
        .borderRadius(20)
        .backgroundColor(AppColors.BgPill + 'D9')
        .alignItems(VerticalAlign.Center)
        .onClick(() => this.onOpenPlayer())
      }
      .width('100%')
      .padding({ left: 10, right: 10, bottom: 6 })
    }
  }
}