import UIKit
import SnapKit

final class CategoriesViewController: UIViewController {

    private var categoriesView: CategoriesView { view as! CategoriesView }
    private let addButton = UIButton(type: .system)
    private var sections: [(title: String, items: [Category])] = []

    override func loadView() { view = CategoriesView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        categoriesView.backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        categoriesView.tableView.dataSource = self
        categoriesView.tableView.delegate   = self

        let cfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: cfg), for: .normal)
        addButton.tintColor = AppColors.primary
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        categoriesView.addSubview(addButton)
        addButton.snp.makeConstraints {
            $0.centerY.equalTo(categoriesView.backButton)
            $0.trailing.equalToSuperview().offset(-16)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: DataStore.dataChangedNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
}

extension CategoriesViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CategoryCell.id, for: indexPath) as! CategoryCell
        let section = sections[indexPath.section]
        cell.configure(with: section.items[indexPath.row])

        let isFirst = indexPath.row == 0
        let isLast  = indexPath.row == section.items.count - 1
        var corners: CACornerMask = []
        if isFirst { corners.insert([.layerMinXMinYCorner, .layerMaxXMinYCorner]) }
        if isLast  { corners.insert([.layerMinXMaxYCorner, .layerMaxXMaxYCorner]) }
        cell.contentView.layer.cornerRadius = 16
        cell.contentView.layer.maskedCorners = corners
        cell.contentView.clipsToBounds = true

        if !isLast {
            let sep = UIView(); sep.backgroundColor = AppColors.separator
            cell.contentView.addSubview(sep)
            sep.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(60)
                $0.trailing.bottom.equalToSuperview()
                $0.height.equalTo(0.5)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 52 }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        let label  = UILabel()
        label.text = sections[section].title
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = AppColors.textSecondary
        header.addSubview(label)
        label.snp.makeConstraints { $0.leading.equalToSuperview().offset(20); $0.bottom.equalToSuperview().offset(-4) }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 40 }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 8 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showActions(for: sections[indexPath.section].items[indexPath.row])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let category = sections[indexPath.section].items[indexPath.row]
        let del = UIContextualAction(style: .destructive, title: "Видалити") { [weak self] _, _, done in
            self?.confirmDelete(category)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [del])
    }
}

private extension CategoriesViewController {
    @objc func backTapped() { navigationController?.popViewController(animated: true) }

    @objc func reloadData() {
        let custom = DataStore.shared.customCategories
        sections = [
            (title: "ВИТРАТИ", items: custom.filter { $0.type == .expense }),
            (title: "ДОХОДИ",  items: custom.filter { $0.type == .income }),
        ].filter { !$0.items.isEmpty }
        categoriesView.emptyLabel.isHidden = !custom.isEmpty
        categoriesView.tableView.reloadData()
    }

    @objc func addTapped() {
        let alert = UIAlertController(title: "Нова категорія", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Назва категорії" }
        alert.addAction(UIAlertAction(title: "Додати як витрату", style: .default) { [weak self] _ in
            self?.createCategory(alert: alert, type: .expense)
        })
        alert.addAction(UIAlertAction(title: "Додати як дохід", style: .default) { [weak self] _ in
            self?.createCategory(alert: alert, type: .income)
        })
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }

    func createCategory(alert: UIAlertController, type: TransactionType) {
        let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !name.isEmpty else { return }
        let colors = ["#FF9500", "#5856D6", "#34C759", "#0066FF", "#FF3B30", "#8A8A8E"]
        let cat = Category(id: UUID(), name: name, icon: "tag.fill",
                           colorHex: colors[DataStore.shared.customCategories.count % colors.count],
                           type: type)
        DataStore.shared.addCategory(cat)
    }

    func showActions(for category: Category) {
        let sheet = UIAlertController(title: category.name, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Перейменувати", style: .default) { [weak self] _ in
            self?.rename(category)
        })
        sheet.addAction(UIAlertAction(title: "Видалити", style: .destructive) { [weak self] _ in
            self?.confirmDelete(category)
        })
        sheet.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(sheet, animated: true)
    }

    func rename(_ category: Category) {
        let alert = UIAlertController(title: "Перейменувати категорію", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Назва категорії"; $0.text = category.name }
        alert.addAction(UIAlertAction(title: "Зберегти", style: .default) { _ in
            let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces) ?? ""
            guard !name.isEmpty else { return }
            var c = category
            c.name = name
            DataStore.shared.updateCategory(c)
        })
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }

    func confirmDelete(_ category: Category) {
        let confirm = UIAlertController(title: "Видалити «\(category.name)»?",
                                        message: "Операції з цією категорією відображатимуться як «Інше».",
                                        preferredStyle: .alert)
        confirm.addAction(UIAlertAction(title: "Видалити", style: .destructive) { _ in
            DataStore.shared.deleteCategory(id: category.id)
        })
        confirm.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(confirm, animated: true)
    }
}
