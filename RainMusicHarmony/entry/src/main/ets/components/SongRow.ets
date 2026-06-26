import { Song } from '../model/SongModel'

/**
 * 歌曲列表行组件
 */
@Component
export struct SongRow {
  song: Song = new Song()
  isCurrentPlaying: boolean = false
  onTap: () => void = () => {}
  onDelete: () => void = () => {}

  build() {
    Row() {
      // 播放指示器
      if (this.isCurrentPlaying) {
        Image($r('app.media.icon'))
          .width(16)
          .height(16)
          .fillColor('#6650A4')
          .margin({ right: 8 })
      }

      Column() {
        Text(this.song.title)
          .fontSize(16)
          .fontColor(this.isCurrentPlaying ? '#6650A4' : '#1C1B1F')
          .fontWeight(this.isCurrentPlaying ? FontWeight.Bold : FontWeight.Normal)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          Text(this.song.artist)
            .fontSize(13)
            .fontColor('#79747E')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(' · ')
            .fontSize(13)
            .fontColor('#79747E')

          Text(this.song.album)
            .fontSize(13)
            .fontColor('#79747E')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.Transparent)
    .onClick(() => this.onTap())
    .gesture(
      LongPressGesture()
        .onAction(() => this.onDelete())
    )
  }
}
