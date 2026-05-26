import Foundation

extension DateFormatter {
  static let koreanShort = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "ko_KR")
    f.dateFormat = "yyyy.MM.dd (EEE) a hh:mm"
    return f
  }()

  static let shortDate = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f
  }()

  static let iso8601 = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
  }()
}
