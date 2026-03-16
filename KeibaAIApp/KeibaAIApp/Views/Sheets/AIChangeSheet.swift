//
//  AIChangeSheet.swift
//  KeibaAIApp
//
//  Created by suke on 2025/11/05.
//
import SwiftUI

struct AIChangeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("aiName") private var aiName: String = "血統重視AI"
    @AppStorage("aiStyleRaw") private var aiStyleRaw: String = AIStyle.pedigree.rawValue
    @State private var tmpName: String = ""
    @State private var tmpStyle: AIStyle = .pedigree

    var body: some View {
        NavigationStack {
            Form {
                Section("AIの名前") {
                    TextField("例：血統キング", text: $tmpName)
                }
                Section("スタイル") {
                    Picker("スタイル", selection: $tmpStyle) {
                        ForEach(AIStyle.allCases) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("AIを変更")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if !tmpName.trimmingCharacters(in: .whitespaces).isEmpty {
                            aiName = tmpName
                        }
                        aiStyleRaw = tmpStyle.rawValue
                        dismiss()
                    }
                }
            }
            .onAppear {
                tmpName = aiName
                tmpStyle = AIStyle(rawValue: aiStyleRaw) ?? .pedigree
            }
        }
    }
}
