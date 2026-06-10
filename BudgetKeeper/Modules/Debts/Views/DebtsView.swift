import UIKit
import SnapKit

final class DebtsView: UIView {

    let headerLabel = UILabel()
    let backButton = UIButton(type: .system)
    let iOweCard = DebtSummaryCard(title: "Я винна", amount: "₴0,00", color: AppColors.red)
    let owedCard = DebtSummaryCard(title: "Мені винні", amount: "₴0,00", color: AppColors.green)
    let filterScrollView = UIScrollView()
    let filterStackView = UIStackView()
    let tableView = UITableView(frame: .zero, style: .plain)

    private let filters = ["Усі", "Я винна", "Мені винні"]
    private(set) var selectedFilter = 0
    var onFilterChanged: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError() }
}

private extension DebtsView {
    func setupUI() {
        backgroundColor = AppColors.background

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.setTitle("Ще", for: .normal)
        backButton.tintColor = AppColors.primary

        headerLabel.text = "Борги"
        headerLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        headerLabel.textColor = AppColors.textPrimary

        filterScrollView.showsHorizontalScrollIndicator = false
        filterStackView.axis = .horizontal
        filterStackView.spacing = 8

        for (i, filter) in filters.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(filter, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            btn.layer.cornerRadius = 16
            btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            btn.tag = i
            btn.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
            updateFilterButton(btn, selected: i == 0)
            filterStackView.addArrangedSubview(btn)
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(DebtCell.self, forCellReuseIdentifier: DebtCell.id)
    }

    func setupConstraints() {
        [backButton, headerLabel, iOweCard, owedCard, filterScrollView, tableView].forEach { addSubview($0) }
        filterScrollView.addSubview(filterStackView)

        backButton.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(8)
            $0.leading.equalToSuperview().offset(8)
        }
        headerLabel.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(16)
        }
        iOweCard.snp.makeConstraints {
            $0.top.equalTo(headerLabel.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.width.equalToSuperview().dividedBy(2).offset(-20)
            $0.height.equalTo(90)
        }
        owedCard.snp.makeConstraints {
            $0.top.equalTo(iOweCard)
            $0.leading.equalTo(iOweCard.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().offset(-16)
            $0.height.equalTo(90)
        }
        filterScrollView.snp.makeConstraints {
            $0.top.equalTo(iOweCard.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(40)
        }
        filterStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
            $0.height.equalToSuperview()
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(filterScrollView.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    func updateFilterButton(_ btn: UIButton, selected: Bool) {
        btn.backgroundColor = selected ? AppColors.primary : AppColors.card
        btn.setTitleColor(selected ? .white : AppColors.textSecondary, for: .normal)
    }

    @objc func filterTapped(_ sender: UIButton) {
        selectedFilter = sender.tag
        for view in filterStackView.arrangedSubviews {
            if let btn = view as? UIButton {
                updateFilterButton(btn, selected: btn.tag == selectedFilter)
            }
        }
        onFilterChanged?()
    }
}

final class DebtSummaryCard: UIView {
    private let amountLabel = UILabel()

    init(title: String, amount: String, color: UIColor) {
        super.init(frame: .zero)
        backgroundColor = color.withAlphaComponent(0.1)
        layer.cornerRadius = 16

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = color

        amountLabel.text = amount
        amountLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        amountLabel.textColor = AppColors.textPrimary

        let stack = UIStackView(arrangedSubviews: [titleLabel, amountLabel])
        stack.axis = .vertical
        stack.spacing = 6
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }
    }
    required init?(coder: NSCoder) { fatalError() }

    func update(amount: String) { amountLabel.text = amount }
}

final class DebtCell: UITableViewCell {
    static let id = "DebtCell"

    private let avatarView = UIView()
    private let avatarLabel = UILabel()
    private let nameLabel = UILabel()
    private let descLabel = UILabel()
    private let amountLabel = UILabel()
    private let typeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = AppColors.card

        avatarView.layer.cornerRadius = 22
        avatarView.backgroundColor = AppColors.primary.withAlphaComponent(0.15)
        avatarLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        avatarLabel.textColor = AppColors.primary
        avatarLabel.textAlignment = .center

        nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = AppColors.textPrimary
        descLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        descLabel.textColor = AppColors.textSecondary

        amountLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)
        typeLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        typeLabel.textAlignment = .right
        typeLabel.setContentHuggingPriority(.required, for: .horizontal)

        [avatarView, nameLabel, descLabel, amountLabel, typeLabel].forEach { contentView.addSubview($0) }
        avatarView.addSubview(avatarLabel)

        avatarView.snp.makeConstraints { $0.leading.equalToSuperview().offset(16); $0.centerY.equalToSuperview(); $0.size.equalTo(44) }
        avatarLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        amountLabel.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.top.equalToSuperview().offset(16) }
        typeLabel.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.top.equalTo(amountLabel.snp.bottom).offset(2) }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(avatarView.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-8)
            $0.top.equalToSuperview().offset(14)
        }
        descLabel.snp.makeConstraints { $0.leading.equalTo(nameLabel); $0.top.equalTo(nameLabel.snp.bottom).offset(2) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, desc: String, amount: String, type: String, isOwe: Bool) {
        let initials = name.components(separatedBy: " ").compactMap { $0.first }.prefix(2).map(String.init).joined()
        avatarLabel.text = initials
        avatarView.backgroundColor = isOwe ? AppColors.red.withAlphaComponent(0.1) : AppColors.green.withAlphaComponent(0.1)
        avatarLabel.textColor = isOwe ? AppColors.red : AppColors.green
        nameLabel.text = name
        descLabel.text = desc
        amountLabel.text = amount
        amountLabel.textColor = isOwe ? AppColors.red : AppColors.green
        typeLabel.text = type
        typeLabel.textColor = AppColors.textSecondary
    }
}
