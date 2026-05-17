import UIKit
import SnapKit

final class RecurringPaymentsViewController: UIViewController {

    private var rpView: RecurringPaymentsView { view as! RecurringPaymentsView }
    private let addButton = UIButton(type: .system)

    override func loadView() { view = RecurringPaymentsView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        rpView.backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        rpView.tableView.dataSource = self
        rpView.tableView.delegate   = self

        let cfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        addButton.setImage(UIImage(systemName: "plus", withConfiguration: cfg), for: .normal)
        addButton.tintColor = AppColors.primary
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        rpView.addSubview(addButton)
        addButton.snp.makeConstraints {
            $0.centerY.equalTo(rpView.backButton)
            $0.trailing.equalToSuperview().offset(-16)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: DataStore.dataChangedNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
}

extension RecurringPaymentsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        DataStore.shared.recurringPayments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecurringPaymentCell.id, for: indexPath) as! RecurringPaymentCell
        let r = DataStore.shared.recurringPayments[indexPath.row]
        let f = DateFormatter(); f.locale = Locale(identifier: "uk_UA"); f.dateFormat = "d MMMM yyyy"
        let color = UIColor(hex: r.colorHex) ?? AppColors.primary
        cell.configure(name: r.name, date: f.string(from: r.nextDate), amount: "-\(r.amount.hryvnia)",
                       status: "Активна", color: color, icon: r.icon)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 68 }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { UIView() }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0 }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let del = UIContextualAction(style: .destructive, title: "Видалити") { [weak self] _, _, done in
            let id = DataStore.shared.recurringPayments[indexPath.row].id
            DataStore.shared.deleteRecurringPayment(id: id)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [del])
    }
}

private extension RecurringPaymentsViewController {
    @objc func backTapped() { navigationController?.popViewController(animated: true) }
    @objc func reloadData() { rpView.tableView.reloadData() }

    @objc func addTapped() {
        let icons  = ["tv.fill", "music.note", "cloud.fill", "figure.run", "cart.fill", "phone.fill"]
        let colors = ["#FF3B30", "#34C759", "#0066FF", "#FF9500", "#5856D6", "#8A8A8E"]

        let alert = UIAlertController(title: "Нова підписка", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Назва (напр. Netflix)" }
        alert.addTextField { tf in tf.placeholder = "Сума на місяць (₴)"; tf.keyboardType = .decimalPad }

        alert.addAction(UIAlertAction(title: "Додати", style: .default) { [weak self] _ in
            guard let self else { return }
            let name   = alert.textFields?[0].text?.trimmingCharacters(in: .whitespaces) ?? ""
            let amount = Double(alert.textFields?[1].text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
            guard !name.isEmpty, amount > 0 else { return }
            let idx = DataStore.shared.recurringPayments.count
            let nextDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            let r = RecurringPayment(id: UUID(), name: name, amount: amount, nextDate: nextDate,
                                     icon: icons[idx % icons.count], colorHex: colors[idx % colors.count])
            DataStore.shared.addRecurringPayment(r)
        })
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }
}
