import UIKit

final class MainTabBarController: UITabBarController {

    private let customTabBar = CustomTabBarView()
    private let fabButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.isHidden = true
        setupViewControllers()
        setupCustomBar()
        setupFAB()
        delegate = self
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutBarAndFAB()
        view.bringSubviewToFront(customTabBar)
        view.bringSubviewToFront(fabButton)
    }
}

// MARK: - UITabBarControllerDelegate

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        customTabBar.setSelectedIndex(selectedIndex, animated: true)
    }
}

// MARK: - Private setup

private extension MainTabBarController {

    func setupViewControllers() {
        let home     = wrap(HomeViewController())
        let ops      = wrap(OperationsViewController())
        let analytics = wrap(AnalyticsViewController())
        let more     = wrap(MoreViewController())

        let navs = [home, ops, analytics, more]
        // Add 49pt bottom inset so content stays above our custom tab bar
        navs.forEach { $0.additionalSafeAreaInsets.bottom = 49 }
        viewControllers = navs
    }

    func wrap(_ vc: UIViewController) -> UINavigationController {
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.isHidden = true
        return nav
    }

    func setupCustomBar() {
        view.addSubview(customTabBar)
        customTabBar.onTabTapped = { [weak self] index in
            guard let self else { return }
            self.selectedIndex = index
            self.customTabBar.setSelectedIndex(index, animated: true)
        }
        customTabBar.setSelectedIndex(0, animated: false)
    }

    func setupFAB() {
        fabButton.backgroundColor = AppColors.primary
        fabButton.layer.cornerRadius = 28
        fabButton.layer.shadowColor = AppColors.primary.cgColor
        fabButton.layer.shadowOpacity = 0.4
        fabButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        fabButton.layer.shadowRadius = 8
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        fabButton.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        fabButton.tintColor = .white
        fabButton.addTarget(self, action: #selector(fabTapped), for: .touchUpInside)
        view.addSubview(fabButton)
    }

    func layoutBarAndFAB() {
        let safeBottom = view.safeAreaInsets.bottom
        let contentH: CGFloat = 49
        let barH = contentH + safeBottom

        customTabBar.frame = CGRect(
            x: 0,
            y: view.bounds.height - barH,
            width: view.bounds.width,
            height: barH
        )

        // FAB: centered horizontally, top edge 17pt above the tab bar top
        let fabSize: CGFloat = 56
        fabButton.frame = CGRect(
            x: (view.bounds.width - fabSize) / 2,
            y: customTabBar.frame.minY - 17,
            width: fabSize,
            height: fabSize
        )
    }

    @objc func fabTapped() {
        let vc = NewOperationViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }
}

// MARK: - CustomTabBarView

final class CustomTabBarView: UIView {

    var onTabTapped: ((Int) -> Void)?

    private let topBorder = UIView()
    private var itemViews: [TabBarItemView] = []

    // Figma: 4 items split as [Головна, Операції] [gap=FAB] [Аналітика, Ще]
    private let items: [(icon: String, activeIcon: String, title: String)] = [
        ("house",      "house.fill",      "Головна"),
        ("list.bullet", "list.bullet",    "Операції"),
        ("chart.bar",  "chart.bar.fill",  "Аналітика"),
        ("ellipsis",   "ellipsis",        "Ще"),
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    func setSelectedIndex(_ index: Int, animated: Bool) {
        itemViews.enumerated().forEach { i, v in v.setActive(i == index, animated: animated) }
    }

    private func setupUI() {
        backgroundColor = AppColors.card
        topBorder.backgroundColor = AppColors.separator
        addSubview(topBorder)

        for (i, data) in items.enumerated() {
            let item = TabBarItemView(icon: data.icon, activeIcon: data.activeIcon, title: data.title)
            item.tag = i
            item.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
            addSubview(item)
            itemViews.append(item)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        topBorder.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 0.5)

        // Figma: screen 393pt wide
        // Left group:  x=0        width=160.5  (two buttons × 80.25)
        // FAB gap:     x=160.5    width=72      (center of 393 = 196.5, FAB left=168.5 size=56)
        // Right group: x=232.5    width=160.5  (two buttons × 80.25)
        let w = bounds.width
        let scale = w / 393.0
        let btnW  = 80.25 * scale
        let rStart = 232.5 * scale
        let h: CGFloat = 49

        itemViews[0].frame = CGRect(x: 0,           y: 0, width: btnW, height: h)
        itemViews[1].frame = CGRect(x: btnW,         y: 0, width: btnW, height: h)
        itemViews[2].frame = CGRect(x: rStart,       y: 0, width: btnW, height: h)
        itemViews[3].frame = CGRect(x: rStart + btnW, y: 0, width: btnW, height: h)
    }

    @objc private func tapped(_ sender: UIControl) {
        onTabTapped?(sender.tag)
    }
}

// MARK: - TabBarItemView

final class TabBarItemView: UIControl {

    private let iconView  = UIImageView()
    private let label     = UILabel()
    private let iconName:  String
    private let activeIcon: String

    init(icon: String, activeIcon: String, title: String) {
        self.iconName   = icon
        self.activeIcon = activeIcon
        super.init(frame: .zero)
        iconView.contentMode = .scaleAspectFit
        label.textAlignment = .center
        label.text = title
        addSubview(iconView)
        addSubview(label)
        setActive(false, animated: false)
    }
    required init?(coder: NSCoder) { fatalError() }

    func setActive(_ active: Bool, animated: Bool) {
        let update: () -> Void = {
            let weight: UIImage.SymbolWeight = active ? .semibold : .regular
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: weight)
            self.iconView.image = UIImage(systemName: active ? self.activeIcon : self.iconName,
                                          withConfiguration: config)
            self.iconView.tintColor  = active ? AppColors.primary : AppColors.textSecondary
            self.label.textColor     = active ? AppColors.primary : AppColors.textSecondary
            self.label.font          = .systemFont(ofSize: 10, weight: active ? .semibold : .regular)
        }
        animated ? UIView.animate(withDuration: 0.2, animations: update) : update()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Figma: pt-[8px] top padding, icon 24×24, gap 4px, label 15px height
        let w: CGFloat = bounds.width
        let iconSize: CGFloat  = 24
        let labelH:   CGFloat  = 15
        let gap:      CGFloat  = 4
        let topPad:   CGFloat  = 8
        iconView.frame = CGRect(x: (w - iconSize) / 2, y: topPad,
                                 width: iconSize, height: iconSize)
        label.frame    = CGRect(x: 0, y: topPad + iconSize + gap,
                                 width: w, height: labelH)
    }
}
