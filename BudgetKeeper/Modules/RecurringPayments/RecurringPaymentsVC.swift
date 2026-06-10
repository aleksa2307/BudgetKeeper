import UIKit
import SnapKit

final class RecurringPaymentsViewController: UIViewController {

    private var rpView: RecurringPaymentsView { view as! RecurringPaymentsView }
    private let addButton = UIButton(type: .system)
    private var payments: [RecurringPayment] = []

    override func loadView() { view = RecurringPaymentsView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        rpView.backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        rpView.segmentControl.addTarget(self, action: #selector(reloadData), for: .valueChanged)
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
        payments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecurringPaymentCell.id, for: indexPath) as! RecurringPaymentCell
        let r = payments[indexPath.row]
        let f = DateFormatter(); f.locale = Locale(identifier: "uk_UA"); f.dateFormat = "d MMMM yyyy"
        let color = UIColor(hex: r.colorHex) ?? AppColors.primary
        cell.configure(name: r.name, date: f.string(from: r.nextDate), amount: "-\(r.amount.hryvnia)",
                       status: r.isPaused ? "Призупинена" : "Активна",
                       statusColor: r.isPaused ? AppColors.orange : AppColors.green,
                       color: color, icon: r.icon)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 68 }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { UIView() }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showActions(for: payments[indexPath.row])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let del = UIContextualAction(style: .destructive, title: "Видалити") { [weak self] _, _, done in
            guard let self, indexPath.row < self.payments.count else { done(false); return }
            DataStore.shared.deleteRecurringPayment(id: self.payments[indexPath.row].id)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [del])
    }
}

private extension RecurringPaymentsViewController {
    @objc func backTapped() { navigationController?.popViewController(animated: true) }

    @objc func reloadData() {
        let all = DataStore.shared.recurringPayments
        switch rpView.segmentControl.selectedSegmentIndex {
        case 0:
            let horizon = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            payments = all.filter { !$0.isPaused && $0.nextDate <= horizon }.sorted { $0.nextDate < $1.nextDate }
        case 1:
            payments = all.filter { !$0.isPaused }.sorted { $0.nextDate < $1.nextDate }
        default:
            payments = all.filter { $0.isPaused }
        }
        rpView.tableView.reloadData()
    }

    func showActions(for payment: RecurringPayment) {
        let sheet = UIAlertController(title: payment.name, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Оплатити", style: .default) { [weak self] _ in
            self?.payTapped(payment)
        })
        sheet.addAction(UIAlertAction(title: "Редагувати", style: .default) { [weak self] _ in
            self?.editTapped(payment)
        })
        sheet.addAction(UIAlertAction(title: payment.isPaused ? "Відновити" : "Призупинити", style: .default) { _ in
            var p = payment
            p.isPaused.toggle()
            DataStore.shared.updateRecurringPayment(p)
        })
        sheet.addAction(UIAlertAction(title: "Закрити", style: .destructive) { [weak self] _ in
            self?.confirmClose(payment)
        })
        sheet.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(sheet, animated: true)
    }

    func payTapped(_ payment: RecurringPayment) {
        let accounts = DataStore.shared.accounts
        guard !accounts.isEmpty else {
            let alert = UIAlertController(title: "Спочатку додайте рахунок у розділі «Ще → Рахунки»", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let sheet = UIAlertController(title: "Рахунок", message: nil, preferredStyle: .actionSheet)
        for acc in accounts {
            sheet.addAction(UIAlertAction(title: "\(acc.name) (\(acc.balance.hryvnia))", style: .default) { [weak self] _ in
                let t = Transaction(id: UUID(), type: .expense, amount: payment.amount,
                                    categoryId: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
                                    accountId: acc.id, toAccountId: nil, date: Date(), note: payment.name)
                DataStore.shared.addTransaction(t)
                var p = payment
                p.nextDate = Calendar.current.date(byAdding: .month, value: 1, to: p.nextDate) ?? p.nextDate
                DataStore.shared.updateRecurringPayment(p)
                let done = UIAlertController(title: "Платіж оплачено", message: nil, preferredStyle: .alert)
                done.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(done, animated: true)
            })
        }
        sheet.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(sheet, animated: true)
    }

    func editTapped(_ payment: RecurringPayment) {
        let alert = UIAlertController(title: "Редагувати підписку", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Назва (напр. Netflix)"; $0.text = payment.name }
        alert.addTextField { tf in
            tf.placeholder = "Сума на місяць (₴)"; tf.keyboardType = .decimalPad
            tf.text = payment.amount == payment.amount.rounded() ? String(Int(payment.amount)) : String(payment.amount)
        }
        alert.addAction(UIAlertAction(title: "Зберегти", style: .default) { _ in
            let name   = alert.textFields?[0].text?.trimmingCharacters(in: .whitespaces) ?? ""
            let amount = Double(alert.textFields?[1].text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
            guard !name.isEmpty, amount > 0 else { return }
            var p = payment
            p.name = name
            p.amount = amount
            DataStore.shared.updateRecurringPayment(p)
        })
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }

    func confirmClose(_ payment: RecurringPayment) {
        let alert = UIAlertController(title: "Закрити «\(payment.name)»?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Закрити", style: .destructive) { _ in
            DataStore.shared.deleteRecurringPayment(id: payment.id)
        })
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }

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
