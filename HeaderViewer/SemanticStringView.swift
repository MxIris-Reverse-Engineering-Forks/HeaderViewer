//
//  SemanticStringView.swift
//  HeaderViewer
//
//  Created by Leptos on 2/19/24.
//

import SwiftUI
import ClassDump

struct SemanticStringView: View {
    let semanticString: CDSemanticString
    
    init(_ semanticString: CDSemanticString) {
        self.semanticString = semanticString
    }
    
    var body: some View {
        GeometryReader { geomProxy in
            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .leading) {
                    // use the longest line to expand the view as much as needed
                    // without having to render all the lines
                    let (lines, longestLineIndex) = semanticString.semanticLines()
                    if let longestLineIndex {
                        SemanticLineView(line: lines[longestLineIndex])
                            .opacity(0)
                    }
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(lines) { line in
                            SemanticLineView(line: line)
                        }
                    }
                }
                .font(.body.monospaced())
                .textSelection(.enabled)
                .multilineTextAlignment(.leading)
                .scenePadding()
                .frame(
                    minWidth: geomProxy.size.width, maxWidth: .infinity,
                    minHeight: geomProxy.size.height, maxHeight: .infinity,
                    alignment: .topLeading
                )
            }
            .animation(.snappy, value: geomProxy.size)
        }
    }
}

private struct SemanticLine: Identifiable {
    let number: Int
    let content: [SemanticRun]
    
    var id: Int { number }
}

private struct SemanticRun: Identifiable {
    // it is the caller's responsibility to set a unique id relative to the container
    let id: Int
    let string: String
    let type: CDSemanticType
}

private struct SemanticRunView: View {
    let run: SemanticRun
    
    init(_ run: SemanticRun) {
        self.run = run
    }
    
    var body: some View {
        Group {
            switch run.type {
            case .standard:
                Text(run.string)
            case .comment:
                Text(run.string)
                    .foregroundColor(.gray)
            case .keyword:
                Text(run.string)
                    .foregroundColor(.pink)
            case .variable:
                Text(run.string)
            case .recordName:
                Text(run.string)
                    .foregroundColor(.cyan)
            case .class:
                NavigationLink(value: RuntimeObjectType.class(named: run.string)) {
                    Text(run.string)
                        .foregroundColor(.mint)
                }
                .buttonStyle(.plain)
            case .protocol:
                NavigationLink(value: RuntimeObjectType.protocol(named: run.string)) {
                    Text(run.string)
                        .foregroundColor(.teal)
                }
                .buttonStyle(.plain)
            case .numeric:
                Text(run.string)
                    .foregroundColor(.purple)
            default:
                Text(run.string)
            }
        }
        .lineLimit(1, reservesSpace: true)
    }
}

private struct SemanticLineView: View {
    let line: SemanticLine
    
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            ForEach(line.content) { run in
                SemanticRunView(run)
            }
        }
        .padding(.vertical, 1) // effectively line spacing
    }
}

private extension CDSemanticString {
    func semanticLines() -> (lines: [SemanticLine], longestLineIndex: Int?) {
        var lines: [SemanticLine] = []
        var longestLineIndex: Int?
        var longestLineLength: Int = 0
        
        var current: [SemanticRun] = []
        var currentLineLength = 0
        
        func pushLine() {
            let upcomingIndex = lines.count
            lines.append(SemanticLine(number: upcomingIndex, content: current))
            if currentLineLength > longestLineLength {
                longestLineLength = currentLineLength
                longestLineIndex = upcomingIndex
            }
            current = []
            currentLineLength = 0
        }
        
        enumerateTypes { str, type in
            func pushRun(string: String) {
                current.append(SemanticRun(id: current.count, string: string, type: type))
                currentLineLength += string.count
            }
            
            var movingSubstring: String = str
            while let lineBreakIndex = movingSubstring.firstIndex(of: "\n") {
                pushRun(string: String(movingSubstring[..<lineBreakIndex]))
                pushLine()
                // index after because we don't want to include '\n' in the output
                movingSubstring = String(movingSubstring[movingSubstring.index(after: lineBreakIndex)...])
            }
            pushRun(string: movingSubstring)
        }
        if !current.isEmpty {
            pushLine()
        }
        return (lines, longestLineIndex)
    }
}