import UIKit
import SnapKit

final class BudgetsView: UIView {

    let headerLabel = UILabel()
    let backButton = UIButton(type: .system)
    let periodSegment = UISegmentedControl(items: ["Тиждень", "Місяць", "Рік"])
    let tableView = UITableView(frame: .zero, style: .plain)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError() }
}

private extension BudgetsView {
    func setupUI() {
        backgroundColor = AppColors.background

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.setTitle("Ще", for: .normal)
        backButton.tintColor = AppColors.primary

        headerLabel.text = "Бюджети"
        headerLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        headerLabel.textColor = AppColors.textPrimary

        periodSegment.selectedSegmentIndex = 1
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(BudgetItemCell.self, forCellReuseIdentifier: BudgetItemCell.id)
    }

    func setupConstraints() {
        [backButton, headerLabel, periodSegment, tableView].forEach { addSubview($0) }

        backButton.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(8)
            $0.leading.equalToSuperview().offset(8)
        }
        headerLabel.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(16)
        }
        periodSegment.snp.makeConstraints {
            $0.top.equalTo(headerLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(36)
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(periodSegment.snp.bottom).offset(16)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
}

final class BudgetItemCell: UITableViewCell {
    static let id = "BudgetItemCell"

    private let dot = UIView()
    private let nameLabel = UILabel()
    private let spentLabel = UILabel()
    private let pctLabel = UILabel()
    private let progBg = UIView()
    private let progFill = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = AppColors.card
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true

        dot.layer.cornerRadius = 8
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = AppColors.textPrimary

        spentLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        spentLabel.textColor = AppColors.textSecondary

        pctLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        pctLabel.textColor = AppColors.textPrimary
        pctLabel.setContentHuggingPriority(.required, for: .horizontal)

        progBg.backgroundColor = AppColors.background
        progBg.layer.cornerRadius = 4
        progFill.layer.cornerRadius = 4

        [dot, nameLabel, spentLabel, pctLabel, progBg, progFill].forEach { contentView.addSubview($0) }

        dot.snp.makeConstraints { $0.leading.equalToSuperview().offset(16); $0.top.equalToSuperview().offset(16); $0.size.equalTo(16) }
        pctLabel.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.top.equalToSuperview().offset(14) }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(dot.snp.trailing).offset(10)
            $0.trailing.lessThanOrEqualTo(pctLabel.snp.leading).offset(-8)
            $0.centerY.equalTo(dot)
        }
        spentLabel.snp.makeConstraints {
            $0.leading.equalTo(dot)
            $0.top.equalTo(dot.snp.bottom).offset(8)
        }
        progBg.snp.makeConstraints {
            $0.leading.equalTo(dot)
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalTo(spentLabel.snp.bottom).offset(8)
            $0.height.equalTo(8)
            $0.bottom.equalToSuperview().offset(-16)
        }
        progFill.snp.makeConstraints {
            $0.leading.top.bottom.equalTo(progBg)
            $0.width.equalTo(progBg).multipliedBy(0.5)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(name: String, spent: String, percent: Int, color: UIColor) {
        dot.backgroundColor = color
        nameLabel.text = name
        spentLabel.text = spent
        pctLabel.text = "\(percent)%"
        progFill.backgroundColor = color
        let ratio = min(CGFloat(percent) / 100.0, 1.0)
        progFill.snp.remakeConstraints {
            $0.leading.top.bottom.equalTo(progBg)
            $0.width.equalTo(progBg).multipliedBy(ratio)
        }
    }
}
