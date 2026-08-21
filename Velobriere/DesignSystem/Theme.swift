import SwiftUI

/// Design tokens derived from la charte graphique Ker Vélo Brière (v1.0).
enum Theme {
    enum Colors {
        static let background = Color("ColorBackground")
        static let surface = Color("ColorSurface")
        static let surfaceAlt = Color("ColorSurfaceAlt")
        static let ink = Color("ColorInk")
        static let inkSoft = Color("ColorInkSoft")
        static let line = Color("ColorLine")
        static let primary = Color("ColorPrimary")
        static let primaryStrong = Color("ColorPrimaryStrong")
        static let sage = Color("ColorSage")
        static let sand = Color("ColorSand")
        static let warning = Color("ColorWarning")
    }

    enum Fonts {
        /// Poppins — titres & logotype. Falls back to the system font until
        /// the real Poppins .ttf files are added to the target (see README).
        static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
            .custom(weight == .bold ? "Poppins-Bold" : "Poppins-SemiBold", size: size, relativeTo: .headline)
        }

        /// Work Sans — texte courant.
        static func body(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
            .custom(weight == .semibold ? "WorkSans-SemiBold" : "WorkSans-Regular", size: size, relativeTo: .body)
        }
    }

    enum Radius {
        static let card: CGFloat = 14
        static let control: CGFloat = 12
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
}
