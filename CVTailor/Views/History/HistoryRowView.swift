//
//  HistoryRowView.swift
//  CVTailor
//
//  Created by Mahmoud Amer on 18.05.26.
//
import SwiftUI

struct HistoryRowView: View {
    private let record: TailoredCVRecord

    init(record: TailoredCVRecord) {
        self.record = record
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(record.cvTitle)
                .font(.headline)
                .lineLimit(1)
            Text(record.createdAt, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
