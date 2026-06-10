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

        if indexPath.section == 0 && indexPath.row == 0 {
            row = SettingsView.Row(title: row.title, value: DataStore.shared.userName,
                                   icon: row.icon, color: row.color, accessory: row.accessory)
        }
        if indexPath.section == 2 && indexPath.row == 0 {
            let names = ["Системна", "Світла", "Темна"]
            let idx  = DataStore.shared.themeStyle
            let name = idx >= 0 && idx < names.count ? names[idx] : "Системна"
            row = SettingsView.Row(title: row.title, value: name,
                                   icon: row.icon, color: row.color, accessory: row.accessory)
        }
        cell.configure(with: row)

        if indexPath.section == 1 && indexPath.row == 1 {
            cell.toggle.isOn = DataStore.shared.isFaceIDEnabled
            cell.toggle.addTarget(self, action: #selector(faceIDToggled(_:)), for: .valueChanged)
        }

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
        switch row.title {
        case "Ім'я": editName()
        case "PIN-код": changePIN()
        case "Тема": pickTheme()
        case "Категорії": navigationController?.pushViewController(CategoriesViewController(), animated: true)
        case "Експорт у CSV": exportCSV()
        case "Експорт у PDF": exportPDF()
        case "Очистити всі дані": clearAllData()
        case "Політика конфіденційності": openPrivacyPolicy()
        default: break
        }
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

    func pickTheme() {
        let sheet = UIAlertController(title: "Тема", message: nil, preferredStyle: .actionSheet)
        let options: [(String, Int)] = [("Системна", 0), ("Світла", 1), ("Темна", 2)]
        for (name, raw) in options {
            let action = UIAlertAction(title: name, style: .default) { [weak self] _ in
                DataStore.shared.themeStyle = raw
                let style = UIUserInterfaceStyle(rawValue: raw) ?? .unspecified
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .forEach { $0.overrideUserInterfaceStyle = style }
                self?.settingsView.tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
            }
            if DataStore.shared.themeStyle == raw {
                action.setValue(true, forKey: "checked")
            }
            sheet.addAction(action)
        }
        sheet.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(sheet, animated: true)
    }

    func changePIN() {
        let vc = CreatePINViewController()
        vc.onSuccess = { [weak self] in self?.dismiss(animated: true) }
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.isHidden = true
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    func clearAllData() {
        let confirm = UIAlertController(title: "Очистити всі дані?",
                                        message: "Всі транзакції, рахунки та налаштування будуть видалені. Цю дію не можна скасувати.",
                                        preferredStyle: .alert)
        confirm.addAction(UIAlertAction(title: "Очистити", style: .destructive) { [weak self] _ in
            guard DataStore.shared.wipeAllData() else {
                let fail = UIAlertController(title: "Не вдалося очистити дані",
                                             message: "Спробуйте ще раз.", preferredStyle: .alert)
                fail.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(fail, animated: true)
                return
            }
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            let window = scene?.windows.first
            UIView.transition(with: window!, duration: 0.4, options: .transitionFlipFromLeft) {
                window?.rootViewController = OnboardingViewController()
            }
        })
        confirm.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        present(confirm, animated: true)
    }

    func exportCSV() {
        let transactions = DataStore.shared.transactions
        guard !transactions.isEmpty else { showNoDataAlert(); return }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"

        func escaped(_ field: String) -> String {
            guard field.contains(";") || field.contains("\"") || field.contains("\n") else { return field }
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }

        var csv = "\u{FEFF}"
        csv += "Дата;Тип;Категорія;Рахунок;Сума;Нотатка\n"
        for t in transactions {
            let date     = formatter.string(from: t.date)
            let category = escaped(DataStore.shared.category(for: t.categoryId)?.name ?? "Інше")
            let account  = escaped(DataStore.shared.account(for: t.accountId)?.name ?? "—")
            let amount   = String(format: "%.2f", t.amount)
            let note     = escaped(t.note)
            csv += "\(date);\(t.type.displayName);\(category);\(account);\(amount);\(note)\n"
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("BudgetKeeper.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
        } catch { return }
        present(UIActivityViewController(activityItems: [url], applicationActivities: nil), animated: true)
    }

    func exportPDF() {
        let store = DataStore.shared
        guard !store.transactions.isEmpty else { showNoDataAlert(); return }

        let pageWidth: CGFloat  = 595.2
        let pageHeight: CGFloat = 841.8
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "uk_UA")
        dateFormatter.dateStyle = .long

        let lineFormatter = DateFormatter()
        lineFormatter.dateFormat = "dd.MM.yyyy"

        let titleAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 24), .foregroundColor: UIColor.black]
        let textAttrs:  [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13),     .foregroundColor: UIColor.black]

        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = 40

            "BudgetKeeper — Фінансовий звіт".draw(at: CGPoint(x: 40, y: y), withAttributes: titleAttrs)
            y += 36
            dateFormatter.string(from: Date()).draw(at: CGPoint(x: 40, y: y), withAttributes: textAttrs)
            y += 30

            let summary = [
                "Загальний баланс: \(store.totalBalance.hryvnia)",
                "Доходи за місяць: \(store.monthlyIncome.hryvnia)",
                "Витрати за місяць: \(store.monthlyExpense.hryvnia)",
            ]
            for line in summary {
                line.draw(at: CGPoint(x: 40, y: y), withAttributes: textAttrs)
                y += 20
            }
            y += 16

            for t in store.transactions {
                if y > pageHeight - 60 {
                    context.beginPage()
                    y = 40
                }
                let category = store.category(for: t.categoryId)?.name ?? "Інше"
                let sign = t.type == .income ? "+" : "-"
                let line = "\(lineFormatter.string(from: t.date))  \(category)  \(sign)\(t.amount.hryvnia)"
                line.draw(at: CGPoint(x: 40, y: y), withAttributes: textAttrs)
                y += 18
            }
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("BudgetKeeper.pdf")
        do {
            try data.write(to: url)
        } catch { return }
        present(UIActivityViewController(activityItems: [url], applicationActivities: nil), animated: true)
    }

    func openPrivacyPolicy() {
        guard let url = URL(string: "https://www.example.com") else { return }
        UIApplication.shared.open(url)
    }

    func showNoDataAlert() {
        let alert = UIAlertController(title: "Немає операцій для експорту", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
