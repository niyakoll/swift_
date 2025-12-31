import SwiftUI

struct PredictorCardView: View {
    let model: PredictorModel
    var onDelete: () -> Void = {}
    var onEdit: (PredictorModel) -> Void = { _ in }
    // MARK: - Animation States
    @State private var isPressed = false
    @State private var shineOffset: CGFloat = -100
    
    // MARK: - Computed Properties
    private var isDefaultModel: Bool {
        model.name == "SmartInvest Default"
    }
    
    private var initialLetter: String {
        String(model.name.prefix(1)).uppercased()
    }
    
    var body: some View {
        NavigationLink(destination: PredictorDetailView(model: model, onDelete: onDelete,onEdit: onEdit)) {
            HStack(spacing: 16) {
                // MARK: - Icon
                ZStack {
                    Circle()
                        .fill(iconBackgroundColor)
                        .frame(width: 60, height: 60)
                    
                    if isDefaultModel {
                        Image(systemName: "brain")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white)
                    } else {
                        Text(initialLetter)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                
                // MARK: - Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    
                    Text(model.description.isEmpty ? "No description" : model.description)
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)
                    
                    HStack {
                        Image(systemName: model.isAutoPredictEnabled ? "clock.badge.checkmark" : "clock")
                            .font(.caption)
                            .foregroundStyle(model.isAutoPredictEnabled ? Color.successAccent : Color.textSecondary)
                        
                        Text(model.isAutoPredictEnabled ? "Auto-predict enabled" : "Manual only")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.textSecondary.opacity(0.6))
            }
            .padding(20)
            .background(Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.borderSeparator, lineWidth: 1)
            )
            // MARK: - Shine Sweep
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .mask(Rectangle().offset(x: shineOffset))
                    .opacity(isPressed ? 1 : 0)
            )
            // MARK: - Floating & Glow
            .scaleEffect(isPressed ? 1.03 : 1.0)
            .shadow(
                color: Color.primaryAccent.opacity(isPressed ? 0.6 : 0.05),
                radius: isPressed ? 16 : 8,
                y: isPressed ? 12 : 4
            )
            .animation(.easeInOut(duration: 0.2), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())  // Crucial: keeps custom animation
        
        // MARK: - Tap Gesture (for animation + haptic)
        .onTapGesture {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.3)) {
                isPressed = true
                shineOffset = 300
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    isPressed = false
                    shineOffset = -100
                }
            }
        }
        
        // MARK: - Default Model Specials
        .overlay(alignment: .topLeading) {
            if isDefaultModel {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                    Text("Official")
                        .font(.caption.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.primaryAccent)
                .clipShape(Capsule())
                .padding(8)
            }
        }
        .overlay {
            if isDefaultModel {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primaryAccent, lineWidth: 3)
            }
        }
    }
    
    // MARK: - Icon Background Color
    private var iconBackgroundColor: Color {
        if isDefaultModel {
            return Color.primaryAccent
        } else {
            let pastelColors: [Color] = [
                Color(red: 0.95, green: 0.75, blue: 0.45),  // soft gold
                Color(red: 0.75, green: 0.85, blue: 0.95),
                Color(red: 0.85, green: 0.95, blue: 0.75),
                Color(red: 0.95, green: 0.85, blue: 0.75),
                Color(red: 0.75, green: 0.95, blue: 0.85),
                Color(red: 0.95, green: 0.70, blue: 0.85)
            ]
            let hash = abs(model.name.hashValue) % pastelColors.count
            return pastelColors[hash]
        }
    }
}

// MARK: - Previews
#Preview("Default Model") {
    PredictorCardView(
        model: PredictorModel(
            name: "SmartInvest Default",
            description: "Official model",
            apiURL: "",
            isAutoPredictEnabled: true
        )
    )
    .padding()
    .background(Color.backgroundSecondary)
}

#Preview("User Model") {
    PredictorCardView(
        model: PredictorModel(
            name: "My Gold Pro",
            description: "Custom high-accuracy model",
            apiURL: "",
            isAutoPredictEnabled: true
        )
    )
    .padding()
    .background(Color.backgroundSecondary)
}

#Preview("Dark Mode") {
    PredictorCardView(
        model: PredictorModel(
            name: "Test Model",
            description: "User created",
            apiURL: "",
            isAutoPredictEnabled: false
        )
    )
    .padding()
    .preferredColorScheme(.dark)
}   
