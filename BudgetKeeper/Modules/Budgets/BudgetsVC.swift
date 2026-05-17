import UIKit
import SnapKit

final class BudgetsViewController: UIViewController {

    private var budgetsView: BudgetsView { view as! BudgetsView }
    private let addButton = UIButton(type: .system)

    override func loadView() { view = BudgetsView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        budgetsView.backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        budgetsView.tableView.dataSource = self
        budgetsView.tableView.delegate   = self

        // Add button in top-right
        let cfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: cfg), for: .normal)
        addButton.tintColor = AppColors.primary
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        budgetsView.addSubview(addButton)
        addButton.snp.makeConstraints {
            $0.centerY.equalTo(budgetsView.backButton)
            $0.trailing.equalToSuperview().offset(-16)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: DataStore.dataChangedNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
}

extension BudgetsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        DataStore.shared.budgets.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BudgetItemCell.id, for: indexPath) as! BudgetItemCell
        let b    = DataStore.shared.budgets[indexPath.row]
        let spent = DataStore.shared.monthlySpent(for: b)
        let pct   = b.limit > 0 ? Int(min(spent / b.limit * 100, 100)) : 0
        let color = UIColor(hex: b.colorHex) ?? AppColors.primary
        let spentStr = "\(spent.hryvnia) з \(b.limit.hryvnia)"
        cell.configure(name: b.name, spent: spentStr, percent: pct, color: color)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 96 }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { UIView() }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0 }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let del = UIContextualAction(style: .destructive, title: "Видалити") { [weak self] _, _, done in
            let id = DataStore.shared.budgets[indexPath.row].id
            DataStore.shared.deleteBudget(id: id)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [del])
    }
}

private extension BudgetsViewController {
    @objc func backTapped() { navigationController?.popViewController(animated: true) }

    @objc func reloadData() { budgetsView.tableView.reloadData() }

    @objc func addTapped() {
        let cats   = DataStore.expenseCategories
        let colors = ["#FF9500", "#5856D6", "#34C759", "#0066FF", "#FF3B30"]

        let alert = UIAlertController(title: "Новий бюджет", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Ліміт (₴)" ; $0.keyboardType = .decimalPad }

        alert.addAction(UIAlertAction(title: "Далі", style: .default) { [weak self] _ in
            guard let self else { return }
            let limit = Double(alert.textFields?.first?.text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
            guard limit > 0 else { return }
            self.pickCategory(cats: cats, colors: colors, limit: limit)
        })
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }

    func pickCategory(cats: [Category], colors: [String], limit: Double) {
        let sheet = UIAlertController(title: "Категорія", message: nil, preferredStyle: .actionSheet)
        let idx = DataStore.shared.budgets.count
        for cat in cats {
            sheet.addAction(UIAlertAction(title: cat.name, style: .default) { _ in
                let b = Budget(id: UUID(), name: cat.name, limit: limit, categoryId: cat.id, colorHex: colors[idx % colors.count])
                DataStore.shared.addBudget(b)
            })
        }
        sheet.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(sheet, animated: true)
    }
}
