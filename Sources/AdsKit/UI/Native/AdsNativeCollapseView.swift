@preconcurrency import GoogleMobileAds
import UIKit

final class AdsNativeCollapseView: NativeAdView {
    var onCollapse: (() -> Void)?

    private let theme: AdsTheme
    private let collapseButtonConfiguration: AdsCollapseButtonConfiguration

    private let backgroundCard = UIView()
    private let mediaContainerView = UIView()
    private let mediaAssetView = MediaView()
    private let collapseButton = UIButton(type: .system)
    private let collapseButtonBackground = UIView()
    private let floatingAdTagLabel = PaddingLabel()
    private let expandedAdTagLabel = PaddingLabel()
    private let expandedHeadlineLabel = UILabel()
    private let expandedCallToActionButton = UIButton(type: .system)
    private let collapsedIconImageView = UIImageView()
    private let collapsedHeadlineLabel = UILabel()
    private let collapsedBodyLabel = UILabel()
    private let collapsedCallToActionButton = UIButton(type: .system)

    private let rootStack = UIStackView()
    private let expandedBottomStack = UIStackView()
    private let collapsedBottomStack = UIStackView()

    private var appliedNativeAd: NativeAd?
    private var isMediaCollapsed = false
    private var isFullyCollapsed = false

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

        if hasMediaContent(nativeAd) {
            showExpandedState()
        } else {
            showCollapsedState()
            DispatchQueue.main.async { [weak self] in
                self?.onCollapse?()
            }
        }

        updateAdRegistration()
    }

    private func setupViews() {
        backgroundColor = .clear
        clipsToBounds = false

        backgroundCard.backgroundColor = theme.cardBackgroundColor
        backgroundCard.layer.cornerRadius = CGFloat(theme.largeCornerRadius)
        backgroundCard.layer.borderWidth = 1
        backgroundCard.layer.borderColor = theme.borderColor.cgColor
        addSubview(backgroundCard)
        backgroundCard.adsPinEdges(to: self)

        configureAdTag(floatingAdTagLabel)
        configureAdTag(expandedAdTagLabel)

        mediaAssetView.contentMode = .scaleAspectFill
        mediaAssetView.clipsToBounds = true
        mediaContainerView.addSubview(mediaAssetView)
        mediaAssetView.adsPinEdges(to: mediaContainerView)
        mediaContainerView.heightAnchor.constraint(
            equalTo: mediaContainerView.widthAnchor,
            multiplier: 0.6
        ).isActive = true

        let buttonConfig = UIImage.SymbolConfiguration(
            pointSize: CGFloat(collapseButtonConfiguration.iconPointSize),
            weight: .bold
        )
        collapseButton.setImage(
            UIImage(systemName: collapseButtonConfiguration.symbolName, withConfiguration: buttonConfig),
            for: .normal
        )
        collapseButton.tintColor = UIColor(hex: collapseButtonConfiguration.iconHex)
        collapseButton.addTarget(self, action: #selector(handleCollapse), for: .touchUpInside)
        collapseButton.translatesAutoresizingMaskIntoConstraints = false

        collapseButtonBackground.backgroundColor = UIColor(hex: collapseButtonConfiguration.backgroundHex)
        collapseButtonBackground.layer.cornerRadius = CGFloat(collapseButtonConfiguration.visualSize) / 2
        collapseButtonBackground.layer.borderWidth = 1
        collapseButtonBackground.layer.borderColor = UIColor(hex: collapseButtonConfiguration.borderHex)
            .withAlphaComponent(collapseButtonConfiguration.borderOpacity)
            .cgColor
        collapseButtonBackground.isUserInteractionEnabled = false
        collapseButton.insertSubview(collapseButtonBackground, at: 0)
        collapseButtonBackground.translatesAutoresizingMaskIntoConstraints = false

        mediaContainerView.addSubview(collapseButton)
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
            collapseButtonBackground.heightAnchor.constraint(equalToConstant: CGFloat(collapseButtonConfiguration.visualSize))
        ])

        expandedHeadlineLabel.font = theme.font(size: 15, weight: .medium)
        expandedHeadlineLabel.textColor = theme.primaryTextColor
        expandedHeadlineLabel.numberOfLines = 1

        configureCallToActionButton(expandedCallToActionButton, fontSize: 16)

        collapsedIconImageView.contentMode = .scaleAspectFit
        collapsedIconImageView.layer.cornerRadius = CGFloat(theme.smallCornerRadius)
        collapsedIconImageView.clipsToBounds = true
        collapsedIconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collapsedIconImageView.widthAnchor.constraint(equalToConstant: 40),
            collapsedIconImageView.heightAnchor.constraint(equalToConstant: 40)
        ])

        collapsedHeadlineLabel.font = theme.font(size: 15, weight: .bold)
        collapsedHeadlineLabel.textColor = theme.primaryTextColor
        collapsedHeadlineLabel.numberOfLines = 1

        collapsedBodyLabel.font = theme.font(size: 14, weight: .regular)
        collapsedBodyLabel.textColor = theme.secondaryTextColor
        collapsedBodyLabel.numberOfLines = 2

        configureCallToActionButton(collapsedCallToActionButton, fontSize: 14)
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
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .horizontal)
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
        collapsedIconImageView.isHidden = nativeAd.icon == nil

        mediaAssetView.mediaContent = nativeAd.mediaContent
    }

    private func hasMediaContent(_ nativeAd: NativeAd) -> Bool {
        let mediaContent = nativeAd.mediaContent
        return mediaContent.aspectRatio > 0 && (mediaContent.hasVideoContent || mediaContent.mainImage != nil)
    }

    private func showExpandedState() {
        isMediaCollapsed = false
        isFullyCollapsed = false

        mediaContainerView.isHidden = false
        mediaContainerView.alpha = 1
        mediaAssetView.isHidden = false
        mediaAssetView.alpha = 1
        expandedBottomStack.isHidden = false
        expandedBottomStack.alpha = 1
        collapsedBottomStack.isHidden = true
        collapsedBottomStack.alpha = 0
        floatingAdTagLabel.isHidden = true

        headlineView = expandedHeadlineLabel
        bodyView = nil
        callToActionView = expandedCallToActionButton
        iconView = nil
        mediaView = mediaAssetView
    }

    private func showCollapsedState() {
        isMediaCollapsed = true
        isFullyCollapsed = true

        mediaAssetView.isHidden = true
        mediaAssetView.alpha = 0
        mediaContainerView.isHidden = true
        mediaContainerView.alpha = 0
        expandedBottomStack.isHidden = true
        expandedBottomStack.alpha = 0
        collapsedBottomStack.isHidden = false
        collapsedBottomStack.alpha = 1
        floatingAdTagLabel.isHidden = false

        headlineView = collapsedHeadlineLabel
        bodyView = collapsedBodyLabel
        callToActionView = collapsedCallToActionButton
        iconView = collapsedIconImageView
        mediaView = nil
    }

    private func updateAdRegistration() {
        guard let appliedNativeAd else { return }
        super.nativeAd = appliedNativeAd
    }

    @objc private func handleCollapse() {
        guard let appliedNativeAd, hasMediaContent(appliedNativeAd) else { return }

        if !isMediaCollapsed {
            isMediaCollapsed = true
            UIView.animate(withDuration: 0.3) {
                self.mediaAssetView.isHidden = true
                self.mediaAssetView.alpha = 0
            }
            return
        }

        guard !isFullyCollapsed else { return }
        isFullyCollapsed = true

        UIView.animate(
            withDuration: 0.3,
            animations: {
                self.mediaContainerView.isHidden = true
                self.mediaContainerView.alpha = 0
                self.expandedBottomStack.isHidden = true
                self.expandedBottomStack.alpha = 0
                self.collapsedBottomStack.isHidden = false
                self.collapsedBottomStack.alpha = 1
                self.floatingAdTagLabel.isHidden = false
                self.layoutIfNeeded()
            },
            completion: { _ in
                self.headlineView = self.collapsedHeadlineLabel
                self.bodyView = self.collapsedBodyLabel
                self.callToActionView = self.collapsedCallToActionButton
                self.iconView = self.collapsedIconImageView
                self.mediaView = nil
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
