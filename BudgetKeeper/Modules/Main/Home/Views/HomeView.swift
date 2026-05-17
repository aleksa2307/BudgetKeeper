import UIKit
import SnapKit

final class HomeView: UIView {

    let scrollView = UIScrollView()
    let contentView = UIView()

    // Header
    let greetingLabel   = UILabel()
    let dateLabel       = UILabel()
    let notificationButton = UIButton(type: .system)

    // Balance card
    let balanceCard         = UIView()
    let balanceTitleLabel   = UILabel()
    let balanceAmountLabel  = UILabel()
    let incomeChip  = SummaryChipView(title: "Доходи",  amount: "₴0,00", color: AppColors.green)
    let expenseChip = SummaryChipView(title: "Витрати", amount: "₴0,00", color: AppColors.red)

    // Budgets section
    let budgetsSectionTitle = UILabel()
    let budgetsScrollView   = UIScrollView()
    let budgetsStackView    = UIStackView()

    // Transactions section
    let transactionsSectionTitle = UILabel()
    let transactionsContainer    = UIView()
    private let transactionsStack = UIStackView()
    private let emptyTransactionsLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Public refresh methods

    func configure(userName: String, balance: Double, income: Double, expense: Double) {
        greetingLabel.text     = "Привіт, \(userName)! 👋"
        balanceAmountLabel.text = balance.hryvnia
        incomeChip.update(amount: "+\(income.hryvnia)")
        expenseChip.update(amount: "-\(expense.hryvnia)")
    }

    func refreshBudgets(_ items: [(title: String, progress: CGFloat, color: UIColor)]) {
        budgetsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (title, progress, color) in items {
            let card = BudgetCardView(title: title, progress: progress, color: color)
            budgetsStackView.addArrangedSubview(card)
            card.snp.makeConstraints { $0.width.equalTo(150) }
        }
    }

    func refreshTransactions(_ items: [(title: String, subtitle: String, amount: String, color: UIColor)]) {
        transactionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        emptyTransactionsLabel.isHidden = !items.isEmpty

        for (i, item) in items.enumerated() {
            if i > 0 {
                let sep = UIView()
                sep.backgroundColor = AppColors.separator
                transactionsStack.addArrangedSubview(sep)
                sep.snp.makeConstraints { $0.height.equalTo(0.5) }
            }
            let row = TransactionRowView(title: item.title, subtitle: item.subtitle, amount: item.amount, amountColor: item.color)
            transactionsStack.addArrangedSubview(row)
            row.snp.makeConstraints { $0.height.equalTo(60) }
        }
    }
}

private extension HomeView {
    func setupUI() {
        backgroundColor = AppColors.background
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true

        greetingLabel.text = "Привіт! 👋"
        greetingLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        greetingLabel.textColor = AppColors.textPrimary

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.dateFormat = "EEEE, d MMMM"
        dateLabel.text = formatter.string(from: Date()).capitalized
        dateLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        dateLabel.textColor = AppColors.textSecondary

        let notifConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        notificationButton.setImage(UIImage(systemName: "bell", withConfiguration: notifConfig), for: .normal)
        notificationButton.tintColor = AppColors.textPrimary

        // Balance card
        balanceCard.backgroundColor = AppColors.primary
        balanceCard.layer.cornerRadius = 24

        balanceTitleLabel.text = "Загальний баланс"
        balanceTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        balanceTitleLabel.textColor = .white.withAlphaComponent(0.7)

        balanceAmountLabel.text = "₴0,00"
        balanceAmountLabel.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        balanceAmountLabel.textColor = .white

        // Budgets
        budgetsSectionTitle.text = "Бюджети"
        budgetsSectionTitle.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        budgetsSectionTitle.textColor = AppColors.textPrimary

        budgetsScrollView.showsHorizontalScrollIndicator = false
        budgetsStackView.axis = .horizontal
        budgetsStackView.spacing = 12

        // Transactions
        transactionsSectionTitle.text = "Останні операції"
        transactionsSectionTitle.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        transactionsSectionTitle.textColor = AppColors.textPrimary

        transactionsContainer.backgroundColor = AppColors.card
        transactionsContainer.layer.cornerRadius = 16
        transactionsContainer.clipsToBounds = true

        transactionsStack.axis = .vertical

        emptyTransactionsLabel.text = "Немає операцій\nДодайте першу натиснувши +"
        emptyTransactionsLabel.numberOfLines = 2
        emptyTransactionsLabel.textAlignment = .center
        emptyTransactionsLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        emptyTransactionsLabel.textColor = AppColors.textSecondary
    }

    func setupConstraints() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(safeAreaLayoutGuide) }
        contentView.snp.makeConstraints { $0.edges.equalToSuperview(); $0.width.equalToSuperview() }

        [greetingLabel, dateLabel, notificationButton, balanceCard,
         budgetsSectionTitle, budgetsScrollView,
         transactionsSectionTitle, transactionsContainer].forEach { contentView.addSubview($0) }

        [balanceTitleLabel, balanceAmountLabel, incomeChip, expenseChip].forEach { balanceCard.addSubview($0) }

        greetingLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalTo(notificationButton.snp.leading).offset(-8)
        }
        dateLabel.snp.makeConstraints {
            $0.top.equalTo(greetingLabel.snp.bottom).offset(2)
            $0.leading.equalToSuperview().offset(16)
        }
        notificationButton.snp.makeConstraints {
            $0.centerY.equalTo(greetingLabel)
            $0.trailing.equalToSuperview().offset(-16)
            $0.size.equalTo(44)
        }
        balanceCard.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(160)
        }
        balanceTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(20)
        }
        balanceAmountLabel.snp.makeConstraints {
            $0.top.equalTo(balanceTitleLabel.snp.bottom).offset(6)
            $0.leading.equalToSuperview().offset(20)
        }
        incomeChip.snp.makeConstraints {
            $0.top.equalTo(balanceAmountLabel.snp.bottom).offset(16)
            $0.leading.equalToSuperview().offset(20)
        }
        expenseChip.snp.makeConstraints {
            $0.top.equalTo(incomeChip.snp.top)
            $0.leading.equalTo(incomeChip.snp.trailing).offset(12)
        }

        budgetsSectionTitle.snp.makeConstraints {
            $0.top.equalTo(balanceCard.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(16)
        }
        budgetsScrollView.snp.makeConstraints {
            $0.top.equalTo(budgetsSectionTitle.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(110)
        }
        budgetsScrollView.addSubview(budgetsStackView)
        budgetsStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
            $0.height.equalToSuperview()
        }

        transactionsSectionTitle.snp.makeConstraints {
            $0.top.equalTo(budgetsScrollView.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(16)
        }
        transactionsContainer.snp.makeConstraints {
            $0.top.equalTo(transactionsSectionTitle.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-16)
        }

        transactionsContainer.addSubview(transactionsStack)
        transactionsContainer.addSubview(emptyTransactionsLabel)

        transactionsStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        emptyTransactionsLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        transactionsContainer.snp.makeConstraints { $0.height.greaterThanOrEqualTo(80) }
    }
}

// MARK: - SummaryChipView

final class SummaryChipView: UIView {
    private let amountLabel = UILabel()
    private let titleLabel  = UILabel()

    init(title: String, amount: String, color: UIColor) {
        super.init(frame: .zero)
        backgroundColor = color.withAlphaComponent(0.15)
        layer.cornerRadius = 12

        amountLabel.text = amount
        amountLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        amountLabel.textColor = .white

        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        titleLabel.textColor = .white.withAlphaComponent(0.8)

        let stack = UIStackView(arrangedSubviews: [amountLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = 2
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)) }
    }

    required init?(coder: NSCoder) { fatalError() }

    func update(amount: String) { amountLabel.text = amount }
}

// MARK: - BudgetCardView

final class BudgetCardView: UIView {
    init(title: String, progress: CGFloat, color: UIColor) {
        super.init(frame: .zero)
        backgroundColor = AppColors.card
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.04
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 3

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = AppColors.textPrimary

        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 6

        let progressBg = UIView()
        progressBg.backgroundColor = AppColors.separator
        progressBg.layer.cornerRadius = 4

        let progressFill = UIView()
        progressFill.backgroundColor = color
        progressFill.layer.cornerRadius = 4

        let pctLabel = UILabel()
        pctLabel.text = "\(Int(progress * 100))%"
        pctLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        pctLabel.textColor = AppColors.textSecondary

        [dot, titleLabel, progressBg, progressFill, pctLabel].forEach { addSubview($0) }

        dot.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16); $0.size.equalTo(12) }
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14)
            $0.leading.equalTo(dot.snp.trailing).offset(6)
            $0.trailing.equalToSuperview().offset(-12)
        }
        progressBg.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-30)
            $0.height.equalTo(8)
        }
        progressFill.snp.makeConstraints {
            $0.leading.top.bottom.equalTo(progressBg)
            $0.width.equalTo(progressBg).multipliedBy(progress)
        }
        pctLabel.snp.makeConstraints { $0.bottom.equalToSuperview().offset(-12); $0.leading.equalToSuperview().offset(16) }
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - TransactionRowView

final class TransactionRowView: UIView {
    init(title: String, subtitle: String, amount: String, amountColor: UIColor) {
        super.init(frame: .zero)
        let iconView = UIView()
        iconView.backgroundColor = AppColors.background
        iconView.layer.cornerRadius = 20

        let iconImg = UIImageView()
        iconImg.image = UIImage(systemName: "arrow.up.arrow.down")
        iconImg.tintColor = AppColors.textSecondary
        iconImg.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = AppColors.textPrimary

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = AppColors.textSecondary

        let amountLabel = UILabel()
        amountLabel.text = amount
        amountLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        amountLabel.textColor = amountColor
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)

        [iconView, titleLabel, subtitleLabel, amountLabel].forEach { addSubview($0) }
        iconView.addSubview(iconImg)

        iconView.snp.makeConstraints { $0.leading.equalToSuperview().offset(16); $0.centerY.equalToSuperview(); $0.size.equalTo(40) }
        iconImg.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(18) }
        amountLabel.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-16); $0.centerY.equalToSuperview() }
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(12)
            $0.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-8)
            $0.top.equalToSuperview().offset(12)
        }
        subtitleLabel.snp.makeConstraints { $0.leading.equalTo(titleLabel); $0.top.equalTo(titleLabel.snp.bottom).offset(2) }
    }
    required init?(coder: NSCoder) { fatalError() }
}
