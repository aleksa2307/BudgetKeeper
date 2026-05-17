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
        let all = DataStore.shared.transactions

        let filtered: [Transaction]
        switch opsView.selectedFilter {
        case 1: filtered = all.filter { $0.type == .income }
        case 2: filtered = all.filter { $0.type == .expense }
        case 3: filtered = all.filter { $0.type == .transfer }
        default: filtered = all
        }

        let grouped = Dictionary(grouping: filtered) { cal.startOfDay(for: $0.date) }
        let sortedDays = grouped.keys.sorted(by: >)
        sections = sortedDays.map { day in
            let txs = (grouped[day] ?? []).sorted { $0.date > $1.date }
            return Section(title: day.sectionTitle, transactions: txs)
        }
        opsView.tableView.reloadData()
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
