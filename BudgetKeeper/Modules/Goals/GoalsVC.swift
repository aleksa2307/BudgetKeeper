import UIKit

final class GoalsViewController: UIViewController {

    private var goalsView: GoalsView { view as! GoalsView }

    override func loadView() { view = GoalsView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        goalsView.backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        goalsView.addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        goalsView.tableView.dataSource = self
        goalsView.tableView.delegate   = self
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: DataStore.dataChangedNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
}

extension GoalsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        DataStore.shared.goals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GoalCell.id, for: indexPath) as! GoalCell
        let g    = DataStore.shared.goals[indexPath.row]
        let color = UIColor(hex: g.colorHex) ?? AppColors.primary
        cell.configure(name: g.name, saved: g.saved.hryvnia, target: g.target.hryvnia,
                       percent: Int(g.progress * 100), color: color)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 100 }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { UIView() }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showGoalActions(at: indexPath.row)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let del = UIContextualAction(style: .destructive, title: "Видалити") { [weak self] _, _, done in
            let id = DataStore.shared.goals[indexPath.row].id
            DataStore.shared.deleteGoal(id: id)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [del])
    }
}

private extension GoalsViewController {
    @objc func backTapped() { navigationController?.popViewController(animated: true) }

    @objc func reloadData() { goalsView.tableView.reloadData() }

    @objc func addTapped() {
        let colors = ["#FF9500", "#0066FF", "#34C759", "#5856D6", "#FF3B30"]
        let alert = UIAlertController(title: "Нова ціль", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Назва цілі" }
        alert.addTextField { tf in tf.placeholder = "Цільова сума (₴)"; tf.keyboardType = .decimalPad }

        alert.addAction(UIAlertAction(title: "Додати", style: .default) { [weak self] _ in
            guard let self else { return }
            let name   = alert.textFields?[0].text?.trimmingCharacters(in: .whitespaces) ?? ""
            let target = Double(alert.textFields?[1].text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
            guard !name.isEmpty, target > 0 else { return }
            let g = Goal(id: UUID(), name: name, target: target, saved: 0,
                         colorHex: colors[DataStore.shared.goals.count % colors.count],
                         icon: "target")
            DataStore.shared.addGoal(g)
        })
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }

    func showGoalActions(at index: Int) {
        let goal = DataStore.shared.goals[index]
        let sheet = UIAlertController(title: goal.name, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Поповнити", style: .default) { [weak self] _ in
            self?.addSavings(to: index)
        })
        sheet.addAction(UIAlertAction(title: "Редагувати", style: .default) { [weak self] _ in
            self?.editGoal(at: index)
        })
        sheet.addAction(UIAlertAction(title: "Видалити", style: .destructive) { [weak self] _ in
            self?.confirmDeleteGoal(at: index)
        })
        sheet.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(sheet, animated: true)
    }

    func editGoal(at index: Int) {
        var goal = DataStore.shared.goals[index]
        let alert = UIAlertController(title: "Редагувати ціль", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Назва цілі"; tf.text = goal.name }
        alert.addTextField { tf in
            tf.placeholder = "Цільова сума (₴)"
            tf.keyboardType = .decimalPad
            tf.text = goal.target == goal.target.rounded() ? String(Int(goal.target)) : String(goal.target)
        }
        alert.addAction(UIAlertAction(title: "Зберегти", style: .default) { _ in
            let name   = alert.textFields?[0].text?.trimmingCharacters(in: .whitespaces) ?? ""
            let target = Double(alert.textFields?[1].text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
            guard !name.isEmpty, target > 0 else { return }
            goal.name   = name
            goal.target = target
            DataStore.shared.updateGoal(goal)
        })
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }

    func confirmDeleteGoal(at index: Int) {
        let goal = DataStore.shared.goals[index]
        let alert = UIAlertController(title: "Видалити «\(goal.name)»?",
                                      message: "Цю дію не можна скасувати.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Видалити", style: .destructive) { _ in
            DataStore.shared.deleteGoal(id: goal.id)
        })
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }

    func addSavings(to index: Int) {
        var goal = DataStore.shared.goals[index]
        let alert = UIAlertController(title: "Поповнити «\(goal.name)»", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = "Сума (₴)"; tf.keyboardType = .decimalPad }
        alert.addAction(UIAlertAction(title: "Додати", style: .default) { _ in
            let amount = Double(alert.textFields?.first?.text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
            guard amount > 0 else { return }
            goal.saved += amount
            DataStore.shared.updateGoal(goal)
        })
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }
}
