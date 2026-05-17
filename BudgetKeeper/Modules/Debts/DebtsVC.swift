import UIKit
import SnapKit

final class DebtsViewController: UIViewController {

    private var debtsView: DebtsView { view as! DebtsView }
    private let addButton = UIButton(type: .system)

    override func loadView() { view = DebtsView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        debtsView.backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        debtsView.tableView.dataSource = self
        debtsView.tableView.delegate   = self

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
        DataStore.shared.debts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DebtCell.id, for: indexPath) as! DebtCell
        let d = DataStore.shared.debts[indexPath.row]
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
            let id = DataStore.shared.debts[indexPath.row].id
            DataStore.shared.deleteDebt(id: id)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [del])
    }
}

private extension DebtsViewController {
    @objc func backTapped() { navigationController?.popViewController(animated: true) }
    @objc func reloadData() { debtsView.tableView.reloadData() }

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
}
