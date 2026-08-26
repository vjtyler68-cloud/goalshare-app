import WidgetKit
import SwiftUI

// The App Group shared between the main app (Runner) and this widget extension.
// Both targets MUST have this exact App Group enabled (see SETUP.md). The Flutter
// side writes the values via the `home_widget` package; we read them here.
private let kAppGroup = "group.com.goal.share"

// Brand colors (GoalShare red).
private let kRed = Color(red: 0.90, green: 0.16, blue: 0.16)
private let kRedDark = Color(red: 0.66, green: 0.09, blue: 0.09)

struct GoalShareEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let todayXp: Int
    let level: Int
    let levelTitle: String
    let ritualDone: Bool
    let streakAlive: Bool
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> GoalShareEntry {
        GoalShareEntry(date: Date(), streak: 12, todayXp: 80, level: 3,
                       levelTitle: "Grinder", ritualDone: true, streakAlive: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (GoalShareEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GoalShareEntry>) -> Void) {
        // The app pushes fresh values whenever XP/streak/ritual change; this
        // periodic refresh is a safety net so the tile never goes stale.
        let next = Calendar.current.date(byAdding: .hour, value: 2, to: Date())
            ?? Date().addingTimeInterval(7200)
        completion(Timeline(entries: [readEntry()], policy: .after(next)))
    }

    private func readEntry() -> GoalShareEntry {
        let d = UserDefaults(suiteName: kAppGroup)
        return GoalShareEntry(
            date: Date(),
            streak: d?.integer(forKey: "streak") ?? 0,
            todayXp: d?.integer(forKey: "todayXp") ?? 0,
            level: d?.integer(forKey: "level") ?? 1,
            levelTitle: d?.string(forKey: "levelTitle") ?? "",
            ritualDone: d?.bool(forKey: "ritualDone") ?? false,
            streakAlive: d?.bool(forKey: "streakAlive") ?? false
        )
    }
}

// Applies the brand gradient as the widget background, using the iOS 17+
// containerBackground API when available and a plain background otherwise.
private struct BrandBackground: ViewModifier {
    func body(content: Content) -> some View {
        let gradient = LinearGradient(
            colors: [kRed, kRedDark],
            startPoint: .topLeading, endPoint: .bottomTrailing)
        if #available(iOSApplicationExtension 17.0, *) {
            return AnyView(content.containerBackground(gradient, for: .widget))
        } else {
            return AnyView(
                ZStack { gradient; content }
            )
        }
    }
}

private extension View {
    func brandBackground() -> some View { modifier(BrandBackground()) }
}

struct SmallView: View {
    let entry: GoalShareEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text("🔥").font(.system(size: 22))
                Text("\(entry.streak)")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
            Text(entry.streak == 1 ? "day streak" : "day streak")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
            Spacer(minLength: 2)
            HStack(spacing: 5) {
                Image(systemName: "bolt.fill").font(.system(size: 11))
                Text("+\(entry.todayXp) XP")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            HStack(spacing: 5) {
                Image(systemName: entry.ritualDone ? "checkmark.circle.fill" : "sun.max")
                    .font(.system(size: 11))
                Text(entry.ritualDone ? "Ritual done" : "Start ritual")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.95))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(14)
        .brandBackground()
    }
}

struct MediumView: View {
    let entry: GoalShareEntry
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("🔥").font(.system(size: 26))
                    Text("\(entry.streak)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
                Text(entry.streakAlive ? "day streak" : "streak at risk")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                Label("+\(entry.todayXp) XP today", systemImage: "bolt.fill")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Label("Level \(entry.level) · \(entry.levelTitle)", systemImage: "star.fill")
                    .font(.system(size: 13, weight: .semibold))
                Label(entry.ritualDone ? "Ritual complete" : "Start your ritual",
                      systemImage: entry.ritualDone ? "checkmark.circle.fill" : "sun.max")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
        .brandBackground()
    }
}

struct GoalShareWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            MediumView(entry: entry)
        default:
            SmallView(entry: entry)
        }
    }
}

@main
struct GoalShareWidget: Widget {
    let kind: String = "GoalShareWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            GoalShareWidgetEntryView(entry: entry)
                // Tapping the tile opens the app (deep link handled app-side).
                .widgetURL(URL(string: "goalshare://home"))
        }
        .configurationDisplayName("GoalShare Streak")
        .description("Your streak, today's XP, and whether you've done your ritual.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
