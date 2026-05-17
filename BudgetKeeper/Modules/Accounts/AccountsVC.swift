import UIKit

final class AccountsViewController: UIViewController {

    private var accountsView: AccountsView { view as! AccountsView }

    override func loadView() { view = AccountsView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        accountsView.backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        accountsView.addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        accountsView.tableView.dataSource = self
        accountsView.tableView.delegate   = self
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: DataStore.dataChangedNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
}

extension AccountsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        DataStore.shared.accounts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AccountCell.id, for: indexPath) as! AccountCell
        let a = DataStore.shared.accounts[indexPath.row]
        let color = UIColor(hex: a.colorHex) ?? AppColors.primary
        cell.configure(name: a.name, type: a.typeName, amount: a.balance.hryvnia, color: color, icon: a.icon)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 68 }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { UIView() }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0 }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let del = UIContextualAction(style: .destructive, title: "Видалити") { [weak self] _, _, done in
            guard let self else { done(false); return }
            let id = DataStore.shared.accounts[indexPath.row].id
            DataStore.shared.deleteAccount(id: id)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [del])
    }
}

private extension AccountsViewController {
    @objc func backTapped() { navigationController?.popViewController(animated: true) }

    @objc func reloadData() {
        let store = DataStore.shared
        let total = store.totalBalance
        let count = store.accounts.count
        accountsView.balanceAmountLabel.text = total.hryvnia
        accountsView.balanceTitleLabel.text  = "UAH · \(count) \(accountsWord(count))"
        accountsView.tableView.reloadData()
    }

    func accountsWord(_ n: Int) -> String {
        switch n % 10 {
        case 1 where n % 100 != 11: return "рахунок"
        case 2...4 where !(11...14 ~= n % 100): return "рахунки"
        default: return "рахунків"
        }
    }

    @objc func addTapped() {
        let icons  = ["creditcard.fill", "banknote.fill", "building.columns.fill", "dollarsign.circle.fill"]
        let colors = [AppColors.primary.hexString, AppColors.green.hexString, AppColors.orange.hexString, AppColors.purple.hexString]

        let alert = UIAlertController(title: "Новий рахунок", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Назва (напр. Картка ПриватБанк)" }
        alert.addTextField { tf in
            tf.placeholder = "Початковий баланс"
            tf.keyboardType = .decimalPad
        }

        alert.addAction(UIAlertAction(title: "Додати", style: .default) { [weak self] _ in
            guard let self else { return }
            let name    = alert.textFields?[0].text?.trimmingCharacters(in: .whitespaces) ?? ""
            let balance = Double(alert.textFields?[1].text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
            guard !name.isEmpty else { return }

            let acc = Account(
                id: UUID(),
                name: name,
                typeName: "Дебетова · UAH",
                balance: balance,
                colorHex: colors[DataStore.shared.accounts.count % colors.count],
                icon: icons[DataStore.shared.accounts.count % icons.count],
                currency: "UAH"
            )
            DataStore.shared.addAccount(acc)
        })
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }
}
