import UIKit
import SnapKit

final class OperationsView: UIView {

    let headerLabel = UILabel()
    let searchBar = UISearchBar()
    let filterScrollView = UIScrollView()
    let filterStackView = UIStackView()
    let tableView = UITableView(frame: .zero, style: .grouped)
    let emptyLabel = UILabel()

    private let filters = ["Усі", "Доходи", "Витрати"]
    var selectedFilter = 0
    var onFilterChanged: (() -> Void)?
    var onSearchChanged: (() -> Void)?

    /// Trimmed search text. Empty when the field is blank or whitespace-only.
    var searchQuery: String {
        (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError() }
}

private extension OperationsView {
    func setupUI() {
        backgroundColor = AppColors.background

        headerLabel.text = "Операції"
        headerLabel.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        headerLabel.textColor = AppColors.textPrimary

        searchBar.placeholder = "Пошук"
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .clear
        searchBar.delegate = self
        searchBar.autocorrectionType = .no
        searchBar.smartQuotesType = .no
        searchBar.returnKeyType = .search
        searchBar.enablesReturnKeyAutomatically = false

        emptyLabel.text = "Нічого не знайдено"
        emptyLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        emptyLabel.textColor = AppColors.textSecondary
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true

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
        tableView.showsVerticalScrollIndicator = false
        tableView.keyboardDismissMode = .onDrag
        tableView.register(OperationCell.self, forCellReuseIdentifier: OperationCell.id)
    }

    func setupConstraints() {
        [headerLabel, searchBar, filterScrollView, tableView, emptyLabel].forEach { addSubview($0) }
        filterScrollView.addSubview(filterStackView)

        headerLabel.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(16)
            $0.leading.equalToSuperview().offset(16)
        }
        searchBar.snp.makeConstraints {
            $0.top.equalTo(headerLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(8)
        }
        filterScrollView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(4)
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
        emptyLabel.snp.makeConstraints {
            $0.centerX.equalTo(tableView)
            $0.centerY.equalTo(tableView).offset(-40)
            $0.leading.trailing.equalToSuperview().inset(32)
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

extension OperationsView: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        onSearchChanged?()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

final class OperationCell: UITableViewCell {
    static let id = "OperationCell"

    private let iconView = UIView()
    private let iconImg = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let amountLabel = UILabel()
    private let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = AppColors.card

        iconView.backgroundColor = AppColors.background
        iconView.layer.cornerRadius = 20

        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        iconImg.image = UIImage(systemName: "arrow.up.arrow.down", withConfiguration: config)
        iconImg.tintColor = AppColors.textSecondary
        iconImg.contentMode = .scaleAspectFit

        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = AppColors.textPrimary

        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = AppColors.textSecondary

        amountLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)

        separator.backgroundColor = AppColors.separator

        [iconView, titleLabel, subtitleLabel, amountLabel, separator].forEach { contentView.addSubview($0) }
        iconView.addSubview(iconImg)

        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(40)
        }
        iconImg.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(18) }
        amountLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-8)
            $0.top.equalToSuperview().offset(12)
        }
        subtitleLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(2)
        }
        separator.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, subtitle: String, amount: String, isIncome: Bool) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        amountLabel.text = amount
        amountLabel.textColor = isIncome ? AppColors.green : AppColors.red
    }
}
