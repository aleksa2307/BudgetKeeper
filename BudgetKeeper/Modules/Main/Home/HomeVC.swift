import UIKit

final class HomeViewController: UIViewController {
    private var homeView: HomeView { view as! HomeView }

    override func loadView() { view = HomeView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        homeView.notificationButton.addTarget(self, action: #selector(notificationTapped), for: .touchUpInside)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: DataStore.dataChangedNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
}

private extension HomeViewController {
    @objc func notificationTapped() {}

    @objc func reloadData() {
        let store = DataStore.shared
        homeView.configure(
            userName: store.userName,
            balance: store.totalBalance,
            income: store.monthlyIncome,
            expense: store.monthlyExpense
        )

        let budgetItems: [(title: String, progress: CGFloat, color: UIColor)] = store.budgets.prefix(5).map { b in
            let spent  = store.monthlySpent(for: b)
            let progress = b.limit > 0 ? CGFloat(min(spent / b.limit, 1.0)) : 0
            let color  = UIColor(hex: b.colorHex) ?? AppColors.primary
            return (b.name, progress, color)
        }
        homeView.refreshBudgets(budgetItems)

        let txItems: [(title: String, subtitle: String, amount: String, color: UIColor)] = store.transactions.prefix(4).map { t in
            let catName = store.category(for: t.categoryId)?.name ?? "Інше"
            let accName = store.account(for: t.accountId)?.name ?? "Рахунок"
            let subtitle = "\(t.type.displayName) · \(accName)"
            let isIncome = t.type == .income
            let amountStr = (isIncome ? "+" : "-") + t.amount.hryvnia
            let color: UIColor = isIncome ? AppColors.green : AppColors.red
            return (catName, subtitle, amountStr, color)
        }
        homeView.refreshTransactions(txItems)
    }
}
