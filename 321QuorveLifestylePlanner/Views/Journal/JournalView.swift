import SwiftUI

struct JournalView: View {
    @ObservedObject var store: DataStore

    @State private var selectedEmoji = "🙂"
    @State private var noteText = ""
    @State private var selectedTags: Set<String> = []
    @State private var showAddHabit = false
    @State private var newHabitName = ""
    @State private var showSavedPulse = false
    @State private var showWeeklyReview = false
    @State private var habitForNote: Habit?
    @State private var habitNoteDraft = ""

    private let moodEmojis = ["😊", "😄", "🙂", "😐", "😔", "😢", "😌", "🥰", "😇", "🤔", "😴", "😤"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerBanner
                dailyQuoteCard
                moodSection
                habitsSection
                streakToolsSection
                historySection
                analyticsSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissKeyboardOnTap()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { KeyboardDismiss.resign() }
            }
        }
        .overlay {
            if showSavedPulse {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color("AppAccent"))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showAddHabit) { addHabitSheet }
        .sheet(isPresented: $showWeeklyReview) {
            WeeklyReviewView(store: store)
        }
        .sheet(item: $habitForNote) { habit in
            habitNoteSheet(habit)
        }
        .onAppear {
            store.ensureTodayHabits()
            if let today = store.todayMood {
                selectedEmoji = today.emoji
                noteText = today.note
                selectedTags = Set(today.tags)
            }
        }
    }

    private var headerBanner: some View {
        VStack(spacing: 14) {
            Image("BannerCalm")
                .resizable()
                .scaledToFill()
                .frame(height: 140)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color("AppAccent").opacity(0.35), lineWidth: 1)
                )
                .shadow(color: Color("AppPrimary").opacity(0.25), radius: 12, y: 6)

            VStack(spacing: 6) {
                Text("Mindfulness Journal")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundStyle(Color("AppTextPrimary"))
                Text("Track your mood & habits")
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 12)
    }

    private var dailyQuoteCard: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Today's Affirmation", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(DailyQuotes.quote())
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var moodSection: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Today's Mood", systemImage: "face.smiling")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                if store.todayMood == nil && noteText.isEmpty {
                    HStack {
                        Image("EmptyArt")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                        Text("Track your mood today!")
                            .font(.subheadline)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }

                EmojiPickerView(emojis: moodEmojis, selected: $selectedEmoji)

                Text("What shaped today?")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                    ForEach(MoodTag.allCases) { tag in
                        let selected = selectedTags.contains(tag.rawValue)
                        Button {
                            FeedbackHelper.tap()
                            if selected {
                                selectedTags.remove(tag.rawValue)
                            } else {
                                selectedTags.insert(tag.rawValue)
                            }
                        } label: {
                            Label(tag.rawValue, systemImage: tag.icon)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(selected ? Color.white : Color("AppTextPrimary"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule().fill(selected ? Color("AppPrimary") : Color("AppBackground").opacity(0.55))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                TextField("Add a note about your day...", text: $noteText, axis: .vertical)
                    .lineLimit(3...5)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color("AppBackground").opacity(0.5))
                    )
                    .accessibilityIdentifier("journal_note_field")

                Button {
                    KeyboardDismiss.resign()
                    store.addMood(
                        emoji: selectedEmoji,
                        note: noteText,
                        tags: Array(selectedTags).sorted()
                    )
                    withAnimation(.spring(response: 0.35)) {
                        showSavedPulse = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation { showSavedPulse = false }
                    }
                } label: {
                    Text(store.todayMood == nil ? "Save Mood" : "Update Mood")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color("AppPrimary"))
                        )
                }
                .accessibilityIdentifier("save_mood_button")
            }
        }
    }

    private var habitsSection: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Today's Habits", systemImage: "checkmark.circle")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Spacer()
                    Button {
                        FeedbackHelper.tap()
                        showAddHabit = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color("AppAccent"))
                    }
                    .accessibilityIdentifier("add_habit_button")
                }

                let todayHabits = store.todayHabits
                if todayHabits.isEmpty {
                    Text("No habits logged yet")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                } else {
                    ForEach(todayHabits) { habit in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(habit.name)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { habit.isCompleted },
                                    set: { newValue in
                                        if newValue && !habit.isCompleted {
                                            habitNoteDraft = habit.note
                                            habitForNote = habit
                                        } else {
                                            store.toggleHabit(habit)
                                        }
                                    }
                                ))
                                .labelsHidden()
                                .tint(Color("AppPrimary"))
                                .accessibilityIdentifier("habit_toggle_\(habit.name)")
                            }

                            if !habit.note.isEmpty {
                                Text(habit.note)
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                        .contextMenu {
                            Button {
                                habitNoteDraft = habit.note
                                habitForNote = habit
                            } label: {
                                Label("Edit Note", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                store.deleteHabit(habit)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    private var streakToolsSection: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Streak & Review", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                MoodStreakBadge(streak: store.streakDays)

                Text("Freezes left this month: \(store.streakFreezesRemaining)")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))

                HStack(spacing: 10) {
                    Button {
                        _ = store.useStreakFreeze()
                    } label: {
                        Text(store.canUseStreakFreeze ? "Freeze Yesterday" : "Freeze Unavailable")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color("AppPrimary").opacity(store.canUseStreakFreeze ? 1 : 0.45))
                            )
                    }
                    .disabled(!store.canUseStreakFreeze)

                    Button {
                        FeedbackHelper.tap()
                        showWeeklyReview = true
                    } label: {
                        Text("Weekly Review")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color("AppSurface"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color("AppAccent").opacity(0.45), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
        }
    }

    private var historySection: some View {
        let past = Array(store.pastMoods.prefix(8))
        return Group {
            if !past.isEmpty {
                CalmCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Recent Entries", systemImage: "clock.arrow.circlepath")
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))

                        ForEach(past) { mood in
                            HStack(alignment: .top, spacing: 12) {
                                Text(mood.emoji)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(historyDate(mood.date))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color("AppTextPrimary"))
                                    if mood.note.isEmpty {
                                        Text("No note")
                                            .font(.caption)
                                            .foregroundStyle(Color("AppTextSecondary"))
                                    } else {
                                        Text(mood.note)
                                            .font(.caption)
                                            .foregroundStyle(Color("AppTextSecondary"))
                                            .lineLimit(2)
                                    }
                                    if !mood.tags.isEmpty {
                                        Text(mood.tags.joined(separator: " · "))
                                            .font(.caption2)
                                            .foregroundStyle(Color("AppAccent"))
                                    }
                                }
                                Spacer()
                                Button {
                                    store.deleteMood(mood)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                                .accessibilityLabel("Delete entry")
                            }
                            .padding(.vertical, 4)

                            if mood.id != past.last?.id {
                                Divider().overlay(Color("AppTextSecondary").opacity(0.2))
                            }
                        }
                    }
                }
            }
        }
    }

    private var analyticsSection: some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Mindful Analytics", systemImage: "chart.bar.fill")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                if store.moods.isEmpty {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title2)
                            .foregroundStyle(Color("AppAccent"))
                        Text("Start journaling to see your progress!")
                            .font(.subheadline)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                } else {
                    Text("28-Day Mood Heatmap")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("AppTextSecondary"))

                    MoodHeatmapView(moods: store.moods) { date in
                        store.moodIntensity(for: date)
                    }
                    .accessibilityIdentifier("mood_heatmap")

                    Text("Open the Stats tab for detailed charts.")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
    }

    private var addHabitSheet: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea()
                VStack(spacing: 16) {
                    TextField("Habit name", text: $newHabitName)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("AppSurface"))
                        )
                        .accessibilityIdentifier("new_habit_field")
                        .submitLabel(.done)
                        .onSubmit { confirmAddHabit() }

                    Button("Add Habit", action: confirmAddHabit)
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("AppPrimary"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityIdentifier("confirm_add_habit")

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        KeyboardDismiss.resign()
                        showAddHabit = false
                    }
                }
            }
            .dismissKeyboardOnTap()
        }
        .presentationDetents([.medium])
    }

    private func habitNoteSheet(_ habit: Habit) -> some View {
        NavigationStack {
            ZStack {
                Color("AppBackground").ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    Text("Optional note for \"\(habit.name)\"")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))

                    TextField("How did it go?", text: $habitNoteDraft, axis: .vertical)
                        .lineLimit(3...6)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("AppSurface"))
                        )

                    Button("Save") {
                        if habit.isCompleted {
                            store.updateHabitNote(habit, note: habitNoteDraft)
                        } else {
                            store.completeHabit(habit, note: habitNoteDraft)
                        }
                        habitForNote = nil
                        habitNoteDraft = ""
                    }
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("AppPrimary"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button("Skip Note") {
                        if !habit.isCompleted {
                            store.completeHabit(habit, note: "")
                        }
                        habitForNote = nil
                        habitNoteDraft = ""
                    }
                    .foregroundStyle(Color("AppTextSecondary"))
                    .frame(maxWidth: .infinity)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Habit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        habitForNote = nil
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func confirmAddHabit() {
        let trimmed = newHabitName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            FeedbackHelper.warning()
            return
        }
        store.addHabit(name: trimmed)
        newHabitName = ""
        KeyboardDismiss.resign()
        showAddHabit = false
    }

    private func historyDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
