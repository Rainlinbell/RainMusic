import Foundation

struct LyricLine: Identifiable {
    let id = UUID()
    let time: TimeInterval
    let text: String
}

struct LyricsParser {

    // MARK: - Parse LRC

    static func parse(lrcContent: String) -> [LyricLine] {
        var lines: [LyricLine] = []

        // 正则匹配时间标签 [mm:ss.xx] 或 [mm:ss.xxx]
        let pattern = "\\[(\\d{1,3}):(\\d{2})\\.(\\d{2,3})\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return lines
        }

        let contentLines = lrcContent.components(separatedBy: .newlines)

        for line in contentLines {
            let range = NSRange(line.startIndex..., in: line)
            let matches = regex.matches(in: line, range: range)

            if matches.isEmpty {
                continue
            }

            // 提取歌词文本（去掉所有时间标签后的部分）
            var text = line
            var times: [TimeInterval] = []

            for match in matches {
                guard let minRange = Range(match.range(at: 1), in: line),
                      let secRange = Range(match.range(at: 2), in: line),
                      let msRange = Range(match.range(at: 3), in: line) else {
                    continue
                }

                let minutes = Double(line[minRange]) ?? 0
                let seconds = Double(line[secRange]) ?? 0
                let msString = line[msRange]
                let msDigits = msString.count

                let milliseconds: Double
                if msDigits == 2 {
                    milliseconds = (Double(msString) ?? 0) / 100.0
                } else {
                    milliseconds = (Double(msString) ?? 0) / 1000.0
                }

                let time = minutes * 60.0 + seconds + milliseconds
                times.append(time)

                // 移除时间标签
                let fullRange = Range(match.range, in: line)
                if let fullRange = fullRange {
                    text = text.replacingOccurrences(of: line[fullRange], with: "")
                }
            }

            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

            // 跳过元数据标签
            if trimmedText.hasPrefix("[") && trimmedText.contains(":") {
                continue
            }

            // 一行可能有多个时间标签（重复歌词）
            for time in times {
                lines.append(LyricLine(time: time, text: trimmedText))
            }
        }

        // 按时间排序
        lines.sort { $0.time < $1.time }

        return lines
    }

    // MARK: - Find Current Line

    static func currentLineIndex(in lyrics: [LyricLine], at time: TimeInterval) -> Int {
        guard !lyrics.isEmpty else { return -1 }

        // 二分查找
        var left = 0
        var right = lyrics.count - 1
        var result = -1

        while left <= right {
            let mid = (left + right) / 2
            if lyrics[mid].time <= time {
                result = mid
                left = mid + 1
            } else {
                right = mid - 1
            }
        }

        return result
    }

    // MARK: - Load Lyrics File

    static func loadLyrics(for song: Song) -> [LyricLine]? {
        // 优先使用关联的歌词文件
        if let lyricsURL = song.lyricsFileURL {
            if let content = readFileContent(at: lyricsURL) {
                let lines = parse(lrcContent: content)
                return lines.isEmpty ? nil : lines
            }
        }

        // 尝试在歌曲同目录下查找同名 .lrc 文件
        let songURL = song.fileURL
        let lrcURL = songURL.deletingPathExtension().appendingPathExtension("lrc")

        if FileManager.default.fileExists(atPath: lrcURL.path) {
            if let content = readFileContent(at: lrcURL) {
                let lines = parse(lrcContent: content)
                return lines.isEmpty ? nil : lines
            }
        }

        return nil
    }

    // MARK: - Read File with Encoding Detection

    private static func readFileContent(at url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        // 先尝试 UTF-8
        if let content = String(data: data, encoding: .utf8) {
            return content
        }

        // 尝试 GBK / GB18030
        if let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
        )),
           let content = String(data: data, encoding: encoding) {
            return content
        }

        // 尝试 ASCII
        if let content = String(data: data, encoding: .ascii) {
            return content
        }

        return nil
    }
}
