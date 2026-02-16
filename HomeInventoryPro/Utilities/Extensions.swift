import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.md)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    
    func primaryButtonStyle() -> some View {
        self
            .font(Theme.Fonts.headline(size: 17))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [Theme.Colors.accent, Theme.Colors.accentLight],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(26)
            .shadow(color: Theme.Colors.accent.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(Theme.Fonts.headline(size: 17))
            .foregroundColor(Theme.Colors.accent)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Theme.Colors.accent.opacity(0.1))
            .cornerRadius(26)
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Date Extensions
extension Date {
    func toString(format: String = "MMM dd, yyyy") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isInPast: Bool {
        self < Date()
    }
    
    func daysUntil() -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: self).day ?? 0
    }
}

// MARK: - String Extensions
extension String {
    func toDate(format: String = "MMM dd, yyyy") -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: self)
    }
}

// MARK: - Double Extensions
extension Double {
    func toCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
}
