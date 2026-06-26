/**
 * 迷你播放条组件
 */
@Component
export struct MiniPlayer {
  songTitle: string = '未在播放'
  songArtist: string = ''
  isPlaying: boolean = false
  currentTime: number = 0
  duration: number = 1
  onTap: () => void = () => {}
  onTogglePlay: () => void = () => {}
  onNext: () => void = () => {}

  build() {
    Column() {
      // 进度条
      Progress({ value: this.currentTime, total: this.duration, type: ProgressType.Linear })
        .color('#6650A4')
        .backgroundColor('#E0E0E0')
        .width('100%')
        .height(2)

      Row() {
        // 封面占位
        Stack() {
          Image($r('app.media.icon'))
            .width(40)
            .height(40)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
        }
        .width(40)
        .height(40)
        .borderRadius(8)
        .backgroundColor('#E8DEF8')

        // 歌曲信息
        Column() {
          Text(this.songTitle)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1C1B1F')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.songArtist)
            .fontSize(12)
            .fontColor('#79747E')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })

        // 播放/暂停
        Button() {
          Text(this.isPlaying ? '⏸' : '▶')
            .fontSize(20)
            .fontColor('#1C1B1F')
        }
        .type(ButtonType.Circle)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.onTogglePlay())

        // 下一曲
        Button() {
          Text('⏭')
            .fontSize(18)
        }
        .type(ButtonType.Circle)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.onNext())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor('#F5F5F5')
    .borderRadius({ topLeft: 12, topRight: 12 })
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.1)', offsetY: -2 })
    .onClick(() => this.onTap())
  }
}
