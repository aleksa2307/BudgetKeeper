import UIKit
import SnapKit

final class OnboardingView: UIView {

    let iconView = UIView()
    let iconImageView = UIImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let pageControl = UIPageControl()
    let nextButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(page: Int, animated: Bool) {
        let pages: [(icon: String, title: String, subtitle: String)] = [
            ("chart.line.uptrend.xyaxis",
             "Слідкуй за кожною копійкою",
             "Контролюй доходи та витрати,\nбудуй фінансові цілі"),
            ("chart.pie.fill",
             "Плануй бюджет розумно",
             "Розподіляй кошти за категоріями\nі не виходь за межі бюджету"),
            ("target",
             "Досягай фінансових цілей",
             "Відкладай на мрії, відстежуй\nпрогрес і мотивуй себе"),
        ]

        let data = pages[page]
        let isLast = page == pages.count - 1

        let update = {
            let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .medium)
            self.iconImageView.image = UIImage(systemName: data.icon, withConfiguration: config)
            self.titleLabel.text = data.title
            self.subtitleLabel.text = data.subtitle
            self.pageControl.currentPage = page
            let title = isLast ? "Почати" : "Далі"
            self.nextButton.setTitle(title, for: .normal)
        }

        if animated {
            UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: update)
        } else {
            update()
        }
    }
}

private extension OnboardingView {
    func setupUI() {
        backgroundColor = .white

        iconView.backgroundColor = AppColors.primary.withAlphaComponent(0.1)
        iconView.layer.cornerRadius = 40

        let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .medium)
        iconImageView.image = UIImage(systemName: "chart.line.uptrend.xyaxis", withConfiguration: config)
        iconImageView.tintColor = AppColors.primary
        iconImageView.contentMode = .scaleAspectFit

        titleLabel.text = "Слідкуй за кожною копійкою"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = AppColors.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        subtitleLabel.text = "Контролюй доходи та витрати,\nбудуй фінансові цілі"
        subtitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        subtitleLabel.textColor = AppColors.textSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        pageControl.numberOfPages = 3
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = AppColors.primary
        pageControl.pageIndicatorTintColor = AppColors.separator
        pageControl.isUserInteractionEnabled = false

        nextButton.setTitle("Далі", for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        nextButton.backgroundColor = AppColors.primary
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 16
    }

    func setupConstraints() {
        [iconView, titleLabel, subtitleLabel, pageControl, nextButton].forEach {
            addSubview($0)
        }
        iconView.addSubview(iconImageView)

        iconView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(safeAreaLayoutGuide).offset(80)
            $0.size.equalTo(120)
        }
        iconImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(64)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(iconView.snp.bottom).offset(40)
            $0.leading.trailing.equalToSuperview().inset(32)
        }
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(32)
        }
        pageControl.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(nextButton.snp.top).offset(-32)
        }
        nextButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-24)
            $0.height.equalTo(56)
        }
    }
}
