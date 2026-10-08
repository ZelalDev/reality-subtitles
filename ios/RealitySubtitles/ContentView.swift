import SwiftUI
import AVFoundation

struct ContentView: View {

    @StateObject private var recorder = AudioRecorder()

    var body: some View {
        VStack(spacing: 25) {

            Text("Reality Subtitles")
                .font(.largeTitle)
                .bold()

            Text("Türkçe konuşmayı yazıya dönüştürme")
                .font(.subheadline)

            if recorder.isRecording {

                Text("🔴 Kayıt yapılıyor...")
                    .foregroundStyle(.red)

                Button("Kaydı Durdur") {
                    recorder.stopRecording()
                }
                .buttonStyle(.borderedProminent)

            } else {

                Button("Kaydı Başlat") {
                    recorder.startRecording()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
