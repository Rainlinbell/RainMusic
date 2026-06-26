import { PlayerViewModel } from '../viewmodel/PlayerViewModel'
import { AlbumArt } from '../components/AlbumArt'
import { LyricsView } from '../components/LyricsView'
import { ShuffleMode, RepeatMode } from '../model/SongModel'
import { router } from '@kit.ArkUI'

/**
 * 播放器页面 - 完整播放控制
 */
@Entry
@Component
struct PlayerPage {
  @State viewModel: PlayerViewModel = new PlayerViewModel(getContext(this) as import('@kit.AbilityKit').common.UIAbilityContext)
  @State isSeeking: boolean = false
  @State seekPosition: number = 0
  @State showLyrics: boolean = false

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button() {
          Text('⌄')
            .fontSize(28)
            .fontColor('#1C1B1F')
        }
        .type(ButtonType.Circle)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back()
        })

        Text('正在播放')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1B1F')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank().width(48)
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 8, bottom: 8 })

      Scroll() {
        Column() {
          // 封面 / 歌词切换
          if (this.showLyrics) {
            LyricsView({
              lyrics: this.viewModel.lyrics,
              currentIndex: this.viewModel.currentLyricIndex,
              stateVersion: this.viewModel.stateVersion
            })
            .height(320)
            .onClick(() => {
              animateTo({ duration: 300 }, () => {
                this.showLyrics = false
              })
            })
          } else {
            AlbumArt({
              albumArtUri: this.viewModel.currentSong?.albumArtUri ?? '',
              artSize: 280
            })
            .onClick(() => {
              animateTo({ duration: 300 }, () => {
                this.showLyrics = true
              })
            })
          }

          // 切换提示
          Text(this.showLyrics ? '显示封面' : '显示歌词')
            .fontSize(12)
            .fontColor('#79747E')
            .margin({ top: 8 })
            .onClick(() => {
              animateTo({ duration: 300 }, () => {
                this.showLyrics = !this.showLyrics
              })
            })

          // 歌曲信息
          Column() {
            Text(this.viewModel.currentSong?.title ?? '未在播放')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1B1F')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Center)

            Text(this.viewModel.currentSong?.artist ?? '')
              .fontSize(16)
              .fontColor('#49454F')
              .maxLines(1)
              .margin({ top: 4 })

            Text(this.viewModel.currentSong?.album ?? '')
              .fontSize(14)
              .fontColor('#79747E')
              .maxLines(1)
              .margin({ top: 2 })
          }
          .width('100%')
          .padding({ left: 32, right: 32 })
          .margin({ top: 16 })
          .alignItems(HorizontalAlign.Center)

          // 进度条
          Column() {
            Slider({
              value: this.isSeeking ? this.seekPosition : this.viewModel.currentTime,
              min: 0,
              max: Math.max(this.viewModel.duration, 1),
              step: 1
            })
              .blockColor('#6650A4')
              .trackColor('#E0E0E0')
              .selectedColor('#6650A4')
              .onChange((value: number) => {
                this.isSeeking = true
                this.seekPosition = value
              })

            Row() {
              Text(this.viewModel.formatTime(this.viewModel.currentTime))
                .fontSize(12)
                .fontColor('#79747E')

              Blank()

              Text(this.viewModel.formatTime(this.viewModel.duration))
                .fontSize(12)
                .fontColor('#79747E')
            }
            .width('100%')
          }
          .width('100%')
          .padding({ left: 24, right: 24 })
          .margin({ top: 24 })

          // 控制按钮
          Row() {
            // 随机
            Button() {
              Text('⇄')
                .fontSize(22)
                .fontColor(this.viewModel.shuffleMode === ShuffleMode.ON ? '#6650A4' : '#79747E')
            }
            .type(ButtonType.Circle)
            .backgroundColor(Color.Transparent)
            .onClick(() => { this.viewModel.toggleShuffle() })

            // 上一曲
            Button() {
              Text('⏮')
                .fontSize(28)
                .fontColor('#1C1B1F')
            }
            .type(ButtonType.Circle)
            .backgroundColor(Color.Transparent)
            .onClick(() => { this.viewModel.playPrevious() })

            // 播放/暂停
            Button() {
              Text(this.viewModel.isPlaying ? '⏸' : '▶')
                .fontSize(36)
                .fontColor('#1C1B1F')
            }
            .type(ButtonType.Circle)
            .width(64)
            .height(64)
            .backgroundColor('#6650A4')
            .fontColor('#FFFFFF')
            .onClick(() => { this.viewModel.togglePlayPause() })

            // 下一曲
            Button() {
              Text('⏭')
                .fontSize(28)
                .fontColor('#1C1B1F')
            }
            .type(ButtonType.Circle)
            .backgroundColor(Color.Transparent)
            .onClick(() => { this.viewModel.playNext() })

            // 循环
            Button() {
              Text(this.viewModel.repeatMode === RepeatMode.ONE ? '↻¹' : '↻')
                .fontSize(22)
                .fontColor(this.viewModel.repeatMode !== RepeatMode.OFF ? '#6650A4' : '#79747E')
            }
            .type(ButtonType.Circle)
            .backgroundColor(Color.Transparent)
            .onClick(() => { this.viewModel.cycleRepeatMode() })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceEvenly)
          .alignItems(VerticalAlign.Center)
          .margin({ top: 16 })

          // 音量（无极调节）
          Row() {
            Text('🔈')
              .fontSize(16)
              .margin({ right: 8 })

            Slider({
              value: this.viewModel.volume,
              min: 0,
              max: 1,
              step: 0.01
            })
              .blockColor('#6650A4')
              .trackColor('#E0E0E0')
              .selectedColor('#6650A4')
              .layoutWeight(1)
              .onChange((value: number) => {
                this.viewModel.setVolume(value)
              })

            Text('🔊')
              .fontSize(16)
              .margin({ left: 8 })
          }
          .width('100%')
          .padding({ left: 24, right: 24 })
          .alignItems(VerticalAlign.Center)
          .margin({ top: 24 })

          Blank().height(32)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFBFE')
  }
}
