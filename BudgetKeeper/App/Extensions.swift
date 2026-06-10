import UIKit

extension UIColor {
    convenience init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.hasPrefix("#") ? String(s.dropFirst()) : s
        guard s.count == 6, let value = UInt64(s, radix: 16) else { return nil }
        self.init(
            red:   CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >>  8) & 0xFF) / 255,
            blue:  CGFloat( value        & 0xFF) / 255,
            alpha: 1
        )
    }

    var hexString: String {
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

extension Double {
    var hryvnia: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.groupingSeparator = "\u{00A0}"
        f.decimalSeparator = ","
        f.groupingSize = 3
        return "₴\(f.string(from: NSNumber(value: self)) ?? "0,00")"
    }
}

extension Date {
    var sectionTitle: String {
        let cal = Calendar.current
        if cal.isDateInToday(self)     { return "Сьогодні" }
        if cal.isDateInYesterday(self) { return "Вчора" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "uk_UA")
        f.dateFormat = "d MMMM"
        return f.string(from: self)
    }

    var formattedUkrainian: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "uk_UA")
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: self)
    }

    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
}
