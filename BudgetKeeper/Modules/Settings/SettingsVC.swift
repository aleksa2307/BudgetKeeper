import UIKit
import SnapKit

final class SettingsViewController: UIViewController {

    private var settingsView: SettingsView { view as! SettingsView }

    override func loadView() { view = SettingsView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        settingsView.backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        settingsView.tableView.dataSource = self
        settingsView.tableView.delegate   = self
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { settingsView.sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        settingsView.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsCell.id, for: indexPath) as! SettingsCell
        var row  = settingsView.sections[indexPath.section].rows[indexPath.row]

        // Override name value dynamically
        if indexPath.section == 0 && indexPath.row == 0 {
            row = SettingsView.Row(title: row.title, value: DataStore.shared.userName,
                                   icon: row.icon, color: row.color, accessory: row.accessory)
        }
        cell.configure(with: row)

        // Face ID toggle state
        if indexPath.section == 1 && indexPath.row == 1 {
            cell.toggle.isOn = DataStore.shared.isFaceIDEnabled
            cell.toggle.addTarget(self, action: #selector(faceIDToggled(_:)), for: .valueChanged)
        }

        // Corner radius for first/last in section
        let section  = settingsView.sections[indexPath.section]
        let isFirst  = indexPath.row == 0
        let isLast   = indexPath.row == section.rows.count - 1
        var corners: CACornerMask = []
        if isFirst { corners.insert([.layerMinXMinYCorner, .layerMaxXMinYCorner]) }
        if isLast  { corners.insert([.layerMinXMaxYCorner, .layerMaxXMaxYCorner]) }
        cell.contentView.layer.cornerRadius = 16
        cell.contentView.layer.maskedCorners = corners
        cell.contentView.clipsToBounds = true

        if !isLast {
            let sep = UIView(); sep.backgroundColor = AppColors.separator
            cell.contentView.addSubview(sep)
            sep.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(60)
                $0.trailing.bottom.equalToSuperview()
                $0.height.equalTo(0.5)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 52 }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        let label  = UILabel()
        label.text = settingsView.sections[section].title
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = AppColors.textSecondary
        header.addSubview(label)
        label.snp.makeConstraints { $0.leading.equalToSuperview().offset(20); $0.bottom.equalToSuperview().offset(-4) }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 40 }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { UIView() }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 8 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = settingsView.sections[indexPath.section].rows[indexPath.row]
        switch (indexPath.section, indexPath.row) {
        case (0, 0): editName()
        case (1, 0): changePIN()
        case (4, 4): clearAllData()
        default: break
        }
        _ = row
    }
}

private extension SettingsViewController {
    @objc func backTapped() { navigationController?.popViewController(animated: true) }

    @objc func faceIDToggled(_ sender: UISwitch) {
        DataStore.shared.isFaceIDEnabled = sender.isOn
    }

    func editName() {
        let alert = UIAlertController(title: "Ваше ім'я", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.text = DataStore.shared.userName; tf.placeholder = "Ім'я" }
        alert.addAction(UIAlertAction(title: "Зберегти", style: .default) { [weak self] _ in
            let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces) ?? ""
            if !name.isEmpty {
                DataStore.shared.userName = name
                self?.settingsView.tableView.reloadData()
            }
        })
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(alert, animated: true)
    }

    func changePIN() {
        let vc  = CreatePINViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    func clearAllData() {
        let confirm = UIAlertController(title: "Очистити всі дані?",
                                        message: "Всі транзакції, рахунки та налаштування будуть видалені. Цю дію не можна скасувати.",
                                        preferredStyle: .alert)
        confirm.addAction(UIAlertAction(title: "Очистити", style: .destructive) { _ in
            let domain = Bundle.main.bundleIdentifier ?? ""
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            // Restart to onboarding
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let window = scene?.windows.first
            UIView.transition(with: window!, duration: 0.4, options: .transitionFlipFromLeft) {
                window?.rootViewController = OnboardingViewController()
            }
        })
        confirm.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(confirm, animated: true)
    }
}
