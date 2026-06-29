import { PlayerViewModel } from '../viewmodel/PlayerViewModel'
import { SongRow } from '../components/SongRow'
import { BottomTabBar } from '../components/BottomTabBar'
import { Song, SortOrder } from '../model/SongModel'
import { AppColors } from '../constants/Colors'
import { router } from '@kit.ArkUI'
import { picker } from '@kit.CoreFileKit'
import { promptAction } from '@kit.ArkUI'
import { abilityAccessCtrl } from '@kit.AbilityKit'

/**
 * 音乐库主页 — 深色海军蓝主题
 */
@Entry
@Component
struct Index {
  @State viewModel: PlayerViewModel = new PlayerViewModel(getContext(this) as import('@kit.AbilityKit').common.UIAbilityContext)
  @State searchText: string = ''
  @State selectedTab: number = 0 // 0=音乐库, 1=导入音乐
  @State lastSwitchTime: number = 0
  @State listOffsetY: number = 0
  @State isSearchActive: boolean = false

  aboutToAppear() {
    try {
      const atManager = abilityAccessCtrl.createAtManager()
      atManager.requestPermissionsFromUser(getContext(this), ['ohos.permission.READ_MEDIA'])
    } catch (e) {
      console.error('权限请求失败: ' + String(e))
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.selectedTab === 0) {
        this.libraryContent()
      } else {
        this.importContent()
      }

      // 底部 Tab 栏（常驻）
      BottomTabBar({
        viewModel: $viewModel,
        selectedTab: this.selectedTab,
        onTabSelected: (index: number) => {
          this.selectedTab = index
        },
        onOpenPlayer: () => {
          router.pushUrl({ url: 'pages/PlayerPage' })
        }
      })
      .transition(TransitionEffect.translate({ y: 100 }).combine(TransitionEffect.OPACITY))
      .animation({ duration: 300 })

      // 扫描遮罩
      if (this.viewModel.isScanning) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color(AppColors.Accent)

          Text('正在扫描音乐库...')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TextPrimary)
            .margin({ top: 16 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .justifyContent(FlexAlign.Center)
        .zIndex(999)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BgDark)
  }

  @Builder
  libraryContent() {
    Column() {
      // 自定义 Header
      Row() {
        Text('我的音乐')
          .fontSize(28)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TextPrimary)

        Blank()

        // 搜索按钮
        SymbolGlyph(this.isSearchActive ? $r('sys.symbol.xmark') : $r('sys.symbol.magnifyingglass'))
          .fontSize(20)
          .onClick(() => {
            this.isSearchActive = !this.isSearchActive
            if (!this.isSearchActive) {
              this.searchText = ''
              this.viewModel.searchQuery = ''
            }
          })

        // 排序按钮
        SymbolGlyph($r('sys.symbol.more'))
          .fontSize(22)
          .fontColor([AppColors.TextPrimary])
          .margin({ left: 16 })
          .onClick(() => { this.cycleSortOrder() })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 8 })

      // 搜索框
      if (this.isSearchActive) {
        TextInput({ placeholder: '搜索歌曲、艺术家、专辑', text: this.searchText })
          .width('100%')
          .height(44)
          .margin({ left: 20, right: 20, bottom: 8 })
          .borderRadius(12)
          .backgroundColor(AppColors.BgPill)
          .fontColor(AppColors.TextPrimary)
          .placeholderColor(AppColors.TextSecondary)
          .padding({ left: 16, right: 16 })
          .onChange((value: string) => {
            this.searchText = value
            this.viewModel.searchQuery = value
          })
      }

      // 歌曲列表
      if (this.viewModel.filteredSongs.length === 0) {
        this.emptyState()
      } else {
        List() {
          // 歌曲计数
          ListItem() {
            Text(`所有歌曲 · ${this.viewModel.filteredSongs.length}首`)
              .fontSize(14)
              .fontColor(AppColors.TextSecondary)
              .width('100%')
              .padding({ bottom: 8 })
          }

          // 歌曲列表
          ForEach(this.viewModel.filteredSongs, (song: Song) => {
            ListItem() {
              SongRow({
                song: song,
                isCurrentPlaying: this.viewModel.currentSong?.id === song.id,
                onTap: () => {
                  this.viewModel.setPlaylist(this.viewModel.filteredSongs, this.viewModel.filteredSongs.indexOf(song))
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
        .padding({ left: 20, right: 20, bottom: 110 })
        .offset({ y: this.listOffsetY })
        .gesture(
          PanGesture({ direction: PanDirection.Vertical, distance: 10 })
            .onActionUpdate((event: GestureEvent) => {
              this.listOffsetY = event.offsetY * 0.3
            })
            .onActionEnd((event: GestureEvent) => {
              const now = Date.now()
              const threshold = 100
              if (event.offsetY < -threshold && now - this.lastSwitchTime > 1500) {
                this.lastSwitchTime = now
                animateTo({ duration: 250, curve: Curve.FastOutSlowIn }, () => {
                  this.listOffsetY = -80
                })
                setTimeout(() => {
                  this.viewModel.playNext()
                  animateTo({ duration: 300, curve: Curve.FastOutSlowIn }, () => {
                    this.listOffsetY = 0
                  })
                }, 150)
              } else if (event.offsetY > threshold && now - this.lastSwitchTime > 1500) {
                this.lastSwitchTime = now
                animateTo({ duration: 250, curve: Curve.FastOutSlowIn }, () => {
                  this.listOffsetY = 80
                })
                setTimeout(() => {
                  this.viewModel.playPrevious()
                  animateTo({ duration: 300, curve: Curve.FastOutSlowIn }, () => {
                    this.listOffsetY = 0
                  })
                }, 150)
              } else {
                animateTo({ duration: 300, curve: Curve.FastOutSlowIn }, () => {
                  this.listOffsetY = 0
                })
              }
            })
        )
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  importContent() {
    Column() {
      Text('导入音乐')
        .fontSize(24)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TextPrimary)
        .margin({ top: 32 })

      Blank().height(32)

      SymbolGlyph($r('sys.symbol.download'))
        .fontSize(48)

      Blank().height(16)

      Text('导入音频文件')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TextPrimary)

      Blank().height(8)

      Text('支持 MP3、M4A、WAV、FLAC、OGG 等格式')
        .fontSize(14)
        .fontColor(AppColors.TextSecondary)

      Blank().height(32)

      Button('选择文件')
        .type(ButtonType.Capsule)
        .backgroundColor(AppColors.Accent)
        .fontColor(AppColors.BgDark)
        .width('80%')
        .height(48)
        .fontWeight(FontWeight.Medium)
        .onClick(() => { this.pickAndImport() })

      Blank().height(16)

      Button('扫描设备音乐库')
        .type(ButtonType.Capsule)
        .backgroundColor(Color.Transparent)
        .fontColor(AppColors.TextPrimary)
        .borderColor(AppColors.BgBorder)
        .borderWidth(1)
        .width('80%')
        .height(48)
        .onClick(() => { this.doScan() })

      Blank().height(32)

      // 提示卡片
      Column() {
        Text('提示')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TextPrimary)
          .width('100%')
        Blank().height(8)
        Text('• 扫描将自动发现设备上的所有音乐文件\n• 导入支持从文件管理器选择音频文件\n• 歌词文件(.lrc)会自动关联同名音频')
          .fontSize(12)
          .fontColor(AppColors.TextSecondary)
          .width('100%')
      }
      .width('80%')
      .padding(16)
      .borderRadius(16)
      .backgroundColor(AppColors.BgPill)

      Blank().layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: 110 })
  }

  @Builder
  emptyState() {
    Column() {
      Blank().layoutWeight(1)

      SymbolGlyph($r('sys.symbol.music_fill'))
        .fontSize(56)

      Text('音乐库为空')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TextPrimary)
        .margin({ top: 16 })

      Text('扫描设备音乐库或导入音频文件')
        .fontSize(14)
        .fontColor(AppColors.TextSecondary)
        .margin({ top: 8 })

      Row({ space: 16 }) {
        Button('扫描音乐库')
          .type(ButtonType.Capsule)
          .backgroundColor(AppColors.Accent)
          .fontColor(AppColors.BgDark)
          .layoutWeight(1)
          .onClick(() => { this.doScan() })
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

  private async doScan() {
    try {
      await this.viewModel.scanMusic()
      promptAction.showToast({ message: this.viewModel.scanResult, duration: 2000 })
    } catch (e) {
      console.error('扫描异常: ' + String(e))
      promptAction.showToast({ message: '扫描出错，请检查权限设置', duration: 2000 })
    }
  }

  private async pickAndImport() {
    try {
      const documentPicker = new picker.DocumentViewPicker()
      const options: picker.DocumentSelectOptions = {
        fileSuffixFilters: ['.mp3', '.flac', '.wav', '.aac', '.ogg', '.m4a', '.wma', '.ape'],
        maxSelectNumber: 20
      }
      const uris = await documentPicker.select(options)
      if (uris && uris.length > 0) {
        for (const uri of uris) {
          await this.viewModel.importFile(uri)
        }
        promptAction.showToast({ message: `导入成功 ${uris.length} 首歌曲`, duration: 2000 })
      }
    } catch (e) {
      console.error('文件选择失败: ' + JSON.stringify(e))
    }
  }
}
