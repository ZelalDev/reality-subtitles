import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image("DuyBeniLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 112, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .accessibilityHidden(true)
                Text("Duy Beni")
                    .font(.title2.weight(.semibold))
                Text("Kullanmak istediğiniz özelliği seçin.")
                    .foregroundStyle(.secondary)

                NavigationLink {
                    ContentView()
                } label: {
                    feature("Speech-to-Text", subtitle: "Konuşmayı Türkçe metne dönüştür", icon: "mic.fill")
                }
                NavigationLink {
                    LipReadingView()
                } label: {
                    feature("Lip Reading", subtitle: "Kamerayla yüz ve dudak tespiti", icon: "camera.fill")
                }
                Spacer()
            }
            .padding(24)
            .padding(.top, 24)
            .background(.white)
        }
        .tint(.black)
        .preferredColorScheme(.light)
    }

    private func feature(_ title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
        }
        .foregroundStyle(.black)
        .padding(24)
        .background(Color(red: 0.95, green: 0.96, blue: 0.97), in: RoundedRectangle(cornerRadius: 24))
    }
}
