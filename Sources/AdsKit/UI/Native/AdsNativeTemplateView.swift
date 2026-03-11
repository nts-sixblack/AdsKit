@preconcurrency import GoogleMobileAds
import UIKit

final class AdsNativeTemplateView: NativeAdView {
    var onCollapse: (() -> Void)?

    private let style: NativeAdViewStyle
    private let theme: AdsTheme

    private let backgroundCard = UIView()
    private let headerIconImageView = UIImageView()
    private let mediaAssetView = MediaView()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let advertiserLabel = UILabel()
    private let storeLabel = UILabel()
    private let priceLabel = UILabel()
    private let starRatingLabel = UILabel()
    private let callToActionButton = UIButton(type: .system)
    private let adTagLabel = PaddingLabel()
    private let closeButton = UIButton(type: .system)
    private let overlayView = UIView()

    private var collapsibleViews: [UIView] = []
    private var isCollapsed = false

    init(style: NativeAdViewStyle, theme: AdsTheme) {
        self.style = style
        self.theme = theme
        super.init(frame: .zero)
        setupBase()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateCollapseVisibility() {
        let isCollapseStyle: Bool
        if case .collapse = style {
            isCollapseStyle = true
        } else {
            isCollapseStyle = false
        }

        closeButton.isHidden = !isCollapseStyle
        collapsibleViews.forEach { $0.isHidden = isCollapseStyle && isCollapsed }
    }

    private func setupBase() {
        backgroundColor = .clear
        clipsToBounds = false

        backgroundCard.backgroundColor = style == .largeGray ? theme.mutedBackgroundColor : theme.cardBackgroundColor
        backgroundCard.layer.cornerRadius = CGFloat(theme.largeCornerRadius)
        backgroundCard.layer.borderWidth = 1
        backgroundCard.layer.borderColor = theme.borderColor.cgColor
        addSubview(backgroundCard)
        backgroundCard.adsPinEdges(to: self)

        adTagLabel.text = theme.adBadgeText
        adTagLabel.font = theme.font(size: 10, weight: .semibold)
        adTagLabel.textColor = theme.accentTextColor
        adTagLabel.backgroundColor = theme.accentColor
        adTagLabel.layer.cornerRadius = CGFloat(theme.smallCornerRadius)
        adTagLabel.clipsToBounds = true

        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = theme.primaryTextColor
        closeButton.addTarget(self, action: #selector(handleCollapse), for: .touchUpInside)

        headerIconImageView.contentMode = .scaleAspectFill
        headerIconImageView.layer.cornerRadius = CGFloat(theme.smallCornerRadius)
        headerIconImageView.clipsToBounds = true
        headerIconImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        headerIconImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true

        mediaAssetView.contentMode = .scaleAspectFit
        mediaAssetView.clipsToBounds = true

        headlineLabel.font = theme.font(size: 16, weight: .semibold)
        headlineLabel.textColor = theme.primaryTextColor
        headlineLabel.numberOfLines = 2

        bodyLabel.font = theme.font(size: 14, weight: .regular)
        bodyLabel.textColor = theme.secondaryTextColor
        bodyLabel.numberOfLines = 3

        advertiserLabel.font = theme.font(size: 13, weight: .regular)
        advertiserLabel.textColor = theme.secondaryTextColor
        advertiserLabel.numberOfLines = 1

        storeLabel.font = theme.font(size: 13, weight: .regular)
        storeLabel.textColor = theme.secondaryTextColor
        storeLabel.numberOfLines = 1

        priceLabel.font = theme.font(size: 13, weight: .regular)
        priceLabel.textColor = theme.secondaryTextColor
        priceLabel.numberOfLines = 1

        starRatingLabel.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        starRatingLabel.textColor = theme.accentColor
        starRatingLabel.numberOfLines = 1

        configureButton(callToActionButton, filled: style.usesFilledCTA)
    }

    private func setupLayout() {
        let contentView: UIView
        switch style {
        case .overlay:
            contentView = makeOverlayLayout()
        case .fullScreen, .large, .largeGray, .video, .collapse:
            contentView = makeLargeLayout()
        case .medium:
            contentView = makeMediumLayout()
        case .mediumMedia:
            contentView = makeMediumMediaLayout()
        case .smallMedia:
            contentView = makeSmallMediaLayout()
        case .iconMedia:
            contentView = makeIconMediaLayout()
        case .banner:
            contentView = makeBannerLayout()
        case .basic:
            contentView = makeBasicLayout()
        }

        backgroundCard.addSubview(contentView)
        contentView.adsPinEdges(
            to: backgroundCard,
            insets: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        )

        backgroundCard.addSubview(adTagLabel)
        adTagLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            adTagLabel.topAnchor.constraint(equalTo: backgroundCard.topAnchor, constant: 8),
            adTagLabel.leadingAnchor.constraint(equalTo: backgroundCard.leadingAnchor, constant: 8)
        ])

        backgroundCard.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: backgroundCard.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: backgroundCard.trailingAnchor, constant: -8),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28)
        ])

        iconView = headerIconImageView
        mediaView = mediaAssetView
        headlineView = headlineLabel
        bodyView = bodyLabel
        advertiserView = advertiserLabel
        storeView = storeLabel
        priceView = priceLabel
        starRatingView = starRatingLabel
        callToActionView = callToActionButton

        updateCollapseVisibility()
    }

    private func makeBasicLayout() -> UIView {
        let textStack = verticalStack([
            headlineLabel,
            bodyLabel
        ], spacing: 4)
        let row = horizontalStack([
            headerIconImageView,
            textStack,
            callToActionButton
        ], spacing: 12, alignment: .center)
        return row
    }

    private func makeBannerLayout() -> UIView {
        let textStack = verticalStack([
            headlineLabel,
            bodyLabel
        ], spacing: 4)
        let row = horizontalStack([
            textStack,
            callToActionButton
        ], spacing: 12, alignment: .center)
        return row
    }

    private func makeMediumLayout() -> UIView {
        let textStack = verticalStack([
            headlineLabel,
            advertiserLabel,
            bodyLabel
        ], spacing: 4)
        let topRow = horizontalStack([
            headerIconImageView,
            textStack
        ], spacing: 12, alignment: .top)
        let stack = verticalStack([
            topRow,
            callToActionButton
        ], spacing: 12)
        return stack
    }

    private func makeMediumMediaLayout() -> UIView {
        mediaAssetView.heightAnchor.constraint(equalToConstant: 110).isActive = true
        mediaAssetView.widthAnchor.constraint(equalToConstant: 132).isActive = true
        let detailStack = verticalStack([
            headlineLabel,
            advertiserLabel,
            bodyLabel,
            callToActionButton
        ], spacing: 4)
        return horizontalStack([
            mediaAssetView,
            detailStack
        ], spacing: 12, alignment: .center)
    }

    private func makeSmallMediaLayout() -> UIView {
        mediaAssetView.heightAnchor.constraint(equalToConstant: 130).isActive = true
        let stack = verticalStack([
            mediaAssetView,
            headlineLabel,
            bodyLabel,
            callToActionButton
        ], spacing: 10)
        return stack
    }

    private func makeIconMediaLayout() -> UIView {
        mediaAssetView.heightAnchor.constraint(equalToConstant: 140).isActive = true
        let header = horizontalStack([
            headerIconImageView,
            headlineLabel
        ], spacing: 10, alignment: .center)
        let stack = verticalStack([
            header,
            mediaAssetView,
            bodyLabel,
            callToActionButton
        ], spacing: 10)
        return stack
    }

    private func makeLargeLayout() -> UIView {
        mediaAssetView.heightAnchor.constraint(greaterThanOrEqualToConstant: 140).isActive = true
        let metaRow = horizontalStack([
            advertiserLabel,
            starRatingLabel
        ], spacing: 8, alignment: .center)
        let storeRow = horizontalStack([
            storeLabel,
            priceLabel
        ], spacing: 8, alignment: .center)
        let header = horizontalStack([
            headerIconImageView,
            verticalStack([
                headlineLabel,
                metaRow
            ], spacing: 4)
        ], spacing: 12, alignment: .top)
        let stack = verticalStack([
            header,
            mediaAssetView,
            bodyLabel,
            storeRow,
            callToActionButton
        ], spacing: 10)
        collapsibleViews = [
            mediaAssetView,
            bodyLabel,
            storeLabel,
            priceLabel,
            advertiserLabel,
            starRatingLabel
        ]
        return stack
    }

    private func makeOverlayLayout() -> UIView {
        mediaAssetView.heightAnchor.constraint(greaterThanOrEqualToConstant: 180).isActive = true

        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        overlayView.layer.cornerRadius = CGFloat(theme.mediumCornerRadius)

        let overlayStack = verticalStack([
            headlineLabel,
            bodyLabel,
            callToActionButton
        ], spacing: 6)
        overlayView.addSubview(overlayStack)
        overlayStack.adsPinEdges(
            to: overlayView,
            insets: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        )

        let container = UIView()
        container.addSubview(mediaAssetView)
        mediaAssetView.adsPinEdges(to: container)
        container.addSubview(overlayView)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            overlayView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            overlayView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        return container
    }

    private func configureButton(_ button: UIButton, filled: Bool) {
        button.titleLabel?.font = theme.font(size: 15, weight: .bold)
        button.layer.cornerRadius = CGFloat(theme.mediumCornerRadius)
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        button.clipsToBounds = true
        button.setTitleColor(theme.accentTextColor, for: .normal)

        if filled {
            button.backgroundColor = theme.accentColor
        } else {
            button.backgroundColor = theme.mutedBackgroundColor
            button.setTitleColor(theme.primaryTextColor, for: .normal)
        }
    }

    @objc private func handleCollapse() {
        isCollapsed.toggle()
        updateCollapseVisibility()
        onCollapse?()
    }

    private func verticalStack(
        _ arrangedSubviews: [UIView],
        spacing: CGFloat
    ) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: arrangedSubviews)
        stack.axis = .vertical
        stack.spacing = spacing
        return stack
    }

    private func horizontalStack(
        _ arrangedSubviews: [UIView],
        spacing: CGFloat,
        alignment: UIStackView.Alignment
    ) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: arrangedSubviews)
        stack.axis = .horizontal
        stack.spacing = spacing
        stack.alignment = alignment
        return stack
    }
}
