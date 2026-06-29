/**
 * RainMusic 统一布局常量
 * 对齐设计稿 UI/music-player/index.html 尺寸规格
 */
export class AppLayout {
  // 页面内边距
  static readonly PagePaddingH: number = 24   // 水平内边距
  static readonly PagePaddingV: number = 16   // 垂直内边距

  // 播放器
  static readonly CoverSize: number = 280      // 封面尺寸 (vp)
  static readonly CoverRadius: number = 20     // 封面圆角
  static readonly TitleSize: number = 28       // 标题字号
  static readonly ArtistSize: number = 16      // 艺术家字号
  static readonly ProgressHeight: number = 4   // 进度条高度
  static readonly ProgressDot: number = 12     // 进度条拖拽圆点
  static readonly ControlPanelHeight: number = 80  // 控制面板高度
  static readonly ControlPanelRadius: number = 16  // 控制面板圆角
  static readonly PlayButtonSize: number = 56  // 播放按钮尺寸

  // 歌曲行
  static readonly SongRowHeight: number = 64   // 歌曲行高度
  static readonly SongCoverSize: number = 48   // 歌曲封面尺寸
  static readonly SongCoverRadius: number = 6  // 歌曲封面圆角
  static readonly SongTitleSize: number = 15   // 歌曲标题字号
  static readonly SongArtistSize: number = 12  // 歌曲艺术家字号
  static readonly SongDurationSize: number = 13 // 歌曲时长字号

  // Tab 栏
  static readonly TabBarHeight: number = 52    // Tab 栏高度
  static readonly TabBarRadius: number = 36    // Tab 栏圆角

  // 底部安全区
  static readonly BottomPadding: number = 110  // 底部预留空间（Tab栏+迷你播放）
}
