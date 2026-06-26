/**
 * 专辑封面组件
 */
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
          .borderRadius(16)
      } else {
        // 渐变占位图
        Column() {
          Image($r('app.media.icon'))
            .width(this.artSize * 0.3)
            .height(this.artSize * 0.3)
            .fillColor('#6650A4')
        }
        .width(this.artSize)
        .height(this.artSize)
        .borderRadius(16)
        .backgroundColor('#E8DEF8')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width(this.artSize)
    .height(this.artSize)
  }
}
