import OSLog
import SwiftUI
import WidgetKit

// Home screen and lock screen widgets (design/round-11/home-widgets.html).
// The app writes what they show as frames (lib/ui/home_widgets); these
// views only pick the current frame and count the minutes left in a class.

private let appGroup = "group.io.github.koukeneko.tatCcu"
private let log = Logger(subsystem: "io.github.koukeneko.tatCcu.TatWidgets", category: "data")

// MARK: - Data

struct WidgetData: Decodable {
  let signedIn: Bool
  let labels: Labels
  let frames: [Frame]

  static func load() -> WidgetData? {
    guard let json = UserDefaults(suiteName: appGroup)?.string(forKey: "widget_data") else {
      return nil  // The app has not written anything yet.
    }
    do {
      return try JSONDecoder().decode(WidgetData.self, from: Data(json.utf8))
    } catch {
      log.error("widget data: \(error)")
      return nil
    }
  }
}

struct Labels: Decodable {
  let nextClass, toDo, dueThisWeek, countdown, countdownEnded, upcoming: String
  let nothingDue, signedOut, classes, items, minutes: String
}

struct Frame: Decodable {
  let at: Double
  let cls: ClassInfo
  let day: Day
  let due: Due
  let countdown: Countdown?

  enum CodingKeys: String, CodingKey { case at, cls = "class", day, due, countdown }
}

struct ClassInfo: Decodable {
  let label: String
  let name, room, time, color, until, sub: String?
  let start, end: Double?

  var inClass: Bool { end != nil }
  var interval: ClosedRange<Date>? {
    guard let start, let end else { return nil }
    return Date(timeIntervalSince1970: start / 1000)...Date(timeIntervalSince1970: end / 1000)
  }
}

struct Slot: Decodable {
  let name: String
  let room, time, color: String?
  let now: Bool?
}

struct Day: Decodable {
  let date, headline: String
  let count: Int
  let rows: [Slot]
}

struct DueRow: Decodable { let name, course, when: String }

struct Due: Decodable {
  let count: Int
  let rows: [DueRow]
}

struct Countdown: Decodable {
  let title, value, date: String
  let unit, week: String?
  let progress: Double?
}

// MARK: - Timeline

struct Entry: TimelineEntry {
  let date: Date
  let data: WidgetData?
  let frame: Frame?
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> Entry { Entry(date: .now, data: nil, frame: nil) }

  func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
    completion(entries(from: .now).first ?? placeholder(in: context))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    completion(Timeline(entries: entries(from: .now), policy: .atEnd))
  }

  /// A day of entries: one per frame, and one a minute during a class for
  /// the minutes left. The timeline reloads after the last one.
  private func entries(from now: Date) -> [Entry] {
    guard let data = WidgetData.load() else { return [Entry(date: now, data: nil, frame: nil)] }
    let horizon = now.addingTimeInterval(24 * 3600)
    let frames = data.frames
    let current = frames.lastIndex { $0.at / 1000 <= now.timeIntervalSince1970 } ?? 0
    var out: [Entry] = []
    for i in current..<frames.count {
      let frame = frames[i]
      let start = max(now, Date(timeIntervalSince1970: frame.at / 1000))
      if start > horizon { break }
      out.append(Entry(date: start, data: data, frame: frame))
      if let end = frame.cls.interval?.upperBound {
        var t = Calendar.current.nextDate(
          after: start, matching: DateComponents(second: 0), matchingPolicy: .nextTime) ?? end
        while t < end {
          out.append(Entry(date: t, data: data, frame: frame))
          t.addTimeInterval(60)
        }
      }
    }
    return out.isEmpty ? [Entry(date: now, data: data, frame: frames.last)] : out
  }
}

// MARK: - Look

/// The dark tones of lib/ui/core/theme.dart (Tones.of(Brightness.dark)).
struct Tone {
  let fill, ink: Color

  static let lilac = Tone(fill: Color(hex: "#4A3780"), ink: Color(hex: "#EADDFF"))
  static let mint = Tone(fill: Color(hex: "#1D4A30"), ink: Color(hex: "#C4EED0"))
  static let peach = Tone(fill: Color(hex: "#6A3720"), ink: Color(hex: "#FFDBCB"))
  static let sun = Tone(fill: Color(hex: "#574400"), ink: Color(hex: "#FFE08A"))
  static let card = Tone(fill: Color(hex: "#251D1A"), ink: Color(hex: "#F1E3DD"))
}

private let mute = Color(hex: "#B09A94")

extension Color {
  init(hex: String) {
    let v = UInt64(hex.dropFirst(), radix: 16) ?? 0
    self.init(
      red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255,
      blue: Double(v & 0xFF) / 255)
  }
}

private func rounded(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
  .system(size: size, weight: weight, design: .rounded)
}

/// Label row at the top of a block: an icon and a short state.
struct Header: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 5) {
      Image(systemName: icon).font(.system(size: 12, weight: .bold))
      Text(text).font(rounded(13)).lineLimit(1)
    }
    .opacity(0.85)
  }
}

struct Big: View {
  let value: String
  let unit: String?
  var size: CGFloat = 40

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 3) {
      Text(value).font(rounded(size, .black)).minimumScaleFactor(0.6)
      if let unit { Text(unit).font(rounded(15)).opacity(0.8) }
    }
    .lineLimit(1)
  }
}

struct Sub: View {
  let text: String?

  var body: some View {
    if let text { Text(text).font(rounded(12, .bold)).opacity(0.8).lineLimit(1) }
  }
}

struct Bar: View {
  let progress: Double

  var body: some View {
    GeometryReader { g in
      ZStack(alignment: .leading) {
        Capsule().fill(.black.opacity(0.25))
        Capsule().frame(width: g.size.width * min(max(progress, 0), 1))
      }
    }
    .frame(height: 6)
  }
}

/// A class's time, color strip, name and room.
struct SlotRow: View {
  let slot: Slot

  var body: some View {
    HStack(spacing: 9) {
      Text(slot.time ?? "").font(rounded(13)).frame(width: 42, alignment: .leading)
        .foregroundStyle(slot.now == true ? Color(hex: "#D0BCFF") : Tone.card.ink)
      RoundedRectangle(cornerRadius: 2).fill(Color(hex: slot.color ?? "#B09A94")).frame(width: 4)
      VStack(alignment: .leading, spacing: 1) {
        Text(slot.name).font(rounded(13)).lineLimit(1)
        Sub(text: slot.room)
      }
      Spacer(minLength: 0)
    }
    .fixedSize(horizontal: false, vertical: true)
  }
}

struct DueRowView: View {
  let row: DueRow

  var body: some View {
    HStack(spacing: 8) {
      VStack(alignment: .leading, spacing: 1) {
        Text(row.name).font(rounded(13)).lineLimit(1)
        Sub(text: row.course)
      }
      Spacer(minLength: 4)
      Text(row.when).font(rounded(11)).lineLimit(1)
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(.black.opacity(0.22), in: Capsule())
    }
  }
}

/// Full-block message for a missing state: signed out, nothing due.
struct Notice: View {
  let icon: String
  let title: String
  let text: String

  var body: some View {
    VStack(alignment: .leading) {
      Header(icon: icon, text: title).foregroundStyle(mute)
      Spacer(minLength: 0)
      Text(text).font(rounded(15)).foregroundStyle(Tone.card.ink)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}

private func minutesLeft(_ cls: ClassInfo, at date: Date) -> Int {
  guard let end = cls.interval?.upperBound else { return 0 }
  return max(0, Int((end.timeIntervalSince(date) / 60).rounded(.up)))
}

private func tone(for cls: ClassInfo) -> Tone {
  cls.inClass ? .lilac : cls.name == nil ? .card : .mint
}

// MARK: - 下一堂

struct NextClassView: View {
  @Environment(\.widgetFamily) var family
  let entry: Entry

  var body: some View {
    if let data = entry.data, let frame = entry.frame {
      if !data.signedIn {
        Notice(icon: "graduationcap", title: data.labels.nextClass, text: data.labels.signedOut)
          .containerBackground(Tone.card.fill, for: .widget)
      } else if family == .accessoryRectangular {
        rectangular(frame.cls)
      } else {
        small(frame.cls).foregroundStyle(tone(for: frame.cls).ink)
          .containerBackground(tone(for: frame.cls).fill, for: .widget)
      }
    } else {
      Color.clear.containerBackground(Tone.card.fill, for: .widget)
    }
  }

  @ViewBuilder func small(_ cls: ClassInfo) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Header(icon: "graduationcap", text: cls.label)
      if cls.inClass {
        Spacer(minLength: 0)
        Text(cls.name ?? "").font(rounded(16)).lineLimit(2)
        Sub(text: cls.room)
        Sub(text: cls.until).padding(.top, 8)
        if let interval = cls.interval {
          ProgressView(timerInterval: interval, countsDown: false) { EmptyView() } currentValueLabel: {
            EmptyView()
          }
          .tint(Tone.lilac.ink).padding(.top, 4)
        }
      } else if let name = cls.name {
        Sub(text: cls.sub).padding(.top, 8)
        Big(value: cls.time ?? "", unit: nil, size: 36).padding(.top, 2)
        Spacer(minLength: 0)
        Text(name).font(rounded(16)).lineLimit(2)
        Sub(text: cls.room)
      } else {
        Spacer(minLength: 0)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  @ViewBuilder func rectangular(_ cls: ClassInfo) -> some View {
    VStack(alignment: .leading, spacing: 1) {
      HStack(spacing: 4) {
        Image(systemName: "graduationcap").font(.system(size: 11, weight: .bold))
        Text([cls.label, cls.inClass ? cls.until : cls.time].compactMap { $0 }.joined(separator: "・"))
          .font(rounded(12, .bold))
      }
      .opacity(0.8)
      Text(cls.name ?? cls.label).font(rounded(15)).lineLimit(1)
      if let room = cls.room { Text(room).font(rounded(12, .bold)).opacity(0.8).lineLimit(1) }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .containerBackground(.clear, for: .widget)
  }
}

// MARK: - 今日課表

struct TodayView: View {
  @Environment(\.widgetFamily) var family
  let entry: Entry

  var body: some View {
    if let data = entry.data, let frame = entry.frame {
      if !data.signedIn {
        Notice(icon: "calendar", title: frame.day.date, text: data.labels.signedOut)
          .containerBackground(Tone.card.fill, for: .widget)
      } else {
        switch family {
        case .accessoryCircular: circular(frame, data.labels)
        case .systemLarge: large(frame, data.labels)
        default: medium(frame, data.labels)
        }
      }
    } else {
      Color.clear.containerBackground(Tone.card.fill, for: .widget)
    }
  }

  func medium(_ frame: Frame, _ labels: Labels) -> some View {
    HStack(spacing: 14) {
      VStack(alignment: .leading, spacing: 0) {
        Header(icon: "calendar", text: frame.day.date)
        Spacer(minLength: 0)
        Big(value: "\(frame.day.count)", unit: labels.classes, size: 34)
        Text(frame.day.headline).font(rounded(12, .bold)).opacity(0.8).lineLimit(2)
      }
      .padding(12)
      .frame(width: 124, alignment: .leading)
      .frame(maxHeight: .infinity)
      .foregroundStyle(Tone.lilac.ink)
      .background(Tone.lilac.fill, in: RoundedRectangle(cornerRadius: 16))
      VStack(alignment: .leading, spacing: 7) {
        if frame.day.rows.isEmpty {
          nextDay(frame.cls)
        } else {
          ForEach(Array(frame.day.rows.prefix(3).enumerated()), id: \.offset) { SlotRow(slot: $0.element) }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .foregroundStyle(Tone.card.ink)
    .containerBackground(Tone.card.fill, for: .widget)
  }

  /// After the day's classes: the next school day's first one.
  @ViewBuilder func nextDay(_ cls: ClassInfo) -> some View {
    if let name = cls.name {
      Sub(text: cls.sub).foregroundStyle(mute)
      Text(cls.time ?? "").font(rounded(28, .black))
      Text(name).font(rounded(15)).lineLimit(1)
      Sub(text: cls.room).foregroundStyle(mute)
    }
  }

  func large(_ frame: Frame, _ labels: Labels) -> some View {
    let cls = frame.cls
    let later = frame.day.rows.filter { $0.now != true && $0.time != cls.time }
    // On the card background the hero block needs a lighter surface.
    let hero = cls.name == nil ? Tone(fill: Color(hex: "#2F2522"), ink: Tone.card.ink) : tone(for: cls)
    return VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .bottom, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text([cls.label, cls.inClass ? cls.until : cls.sub].compactMap { $0 }.joined(separator: "・"))
            .font(rounded(13)).opacity(0.85).lineLimit(1)
          Text(cls.name ?? frame.day.headline).font(rounded(20)).lineLimit(1)
          Sub(text: cls.room)
        }
        Spacer(minLength: 0)
        if cls.inClass {
          Big(value: "\(minutesLeft(cls, at: entry.date))", unit: labels.minutes, size: 30)
        } else if let time = cls.time {
          Big(value: time, unit: nil, size: 30)
        }
      }
      .padding(12)
      .foregroundStyle(hero.ink)
      .background(hero.fill, in: RoundedRectangle(cornerRadius: 16))
      if !later.isEmpty {
        section(labels.upcoming)
        VStack(alignment: .leading, spacing: 7) {
          ForEach(Array(later.prefix(3).enumerated()), id: \.offset) { SlotRow(slot: $0.element) }
        }
      }
      section(labels.dueThisWeek)
      if frame.due.rows.isEmpty {
        Text(labels.nothingDue).font(rounded(13)).foregroundStyle(mute)
      } else {
        VStack(alignment: .leading, spacing: 7) {
          ForEach(Array(frame.due.rows.prefix(later.isEmpty ? 3 : 2).enumerated()), id: \.offset) {
            DueRowView(row: $0.element)
          }
        }
      }
      Spacer(minLength: 0)
    }
    .foregroundStyle(Tone.card.ink)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .containerBackground(Tone.card.fill, for: .widget)
  }

  func section(_ text: String) -> some View {
    Text(text).font(rounded(12)).foregroundStyle(mute).padding(.top, 12).padding(.bottom, 7)
  }

  func circular(_ frame: Frame, _ labels: Labels) -> some View {
    ZStack {
      AccessoryWidgetBackground()
      VStack(spacing: 0) {
        Text("\(frame.day.count)").font(rounded(24, .black))
        Text(labels.classes).font(rounded(10)).opacity(0.85)
      }
    }
    .containerBackground(.clear, for: .widget)
  }
}

// MARK: - 待辦

struct DueView: View {
  @Environment(\.widgetFamily) var family
  let entry: Entry

  var body: some View {
    if let data = entry.data, let frame = entry.frame {
      let labels = data.labels
      if family == .accessoryCircular {
        ZStack {
          AccessoryWidgetBackground()
          VStack(spacing: 0) {
            Text(data.signedIn ? "\(frame.due.count)" : "–").font(rounded(24, .black))
            Text(labels.toDo).font(rounded(10)).opacity(0.85)
          }
        }
        .containerBackground(.clear, for: .widget)
      } else if !data.signedIn {
        Notice(icon: "checklist", title: labels.toDo, text: labels.signedOut)
          .containerBackground(Tone.card.fill, for: .widget)
      } else if frame.due.rows.isEmpty {
        Notice(icon: "checklist", title: labels.toDo, text: labels.nothingDue)
          .containerBackground(Tone.card.fill, for: .widget)
      } else if family == .systemMedium {
        medium(frame.due, labels)
      } else {
        small(frame.due, labels)
      }
    } else {
      Color.clear.containerBackground(Tone.card.fill, for: .widget)
    }
  }

  func small(_ due: Due, _ labels: Labels) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Header(icon: "checklist", text: labels.toDo)
      Big(value: "\(due.count)", unit: labels.items).padding(.top, 8)
      Spacer(minLength: 0)
      if let first = due.rows.first {
        Text(first.name).font(rounded(14)).lineLimit(2)
        Sub(text: first.when)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .foregroundStyle(Tone.peach.ink)
    .containerBackground(Tone.peach.fill, for: .widget)
  }

  func medium(_ due: Due, _ labels: Labels) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Header(icon: "checklist", text: labels.dueThisWeek)
        Spacer()
        Text("\(due.count) \(labels.items)").font(rounded(13)).opacity(0.8)
      }
      ForEach(Array(due.rows.prefix(3).enumerated()), id: \.offset) { DueRowView(row: $0.element) }
      Spacer(minLength: 0)
    }
    .foregroundStyle(Tone.peach.ink)
    .containerBackground(Tone.peach.fill, for: .widget)
  }
}

// MARK: - 學期倒數

struct CountdownView: View {
  let entry: Entry

  var body: some View {
    if let data = entry.data, let frame = entry.frame {
      if let c = frame.countdown {
        VStack(alignment: .leading, spacing: 0) {
          Header(icon: "flag", text: data.labels.countdown)
          Big(value: c.value, unit: c.unit).padding(.top, 8)
          Spacer(minLength: 0)
          Text(c.title).font(rounded(14)).lineLimit(1).minimumScaleFactor(0.8)
          Sub(text: c.date)
          if let progress = c.progress {
            Bar(progress: progress).padding(.top, 8)
            Sub(text: c.week).padding(.top, 4)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .foregroundStyle(Tone.sun.ink)
        .containerBackground(Tone.sun.fill, for: .widget)
      } else {
        Notice(icon: "flag", title: data.labels.countdown, text: data.labels.countdownEnded)
          .containerBackground(Tone.card.fill, for: .widget)
      }
    } else {
      Color.clear.containerBackground(Tone.card.fill, for: .widget)
    }
  }
}

// MARK: - Widgets

struct NextClassWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "NextClass", provider: Provider()) { NextClassView(entry: $0) }
      .configurationDisplayName("下一堂")
      .description("上課中與下一堂課。")
      .supportedFamilies([.systemSmall, .accessoryRectangular])
  }
}

struct TodayWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "TodayClasses", provider: Provider()) { TodayView(entry: $0) }
      .configurationDisplayName("今日課表")
      .description("今天剩下的課；大尺寸另列本週到期。")
      .supportedFamilies([.systemMedium, .systemLarge, .accessoryCircular])
  }
}

struct DueWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "DueSoon", provider: Provider()) { DueView(entry: $0) }
      .configurationDisplayName("待辦")
      .description("本週到期的作業與活動。")
      .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
  }
}

struct CountdownWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "Countdown", provider: Provider()) { CountdownView(entry: $0) }
      .configurationDisplayName("學期倒數")
      .description("行事曆上的下一件事。")
      .supportedFamilies([.systemSmall])
  }
}

@main
struct TatWidgets: WidgetBundle {
  var body: some Widget {
    NextClassWidget()
    TodayWidget()
    DueWidget()
    CountdownWidget()
  }
}
