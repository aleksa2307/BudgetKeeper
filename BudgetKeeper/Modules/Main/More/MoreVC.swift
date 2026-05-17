import UIKit

final class MoreViewController: UIViewController {

    private var moreView: MoreView { view as! MoreView }

    override func loadView() { view = MoreView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        moreView.onItemTapped = { [weak self] index in
            self?.navigate(to: index)
        }
    }

    private func navigate(to index: Int) {
        let vc: UIViewController
        switch index {
        case 0: vc = AccountsViewController()
        case 1: vc = BudgetsViewController()
        case 2: vc = GoalsViewController()
        case 3: vc = RecurringPaymentsViewController()
        case 4: vc = DebtsViewController()
        case 5: vc = SettingsViewController()
        default: return
        }
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}
