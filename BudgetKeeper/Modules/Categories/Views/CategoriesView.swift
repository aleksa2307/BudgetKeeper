import UIKit
import SnapKit

final class CategoriesView: UIView {

    let headerLabel = UILabel()
    let backButton = UIButton(type: .system)
    let tableView = UITableView(frame: .zero, style: .grouped)
    let emptyLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError() }
}

private extension CategoriesView {
    func setupUI() {
        backgroundColor = AppColors.background

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.setTitle("Назад", for: .normal)
        backButton.tintColor = AppColors.primary

        headerLabel.text = "Категорії"
        headerLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        headerLabel.textColor = AppColors.textPrimary

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.id)

        emptyLabel.text = "Немає власних категорій\nНатисніть +, щоб створити"
        emptyLabel.numberOfLines = 2
        emptyLabel.textAlignment = .center
        emptyLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        emptyLabel.textColor = AppColors.textSecondary
        emptyLabel.isHidden = true
    }

    func setupConstraints() {
        [backButton, headerLabel, tableView, emptyLabel].forEach { addSubview($0) }

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
        emptyLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(40)
        }
    }
}

final class CategoryCell: UITableViewCell {
    static let id = "CategoryCell"

    private let iconContainer = UIView()
    private let iconImg = UIImageView()
    private let titleLabel = UILabel()
    private let chevron = UIImageView()

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

        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        chevron.image = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
        chevron.tintColor = AppColors.textSecondary.withAlphaComponent(0.5)

        [iconContainer, titleLabel, chevron].forEach { contentView.addSubview($0) }
        iconContainer.addSubview(iconImg)

        iconContainer.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(32)
        }
        iconImg.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(18) }
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconContainer.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-8)
            $0.centerY.equalToSuperview()
        }
        chevron.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with category: Category) {
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        iconImg.image = UIImage(systemName: category.icon, withConfiguration: iconConfig)
        iconContainer.backgroundColor = UIColor(hex: category.colorHex) ?? AppColors.primary
        titleLabel.text = category.name
    }
}
