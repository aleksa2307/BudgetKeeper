import UIKit
import SnapKit

final class OperationsViewController: UIViewController {

    private var opsView: OperationsView { view as! OperationsView }

    private struct Section {
        let title: String
        let transactions: [Transaction]
    }
    private var sections: [Section] = []

    override func loadView() { view = OperationsView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        opsView.tableView.dataSource = self
        opsView.tableView.delegate   = self
        opsView.onFilterChanged = { [weak self] in self?.reloadData() }
        opsView.onSearchChanged = { [weak self] in self?.reloadData() }
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: DataStore.dataChangedNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
}

private extension OperationsViewController {
    @objc func reloadData() {
        let cal = Calendar.current
        let store = DataStore.shared
        let all = store.transactions

        let byType: [Transaction]
        switch opsView.selectedFilter {
        case 1: byType = all.filter { $0.type == .income }
        case 2: byType = all.filter { $0.type == .expense }
        default: byType = all
        }

        let query = opsView.searchQuery
        let filtered: [Transaction]
        if query.isEmpty {
            filtered = byType
        } else {
            let categoryNames = Dictionary(
                (DataStore.allCategories + store.customCategories).map { ($0.id, $0.name) },
                uniquingKeysWith: { first, _ in first }
            )
            let accountNames = Dictionary(
                store.accounts.map { ($0.id, $0.name) },
                uniquingKeysWith: { first, _ in first }
            )
            filtered = byType.filter { t in
                // Match the same text the row renders (incl. fallbacks), plus the amount and note.
                let catName = categoryNames[t.categoryId] ?? "Інше"
                let accName = accountNames[t.accountId]  ?? "Рахунок"
                let fields = [catName, accName, t.note, t.type.displayName] + t.amount.searchStrings
                return fields.contains { $0.matchesSearch(query) }
            }
        }

        let grouped = Dictionary(grouping: filtered) { cal.startOfDay(for: $0.date) }
        let sortedDays = grouped.keys.sorted(by: >)
        sections = sortedDays.map { day in
            let txs = (grouped[day] ?? []).sorted { $0.date > $1.date }
            return Section(title: day.sectionTitle, transactions: txs)
        }
        opsView.emptyLabel.isHidden = !(sections.isEmpty && !query.isEmpty)
        opsView.tableView.reloadData()
    }
}

private extension String {
    /// Case-insensitive substring match with apostrophe normalization.
    /// Only `.caseInsensitive` is used (no `.diacriticInsensitive`): for Ukrainian,
    /// diacritic folding wrongly collapses й→и and ї→і, so distinct letters would
    /// match each other. Case folding alone still matches "зар" against "Зарплата".
    func matchesSearch(_ query: String) -> Bool {
        normalizedForSearch.range(of: query.normalizedForSearch, options: .caseInsensitive) != nil
    }

    /// Unify apostrophe variants so "Здоров'я" matches whether the keyboard typed a
    /// straight ('), typographic (’), or modifier (ʼ/ʹ) apostrophe.
    private var normalizedForSearch: String {
        replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{02BC}", with: "'")
            .replacingOccurrences(of: "\u{02B9}", with: "'")
    }
}

private extension Double {
    /// Plain string forms of a money amount a user might type when searching,
    /// covering "8888", "8888.00", "8888,00" and the grouped "8 888,00".
    var searchStrings: [String] {
        let plain = String(format: "%.2f", self)                    // "8888.00"
        let comma = plain.replacingOccurrences(of: ".", with: ",")  // "8888,00"
        let grouped = hryvnia                                       // "₴8 888,00"
            .replacingOccurrences(of: "₴", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .trimmingCharacters(in: .whitespaces)                   // "8 888,00"
        return [plain, comma, grouped]
    }
}

extension OperationsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OperationCell.id, for: indexPath) as! OperationCell
        let t    = sections[indexPath.section].transactions[indexPath.row]
        let store = DataStore.shared
        let catName  = store.category(for: t.categoryId)?.name ?? "Інше"
        let accName  = store.account(for: t.accountId)?.name  ?? "Рахунок"
        let subtitle = "\(t.type.displayName) · \(accName)"
        let isIncome = t.type == .income
        let amountStr = (isIncome ? "+" : "-") + t.amount.hryvnia
        cell.configure(title: catName, subtitle: subtitle, amount: amountStr, isIncome: isIncome)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 64 }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        let label = UILabel()
        label.text = sections[section].title
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = AppColors.textSecondary
        header.addSubview(label)
        label.snp.makeConstraints { $0.leading.equalToSuperview().offset(16); $0.centerY.equalToSuperview() }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 32 }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let t = sections[indexPath.section].transactions[indexPath.row]
        guard t.type != .transfer else {
            let alert = UIAlertController(title: nil,
                                          message: "Старі операції-перекази не можна редагувати, лише видалити",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let vc = NewOperationViewController()
        vc.transactionToEdit = t
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Видалити") { [weak self] _, _, done in
            guard let self else { done(false); return }
            let id = self.sections[indexPath.section].transactions[indexPath.row].id
            DataStore.shared.deleteTransaction(id: id)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
