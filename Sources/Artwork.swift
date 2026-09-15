// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 hikmetozcann and contributors
import SwiftUI

/// Original vector illustration. No vendor photography or logo is bundled.
struct EarbudsArtwork: View {
    var body: some View {
        ZStack {
            Ellipse().fill(.black.opacity(0.10)).frame(width: 115, height: 12).blur(radius: 7).offset(y: 51)
            bud.rotationEffect(.degrees(-19)).offset(x: -31, y: -10)
            bud.scaleEffect(x: -1, y: 1).rotationEffect(.degrees(19)).offset(x: 33, y: 9)
        }.frame(width: 157, height: 132).accessibilityHidden(true)
    }
    private var bud: some View {
        ZStack {
            Capsule().fill(LinearGradient(colors: [Color(white: 0.97), Color(white: 0.72), Color(white: 0.91)], startPoint: .leading, endPoint: .trailing))
                .frame(width: 19, height: 70).offset(x: 5, y: 16)
                .overlay(Capsule().fill(Color(white: 0.36)).frame(width: 9, height: 3).offset(x: 5, y: 46))
            Ellipse().fill(LinearGradient(colors: [.white, Color(white: 0.78)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 49, height: 52).rotationEffect(.degrees(-22)).offset(y: -17)
            Ellipse().fill(LinearGradient(colors: [Color(white: 0.99), Color(white: 0.64)], startPoint: .top, endPoint: .bottom))
                .frame(width: 23, height: 30).rotationEffect(.degrees(-25)).offset(x: -21, y: -10)
            Ellipse().fill(Color(white: 0.29)).frame(width: 8, height: 15).rotationEffect(.degrees(-25)).offset(x: -23, y: -10)
            Capsule().fill(Color(white: 0.28)).frame(width: 18, height: 3).rotationEffect(.degrees(-22)).offset(x: 0, y: -36)
            Capsule().fill(.white.opacity(0.65)).frame(width: 3, height: 33).offset(x: 1, y: 21)
        }.shadow(color: .black.opacity(0.14), radius: 5, x: 2, y: 4)
    }
}
