import { PlayerViewModel } from '../viewmodel/PlayerViewModel'
import { AlbumArt } from '../components/AlbumArt'
import { LyricsView } from '../components/LyricsView'
import { ShuffleMode, RepeatMode } from '../model/SongModel'
import { AppColors } from '../constants/Colors'
import { router } from '@kit.ArkUI'
import { picker, fileIo } from '@kit.CoreFileKit'
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit'
import { mediaquery } from '@kit.ArkUI'
import { display } from '@kit.ArkUI'

/**
 * 播放器页面 — 深色海军蓝主题
 */
@Entry
@Component
struct PlayerPage {
  @State viewModel: PlayerViewModel = new PlayerViewModel(getContext(this) as import('@kit.AbilityKit').common.UIAbilityContext)
  @State isSeeking: boolean = false
  @State seekPosition: number = 0
  @State showLyrics: boolean = false
  @State dragOffsetY: number = 0
  @State showMenu: boolean = false
  @State isLandscape: boolean = false
  @State progressWidth: number = 300
  private orientationListener?: mediaquery.MediaQueryListener

  aboutToAppear() {
    this.checkOrientation()
    this.orientationListener = mediaquery.matchMediaSync('(orientation: landscape)')
    this.orientationListener.on('change', (result: mediaquery.MediaQueryResult) => {
      this.isLandscape = result.matches
    })
  }

  aboutToDisappear() {
    if (this.orientationListener) {
      this.orientationListener.off('change')
    }
  }

  private checkOrientation() {
    try {
      const d = display.getDefaultDisplaySync()
      this.isLandscape = d.width > d.height
    } catch (e) {
      console.error('获取屏幕方向失败: ' + String(e))
    }
  }

  build() {
    Column() {
      // 顶部导航：返回箭头 + 竖三点菜单
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_down'))
          .fontSize(28)
          .fontColor([AppColors.TextPrimary])
          .onClick(() => { router.back() })
          .padding({ left: 8, right: 16 })

        Blank()

        // 竖三点菜单
        Column({ space: 3 }) {
          Row().width(3).height(3).borderRadius(50).backgroundColor(AppColors.DotGray)
          Row().width(3).height(3).borderRadius(50).backgroundColor(AppColors.DotGray)
          Row().width(3).height(3).borderRadius(50).backgroundColor(AppColors.DotGray)
        }
        .padding({ left: 16, right: 8 })
        .onClick(() => { this.pickAlbumArt() })
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 12, bottom: 8 })

      if (this.isLandscape) {
        // 横屏布局：封面居左 + 控制区居右
        Row() {
          // 左侧封面
          Column() {
            if (this.showLyrics) {
              LyricsView({
                lyrics: this.viewModel.lyrics,
                currentIndex: this.viewModel.currentLyricIndex
              })
              .height(200)
            } else {
              AlbumArt({
                albumArtUri: this.viewModel.currentSong?.albumArtUri ?? '',
                artSize: 220
              })
              .onClick(() => {
                animateTo({ duration: 300 }, () => {
                  this.showLyrics = true
                })
              })
              .gesture(
                LongPressGesture().onAction(() => {
                  this.pickAlbumArt()
                })
              )
            }
            Text(this.showLyrics ? '显示封面' : '显示歌词')
              .fontSize(12)
              .fontColor(AppColors.TextSecondary)
              .margin({ top: 4 })
              .onClick(() => {
                animateTo({ duration: 300 }, () => {
                  this.showLyrics = !this.showLyrics
                })
              })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          // 右侧控制区
          Scroll() {
            Column() {
              // 歌曲信息
              Column() {
                Text(this.viewModel.currentSong?.title ?? '未在播放')
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AppColors.TextPrimary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .textAlign(TextAlign.Center)

                Text(this.viewModel.currentSong?.artist ?? '')
                  .fontSize(14)
                  .fontColor(AppColors.TextSecondary)
                  .maxLines(1)
                  .margin({ top: 4 })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)

              // 进度条
              Column() {
                Stack({ alignContent: Alignment.Start }) {
                  Row().width('100%').height(4).borderRadius(2).backgroundColor(AppColors.BgBorder)
                  Row().width(`${this.getProgressPercent()}%`).height(4).borderRadius(2).backgroundColor(AppColors.Accent)
                  Row().width(12).height(12).borderRadius(6).backgroundColor(AppColors.Accent)
                    .offset({ x: `${this.getProgressPercent()}%` }).translate({ x: -6 })
                }
                .width('100%').height(24).alignContent(Alignment.Center)
                .gesture(
                  PanGesture({ direction: PanDirection.Horizontal })
                    .onActionUpdate((event: GestureEvent) => {
                      this.isSeeking = true
                      const progress = Math.max(0, Math.min(1, event.offsetX / 200))
                      this.seekPosition = progress * Math.max(this.viewModel.duration, 1)
                    })
                    .onActionEnd(() => {
                      this.viewModel.seekTo(this.seekPosition)
                      this.isSeeking = false
                    })
                )
                Row() {
                  Text(this.viewModel.formatTime(this.viewModel.currentTime)).fontSize(12).fontColor('#8899AA')
                  Blank()
                  Text(this.viewModel.formatTime(this.viewModel.duration)).fontSize(12).fontColor('#8899AA')
                }.width('100%')
              }
              .width('100%').padding({ left: 12, right: 12 }).margin({ top: 12 })

              // 药丸控制面板
              Row() {
                SymbolGlyph($r('sys.symbol.shuffle')).fontSize(18).fontColor(['#8899AA']).onClick(() => { this.viewModel.toggleShuffle() })
                SymbolGlyph($r('sys.symbol.backward_end_fill')).fontSize(22).fontColor(['#E0E8F0']).onClick(() => { this.viewModel.playPrevious() })
                Stack() {
                  SymbolGlyph(this.viewModel.isPlaying ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'))
                    .fontSize(24)
                    .fontColor([AppColors.BgDark])
                }
                .width(48).height(48).borderRadius(24)
                .backgroundColor('#4FC3F7')
                .alignContent(Alignment.Center)
                .onClick(() => { this.viewModel.togglePlayPause() })
                SymbolGlyph($r('sys.symbol.forward_end_fill')).fontSize(22).fontColor(['#E0E8F0']).onClick(() => { this.viewModel.playNext() })
                SymbolGlyph(this.viewModel.repeatMode === RepeatMode.ONE ? $r('sys.symbol.repeat_1') : $r('sys.symbol.repeat'))
                  .fontSize(18).fontColor(['#8899AA']).onClick(() => { this.viewModel.cycleRepeatMode() })
              }
              .width('100%').height(64).justifyContent(FlexAlign.SpaceEvenly)
              .alignItems(VerticalAlign.Center).borderRadius(16).backgroundColor(AppColors.BgPill)
              .margin({ top: 8, left: 12, right: 12 })

              // 额外操作行
              Row() {
                SymbolGlyph($r('sys.symbol.mic')).fontSize(20).onClick(() => {
                  animateTo({ duration: 300 }, () => { this.showLyrics = !this.showLyrics })
                })
                Blank()
                SymbolGlyph($r('sys.symbol.music_fill')).fontSize(20)
              }
              .width('100%').padding({ left: 24, right: 24, top: 8 })

              Text('↑↓ 滑动切换歌曲').fontSize(11).fontColor('#8899AA').opacity(0.5)
                .margin({ top: 4 }).textAlign(TextAlign.Center).width('100%')
            }
            .width('100%').alignItems(HorizontalAlign.Center)
          }
          .layoutWeight(1)
        }
        .width('100%').layoutWeight(1)
      } else {
        // 竖屏布局（保持原有结构）
        Scroll() {
          Column() {
            // 封面 / 歌词切换
            if (this.showLyrics) {
              LyricsView({
                lyrics: this.viewModel.lyrics,
                currentIndex: this.viewModel.currentLyricIndex
              })
              .height(300)
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
              .gesture(
                LongPressGesture().onAction(() => {
                  this.pickAlbumArt()
                })
              )
            }

            // 切换歌词/封面按钮
            Text(this.showLyrics ? '显示封面' : '显示歌词')
              .fontSize(12)
              .fontColor(AppColors.TextSecondary)
              .margin({ top: 4 })
              .onClick(() => {
                animateTo({ duration: 300 }, () => {
                  this.showLyrics = !this.showLyrics
                })
              })

            // 歌曲信息：28sp 标题 + 16sp 艺术家
            Column() {
              Text(this.viewModel.currentSong?.title ?? '未在播放')
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TextPrimary)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .textAlign(TextAlign.Center)

              Text(this.viewModel.currentSong?.artist ?? '')
                .fontSize(16)
                .fontColor(AppColors.TextSecondary)
                .maxLines(1)
                .margin({ top: 4 })
            }
            .width('100%')
            .padding({ left: 32, right: 32 })
            .margin({ top: 12 })
            .alignItems(HorizontalAlign.Center)

            // 4px 自定义进度条
            Column() {
              Stack({ alignContent: Alignment.Start }) {
                // 轨道背景
                Row()
                  .width('100%')
                  .height(4)
                  .borderRadius(2)
                  .backgroundColor(AppColors.BgBorder)

                // 进度填充
                Row()
                  .width(`${this.getProgressPercent()}%`)
                  .height(4)
                  .borderRadius(2)
                  .backgroundColor(AppColors.Accent)

                // 拖拽圆点
                Row()
                  .width(12)
                  .height(12)
                  .borderRadius(6)
                  .backgroundColor(AppColors.Accent)
                  .offset({ x: `${this.getProgressPercent()}%` })
                  .translate({ x: -6 })
              }
              .width('100%')
              .height(24)
              .alignContent(Alignment.Center)
              .onAreaChange((_oldValue: Area, newValue: Area) => {
                const w = newValue.width as number
                if (w > 0) this.progressWidth = w
              })
              .gesture(
                PanGesture({ direction: PanDirection.Horizontal })
                  .onActionUpdate((event: GestureEvent) => {
                    this.isSeeking = true
                    const progress = Math.max(0, Math.min(1, event.offsetX / this.progressWidth))
                    this.seekPosition = progress * Math.max(this.viewModel.duration, 1)
                  })
                  .onActionEnd(() => {
                    this.viewModel.seekTo(this.seekPosition)
                    this.isSeeking = false
                  })
              )

              // 时间标签
              Row() {
                Text(this.viewModel.formatTime(this.viewModel.currentTime))
                  .fontSize(12)
                  .fontColor(AppColors.TextSecondary)

                Blank()

                Text(this.viewModel.formatTime(this.viewModel.duration))
                  .fontSize(12)
                  .fontColor(AppColors.TextSecondary)
              }
              .width('100%')
            }
            .width('100%')
            .padding({ left: 24, right: 24 })
            .margin({ top: 16 })

            // 药丸控制面板
            Row() {
              // 随机播放（始终灰色）
              SymbolGlyph($r('sys.symbol.shuffle'))
                .fontSize(20)
                .fontColor([AppColors.TextSecondary])
                .onClick(() => { this.viewModel.toggleShuffle() })

              // 上一曲
              SymbolGlyph($r('sys.symbol.backward_end_fill'))
                .fontSize(26)
                .fontColor([AppColors.TextPrimary])
                .onClick(() => { this.viewModel.playPrevious() })

              // 播放/暂停 — 56x56 青色圆形
              Stack() {
                SymbolGlyph(this.viewModel.isPlaying ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'))
                  .fontSize(28)
                  .fontColor([AppColors.BgDark])
              }
              .width(56)
              .height(56)
              .borderRadius(28)
              .backgroundColor(AppColors.Accent)
              .alignContent(Alignment.Center)
              .onClick(() => { this.viewModel.togglePlayPause() })

              // 下一曲
              SymbolGlyph($r('sys.symbol.forward_end_fill'))
                .fontSize(26)
                .fontColor([AppColors.TextPrimary])
                .onClick(() => { this.viewModel.playNext() })

              // 循环模式（始终灰色）
              SymbolGlyph(this.viewModel.repeatMode === RepeatMode.ONE ? $r('sys.symbol.repeat_1') : $r('sys.symbol.repeat'))
                .fontSize(20)
                .fontColor([AppColors.TextSecondary])
                .onClick(() => { this.viewModel.cycleRepeatMode() })
            }
            .width('100%')
            .height(80)
            .justifyContent(FlexAlign.SpaceEvenly)
            .alignItems(VerticalAlign.Center)
            .borderRadius(16)
            .backgroundColor(AppColors.BgPill)
            .margin({ top: 12, left: 24, right: 24 })

            // 额外操作行
            Row() {
              // 歌词按钮
              SymbolGlyph($r('sys.symbol.mic'))
                .fontSize(22)
                .onClick(() => {
                  animateTo({ duration: 300 }, () => {
                    this.showLyrics = !this.showLyrics
                  })
                })

              Blank()

              // 播放列表按钮
              SymbolGlyph($r('sys.symbol.music_fill'))
                .fontSize(22)
            }
            .width('100%')
            .padding({ left: 32, right: 32, top: 12 })

            // 滑动提示
            Text('↑↓ 滑动切换歌曲')
              .fontSize(11)
              .fontColor(AppColors.TextSecondary)
              .opacity(0.5)
              .margin({ top: 8 })
              .textAlign(TextAlign.Center)
              .width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .offset({ y: this.dragOffsetY })
        }
        .layoutWeight(1)
        .gesture(
          PanGesture({ direction: PanDirection.Vertical })
            .onActionUpdate((event: GestureEvent) => {
              this.dragOffsetY = event.offsetY
            })
            .onActionEnd((event: GestureEvent) => {
              const threshold = 100
              const slideDistance = 500
              if (event.offsetY < -threshold) {
                animateTo({ duration: 180, curve: Curve.EaseIn }, () => {
                  this.dragOffsetY = -slideDistance
                })
                setTimeout(() => {
                  this.viewModel.playNext()
                  this.dragOffsetY = slideDistance
                  animateTo({ duration: 220, curve: Curve.FastOutSlowIn }, () => {
                    this.dragOffsetY = 0
                  })
                }, 180)
              } else if (event.offsetY > threshold) {
                animateTo({ duration: 180, curve: Curve.EaseIn }, () => {
                  this.dragOffsetY = slideDistance
                })
                setTimeout(() => {
                  this.viewModel.playPrevious()
                  this.dragOffsetY = -slideDistance
                  animateTo({ duration: 220, curve: Curve.FastOutSlowIn }, () => {
                    this.dragOffsetY = 0
                  })
                }, 180)
              } else {
                animateTo({ duration: 350, curve: Curve.FastOutSlowIn }, () => {
                  this.dragOffsetY = 0
                })
              }
            })
        )
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BgDark)
  }

  private getProgressPercent(): number {
    const time = this.isSeeking ? this.seekPosition : this.viewModel.currentTime
    const dur = Math.max(this.viewModel.duration, 1)
    return (time / dur) * 100
  }

  private async requestPhotoPermission(): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager()
      const context = getContext(this)
      const permission: Permissions = 'ohos.permission.READ_IMAGEVIDEO'
      const grantStatus = await atManager.checkAccessToken(context.applicationInfo.accessTokenId, permission)
      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        return true
      }
      const result = await atManager.requestPermissionsFromUser(context, [permission])
      return result.authResults[0] === 0
    } catch (e) {
      console.error('权限请求失败: ' + JSON.stringify(e))
      return false
    }
  }

  private async pickAlbumArt() {
    const hasPermission = await this.requestPhotoPermission()
    if (!hasPermission) {
      console.error('未获得照片访问权限')
      return
    }
    try {
      const photoPicker = new picker.PhotoViewPicker()
      const result = await photoPicker.select({
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      })
      if (result.photoUris && result.photoUris.length > 0) {
        const selectedUri = result.photoUris[0]
        const destDir = getContext(this).filesDir + '/albumArt'
        if (!fileIo.accessSync(destDir)) {
          fileIo.mkdirSync(destDir, true)
        }
        const songId = this.viewModel.currentSong?.id ?? 0
        const destPath = destDir + '/art_' + songId + '_' + Date.now() + '.jpg'
        const srcFile = fileIo.openSync(selectedUri, fileIo.OpenMode.READ_ONLY)
        const destFile = fileIo.openSync(destPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
        const buffer = new ArrayBuffer(1024 * 64)
        let readLen: number = 0
        while ((readLen = fileIo.readSync(srcFile.fd, buffer)) > 0) {
          fileIo.writeSync(destFile.fd, buffer.slice(0, readLen))
        }
        fileIo.closeSync(srcFile)
        fileIo.closeSync(destFile)
        this.viewModel.updateAlbumArt(destPath)
      }
    } catch (e) {
      console.error('选择封面失败: ' + JSON.stringify(e))
    }
  }
}
