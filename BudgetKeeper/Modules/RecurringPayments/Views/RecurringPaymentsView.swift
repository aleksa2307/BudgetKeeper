import UIKit
import SnapKit

final class RecurringPaymentsView: UIView {

    let headerLabel = UILabel()
    let backButton = UIButton(type: .system)
    let calendarButton = UIButton(type: .system)
    let segmentControl = UISegmentedControl(items: ["Найближчі", "Активні", "Призупинені"])
    let tableView = UITableView(frame: .zero, style: .plain)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError() }
}

private extension RecurringPaymentsView {
    func setupUI() {
        backgroundColor = AppColors.background

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.setTitle("Ще", for: .normal)
        backButton.tintColor = AppColors.primary

        headerLabel.text = "Регулярні платежі"
        headerLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        headerLabel.textColor = AppColors.textPrimary

        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        calendarButton.setImage(UIImage(systemName: "calendar", withConfiguration: config), for: .normal)
        calendarButton.tintColor = AppColors.primary

        segmentControl.selectedSegmentIndex = 0
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(RecurringPaymentCell.self, forCellReuseIdentifier: RecurringPaymentCell.id)
    }

    func setupConstraints() {
        [backButton, headerLabel, calendarButton, segmentControl, tableView].forEach { addSubview($0) }

        backButton.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(8)
            $0.leading.equalToSuperview().offset(8)
        }
        calendarButton.snp.makeConstraints {
            $0.centerY.equalTo(backButton)
            $0.trailing.equalToSuperview().offset(-16)
        }
        headerLabel.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(16)
        }
        segmentControl.snp.makeConstraints {
            $0.top.equalTo(headerLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(36)
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(segmentControl.snp.bottom).offset(16)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
}

final class RecurringPaymentCell: UITableViewCell {
    static let id = "RecurringPaymentCell"

    private let iconContainer = UIView()
    private let iconImg = UIImageView()
    private let nameLabel = UILabel()
    private let dateLabel = UILabel()
    private let amountLabel = UILabel()
    private let statusLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = AppColors.card

        iconContainer.layer.cornerRadius = 14
        iconContainer.backgroundColor = AppColors.primary
        iconImg.contentMode = .scaleAspectFit
        iconImg.tintColor = .white

        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = AppColors.textPrimary
        dateLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = AppColors.textSecondary
        amountLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        amountLabel.textColor = AppColors.textPrimary
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)
        statusLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        statusLabel.textAlignment = .right

        [iconContainer, nameLabel, dateLabel, amountLabel, statusLabel].forEach { contentView.addSubview($0) }
        iconContainer.addSubview(iconImg)

        iconContainer.snp.makeConstraints { $0.leading.equalToSuperview().offset(16); $0.centerY.equalToSuperview(); $0.size.equalTo(44) }
        iconImg.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(22) }
        amountLabel.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.top.equalToSuperview().offset(16) }
        statusLabel.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.top.equalTo(amountLabel.snp.bottom).offset(2) }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(iconContainer.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-8)
            $0.top.equalToSuperview().offset(14)
        }
        dateLabel.snp.makeConstraints { $0.leading.equalTo(nameLabel); $0.top.equalTo(nameLabel.snp.bottom).offset(2) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, date: String, amount: String, status: String, statusColor: UIColor, color: UIColor, icon: String) {
        nameLabel.text = name
        dateLabel.text = date
        amountLabel.text = amount
        statusLabel.text = status
        statusLabel.textColor = statusColor
        iconContainer.backgroundColor = color
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        iconImg.image = UIImage(systemName: icon, withConfiguration: config)
    }
}
