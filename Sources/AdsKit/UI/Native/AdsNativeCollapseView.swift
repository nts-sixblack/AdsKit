@preconcurrency import GoogleMobileAds
import UIKit

final class AdsNativeCollapseView: NativeAdView {
    private static let collapseChevronAssetNames = ["down-arrow", "AdsNativeCollapseChevron"]

    var onCollapse: (() -> Void)?

    private var theme: AdsTheme
    private var collapseButtonConfiguration: AdsCollapseButtonConfiguration

    private let backgroundCard = UIView()
    private let mediaContainerView = UIView()
    private let mediaAssetView = MediaView()
    private let collapseButton = UIButton(type: .custom)
    private let collapseButtonBackground = UIView()
    private let collapseButtonIconView = UIImageView()
    private let floatingAdTagLabel = PaddingLabel()
    private let expandedAdTagLabel = PaddingLabel()
    private let expandedHeadlineLabel = UILabel()
    private let expandedCallToActionButton = UIButton(type: .system)
    private let collapsedMediaAssetView = MediaView()
    private let collapsedIconImageView = UIImageView()
    private let collapsedHeadlineLabel = UILabel()
    private let collapsedBodyLabel = UILabel()
    private let collapsedCallToActionButton = UIButton(type: .system)

    private let rootStack = UIStackView()
    private let expandedBottomStack = UIStackView()
    private let collapsedBottomStack = UIStackView()

    private var appliedNativeAd: NativeAd?
    private var hasPrimaryMediaAsset = false
    private var collapseButtonIconWidthConstraint: NSLayoutConstraint?
    private var collapseButtonIconHeightConstraint: NSLayoutConstraint?

    init(theme: AdsTheme) {
        self.theme = theme
        self.collapseButtonConfiguration = theme.resolvedCollapseButton
        super.init(frame: .zero)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(nativeAd: NativeAd) {
        guard nativeAd !== appliedNativeAd else { return }
        appliedNativeAd = nativeAd

        populateContent(with: nativeAd)
        hasPrimaryMediaAsset = AdsNativeMediaSupport.hasPrimaryMedia(in: nativeAd.mediaContent)

        if hasPrimaryMediaAsset {
            showExpandedState()
        } else {
            showCompactState()
            DispatchQueue.main.async { [weak self] in
                self?.onCollapse?()
            }
        }

        updateAdRegistration()
    }

    func apply(theme: AdsTheme) {
        self.theme = theme
        collapseButtonConfiguration = theme.resolvedCollapseButton
        refreshTheme()
    }

    private func setupViews() {
        backgroundColor = .clear
        clipsToBounds = false

        addSubview(backgroundCard)
        backgroundCard.adsPinEdges(to: self)

        configureAdTag(floatingAdTagLabel)
        configureAdTag(expandedAdTagLabel)
        setupAdTagLayout(floatingAdTagLabel)
        setupAdTagLayout(expandedAdTagLabel)

        mediaAssetView.contentMode = .scaleAspectFill
        mediaAssetView.clipsToBounds = true
        mediaContainerView.addSubview(mediaAssetView)
        mediaAssetView.adsPinEdges(to: mediaContainerView)
        mediaContainerView.heightAnchor.constraint(
            equalTo: mediaContainerView.widthAnchor,
            multiplier: 0.6
        ).isActive = true

        collapseButton.addTarget(self, action: #selector(handleCollapse), for: .touchUpInside)
        collapseButton.translatesAutoresizingMaskIntoConstraints = false

        collapseButtonBackground.isUserInteractionEnabled = false
        collapseButton.insertSubview(collapseButtonBackground, at: 0)
        collapseButtonBackground.translatesAutoresizingMaskIntoConstraints = false

        collapseButtonIconView.isUserInteractionEnabled = false
        collapseButtonIconView.contentMode = .scaleAspectFit
        collapseButtonIconView.translatesAutoresizingMaskIntoConstraints = false
        collapseButton.addSubview(collapseButtonIconView)

        mediaContainerView.addSubview(collapseButton)
        collapseButtonIconWidthConstraint = collapseButtonIconView.widthAnchor.constraint(
            equalToConstant: collapseButtonIconDisplaySize()
        )
        collapseButtonIconHeightConstraint = collapseButtonIconView.heightAnchor.constraint(
            equalToConstant: collapseButtonIconDisplaySize()
        )

        NSLayoutConstraint.activate([
            collapseButton.topAnchor.constraint(
                equalTo: mediaContainerView.topAnchor,
                constant: CGFloat(collapseButtonConfiguration.topInset)
            ),
            collapseButton.trailingAnchor.constraint(
                equalTo: mediaContainerView.trailingAnchor,
                constant: -CGFloat(collapseButtonConfiguration.trailingInset)
            ),
            collapseButton.widthAnchor.constraint(equalToConstant: CGFloat(collapseButtonConfiguration.touchTargetSize)),
            collapseButton.heightAnchor.constraint(equalToConstant: CGFloat(collapseButtonConfiguration.touchTargetSize)),
            collapseButtonBackground.centerXAnchor.constraint(equalTo: collapseButton.centerXAnchor),
            collapseButtonBackground.centerYAnchor.constraint(equalTo: collapseButton.centerYAnchor),
            collapseButtonBackground.widthAnchor.constraint(equalToConstant: CGFloat(collapseButtonConfiguration.visualSize)),
            collapseButtonBackground.heightAnchor.constraint(equalToConstant: CGFloat(collapseButtonConfiguration.visualSize)),
            collapseButtonIconView.centerXAnchor.constraint(equalTo: collapseButton.centerXAnchor),
            collapseButtonIconView.centerYAnchor.constraint(equalTo: collapseButton.centerYAnchor),
            collapseButtonIconWidthConstraint!,
            collapseButtonIconHeightConstraint!
        ])

        expandedHeadlineLabel.numberOfLines = 1

        configureCallToActionButton(expandedCallToActionButton, fontSize: 16)
        setupCallToActionButtonLayout(expandedCallToActionButton)

        collapsedIconImageView.contentMode = .scaleAspectFit
        collapsedIconImageView.clipsToBounds = true
        collapsedIconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collapsedIconImageView.widthAnchor.constraint(equalToConstant: 40),
            collapsedIconImageView.heightAnchor.constraint(equalToConstant: 40)
        ])

        collapsedMediaAssetView.contentMode = .scaleAspectFill
        collapsedMediaAssetView.clipsToBounds = true
        collapsedMediaAssetView.isHidden = true
        collapsedMediaAssetView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collapsedMediaAssetView.widthAnchor.constraint(equalToConstant: 56),
            collapsedMediaAssetView.heightAnchor.constraint(equalToConstant: 56)
        ])

        collapsedHeadlineLabel.numberOfLines = 1

        collapsedBodyLabel.numberOfLines = 2

        configureCallToActionButton(collapsedCallToActionButton, fontSize: 14)
        setupCallToActionButtonLayout(collapsedCallToActionButton)
        collapsedCallToActionButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24)

        let expandedTitleRow = horizontalStack(
            arrangedSubviews: [expandedAdTagLabel, expandedHeadlineLabel],
            spacing: 6,
            alignment: .center
        )
        expandedBottomStack.axis = .vertical
        expandedBottomStack.spacing = 4
        expandedBottomStack.addArrangedSubview(expandedTitleRow)
        expandedBottomStack.addArrangedSubview(expandedCallToActionButton)
        expandedBottomStack.isLayoutMarginsRelativeArrangement = true
        expandedBottomStack.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        let collapsedTextStack = verticalStack(
            arrangedSubviews: [collapsedHeadlineLabel, collapsedBodyLabel],
            spacing: 2
        )
        collapsedBottomStack.axis = .horizontal
        collapsedBottomStack.spacing = 12
        collapsedBottomStack.alignment = .center
        collapsedBottomStack.addArrangedSubview(collapsedMediaAssetView)
        collapsedBottomStack.addArrangedSubview(collapsedIconImageView)
        collapsedBottomStack.addArrangedSubview(collapsedTextStack)
        collapsedBottomStack.addArrangedSubview(collapsedCallToActionButton)
        collapsedBottomStack.isLayoutMarginsRelativeArrangement = true
        collapsedBottomStack.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        collapsedBottomStack.isHidden = true

        rootStack.axis = .vertical
        rootStack.spacing = 0
        rootStack.addArrangedSubview(mediaContainerView)
        rootStack.addArrangedSubview(expandedBottomStack)
        rootStack.addArrangedSubview(collapsedBottomStack)

        backgroundCard.addSubview(rootStack)
        rootStack.adsPinEdges(to: backgroundCard)

        backgroundCard.addSubview(floatingAdTagLabel)
        floatingAdTagLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            floatingAdTagLabel.topAnchor.constraint(equalTo: backgroundCard.topAnchor, constant: 8),
            floatingAdTagLabel.leadingAnchor.constraint(equalTo: backgroundCard.leadingAnchor, constant: 8)
        ])
        floatingAdTagLabel.isHidden = true

        refreshTheme()
    }

    private func configureAdTag(_ label: PaddingLabel) {
        label.text = theme.adBadgeText
        label.font = theme.font(size: 10, weight: .semibold)
        label.textColor = theme.accentTextColor
        label.backgroundColor = theme.accentColor
        label.textAlignment = .center
        label.layer.cornerRadius = CGFloat(theme.smallCornerRadius)
        label.clipsToBounds = true
        label.topInset = 1
        label.bottomInset = 1
        label.leftInset = 5
        label.rightInset = 5
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func setupAdTagLayout(_ label: PaddingLabel) {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(equalToConstant: 16).isActive = true
        label.widthAnchor.constraint(greaterThanOrEqualToConstant: 24).isActive = true
    }

    private func configureCallToActionButton(_ button: UIButton, fontSize: CGFloat) {
        button.titleLabel?.font = theme.font(size: fontSize, weight: .bold)
        button.setTitleColor(theme.accentTextColor, for: .normal)
        button.backgroundColor = theme.accentColor
        button.layer.cornerRadius = 24
        button.clipsToBounds = true
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func setupCallToActionButtonLayout(_ button: UIButton) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }

    private func refreshTheme() {
        backgroundCard.backgroundColor = theme.cardBackgroundColor
        backgroundCard.layer.cornerRadius = CGFloat(theme.largeCornerRadius)
        backgroundCard.layer.borderWidth = 1
        backgroundCard.layer.borderColor = theme.borderColor.cgColor

        configureAdTag(floatingAdTagLabel)
        configureAdTag(expandedAdTagLabel)

        expandedHeadlineLabel.font = theme.font(size: 15, weight: .medium)
        expandedHeadlineLabel.textColor = theme.primaryTextColor

        collapsedHeadlineLabel.font = theme.font(size: 15, weight: .bold)
        collapsedHeadlineLabel.textColor = theme.primaryTextColor

        collapsedBodyLabel.font = theme.font(size: 14, weight: .regular)
        collapsedBodyLabel.textColor = theme.secondaryTextColor

        configureCallToActionButton(expandedCallToActionButton, fontSize: 16)
        configureCallToActionButton(collapsedCallToActionButton, fontSize: 14)

        collapsedIconImageView.layer.cornerRadius = CGFloat(theme.smallCornerRadius)
        collapsedMediaAssetView.layer.cornerRadius = CGFloat(theme.mediumCornerRadius)

        let iconColor = UIColor(hex: collapseButtonConfiguration.iconHex)
        let buttonImage = collapseButtonImage()
        collapseButton.adjustsImageWhenHighlighted = false
        collapseButton.tintColor = iconColor
        collapseButtonIconView.tintColor = iconColor
        collapseButtonIconView.image = buttonImage
        collapseButtonIconWidthConstraint?.constant = collapseButtonIconDisplaySize()
        collapseButtonIconHeightConstraint?.constant = collapseButtonIconDisplaySize()
        collapseButton.bringSubviewToFront(collapseButtonIconView)

        collapseButtonBackground.backgroundColor = UIColor(hex: collapseButtonConfiguration.backgroundHex)
        collapseButtonBackground.layer.cornerRadius = CGFloat(collapseButtonConfiguration.visualSize) / 2
        collapseButtonBackground.layer.borderWidth = 1
        collapseButtonBackground.layer.borderColor = UIColor(hex: collapseButtonConfiguration.borderHex)
            .withAlphaComponent(collapseButtonConfiguration.borderOpacity)
            .cgColor
    }

    private func collapseButtonImage() -> UIImage? {
        for assetName in Self.collapseChevronAssetNames {
            if let assetImage = AdsKitImageAsset.image(
                named: assetName,
                compatibleWith: traitCollection
            ) {
                return assetImage.withRenderingMode(.alwaysTemplate)
            }
        }

        let symbolConfig = UIImage.SymbolConfiguration(
            pointSize: collapseButtonIconDisplaySize(),
            weight: .bold
        )
        return UIImage(
            systemName: collapseButtonConfiguration.symbolName,
            withConfiguration: symbolConfig
        )?.withRenderingMode(.alwaysTemplate)
    }

    private func collapseButtonIconDisplaySize() -> CGFloat {
        let requestedSize = CGFloat(collapseButtonConfiguration.iconPointSize) + 2
        let maxAllowedSize = max(0, CGFloat(collapseButtonConfiguration.visualSize) - 8)
        return min(requestedSize, maxAllowedSize)
    }

    private func populateContent(with nativeAd: NativeAd) {
        expandedHeadlineLabel.text = nativeAd.headline
        expandedCallToActionButton.setTitle(nativeAd.callToAction, for: .normal)
        expandedCallToActionButton.isHidden = nativeAd.callToAction == nil

        collapsedHeadlineLabel.text = nativeAd.headline
        collapsedBodyLabel.text = nativeAd.body
        collapsedBodyLabel.isHidden = nativeAd.body == nil
        collapsedCallToActionButton.setTitle(nativeAd.callToAction, for: .normal)
        collapsedCallToActionButton.isHidden = nativeAd.callToAction == nil
        collapsedIconImageView.image = nativeAd.icon?.image

        mediaAssetView.mediaContent = nativeAd.mediaContent
        collapsedMediaAssetView.mediaContent = nativeAd.mediaContent
    }

    private func showExpandedState() {
        mediaContainerView.isHidden = false
        mediaContainerView.alpha = 1
        mediaAssetView.isHidden = false
        mediaAssetView.alpha = 1
        expandedBottomStack.isHidden = false
        expandedBottomStack.alpha = 1
        collapsedBottomStack.isHidden = true
        collapsedBottomStack.alpha = 0
        floatingAdTagLabel.isHidden = true
        collapsedMediaAssetView.isHidden = true
        collapsedMediaAssetView.alpha = 0
        collapsedIconImageView.isHidden = true

        headlineView = expandedHeadlineLabel
        bodyView = nil
        callToActionView = expandedCallToActionButton.isHidden ? nil : expandedCallToActionButton
        iconView = nil
        mediaView = mediaAssetView
    }

    private func showCompactState() {
        mediaAssetView.isHidden = true
        mediaAssetView.alpha = 0
        mediaContainerView.isHidden = true
        mediaContainerView.alpha = 0
        expandedBottomStack.isHidden = true
        expandedBottomStack.alpha = 0
        collapsedBottomStack.isHidden = false
        collapsedBottomStack.alpha = 1
        floatingAdTagLabel.isHidden = false
        collapsedMediaAssetView.isHidden = !hasPrimaryMediaAsset
        collapsedMediaAssetView.alpha = hasPrimaryMediaAsset ? 1 : 0
        collapsedIconImageView.isHidden = hasPrimaryMediaAsset || collapsedIconImageView.image == nil

        headlineView = collapsedHeadlineLabel
        bodyView = collapsedBodyLabel.isHidden ? nil : collapsedBodyLabel
        callToActionView = collapsedCallToActionButton.isHidden ? nil : collapsedCallToActionButton
        iconView = collapsedIconImageView.isHidden ? nil : collapsedIconImageView
        mediaView = hasPrimaryMediaAsset ? collapsedMediaAssetView : nil
    }

    private func updateAdRegistration() {
        guard let appliedNativeAd else { return }
        super.nativeAd = appliedNativeAd
    }

    @objc private func handleCollapse() {
        guard hasPrimaryMediaAsset else { return }

        collapsedMediaAssetView.isHidden = false
        collapsedIconImageView.isHidden = true
        collapsedBottomStack.isHidden = false
        collapsedBottomStack.alpha = 0

        UIView.animate(
            withDuration: 0.3,
            animations: {
                self.mediaContainerView.alpha = 0
                self.expandedBottomStack.isHidden = true
                self.expandedBottomStack.alpha = 0
                self.collapsedBottomStack.alpha = 1
                self.floatingAdTagLabel.isHidden = false
                self.layoutIfNeeded()
            },
            completion: { _ in
                self.showCompactState()
                self.updateAdRegistration()
                self.onCollapse?()
            }
        )
    }

    private func verticalStack(
        arrangedSubviews: [UIView],
        spacing: CGFloat
    ) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: arrangedSubviews)
        stack.axis = .vertical
        stack.spacing = spacing
        return stack
    }

    private func horizontalStack(
        arrangedSubviews: [UIView],
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
