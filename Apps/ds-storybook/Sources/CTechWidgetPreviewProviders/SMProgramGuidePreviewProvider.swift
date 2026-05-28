// SMProgramGuidePreviewProvider.swift — CTechWidgetPreviewProviders
// kagami-scope: exempt
//
// Renders SMProgramGuideKatagami (W6) via .swiftUI(theme:).
// Demo: 3 program rows with mixed badge states (live + shoppable, premiere,
// rerun) to exercise all KatagamiBadge variants.

import SwiftUI
import KatagamiCore
import KatagamiSwiftUI
import SMWidgetsKatagami
import CTechPlayer
import DSStorybookKit

public struct SMProgramGuidePreviewProvider: WidgetPreviewProvider {
    public init() {}

    @MainActor
    public func previewView(for entry: CatalogEntry) -> AnyView {
        let response = ProgramGuideResponse(
            widgetType: "PROGRAM_GUIDE",
            title: "Ce soir sur CliffTV",
            displayMode: "VERTICAL",
            channel: "clifftv-demo",
            campaignUuid: "preview-campaign",
            grid: ProgramGrid(
                uuid: "preview-grid",
                startDatetime: "2026-05-26T18:00:00Z",
                endDatetime: "2026-05-26T23:00:00Z",
                totalPrograms: 3,
                items: [
                    ProgramItem(
                        uuid: "prog-1",
                        startTime: "18:00",
                        endTime: "19:30",
                        durationMinutes: 90,
                        isLive: true,
                        isPremiere: false,
                        isRerun: false,
                        isShoppable: true,
                        program: Program(
                            uuid: "show-1",
                            title: "Style & Shopping Live",
                            programType: "LIVE",
                            thumbnailUrl: nil,
                            posterUrl: nil
                        ),
                        event: nil
                    ),
                    ProgramItem(
                        uuid: "prog-2",
                        startTime: "19:30",
                        endTime: "21:00",
                        durationMinutes: 90,
                        isLive: false,
                        isPremiere: true,
                        isRerun: false,
                        isShoppable: false,
                        program: Program(
                            uuid: "show-2",
                            title: "Tech & Innovation — Saison 2",
                            programType: "PREMIERE",
                            thumbnailUrl: nil,
                            posterUrl: nil
                        ),
                        event: nil
                    ),
                    ProgramItem(
                        uuid: "prog-3",
                        startTime: "21:00",
                        endTime: "22:30",
                        durationMinutes: 90,
                        isLive: false,
                        isPremiere: false,
                        isRerun: true,
                        isShoppable: false,
                        program: Program(
                            uuid: "show-3",
                            title: "Cuisine du Monde",
                            programType: "RERUN",
                            thumbnailUrl: nil,
                            posterUrl: nil
                        ),
                        event: nil
                    ),
                ]
            )
        )

        let widget = SMProgramGuideKatagami(response: response)
        let renderer = KatagamiSwiftUIRenderer()
        return (try? renderer.render(widget, theme: KatagamiThemePreset.kintsugi))
            ?? AnyView(Text("SMProgramGuide render failed").foregroundStyle(.orange))
    }
}
