import UIKit
import SnapKit

final class DebtsViewController: UIViewController {

    private var debtsView: DebtsView { view as! DebtsView }
    private let addButton = UIButton(type: .system)
    private var debts: [Debt] = []

    override func loadView() { view = DebtsView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        debtsView.backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        debtsView.tableView.dataSource = self
        debtsView.tableView.delegate   = self
        debtsView.onFilterChanged = { [weak self] in self?.reloadData() }

        let cfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: cfg), for: .normal)
        addButton.tintColor = AppColors.primary
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        debtsView.addSubview(addButton)
        addButton.snp.makeConstraints {
            $0.centerY.equalTo(debtsView.backButton)
            $0.trailing.equalToSuperview().offset(-16)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: DataStore.dataChangedNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
}

extension DebtsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        debts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DebtCell.id, for: indexPath) as! DebtCell
        let d = debts[indexPath.row]
        let f = DateFormatter(); f.locale = Locale(identifier: "uk_UA"); f.dateFormat = "d MMM"
        let dateStr = "Позика · \(f.string(from: d.dueDate))"
        let typeStr = d.iOwe ? "Я винен(а)" : "Мені винні"
        cell.configure(name: d.personName, desc: dateStr, amount: d.amount.hryvnia, type: typeStr, isOwe: d.iOwe)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 68 }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { UIView() }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0 }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let del = UIContextualAction(style: .destructive, title: "Видалити") { [weak self] _, _, done in
            guard let id = self?.debts[indexPath.row].id else { done(false); return }
            DataStore.shared.deleteDebt(id: id)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [del])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let d = debts[indexPath.row]
        let sheet = UIAlertController(title: d.personName, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Закрити борг", style: .default) { [weak self] _ in
            self?.confirmCloseDebt(d)
        })
        sheet.addAction(UIAlertAction(title: "Редагувати", style: .default) { [weak self] _ in
            self?.editDebt(d)
        })
        sheet.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(sheet, animated: true)
    }
}

private extension DebtsViewController {
    @objc func backTapped() { navigationController?.popViewController(animated: true) }

    @objc func reloadData() {
        let all = DataStore.shared.debts
        switch debtsView.selectedFilter {
        case 1:  debts = all.filter { $0.iOwe }
        case 2:  debts = all.filter { !$0.iOwe }
        default: debts = all
        }
        let iOweTotal = all.filter { $0.iOwe }.reduce(0) { $0 + $1.amount }
        let owedTotal = all.filter { !$0.iOwe }.reduce(0) { $0 + $1.amount }
        debtsView.iOweCard.update(amount: iOweTotal.hryvnia)
        debtsView.owedCard.update(amount: owedTotal.hryvnia)
        debtsView.tableView.reloadData()
    }

    @objc func addTapped() {
        let alert = UIAlertController(title: "Новий борг", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Ім'я людини" }
        alert.addTextField { tf in tf.placeholder = "Сума (₴)"; tf.keyboardType = .decimalPad }

        let iOweAction  = UIAlertAction(title: "Я винен(а)", style: .default) { [weak self] _ in
            self?.createDebt(alert: alert, iOwe: true)
        }
        let oweMeAction = UIAlertAction(title: "Мені винні", style: .default) { [weak self] _ in
            self?.createDebt(alert: alert, iOwe: false)
        }
        alert.addAction(iOweAction)
        alert.addAction(oweMeAction)
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }

    func createDebt(alert: UIAlertController, iOwe: Bool) {
        let name   = alert.textFields?[0].text?.trimmingCharacters(in: .whitespaces) ?? ""
        let amount = Double(alert.textFields?[1].text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
        guard !name.isEmpty, amount > 0 else { return }
        let d = Debt(id: UUID(), personName: name, amount: amount,
                     dueDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
                     iOwe: iOwe, note: "")
        DataStore.shared.addDebt(d)
    }

    func confirmCloseDebt(_ d: Debt) {
        let alert = UIAlertController(title: "Закрити борг «\(d.personName)»?",
                                      message: "Борг буде позначено як погашений та прибраний зі списку.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Закрити", style: .default) { _ in
            DataStore.shared.deleteDebt(id: d.id)
        })
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }

    func editDebt(_ d: Debt) {
        let alert = UIAlertController(title: "Редагувати борг", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Ім'я людини"; $0.text = d.personName }
        alert.addTextField { tf in
            tf.placeholder = "Сума (₴)"
            tf.keyboardType = .decimalPad
            tf.text = d.amount == d.amount.rounded() ? String(Int(d.amount)) : String(d.amount)
        }
        alert.addAction(UIAlertAction(title: "Зберегти", style: .default) { _ in
            let name   = alert.textFields?[0].text?.trimmingCharacters(in: .whitespaces) ?? ""
            let amount = Double(alert.textFields?[1].text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
            guard !name.isEmpty, amount > 0 else { return }
            var updated = d
            updated.personName = name
            updated.amount = amount
            DataStore.shared.updateDebt(updated)
        })
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }
}
