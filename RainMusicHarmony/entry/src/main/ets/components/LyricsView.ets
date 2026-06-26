import { LyricLine } from '../model/SongModel'

/**
 * 歌词显示组件 - 同步滚动
 */
@Component
export struct LyricsView {
  @Prop lyrics: LyricLine[] = []
  @Prop @Watch('onCurrentIndexChange') currentIndex: number = -1
  @Prop stateVersion: number = 0

  private scroller: Scroller = new Scroller()
  private itemHeight: number = 44  // 每行高度（文字 + padding）

  build() {
    if (this.lyrics.length === 0) {
      Column() {
        Image($r('app.media.icon'))
          .width(40)
          .height(40)
          .fillColor('#79747E')
          .margin({ bottom: 8 })

        Text('暂无歌词')
          .fontSize(14)
          .fontColor('#79747E')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    } else {
      Scroll(this.scroller) {
        Column() {
          // 上方留白 - 让第一句歌词可以滚动到中间
          Blank().height(120)

          ForEach(this.lyrics, (line: LyricLine, index: number) => {
            Text(line.text)
              .fontSize(index === this.currentIndex ? 18 : 14)
              .fontWeight(index === this.currentIndex ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(index === this.currentIndex ? '#6650A4' : '#79747E')
              .textAlign(TextAlign.Center)
              .width('100%')
              .padding({ top: 6, bottom: 6 })
              .animation({ duration: 300 })
          }, (line: LyricLine, index: number) => index.toString())

          // 下方留白 - 让最后一句歌词可以滚动到中间
          Blank().height(120)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .onAppear(() => {
        // 初始滚动到当前歌词位置
        this.scrollToCurrentLine()
      })
    }
  }

  /**
   * 歌词索引变化时自动滚动
   */
  onCurrentIndexChange(): void {
    this.scrollToCurrentLine()
  }

  /**
   * 自动滚动到当前歌词行（居中显示）
   */
  private scrollToCurrentLine(): void {
    if (this.currentIndex < 0 || this.lyrics.length === 0) return
    // 计算偏移量：行索引 * 每行高度，减去容器高度的一半使当前行居中
    const targetY = Math.max(0, this.currentIndex * this.itemHeight - 100)
    this.scroller.scrollTo({ xOffset: 0, yOffset: targetY })
  }
}
