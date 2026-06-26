import { PlayerViewModel } from '../viewmodel/PlayerViewModel'
import { SongRow } from '../components/SongRow'
import { MiniPlayer } from '../components/MiniPlayer'
import { Song, SortOrder } from '../model/SongModel'
import { router } from '@kit.ArkUI'

/**
 * 音乐库主页
 */
@Entry
@Component
struct Index {
  @State viewModel: PlayerViewModel = new PlayerViewModel(getContext(this) as import('@kit.AbilityKit').common.UIAbilityContext)
  @State searchText: string = ''
  @State showMiniPlayer: boolean = false

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        // 标题栏
        Row() {
          Text('音乐库')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1B1F')

          Blank()

          // 排序按钮
          Button() {
            Text('⇅')
              .fontSize(20)
              .fontColor('#49454F')
          }
          .type(ButtonType.Circle)
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.cycleSortOrder() })

          // 更多菜单
          Button() {
            Text('+')
              .fontSize(24)
              .fontColor('#49454F')
          }
          .type(ButtonType.Circle)
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.showMoreMenu() })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 8 })

        // 搜索框
        TextInput({ placeholder: '搜索歌曲、艺术家、专辑', text: this.searchText })
          .width('100%')
          .height(44)
          .margin({ left: 16, right: 16, bottom: 8 })
          .borderRadius(22)
          .backgroundColor('#F0F0F0')
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.searchText = value
            this.viewModel.searchQuery = value
          })

        // 歌曲列表
        if (this.viewModel.filteredSongs.length === 0) {
          this.emptyState()
        } else {
          List() {
            ForEach(this.viewModel.filteredSongs, (song: Song) => {
              ListItem() {
                SongRow({
                  song: song,
                  isCurrentPlaying: this.viewModel.currentSong?.id === song.id,
                  onTap: () => {
                    this.viewModel.setPlaylist(this.viewModel.filteredSongs, this.viewModel.filteredSongs.indexOf(song))
                    this.showMiniPlayer = true
                  },
                  onDelete: () => {
                    this.viewModel.deleteSong(song)
                  }
                })
              }
            }, (song: Song) => song.id.toString())
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ bottom: this.showMiniPlayer ? 70 : 0 })
        }
      }
      .width('100%')
      .height('100%')

      // 迷你播放器
      if (this.showMiniPlayer && this.viewModel.currentSong) {
        MiniPlayer({
          songTitle: this.viewModel.currentSong?.title ?? '未在播放',
          songArtist: this.viewModel.currentSong?.artist ?? '',
          isPlaying: this.viewModel.isPlaying,
          currentTime: this.viewModel.currentTime,
          duration: this.viewModel.duration,
          onTap: () => {
            router.pushUrl({ url: 'pages/PlayerPage' })
          },
          onTogglePlay: () => { this.viewModel.togglePlayPause() },
          onNext: () => { this.viewModel.playNext() }
        })
        .transition(TransitionEffect.translate({ y: 100 }).combine(TransitionEffect.OPACITY))
        .animation({ duration: 300 })
      }

      // 扫描遮罩
      if (this.viewModel.isScanning) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color('#6650A4')

          Text('正在扫描音乐库...')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1C1B1F')
            .margin({ top: 16 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.4)')
        .justifyContent(FlexAlign.Center)
        .zIndex(999)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFBFE')
  }

  @Builder
  emptyState() {
    Column() {
      Blank().layoutWeight(1)

      Image($r('app.media.icon'))
        .width(80)
        .height(80)
        .fillColor('#79747E')

      Text('音乐库为空')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1C1B1F')
        .margin({ top: 16 })

      Text('扫描设备音乐库或导入音频文件')
        .fontSize(14)
        .fontColor('#79747E')
        .margin({ top: 8 })

      Row({ space: 16 }) {
        Button('扫描音乐库')
          .type(ButtonType.Capsule)
          .backgroundColor('#6650A4')
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .onClick(() => { this.viewModel.scanMusic() })

        Button('导入文件')
          .type(ButtonType.Capsule)
          .backgroundColor(Color.Transparent)
          .fontColor('#6650A4')
          .borderColor('#6650A4')
          .borderWidth(1)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 40, right: 40 })
      .margin({ top: 24 })

      Blank().layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
  }

  private cycleSortOrder() {
    switch (this.viewModel.sortOrder) {
      case SortOrder.DATE_ADDED:
        this.viewModel.sortOrder = SortOrder.TITLE
        break
      case SortOrder.TITLE:
        this.viewModel.sortOrder = SortOrder.ARTIST
        break
      case SortOrder.ARTIST:
        this.viewModel.sortOrder = SortOrder.ALBUM
        break
      case SortOrder.ALBUM:
        this.viewModel.sortOrder = SortOrder.DATE_ADDED
        break
    }
  }

  private showMoreMenu() {
    // 扫描音乐库
    this.viewModel.scanMusic()
  }
}
