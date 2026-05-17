import UIKit

enum AppColors {
    // Accent colors — same in both modes
    static let primary   = UIColor(red: 0/255,   green: 102/255, blue: 255/255, alpha: 1)
    static let green     = UIColor(red: 52/255,  green: 199/255, blue: 89/255,  alpha: 1)
    static let red       = UIColor(red: 255/255, green: 59/255,  blue: 48/255,  alpha: 1)
    static let orange    = UIColor(red: 255/255, green: 149/255, blue: 0/255,   alpha: 1)
    static let purple    = UIColor(red: 88/255,  green: 86/255,  blue: 214/255, alpha: 1)
    static let lightBlue = UIColor(red: 90/255,  green: 200/255, blue: 250/255, alpha: 1)
    static let systemGray = UIColor(red: 142/255, green: 142/255, blue: 147/255, alpha: 1)

    // Adaptive colors
    static let background = UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 28/255,  green: 28/255,  blue: 30/255,  alpha: 1)
            : UIColor(red: 247/255, green: 247/255, blue: 249/255, alpha: 1)
    }

    static let card = UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 1)
            : UIColor.white
    }

    static let textPrimary = UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor(red: 10/255, green: 10/255, blue: 10/255, alpha: 1)
    }

    static let textSecondary = UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 171/255, green: 171/255, blue: 175/255, alpha: 1)
            : UIColor(red: 138/255, green: 138/255, blue: 142/255, alpha: 1)
    }

    static let separator = UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 56/255, green: 56/255, blue: 58/255, alpha: 1)
            : UIColor(red: 229/255, green: 229/255, blue: 234/255, alpha: 1)
    }
}
