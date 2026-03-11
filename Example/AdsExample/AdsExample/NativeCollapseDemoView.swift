//
//  NativeCollapseDemoView.swift
//  AdsExample
//

import AdsKit
import SwiftInjected
import SwiftUI

struct NativeCollapseDemoView: View {
  @InjectedObservable var adsManager: AdsKitManager

  @State private var isAdLoaded = false

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          VStack(alignment: .leading, spacing: 8) {
            Text("Collapse Native Ad")
              .font(.title2.bold())

            Text("This example follows the production pattern: the page reserves a fixed spacer and renders the collapse native ad as a bottom overlay.")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }

          ForEach(0..<8, id: \.self) { index in
            VStack(alignment: .leading, spacing: 8) {
              Text("Demo Card \(index + 1)")
                .font(.headline)

              Text("Scrollable content sits above the overlay ad. When the native ad loads, the spacer keeps the bottom area stable while the ad expands and collapses over it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
          }

          CollapseAdsEmptyView(
            slotKey: "demo_native",
            manager: adsManager,
            height: 80,
            isVisible: $isAdLoaded
          )
        }
        .padding(16)
      }
      .overlay(alignment: .bottom) {
        NativeAdsView(
          slotKey: "demo_native",
          manager: adsManager,
          style: .collapse,
          height: 80,
          onAdLoaded: $isAdLoaded
        )
      }
    }
    .navigationTitle("Native Collapse")
    .navigationBarTitleDisplayMode(.inline)
  }
}
