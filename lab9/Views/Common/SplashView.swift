import SwiftUI

struct SplashView: View {
    @State private var isAnimating: Bool = false
    @State private var showContent: Bool = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var textOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // App Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.white)
                }
                .scaleEffect(scale)
                .opacity(opacity)
                
                // App Name
                VStack(spacing: 8) {
                    Text("Банк")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Мобильный банк")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .opacity(textOpacity)
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                    .padding(.top, 20)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            // Animate icon
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Animate text
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                textOpacity = 1.0
            }
        }
    }
}

// MARK: - Preview

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
