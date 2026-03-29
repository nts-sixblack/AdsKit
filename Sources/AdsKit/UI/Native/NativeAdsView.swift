import Combine
@preconcurrency import GoogleMobileAds
import SwiftUI

public struct CollapseAdsEmptyView: View {
    @ObservedObject private var manager: AdsKitManager
    private let slotKey: String
    private let height: CGFloat
    @Binding private var isVisible: Bool

    public init(
        slotKey: String,
        manager: AdsKitManager,
        height: CGFloat,
        isVisible: Binding<Bool>
    ) {
        self.slotKey = slotKey
        self.manager = manager
        self.height = height
        self._isVisible = isVisible
    }

    public var body: some View {
        if !isVisible || !manager.canDisplay(slotKey: slotKey) {
            EmptyView()
        } else {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: height)
        }
    }
}

public struct NativeAdsView: View {
    @ObservedObject private var manager: AdsKitManager
    private let slotKey: String
    private let style: NativeAdViewStyle
    private let height: CGFloat
    private let onAdLoaded: Binding<Bool>?
    private let showColorAtBottomSafeArea: Bool

    @StateObject private var observer = NativeAdObserver()
    @State private var isCollapsed = false

    public init(
        slotKey: String,
        manager: AdsKitManager,
        style: NativeAdViewStyle,
        height: CGFloat? = nil,
        onAdLoaded: Binding<Bool>? = nil,
        showColorAtBottomSafeArea: Bool = false
    ) {
        self.slotKey = slotKey
        self.manager = manager
        self.style = style
        self.height = height ?? style.suggestedHeight
        self.onAdLoaded = onAdLoaded
        self.showColorAtBottomSafeArea = showColorAtBottomSafeArea
    }

    private var viewModel: NativeAdViewModel? {
        manager.nativeViewModel(for: slotKey)
    }

    private var displayHeight: CGFloat {
        if case .collapse = style {
            guard hasLoadedPrimaryMedia else { return height }
            return isCollapsed ? height : calculateExpandedHeight()
        }
        return height
    }

    private var hasLoadedPrimaryMedia: Bool {
        AdsNativeMediaSupport.hasPrimaryMedia(in: observer.nativeAd?.mediaContent)
    }

    public var body: some View {
        VStack(spacing: 0) {
            if !manager.canDisplay(slotKey: slotKey) {
                EmptyView()
            } else if let viewModel, observer.nativeAd != nil {
                NativeAdsSwiftUIView(
                    nativeViewModel: viewModel,
                    style: style,
                    theme: manager.configuration.theme,
                    onCollapse: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isCollapsed = true
                        }
                    }
                )
                .frame(height: displayHeight)
                .background(Color(hex: manager.configuration.theme.cardBackgroundHex))
                .adsCornerRadius(
                    CGFloat(manager.configuration.theme.largeCornerRadius),
                    corners: showColorAtBottomSafeArea ? [.topLeft, .topRight] : .allCorners
                )
                .overlay {
                    RoundedRectangle(cornerRadius: CGFloat(manager.configuration.theme.largeCornerRadius))
                        .stroke(
                            Color(hex: manager.configuration.theme.borderHex)
                                .opacity(manager.configuration.theme.borderOpacity),
                            lineWidth: 1
                        )
                }

                if showColorAtBottomSafeArea {
                    Color(hex: manager.configuration.theme.cardBackgroundHex)
                        .frame(height: 1)
                }
            } else if observer.isLoading {
                AdsLoadingView(theme: manager.configuration.theme)
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .background(Color(hex: manager.configuration.theme.mutedBackgroundHex).opacity(0.4))
            } else {
                EmptyView()
            }
        }
        .onAppear {
            bindObserver()
            manager.refreshNative(slotKey: slotKey)
        }
        .onChange(of: observer.nativeAd.map(ObjectIdentifier.init)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                isCollapsed = false
            }
        }
        .onChange(of: observer.nativeAd != nil) { isLoaded in
            onAdLoaded?.wrappedValue = isLoaded
        }
        .onChange(of: observer.isLoading) { isLoading in
            if isLoading {
                onAdLoaded?.wrappedValue = true
            } else if observer.nativeAd == nil {
                onAdLoaded?.wrappedValue = false
            }
        }
    }

    private func bindObserver() {
        guard let viewModel else { return }
        observer.bind(to: viewModel)
    }

    private func calculateExpandedHeight() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let mediaHeight = (screenWidth - 32) * 0.66
        return height + mediaHeight + 24
    }
}

public struct PreloadedNativeAdsView: View {
    @ObservedObject private var manager: AdsKitManager
    private let slotKey: String
    private let style: NativeAdViewStyle
    private let height: CGFloat
    private let showBorder: Bool

    @StateObject private var observer = NativeAdObserver()
    @State private var isCollapsed = false

    public init(
        slotKey: String,
        manager: AdsKitManager,
        style: NativeAdViewStyle,
        height: CGFloat? = nil,
        showBorder: Bool = true
    ) {
        self.slotKey = slotKey
        self.manager = manager
        self.style = style
        self.height = height ?? style.suggestedHeight
        self.showBorder = showBorder
    }

    private var viewModel: NativeAdViewModel? {
        manager.nativeViewModel(for: slotKey)
    }

    private var displayHeight: CGFloat {
        if case .collapse = style {
            guard hasLoadedPrimaryMedia else { return height }
            return isCollapsed ? height : calculateExpandedHeight()
        }
        return height
    }

    private var hasLoadedPrimaryMedia: Bool {
        AdsNativeMediaSupport.hasPrimaryMedia(in: observer.nativeAd?.mediaContent)
    }

    public var body: some View {
        VStack {
            if !manager.canDisplay(slotKey: slotKey) {
                EmptyView()
            } else if let viewModel, observer.nativeAd != nil {
                NativeAdsSwiftUIView(
                    nativeViewModel: viewModel,
                    style: style,
                    theme: manager.configuration.theme,
                    onCollapse: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isCollapsed = true
                        }
                    }
                )
                .frame(height: displayHeight)
                .background(Color(hex: manager.configuration.theme.cardBackgroundHex))
                .adsCornerRadius(CGFloat(manager.configuration.theme.mediumCornerRadius), corners: .allCorners)
                .overlay {
                    RoundedRectangle(cornerRadius: CGFloat(manager.configuration.theme.mediumCornerRadius))
                        .stroke(
                            Color(hex: manager.configuration.theme.borderHex)
                                .opacity(showBorder ? manager.configuration.theme.borderOpacity : 0),
                            lineWidth: 1
                        )
                }
            } else if observer.isLoading {
                AdsLoadingView(theme: manager.configuration.theme)
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .background(Color(hex: manager.configuration.theme.mutedBackgroundHex).opacity(0.4))
            } else {
                EmptyView()
            }
        }
        .onAppear {
            guard let viewModel else { return }
            observer.bind(to: viewModel)
            manager.preloadNative(slotKey: slotKey)
        }
        .onChange(of: observer.nativeAd.map(ObjectIdentifier.init)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                isCollapsed = false
            }
        }
    }

    private func calculateExpandedHeight() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let mediaHeight = (screenWidth - 32) * 0.66
        return height + mediaHeight + 24
    }
}

@MainActor
final class NativeAdObserver: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var nativeAd: NativeAd?

    private var cancellables = Set<AnyCancellable>()

    func bind(to viewModel: NativeAdViewModel) {
        cancellables.removeAll()

        nativeAd = viewModel.nativeAd
        isLoading = viewModel.isLoading

        viewModel.$nativeAd.sink { [weak self] ad in
            self?.nativeAd = ad
        }
        .store(in: &cancellables)

        viewModel.$isLoading.sink { [weak self] isLoading in
            self?.isLoading = isLoading
        }
        .store(in: &cancellables)
    }
}
