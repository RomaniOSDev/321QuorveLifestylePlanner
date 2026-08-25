import SwiftUI

struct TodayCloseView: View {
    @ObservedObject var store: DataStore

    @State private var wins: [String] = ["", "", ""]
    @State private var drains: [String] = ["", ""]
    @State private var drainTags: Set<String> = []
    @State private var moveTitle = ""
    @State private var moveSlot: MoveSlot = .morning
    @State private var didPickSlotManually = false
    @State private var isEditing = false
    @State private var showSavedPulse = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                if let planned = store.todaysPlannedMove {
                    plannedMoveCard(planned)
                }
                if store.hasClosedToday && !isEditing {
                    closedSummary
                } else {
                    threeTwoOneForm
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .clearScrollBackground()
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
        .onAppear(perform: loadDraftFromStore)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("3-2-1 Close")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundStyle(Color("AppTextPrimary"))
            Text("Shut the day in three wins, two drains, and one move for tomorrow.")
                .font(.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                metricChip("\(store.streakDays)", "close streak")
                metricChip("\(store.closesCount)", "days closed")
                metricChip("\(store.movesCompleted)", "moves done")
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metricChip(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundStyle(Color("AppAccent"))
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func plannedMoveCard(_ planned: DayClose) -> some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("First move today", systemImage: planned.moveSlot.icon)
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))

                Text(planned.moveTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))

                Text("\(planned.moveSlot.title) · \(planned.moveTimeLabel)")
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))

                if planned.isMoveDone {
                    Text("Done. That plan actually stuck.")
                        .font(.caption)
                        .foregroundStyle(Color("AppAccent"))
                } else {
                    Button {
                        store.completeTodaysPlannedMove()
                    } label: {
                        Text("Mark move done")
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color("AppPrimary"))
                            )
                    }
                    .accessibilityIdentifier("complete_move_button")
                }
            }
        }
    }

    private var closedSummary: some View {
        Group {
            if let closed = store.todayClose {
                CalmCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Day closed")
                                    .font(.headline)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Text("Locked at \(timeLabel(closed.closedAt))")
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                            Spacer()
                            Button("Edit") {
                                FeedbackHelper.tap()
                                loadDraftFromStore()
                                isEditing = true
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppAccent"))
                        }

                        numberedBlock(number: 3, title: "Wins") {
                            ForEach(Array(closed.filledWins.enumerated()), id: \.offset) { _, win in
                                summaryRow(win)
                            }
                        }

                        numberedBlock(number: 2, title: "Drains") {
                            ForEach(Array(closed.filledDrains.enumerated()), id: \.offset) { _, drain in
                                summaryRow(drain)
                            }
                            if !closed.drainTags.isEmpty {
                                Text(closed.drainTags.joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundStyle(Color("AppAccent"))
                            }
                        }

                        numberedBlock(number: 1, title: "Tomorrow's move") {
                            summaryRow(closed.moveTitle)
                            Text("\(closed.moveSlot.title) · \(closed.moveTimeLabel)")
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }

                        Text("Optional next: open Wind-down for a short reset.")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
            }
        }
    }

    private var threeTwoOneForm: some View {
        VStack(spacing: 18) {
            numberedCard(number: 3, title: "Wins", subtitle: "Three things that actually happened.") {
                ForEach(0..<3, id: \.self) { index in
                    closeField(
                        placeholder: winPlaceholder(index),
                        text: $wins[index],
                        identifier: "win_field_\(index)"
                    )
                }
            }

            numberedCard(number: 2, title: "Drains", subtitle: "What pulled energy off the day.") {
                ForEach(0..<2, id: \.self) { index in
                    closeField(
                        placeholder: drainPlaceholder(index),
                        text: $drains[index],
                        identifier: "drain_field_\(index)"
                    )
                }

                Text("Where it came from")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                    ForEach(DrainTag.allCases) { tag in
                        let selected = drainTags.contains(tag.rawValue)
                        Button {
                            FeedbackHelper.tap()
                            if selected {
                                drainTags.remove(tag.rawValue)
                            } else {
                                drainTags.insert(tag.rawValue)
                            }
                            applySuggestedSlotIfNeeded()
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

                Text("Suggested window: \(DrainTag.suggestedSlot(from: Array(drainTags)).title)")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }

            numberedCard(number: 1, title: "One move", subtitle: "A single timed action for tomorrow.") {
                closeField(
                    placeholder: "e.g. Walk 20 min before inbox",
                    text: $moveTitle,
                    identifier: "move_field"
                )

                Picker("When", selection: $moveSlot) {
                    ForEach(MoveSlot.allCases) { slot in
                        Text(slot.title).tag(slot)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: moveSlot) { _ in
                    didPickSlotManually = true
                }

                Text("Park it at \(moveSlot.title.lowercased()) · \(timeLabel(hour: moveSlot.defaultHour, minute: moveSlot.defaultMinute))")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }

            Button {
                KeyboardDismiss.resign()
                let saved = store.saveDayClose(
                    wins: wins,
                    drains: drains,
                    drainTags: Array(drainTags),
                    moveTitle: moveTitle,
                    moveSlot: moveSlot,
                    moveHour: moveSlot.defaultHour,
                    moveMinute: moveSlot.defaultMinute
                )
                guard saved else { return }
                isEditing = false
                withAnimation(.spring(response: 0.35)) {
                    showSavedPulse = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation { showSavedPulse = false }
                }
            } label: {
                Text(store.hasClosedToday ? "Update close" : "Close the day")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color("AppPrimary"))
                    )
            }
            .accessibilityIdentifier("close_day_button")

            if isEditing {
                Button("Cancel") {
                    isEditing = false
                    loadDraftFromStore()
                }
                .foregroundStyle(Color("AppTextSecondary"))
            }
        }
    }

    private func numberedCard<Content: View>(
        number: Int,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        CalmCard {
            VStack(alignment: .leading, spacing: 14) {
                numberedBlock(number: number, title: title) {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                    content()
                }
            }
        }
    }

    private func numberedBlock<Content: View>(
        number: Int,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("\(number)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color("AppPrimary")))
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
            }
            content()
        }
    }

    private func closeField(placeholder: String, text: Binding<String>, identifier: String) -> some View {
        TextField(placeholder, text: text, axis: .vertical)
            .lineLimit(1...3)
            .foregroundStyle(Color("AppTextPrimary"))
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color("AppBackground").opacity(0.5))
            )
            .accessibilityIdentifier(identifier)
    }

    private func summaryRow(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Color("AppTextPrimary"))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func loadDraftFromStore() {
        if let closed = store.todayClose {
            wins = padded(closed.wins, count: 3)
            drains = padded(closed.drains, count: 2)
            drainTags = Set(closed.drainTags)
            moveTitle = closed.moveTitle
            moveSlot = closed.moveSlot
            didPickSlotManually = true
        } else {
            wins = ["", "", ""]
            drains = ["", ""]
            drainTags = []
            moveTitle = ""
            moveSlot = .morning
            didPickSlotManually = false
        }
    }

    private func applySuggestedSlotIfNeeded() {
        guard !didPickSlotManually else { return }
        moveSlot = DrainTag.suggestedSlot(from: Array(drainTags))
    }

    private func padded(_ values: [String], count: Int) -> [String] {
        var result = values
        while result.count < count { result.append("") }
        return Array(result.prefix(count))
    }

    private func winPlaceholder(_ index: Int) -> String {
        ["A concrete win", "Something you finished", "A small thing worth keeping"][index]
    }

    private func drainPlaceholder(_ index: Int) -> String {
        ["What stalled you", "What you would skip tomorrow"][index]
    }

    private func timeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func timeLabel(hour: Int, minute: Int) -> String {
        String(format: "%d:%02d", hour, minute)
    }
}
