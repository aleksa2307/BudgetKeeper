import UIKit
import SnapKit

final class AccountsView: UIView {

    let headerStack = UIStackView()
    let backButton = UIButton(type: .system)
    let headerLabel = UILabel()
    let balanceCard = UIView()
    let balanceTitleLabel = UILabel()
    let balanceAmountLabel = UILabel()
    let currencyLabel = UILabel()
    let tableView = UITableView(frame: .zero, style: .plain)
    let addButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError() }
}

private extension AccountsView {
    func setupUI() {
        backgroundColor = AppColors.background

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.setTitle("Ще", for: .normal)
        backButton.tintColor = AppColors.primary
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)

        headerLabel.text = "Рахунки"
        headerLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        headerLabel.textColor = AppColors.textPrimary

        // Balance card
        balanceCard.backgroundColor = AppColors.primary
        balanceCard.layer.cornerRadius = 24

        balanceTitleLabel.text = "UAH · 4 рахунки"
        balanceTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        balanceTitleLabel.textColor = .white.withAlphaComponent(0.7)

        balanceAmountLabel.text = "₴74 350,00"
        balanceAmountLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        balanceAmountLabel.textColor = .white

        // Table
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(AccountCell.self, forCellReuseIdentifier: AccountCell.id)

        // FAB add button
        addButton.backgroundColor = AppColors.primary
        addButton.layer.cornerRadius = 28
        addButton.layer.shadowColor = AppColors.primary.cgColor
        addButton.layer.shadowOpacity = 0.4
        addButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        addButton.layer.shadowRadius = 8
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        addButton.tintColor = .white
    }

    func setupConstraints() {
        [headerStack, headerLabel, balanceCard, tableView, addButton].forEach { addSubview($0) }
        [balanceTitleLabel, balanceAmountLabel].forEach { balanceCard.addSubview($0) }

        headerStack.addArrangedSubview(backButton)
        headerStack.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(8)
            $0.leading.equalToSuperview().offset(8)
        }
        headerLabel.snp.makeConstraints {
            $0.top.equalTo(headerStack.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(16)
        }
        balanceCard.snp.makeConstraints {
            $0.top.equalTo(headerLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(120)
        }
        balanceTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(20)
        }
        balanceAmountLabel.snp.makeConstraints {
            $0.top.equalTo(balanceTitleLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(20)
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(balanceCard.snp.bottom).offset(16)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        addButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-16)
            $0.size.equalTo(56)
        }
    }
}

final class AccountCell: UITableViewCell {
    static let id = "AccountCell"

    private let iconContainer = UIView()
    private let iconImg = UIImageView()
    private let nameLabel = UILabel()
    private let typeLabel = UILabel()
    private let amountLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = AppColors.card

        iconContainer.layer.cornerRadius = 14
        iconImg.contentMode = .scaleAspectFit
        iconImg.tintColor = .white

        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = AppColors.textPrimary
        typeLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        typeLabel.textColor = AppColors.textSecondary
        amountLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        amountLabel.textColor = AppColors.textPrimary
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)

        [iconContainer, nameLabel, typeLabel, amountLabel].forEach { contentView.addSubview($0) }
        iconContainer.addSubview(iconImg)

        iconContainer.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(44)
        }
        iconImg.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(22) }
        amountLabel.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview() }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(iconContainer.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-8)
            $0.top.equalToSuperview().offset(14)
        }
        typeLabel.snp.makeConstraints {
            $0.leading.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(2)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, type: String, amount: String, color: UIColor, icon: String) {
        nameLabel.text = name
        typeLabel.text = type
        amountLabel.text = amount
        iconContainer.backgroundColor = color
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        iconImg.image = UIImage(systemName: icon, withConfiguration: config)
    }
}
