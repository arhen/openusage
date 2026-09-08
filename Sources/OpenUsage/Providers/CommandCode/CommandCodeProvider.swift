import Foundation

/// Command Code (commandcode.ai) — multi-model inference plan, driven here through pi. The Provider
/// API exposes chat/messages/models only (no usage endpoint, probed 2026-09), so this card is built
/// purely from local harness logs: Usage Trend + Today / Yesterday / Last 30 Days spend from pi's
/// session JSONL, which records authoritative per-message costs. Quota meters land if Command Code
/// ever ships a usage endpoint.
@MainActor
final class CommandCodeProvider: ProviderRuntime {
    let provider = Provider(
        id: "commandcode",
        displayName: "Command Code",
        icon: .providerMark("commandcode"),
        links: [
            ProviderLink(label: "Dashboard", url: "https://commandcode.ai/studio"),
            ProviderLink(label: "Docs", url: "https://commandcode.ai/docs/provider")
        ]
    )

    let authStore: CommandCodeAuthStore
    let pricing: @Sendable () async -> ModelPricing
    let now: @Sendable () -> Date

    init(
        authStore: CommandCodeAuthStore = CommandCodeAuthStore(),
        pricing: @escaping @Sendable () async -> ModelPricing = { await ModelPricingStore.shared.current() },
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.authStore = authStore
        self.pricing = pricing
        self.now = now
    }

    var widgetDescriptors: [WidgetDescriptor] {
        [
            .usageTrend(provider: provider)
                .exportingHistory(
                    scope: .machineLocal,
                    estimatedCost: true,
                    sourceNote: "From your pi logs (estimated)"
                )
        ] + WidgetDescriptor.spendTiles(provider: provider)
    }

    func hasLocalCredentials() async -> Bool {
        await loadOffMainActor { [authStore] in authStore.hasPiCredential() }
    }

    func refresh() async -> ProviderSnapshot {
        let pricing = await pricing()
        let piScan = await PiUsageScanner.shared.scan(cardID: provider.id, now: now(), pricing: pricing)
        var lines: [MetricLine] = []
        var usageHistory: ProviderUsageHistory?
        if !Task.isCancelled, let scan = piScan {
            let note = "From your pi logs (estimated)"
            usageHistory = ProviderUsageHistory(
                series: scan.series,
                modelUsage: scan.modelUsage,
                unknownModelsByDay: scan.unknownModelsByDay
            )
            SpendTileMapper.appendTokenUsage(
                scan.series, to: &lines, now: now(),
                unknownModelsByDay: scan.unknownModelsByDay,
                modelUsage: scan.modelUsage,
                modelSourceNote: note
            )
            SpendTileMapper.appendUsageTrend(scan.series, to: &lines, now: now(), note: note)
        }
        MetricLine.appendNoDataIfNeeded(&lines)
        return ProviderSnapshot.make(
            provider: provider,
            plan: nil,
            lines: lines,
            refreshedAt: now(),
            usageHistory: usageHistory
        )
    }
}
