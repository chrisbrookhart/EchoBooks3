//
//  DesignSystem.swift
//  EchoBooks3
// 
//  Complete design system with colors, typography, spacing, and design tokens.
//  Follows iOS Human Interface Guidelines and supports light/dark mode.
//

import SwiftUI

// MARK: - Design System

enum DesignSystem {
    
    // MARK: - Spacing (8pt Grid System)
    
    enum Spacing {
        static let xs: CGFloat = 4    // 0.5x
        static let sm: CGFloat = 8    // 1x (base unit)
        static let md: CGFloat = 16   // 2x
        static let lg: CGFloat = 24   // 3x
        static let xl: CGFloat = 32   // 4x
        static let xxl: CGFloat = 48  // 6x
        static let xxxl: CGFloat = 64 // 8x
        
        // Semantic spacing
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let screenPadding: CGFloat = 16
        static let buttonPadding: CGFloat = 12
    }
    
    // MARK: - Corner Radius
    
    enum CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        
        // Semantic radius
        static let card: CGFloat = 12
        static let button: CGFloat = 10
        static let bookCover: CGFloat = 8
        static let modal: CGFloat = 16
    }
    
    // MARK: - Typography
    
    enum Typography {
        // Display (largest, for hero text)
        static let displayLarge = Font.system(size: 34, weight: .bold, design: .default)
        static let displayMedium = Font.system(size: 28, weight: .bold, design: .default)
        static let displaySmall = Font.system(size: 24, weight: .semibold, design: .default)
        
        // Headings
        static let h1 = Font.system(size: 22, weight: .bold, design: .default)
        static let h2 = Font.system(size: 20, weight: .semibold, design: .default)
        static let h3 = Font.system(size: 18, weight: .semibold, design: .default)
        static let h4 = Font.system(size: 16, weight: .semibold, design: .default)
        
        // Body text
        static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 15, weight: .regular, design: .default)
        
        // UI Elements
        static let button = Font.system(size: 17, weight: .semibold, design: .default)
        static let buttonSmall = Font.system(size: 15, weight: .semibold, design: .default)
        
        // Labels
        static let label = Font.system(size: 14, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 13, weight: .medium, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        
        // Sentence Display (for reading)
        static let sentenceDisplay = Font.system(size: 24, weight: .regular, design: .default)
        static let sentenceDisplayLarge = Font.system(size: 28, weight: .regular, design: .default)
        
        // Line heights (for better readability)
        static let lineHeightTight: CGFloat = 1.2
        static let lineHeightNormal: CGFloat = 1.5
        static let lineHeightRelaxed: CGFloat = 1.75
    }
    
    // MARK: - Colors
    
    enum Colors {
        // Primary Brand Colors
        static let primary = Color.accentColor
        static let primaryLight = Color.accentColor.opacity(0.8)
        static let primaryDark = Color.accentColor.opacity(0.6)
        
        // Background Colors
        static let background = Color(UIColor.systemBackground)
        static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
        static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)
        
        // Text Colors
        static let textPrimary = Color(UIColor.label)
        static let textSecondary = Color(UIColor.secondaryLabel)
        static let textTertiary = Color(UIColor.tertiaryLabel)
        static let textPlaceholder = Color(UIColor.placeholderText)
        
        // Semantic Colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Interactive States
        static let interactive = Color.accentColor
        static let interactivePressed = Color.accentColor.opacity(0.7)
        static let interactiveDisabled = Color.gray.opacity(0.3)
        
        // Card/Container Colors
        static let cardBackground = Color(UIColor.secondarySystemBackground)
        static let cardBorder = Color(UIColor.separator)
        
        // Overlay Colors
        static let overlay = Color.black.opacity(0.3)
        static let overlayDark = Color.black.opacity(0.6)
        
        // Gradient Colors (for sentence display area)
        static let gradientStart = Color(UIColor.systemBackground)
        static let gradientEnd = Color(UIColor.secondarySystemBackground)
    }
    
    // MARK: - Shadows
    
    enum Shadow {
        static let small = ShadowStyle(
            color: Color.black.opacity(0.1),
            radius: 2,
            x: 0,
            y: 1
        )
        
        static let medium = ShadowStyle(
            color: Color.black.opacity(0.15),
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let large = ShadowStyle(
            color: Color.black.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
        
        static let card = ShadowStyle(
            color: Color.black.opacity(0.1),
            radius: 6,
            x: 0,
            y: 3
        )
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        
        // Spring animations
        static let springQuick = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let springStandard = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
        
        // Interaction animations
        static let buttonPress = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let cardHover = SwiftUI.Animation.easeInOut(duration: 0.2)
    }
    
    // MARK: - Layout
    
    enum Layout {
        // Screen dimensions
        static let screenPadding: CGFloat = 16
        static let maxContentWidth: CGFloat = 600
        
        // Card dimensions
        static let bookCoverAspectRatio: CGFloat = 2.0 / 3.0 // Portrait book ratio
        static let bookCoverMinWidth: CGFloat = 80
        static let bookCoverMaxWidth: CGFloat = 120
        
        // Button dimensions
        static let buttonMinHeight: CGFloat = 44 // iOS HIG minimum
        static let buttonLargeHeight: CGFloat = 56
        static let iconButtonSize: CGFloat = 44
        
        // Playback controls
        static let playbackButtonSize: CGFloat = 60
        static let playbackControlSize: CGFloat = 32
    }
    
    // MARK: - Opacity
    
    enum Opacity {
        static let disabled: Double = 0.4
        static let pressed: Double = 0.7
        static let hover: Double = 0.9
        static let overlay: Double = 0.3
    }
}

// MARK: - Shadow Style Helper

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Modifiers for Design System

extension View {
    /// Applies a shadow style from the design system
    func shadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
    
    /// Applies card styling (background, corner radius, shadow, padding)
    func cardStyle() -> some View {
        self
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.card)
            .shadow(DesignSystem.Shadow.card)
            .padding(DesignSystem.Spacing.cardPadding)
    }
    
    /// Applies button styling
    // Remove the problematic shadow line and replace the entire buttonStyle function with:
    func buttonStyle(primary: Bool = true) -> some View {
        let view = self
            .font(DesignSystem.Typography.button)
            .foregroundColor(primary ? .white : DesignSystem.Colors.textPrimary)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.buttonPadding)
            .background(primary ? DesignSystem.Colors.primary : DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.CornerRadius.button)
        
        if primary {
            return AnyView(view.shadow(DesignSystem.Shadow.small))
        } else {
            return AnyView(view)
        }
    }
    
    /// Applies section header styling
    func sectionHeaderStyle() -> some View {
        self
            .font(DesignSystem.Typography.h2)
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

// MARK: - Color Extensions

extension Color {
    /// Creates a color that adapts to light/dark mode
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
