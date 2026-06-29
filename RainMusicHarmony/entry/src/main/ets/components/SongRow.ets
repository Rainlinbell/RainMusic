import { Song } from '../model/SongModel'
import { AppColors } from '../constants/Colors'

/**
 * 歌曲列表行组件 — 暗色主题
 */
@Component
export struct SongRow {
  song: Song = new Song()
  isCurrentPlaying: boolean = false
  onTap: () => void = () => {}
  onDelete: () => void = () => {}

  build() {
    Row() {
      // 封面
      Stack() {
        if (this.song.albumArtUri) {
          Image(this.song.albumArtUri)
            .width(48)
            .height(48)
            .borderRadius(6)
            .objectFit(ImageFit.Cover)
        } else {
          Row()
            .width(48)
            .height(48)
            .borderRadius(6)
            .backgroundColor(AppColors.CoverNavy1)
        }
      }
      .width(48)
      .height(48)

      // 歌曲信息
      Column() {
        Text(this.song.title)
          .fontSize(15)
          .fontColor(this.isCurrentPlaying ? AppColors.Accent : AppColors.TextPrimary)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.song.artist)
          .fontSize(12)
          .fontColor(AppColors.TextSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      // 时长
      Text(this.song.formattedDuration)
        .fontSize(13)
        .fontColor(AppColors.TextSecondary)

      // 竖三点更多按钮
      Column({ space: 3 }) {
        Row().width(3).height(3).borderRadius(50).backgroundColor(AppColors.DotGray)
        Row().width(3).height(3).borderRadius(50).backgroundColor(AppColors.DotGray)
        Row().width(3).height(3).borderRadius(50).backgroundColor(AppColors.DotGray)
      }
      .margin({ left: 8 })
      .onClick(() => this.onDelete())
    }
    .width('100%')
    .padding({ left: 8, right: 8, top: 8, bottom: 8 })
    .borderRadius(8)
    .onClick(() => this.onTap())
    .gesture(
      LongPressGesture()
        .onAction(() => this.onDelete())
    )
  }
}
