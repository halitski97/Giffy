import SwiftUI

struct InProgressRow: View {
    let job: ConversionJob

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(subtitle)
                .font(.system(size: 13))
            ProgressView(value: fraction)
                .controlSize(.small)
        }
    }

    private var fraction: Double {
        if case .running(let snapshot) = job.status { snapshot.fraction } else { 0 }
    }

    private var subtitle: String {
        switch job.status {
        case .queued:
            "Waiting"
        case .running(let snapshot):
            "Converting · \(ProgressFormatting.percentText(snapshot.fraction))"
        case .finished, .failed, .cancelled:
            "Converting"
        }
    }
}
