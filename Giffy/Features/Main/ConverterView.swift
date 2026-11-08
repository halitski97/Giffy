import FactoryKit
import SwiftUI

struct ConverterView: View {
    let model: ConverterModel
    let isDropTargeted: Bool
    let onChooseFile: () -> Void

    @Injected(\.conversionQueue) private var conversionQueue: ConversionQueue

    var body: some View {
        content
            .inspector(isPresented: isInspectorPresented) {
                inspectorContent
            }
            .onChange(of: currentStatusKind) { _, _ in
                if case .converting(let draft, let jobID) = model.phase,
                   let status = conversionQueue.jobs.first(where: { $0.id == jobID })?.status {
                    model.handleJobStatusChange(status, draft: draft)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .empty(let importError):
            EmptyStateView(importError: importError, isDropTargeted: isDropTargeted, onChooseFile: onChooseFile)
        case .loaded(let draft):
            LoadedView(draft: draft)
        case .converting(let draft, _):
            LoadedView(draft: draft, isDimmed: true)
        case .failed(let draft, _):
            LoadedView(draft: draft)
        case .done(let result):
            DoneView(result: result)
        }
    }

    @ViewBuilder
    private var inspectorContent: some View {
        switch model.phase {
        case .loaded(let draft):
            InspectorView(model: model, draft: draft) {
                EstimatedSizeFooterView(
                    estimatedByteSize: model.estimatedByteSize,
                    isEstimatingSize: model.isEstimatingSize,
                    onConvert: model.startConversion
                )
            }
            .inspectorColumnWidth(ideal: 300)
        case .converting(let draft, let jobID):
            InspectorView(model: model, draft: draft, isInteractive: false) {
                ConvertingFooterView(progress: runningProgress(for: jobID), onCancel: model.cancelConversion)
            }
            .inspectorColumnWidth(ideal: 300)
        case .failed(let draft, let error):
            InspectorView(model: model, draft: draft, isInteractive: false) {
                FailedFooterView(error: error, onTryAgain: model.tryAgain)
            }
            .inspectorColumnWidth(ideal: 300)
        case .empty, .done:
            EmptyView()
        }
    }

    private var isInspectorPresented: Binding<Bool> {
        Binding(
            get: {
                switch model.phase {
                case .loaded, .converting, .failed: true
                case .empty, .done: false
                }
            },
            set: { _ in }
        )
    }

    private func runningProgress(for jobID: ConversionJob.ID) -> ConversionProgressSnapshot? {
        guard case .running(let snapshot) = conversionQueue.jobs.first(where: { $0.id == jobID })?.status else {
            return nil
        }
        return snapshot
    }

    private var currentStatusKind: ConversionJob.StatusKind? {
        guard case .converting(_, let jobID) = model.phase else { return nil }
        return conversionQueue.jobs.first(where: { $0.id == jobID })?.status.kind
    }
}
