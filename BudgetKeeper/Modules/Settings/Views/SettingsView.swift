import UIKit
import SnapKit

final class SettingsView: UIView {

    let headerLabel = UILabel()
    let backButton = UIButton(type: .system)
    let tableView = UITableView(frame: .zero, style: .grouped)

    struct Section {
        let title: String
        let rows: [Row]
    }

    struct Row {
        let title: String
        let value: String?
        let icon: String
        let color: UIColor
        let accessory: AccessoryType
        enum AccessoryType { case chevron, toggle, info }
    }

    let sections: [Section] = [
        Section(title: "ПРОФІЛЬ", rows: [
            Row(title: "Ім'я", value: "Алекса", icon: "person.fill", color: AppColors.purple, accessory: .chevron),
            Row(title: "Основна валюта", value: "UAH — Гривня", icon: "dollarsign.circle.fill", color: AppColors.green, accessory: .chevron),
        ]),
        Section(title: "БЕЗПЕКА", rows: [
            Row(title: "PIN-код", value: "Змінити", icon: "lock.fill", color: AppColors.orange, accessory: .chevron),
            Row(title: "Face ID", value: nil, icon: "faceid", color: AppColors.primary, accessory: .toggle),
            Row(title: "Автоблокування", value: "Одразу", icon: "clock.fill", color: AppColors.systemGray, accessory: .chevron),
        ]),
        Section(title: "ЗОВНІШНІЙ ВИГЛЯД", rows: [
            Row(title: "Тема", value: "Світла", icon: "sun.max.fill", color: AppColors.orange, accessory: .chevron),
        ]),
        Section(title: "ДАНІ", rows: [
            Row(title: "Категорії", value: nil, icon: "tag.fill", color: AppColors.primary, accessory: .chevron),
            Row(title: "Експорт у CSV", value: nil, icon: "arrow.up.doc.fill", color: AppColors.green, accessory: .info),
            Row(title: "Експорт у PDF", value: nil, icon: "doc.fill", color: AppColors.red, accessory: .info),
            Row(title: "Очистити всі дані", value: nil, icon: "trash.fill", color: AppColors.red, accessory: .info),
        ]),
        Section(title: "ПРО ЗАСТОСУНОК", rows: [
            Row(title: "Версія", value: "1.0.0", icon: "info.circle.fill", color: AppColors.systemGray, accessory: .chevron),
            Row(title: "Політика конфіденційності", value: nil, icon: "hand.raised.fill", color: AppColors.systemGray, accessory: .info),
        ]),
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError() }
}

private extension SettingsView {
    func setupUI() {
        backgroundColor = AppColors.background

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.setTitle("Ще", for: .normal)
        backButton.tintColor = AppColors.primary

        headerLabel.text = "Налаштування"
        headerLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        headerLabel.textColor = AppColors.textPrimary

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(SettingsCell.self, forCellReuseIdentifier: SettingsCell.id)
    }

    func setupConstraints() {
        [backButton, headerLabel, tableView].forEach { addSubview($0) }

        backButton.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(8)
            $0.leading.equalToSuperview().offset(8)
        }
        headerLabel.snp.makeConstraints {
            $0.top.equalTo(backButton.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(16)
        }
        tableView.snp.makeConstraints {
            $0.top.equalTo(headerLabel.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
}

final class SettingsCell: UITableViewCell {
    static let id = "SettingsCell"

    let iconContainer = UIView()
    let iconImg = UIImageView()
    let titleLabel = UILabel()
    let valueLabel = UILabel()
    let chevron = UIImageView()
    let toggle = UISwitch()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = AppColors.card

        iconContainer.layer.cornerRadius = 10
        iconImg.contentMode = .scaleAspectFit
        iconImg.tintColor = .white

        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        titleLabel.textColor = AppColors.textPrimary

        valueLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        valueLabel.textColor = AppColors.textSecondary
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        chevron.image = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
        chevron.tintColor = AppColors.textSecondary.withAlphaComponent(0.5)

        toggle.onTintColor = AppColors.green
        toggle.isOn = true

        [iconContainer, titleLabel, valueLabel, chevron, toggle].forEach { contentView.addSubview($0) }
        iconContainer.addSubview(iconImg)

        iconContainer.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(32)
        }
        iconImg.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(18) }
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconContainer.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
        }
        valueLabel.snp.makeConstraints { $0.trailing.equalTo(chevron.snp.leading).offset(-4); $0.centerY.equalToSuperview() }
        chevron.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview() }
        toggle.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with row: SettingsView.Row) {
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        iconImg.image = UIImage(systemName: row.icon, withConfiguration: iconConfig)
        iconContainer.backgroundColor = row.color
        titleLabel.text = row.title
        titleLabel.textColor = (row.title == "Очистити всі дані") ? AppColors.red : AppColors.textPrimary

        valueLabel.text = row.value
        switch row.accessory {
        case .chevron:
            chevron.isHidden = false
            toggle.isHidden = true
            valueLabel.isHidden = row.value == nil
        case .toggle:
            chevron.isHidden = true
            toggle.isHidden = false
            valueLabel.isHidden = true
        case .info:
            chevron.isHidden = false
            toggle.isHidden = true
            valueLabel.isHidden = true
        }
    }
}
