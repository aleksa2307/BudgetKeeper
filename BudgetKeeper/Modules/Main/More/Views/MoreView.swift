import UIKit
import SnapKit

final class MoreView: UIView {

    let headerLabel = UILabel()

    struct MenuItem {
        let title: String
        let subtitle: String
        let icon: String
        let color: UIColor
    }

    let items: [MenuItem] = [
        MenuItem(title: "Рахунки",           subtitle: "Управляй своїми рахунками",     icon: "creditcard.fill",             color: AppColors.primary),
        MenuItem(title: "Бюджети",           subtitle: "Контролюй витрати",             icon: "chart.pie.fill",              color: AppColors.orange),
        MenuItem(title: "Цілі",              subtitle: "Накопичуй на мрію",             icon: "target",                      color: AppColors.green),
        MenuItem(title: "Регулярні платежі", subtitle: "Підписки та щомісячні витрати", icon: "arrow.clockwise.circle.fill", color: AppColors.purple),
        MenuItem(title: "Борги",             subtitle: "Відстежуй борги і кредити",     icon: "person.2.fill",               color: AppColors.red),
        MenuItem(title: "Налаштування",      subtitle: "Профіль, безпека, дані",        icon: "gearshape.fill",              color: AppColors.systemGray),
    ]

    var onItemTapped: ((Int) -> Void)?

    private let headerArea  = UIView()
    private let cardView    = UIView()
    private let menuStack   = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError() }
}

private extension MoreView {
    func setupUI() {
        backgroundColor = AppColors.background

        headerArea.backgroundColor = AppColors.card

        headerLabel.text = "Ще"
        headerLabel.font = .systemFont(ofSize: 34, weight: .bold)
        headerLabel.textColor = AppColors.textPrimary

        cardView.backgroundColor = AppColors.card
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 1)
        cardView.layer.shadowRadius = 1.5
        cardView.layer.shadowOpacity = 0.04
        cardView.clipsToBounds = false

        menuStack.axis = .vertical
    }

    func setupConstraints() {
        addSubview(headerArea)
        addSubview(headerLabel)
        addSubview(cardView)

        let clipView = UIView()
        clipView.layer.cornerRadius = 16
        clipView.clipsToBounds = true
        cardView.addSubview(clipView)
        clipView.addSubview(menuStack)

        for (i, item) in items.enumerated() {
            let row = MoreMenuRow(item: item, isLast: i == items.count - 1)
            row.tag = i
            row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(rowTapped(_:))))
            menuStack.addArrangedSubview(row)
            row.snp.makeConstraints { $0.height.equalTo(76) }
        }

        headerArea.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(headerLabel.snp.bottom).offset(16)
        }
        headerLabel.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(16)
            $0.leading.equalToSuperview().offset(24)
        }
        cardView.snp.makeConstraints {
            $0.top.equalTo(headerArea.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        clipView.snp.makeConstraints { $0.edges.equalToSuperview() }
        menuStack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @objc func rowTapped(_ gr: UITapGestureRecognizer) {
        guard let idx = gr.view?.tag else { return }
        onItemTapped?(idx)
    }
}

// MARK: - MoreMenuRow

private final class MoreMenuRow: UIView {

    private let iconContainer = UIView()
    private let iconImg       = UIImageView()
    private let titleLabel    = UILabel()
    private let subtitleLabel = UILabel()
    private let chevron       = UIImageView()
    private let separator     = UIView()

    init(item: MoreView.MenuItem, isLast: Bool) {
        super.init(frame: .zero)
        backgroundColor = AppColors.card

        iconContainer.backgroundColor = item.color
        iconContainer.layer.cornerRadius = 16
        iconContainer.clipsToBounds = true

        let symCfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        iconImg.image = UIImage(systemName: item.icon, withConfiguration: symCfg)
        iconImg.contentMode = .scaleAspectFit
        iconImg.tintColor = .white

        titleLabel.text = item.title
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = AppColors.textPrimary

        subtitleLabel.text = item.subtitle
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = AppColors.textSecondary

        let chevCfg = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        chevron.image = UIImage(systemName: "chevron.right", withConfiguration: chevCfg)
        chevron.tintColor = AppColors.textSecondary.withAlphaComponent(0.6)

        separator.backgroundColor = AppColors.separator
        separator.isHidden = isLast

        iconContainer.addSubview(iconImg)
        [iconContainer, titleLabel, subtitleLabel, chevron, separator].forEach { addSubview($0) }

        iconContainer.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(44)
        }
        iconImg.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(20) }

        chevron.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconContainer.snp.trailing).offset(16)
            $0.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-8)
            $0.bottom.equalTo(snp.centerY)
        }
        subtitleLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-8)
            $0.top.equalTo(snp.centerY).offset(2)
        }
        // Separator indented from leading edge of text (16 padding + 44 icon + 16 gap = 76)
        separator.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(76)
            $0.trailing.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.1) { self.alpha = 0.6 }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.15) { self.alpha = 1 }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.15) { self.alpha = 1 }
    }
}
