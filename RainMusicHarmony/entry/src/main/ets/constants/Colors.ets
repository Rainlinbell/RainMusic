/**
 * RainMusic 统一颜色常量
 * 对齐设计稿 UI/music-player/index.html 海军蓝深色主题
 */
export class AppColors {
  // 背景色
  static readonly BgDark: string = '#0A1628'     // 主背景
  static readonly BgPill: string = '#111B40'     // 药丸/卡片背景
  static readonly BgBorder: string = '#1E3A5F'   // 边框/轨道
  static readonly CoverNavy1: string = '#2B4D76' // 封面占位渐变浅
  static readonly CoverNavy2: string = '#1E3A5F' // 封面占置渐变深

  // 强调色
  static readonly Accent: string = '#4FC3F7'      // 主强调色
  static readonly AccentDark: string = '#0288D1'  // 深强调色

  // 文字色
  static readonly TextPrimary: string = '#E0E8F0'   // 主文字
  static readonly TextSecondary: string = '#8899AA'  // 次要文字

  // 辅助色
  static readonly DotGray: string = '#B3B3B3'     // 三点菜单

  // 选中态
  static readonly TabSelectedBg: string = '#4FC3F7'     // Tab 选中背景 (accent)
  static readonly TabSelectedText: string = '#0A1628'    // Tab 选中文字 (bg-dark)
  static readonly TabUnselectedText: string = '#8899AA' // Tab 未选中文字
}
