/**
 * 专辑封面组件 — 暗色海军蓝主题
 */
import { AppColors } from '../constants/Colors'

@Component
export struct AlbumArt {
  albumArtUri: string = ''
  artSize: number = 280

  build() {
    Stack() {
      if (this.albumArtUri) {
        Image(this.albumArtUri)
          .width(this.artSize)
          .height(this.artSize)
          .objectFit(ImageFit.Cover)
          .borderRadius(20)
      } else {
        // 海军蓝渐变占位图
        Column() {
          Image($r('app.media.icon'))
            .width(this.artSize * 0.3)
            .height(this.artSize * 0.3)
            .fillColor(AppColors.TextSecondary)
        }
        .width(this.artSize)
        .height(this.artSize)
        .borderRadius(20)
        .linearGradient({
          direction: GradientDirection.RightBottom,
          colors: [[AppColors.CoverNavy1, 0], [AppColors.BgBorder, 1]]
        })
        .justifyContent(FlexAlign.Center)
      }
    }
    .width(this.artSize)
    .height(this.artSize)
    .shadow({ radius: 16, color: 'rgba(0,0,0,0.4)', offsetY: 4 })
  }
}
