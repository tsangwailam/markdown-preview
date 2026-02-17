import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Markdown Preview")
                .font(.title)
            Text("Quick Look extension host app.")
                .font(.headline)
            Text("Launch this app once after install so Finder can discover the extension.")
            Text("Then enable it in System Settings > Privacy & Security > Extensions > Quick Look.")
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 260)
    }
}
