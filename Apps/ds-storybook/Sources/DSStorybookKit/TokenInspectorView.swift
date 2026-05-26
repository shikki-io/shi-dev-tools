// TokenInspectorView.swift — DSStorybookKit
//
// NP-2: DSKintsugi Token Inspector
//
// Renders the loaded catalog's brand tokens (Q3: single-brand, no cross-brand).
// Brand resolved from catalogBrand: "sigma" → Sigma, "wabi-sabi" → WS, "obyw" → OBYW.
//
// Sections:
//   Colors    — swatch grid with hex + token name
//   Typography — text samples at each type scale
//   Spacing   — horizontal ruler bars with pt labels
//   Radius    — rounded rect samples at each corner radius
//   Shadows   — card samples at each elevation (low/medium/high)
//
// Usage (sidebar section — Q4 Option A fast-path):
//   TokenInspectorView(brand: .sigma)

import SwiftUI

// MARK: - TokenBrand

/// DSKintsugi brand selector.
/// Resolved from the catalog's brand identifier string.
public enum TokenBrand: String, Sendable, CaseIterable, Identifiable {
    case sigma     = "sigma"
    case wabiSabi  = "wabi-sabi"
    case obyw      = "obyw"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sigma:    "Sigma"
        case .wabiSabi: "Wabi-Sabi"
        case .obyw:     "OBYW"
        }
    }

    /// Resolve brand from catalog JSON `brand` string or from widget kind hints.
    /// Falls back to sigma (most token-rich) when unknown.
    public static func resolve(from hint: String) -> TokenBrand {
        let lower = hint.lowercased()
        if lower.contains("sigma") || lower.contains("sg") { return .sigma }
        if lower.contains("wabi") || lower.contains("ws")  { return .wabiSabi }
        if lower.contains("obyw") || lower.contains("ob")  { return .obyw }
        return .sigma // Q3 default
    }
}

// MARK: - ColorToken

struct ColorToken: Identifiable {
    let id: String
    let name: String
    let hex: String
    var color: Color { Color(hex: hex) }
}

// MARK: - Color+Hex (local extension, avoids import of DSKintsugi from app level)

extension Color {
    /// Initialise from a 6-digit hex string (without #).
    fileprivate init(hex: String) {
        let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let v = UInt64(h, radix: 16) ?? 0
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8) & 0xFF) / 255
        let b = Double(v & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Brand token tables (static, sourced from DSKintsugi Generated/ files)

private enum SigmaTokens {
    static let colors: [ColorToken] = [
        ColorToken(id: "sgCrimsonRest",     name: "sgCrimsonRest",     hex: "E64A6B"),
        ColorToken(id: "sgCrimson",         name: "sgCrimson",         hex: "C41E3A"),
        ColorToken(id: "sgCrimsonBright",   name: "sgCrimsonBright",   hex: "DC143C"),
        ColorToken(id: "sgCrimsonPressed",  name: "sgCrimsonPressed",  hex: "8B1A1A"),
        ColorToken(id: "sgBurgundyDeep",    name: "sgBurgundyDeep",    hex: "4A0018"),
        ColorToken(id: "sgDataCyan",        name: "sgDataCyan",        hex: "06B6D4"),
        ColorToken(id: "sgDataPurple",      name: "sgDataPurple",      hex: "A855F7"),
        ColorToken(id: "sgCream",           name: "sgCream",           hex: "FAFAFA"),
        ColorToken(id: "sgCreamWarm",       name: "sgCreamWarm",       hex: "F4F4F5"),
        ColorToken(id: "sgWhite",           name: "sgWhite",           hex: "FFFFFF"),
        ColorToken(id: "sgCharcoal",        name: "sgCharcoal",        hex: "171717"),
        ColorToken(id: "sgCharcoalSoft",    name: "sgCharcoalSoft",    hex: "404040"),
        ColorToken(id: "sgCharcoalMuted",   name: "sgCharcoalMuted",   hex: "525252"),
        ColorToken(id: "sgStone",           name: "sgStone",           hex: "E5E5E5"),
        ColorToken(id: "sgInkBg",           name: "sgInkBg",           hex: "0A0A0A"),
        ColorToken(id: "sgInkSurface",      name: "sgInkSurface",      hex: "111111"),
        ColorToken(id: "sgBackground",      name: "sgBackground",      hex: "FAFAFA"),
        ColorToken(id: "sgSurface",         name: "sgSurface",         hex: "FFFFFF"),
        ColorToken(id: "sgTextPrimary",     name: "sgTextPrimary",     hex: "171717"),
        ColorToken(id: "sgTextSecondary",   name: "sgTextSecondary",   hex: "404040"),
        ColorToken(id: "sgAccent",          name: "sgAccent",          hex: "C41E3A"),
        ColorToken(id: "sgBorder",          name: "sgBorder",          hex: "E5E5E5"),
        ColorToken(id: "sgActionPrimary",   name: "sgActionPrimary",   hex: "C41E3A"),
        ColorToken(id: "sgError",           name: "sgError",           hex: "DC2626"),
        ColorToken(id: "sgSuccess",         name: "sgSuccess",         hex: "16A34A"),
    ]
}

private enum WSTokens {
    static let colors: [ColorToken] = [
        ColorToken(id: "wsBeige",           name: "wsBeige",           hex: "F5F0E8"),
        ColorToken(id: "wsBeigeDark",       name: "wsBeigeDark",       hex: "EDE6D8"),
        ColorToken(id: "wsWhite",           name: "wsWhite",           hex: "FAFAF7"),
        ColorToken(id: "wsCharcoal",        name: "wsCharcoal",        hex: "2C2C2C"),
        ColorToken(id: "wsCharcoalLight",   name: "wsCharcoalLight",   hex: "4A4A4A"),
        ColorToken(id: "wsInk",             name: "wsInk",             hex: "1A1A1A"),
        ColorToken(id: "wsStone",           name: "wsStone",           hex: "9B9588"),
        ColorToken(id: "wsMoss",            name: "wsMoss",            hex: "6B7F5E"),
        ColorToken(id: "wsMossLight",       name: "wsMossLight",       hex: "8A9E7C"),
        ColorToken(id: "wsMossDark",        name: "wsMossDark",        hex: "556B49"),
        ColorToken(id: "wsClay",            name: "wsClay",            hex: "C4A882"),
        ColorToken(id: "wsClayLight",       name: "wsClayLight",       hex: "D4BFA0"),
        ColorToken(id: "wsSand",            name: "wsSand",            hex: "E8DFD0"),
        ColorToken(id: "wsSakura",          name: "wsSakura",          hex: "E8A0BF"),
    ]
}

private enum OBYWTokens {
    static let colors: [ColorToken] = [
        ColorToken(id: "obOrange",          name: "obOrange",          hex: "FF6B35"),
        ColorToken(id: "obOrangeLight",     name: "obOrangeLight",     hex: "FF8F60"),
        ColorToken(id: "obOrangeDark",      name: "obOrangeDark",      hex: "E05520"),
        ColorToken(id: "obDark",            name: "obDark",            hex: "1A1A1A"),
        ColorToken(id: "obDarkSurface",     name: "obDarkSurface",     hex: "2A2A2A"),
        ColorToken(id: "obDarkElevated",    name: "obDarkElevated",    hex: "3A3A3A"),
        ColorToken(id: "obGray",            name: "obGray",            hex: "6E6E6E"),
        ColorToken(id: "obLight",           name: "obLight",           hex: "F8F5F2"),
        ColorToken(id: "obLightSurface",    name: "obLightSurface",    hex: "FFFFFF"),
        ColorToken(id: "obCharcoal",        name: "obCharcoal",        hex: "2C2C2C"),
        ColorToken(id: "obCharcoalLight",   name: "obCharcoalLight",   hex: "4A4A4A"),
        ColorToken(id: "obRed",             name: "obRed",             hex: "E53E3E"),
    ]
}

// MARK: - TypeScaleToken

struct TypeScaleToken: Identifiable {
    let id: String
    let name: String
    let size: CGFloat
    let weight: Font.Weight
    let sample: String
}

private let sigmaTypeScale: [TypeScaleToken] = [
    TypeScaleToken(id: "display", name: "display", size: 34, weight: .light,
                   sample: "Display — Hero text, onboarding"),
    TypeScaleToken(id: "h1",      name: "h1",      size: 28, weight: .regular,
                   sample: "Heading 1 — Screen titles"),
    TypeScaleToken(id: "h2",      name: "h2",      size: 22, weight: .medium,
                   sample: "Heading 2 — Section headers"),
    TypeScaleToken(id: "body",    name: "body",    size: 17, weight: .regular,
                   sample: "Body — Primary content text"),
    TypeScaleToken(id: "caption", name: "caption", size: 13, weight: .regular,
                   sample: "Caption — Timestamps, metadata"),
]

// MARK: - SpacingToken

struct SpacingToken: Identifiable {
    let id: String
    let name: String
    let value: CGFloat
}

private let wsSpacingTokens: [SpacingToken] = [
    SpacingToken(id: "xs",  name: "xs",  value: 4),
    SpacingToken(id: "sm",  name: "sm",  value: 8),
    SpacingToken(id: "md",  name: "md",  value: 16),
    SpacingToken(id: "lg",  name: "lg",  value: 32),
    SpacingToken(id: "xl",  name: "xl",  value: 64),
    SpacingToken(id: "xxl", name: "xxl", value: 96),
]

// MARK: - RadiusToken

struct RadiusToken: Identifiable {
    let id: String
    let name: String
    let value: CGFloat
}

private let wsRadiusTokens: [RadiusToken] = [
    RadiusToken(id: "small",  name: "small",  value: 4),
    RadiusToken(id: "medium", name: "medium", value: 6),
    RadiusToken(id: "card",   name: "card",   value: 12),
    RadiusToken(id: "badge",  name: "badge",  value: 20),
]

// MARK: - ShadowToken

struct ShadowToken: Identifiable {
    let id: String
    let name: String
    let radius: CGFloat
    let y: CGFloat
    let opacity: Double
}

private let shadowTokens: [ShadowToken] = [
    ShadowToken(id: "low",    name: "low",    radius: 4,  y: 2,  opacity: 0.08),
    ShadowToken(id: "medium", name: "medium", radius: 8,  y: 4,  opacity: 0.12),
    ShadowToken(id: "high",   name: "high",   radius: 16, y: 8,  opacity: 0.16),
]

// MARK: - TokenInspectorView

/// Dedicated Token Inspector sidebar section (NP-2, Q4 Option A fast-path).
///
/// Renders the catalog's brand tokens:
///   - Colors:     swatch grid with hex + token name
///   - Typography: text samples at each type scale
///   - Spacing:    horizontal ruler bars with pt labels
///   - Radius:     rounded rect samples
///   - Shadows:    card samples at each elevation
///
/// Q3: renders ONLY the catalog's brand; no cross-brand side-by-side.
public struct TokenInspectorView: View {
    public let brand: TokenBrand

    public init(brand: TokenBrand) {
        self.brand = brand
    }

    // Resolve color tokens per brand
    private var colorTokens: [ColorToken] {
        switch brand {
        case .sigma:    SigmaTokens.colors
        case .wabiSabi: WSTokens.colors
        case .obyw:     OBYWTokens.colors
        }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Token Inspector")
                        .font(.largeTitle.bold())
                    Text("\(brand.displayName) brand · \(colorTokens.count) color tokens")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 12)

                Divider()
                    .padding(.horizontal, 24)

                // Colors section
                tokenSection(title: "Colors", systemImage: "paintpalette") {
                    colorSwatchGrid
                }

                Divider()
                    .padding(.horizontal, 24)

                // Typography section
                tokenSection(title: "Typography", systemImage: "textformat") {
                    typographySection
                }

                Divider()
                    .padding(.horizontal, 24)

                // Spacing section
                tokenSection(title: "Spacing", systemImage: "arrow.left.and.right") {
                    spacingSection
                }

                Divider()
                    .padding(.horizontal, 24)

                // Radius section
                tokenSection(title: "Corner Radius", systemImage: "rectangle.roundedtop") {
                    radiusSection
                }

                Divider()
                    .padding(.horizontal, 24)

                // Shadows section
                tokenSection(title: "Shadows", systemImage: "shadow") {
                    shadowSection
                }

                Spacer(minLength: 32)
            }
        }
        .navigationTitle("Token Inspector — \(brand.displayName)")
    }

    // MARK: Section wrapper

    @ViewBuilder
    private func tokenSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.primary)
            content()
        }
        .padding(24)
    }

    // MARK: Colors

    @ViewBuilder
    private var colorSwatchGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 140, maximum: 200))],
            alignment: .leading,
            spacing: 10
        ) {
            ForEach(colorTokens) { token in
                ColorSwatchCell(token: token)
            }
        }
    }

    // MARK: Typography

    @ViewBuilder
    private var typographySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(sigmaTypeScale) { scale in
                VStack(alignment: .leading, spacing: 2) {
                    Text(scale.sample)
                        .font(.system(size: scale.size, weight: scale.weight))
                    Text("\(scale.name) · \(Int(scale.size))pt")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: Spacing

    @ViewBuilder
    private var spacingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(wsSpacingTokens) { token in
                HStack(spacing: 12) {
                    Text(token.name)
                        .font(.caption.monospaced())
                        .frame(width: 40, alignment: .leading)
                        .foregroundStyle(.secondary)
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.6))
                        .frame(width: token.value, height: 12)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                    Text("\(Int(token.value))pt")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: Radius

    @ViewBuilder
    private var radiusSection: some View {
        HStack(alignment: .bottom, spacing: 16) {
            ForEach(wsRadiusTokens) { token in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: token.value)
                        .fill(Color.accentColor.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: token.value)
                                .stroke(Color.accentColor.opacity(0.5), lineWidth: 1.5)
                        )
                        .frame(width: 64, height: 48)
                    Text(token.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(Int(token.value))pt")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: Shadows

    @ViewBuilder
    private var shadowSection: some View {
        HStack(alignment: .bottom, spacing: 20) {
            ForEach(shadowTokens) { token in
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.background)
                        .frame(width: 80, height: 60)
                        .shadow(color: .black.opacity(token.opacity), radius: token.radius, y: token.y)
                    Text(token.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("r:\(Int(token.radius)) y:\(Int(token.y))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - ColorSwatchCell

struct ColorSwatchCell: View {
    let token: ColorToken

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 6)
                .fill(token.color)
                .frame(height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
            Text(token.name)
                .font(.caption2.monospaced())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("#\(token.hex)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
