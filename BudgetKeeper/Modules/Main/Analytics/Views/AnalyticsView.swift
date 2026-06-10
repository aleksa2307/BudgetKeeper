import UIKit
import SnapKit

final class DonutChartView: UIView {
    var segments: [(value: CGFloat, color: UIColor)] = [] { didSet { setNeedsDisplay() } }

    override init(frame: CGRect) { super.init(frame: frame); backgroundColor = .clear }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        let total = segments.reduce(0) { $0 + $1.value }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerR = min(rect.width, rect.height) / 2 - 4
        let innerR = outerR * 0.55

        if total <= 0 {
            let circle = UIBezierPath(arcCenter: center, radius: outerR,
                                      startAngle: 0, endAngle: .pi * 2, clockwise: true)
            AppColors.separator.setFill()
            circle.fill()
        } else {
            var angle: CGFloat = -.pi / 2
            for seg in segments {
                let sweep = .pi * 2 * seg.value / total
                let path = UIBezierPath()
                path.move(to: center)
                path.addArc(withCenter: center, radius: outerR,
                            startAngle: angle, endAngle: angle + sweep, clockwise: true)
                path.close()
                seg.color.setFill()
                path.fill()
                angle += sweep
            }
        }

        let hole = UIBezierPath(arcCenter: center, radius: innerR,
                                startAngle: 0, endAngle: .pi * 2, clockwise: true)
        AppColors.card.setFill()
        hole.fill()
    }
}

final class DonutChartCardView: UIView {
    private let titleLabel = UILabel()
    let chartView = DonutChartView()
    private let legendStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColors.card
        layer.cornerRadius = 16
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        titleLabel.text = "Витрати за категоріями"
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = AppColors.textPrimary

        legendStack.axis = .vertical
        legendStack.spacing = 6

        addSubview(titleLabel)
        addSubview(chartView)
        addSubview(legendStack)

        titleLabel.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16) }
        chartView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.width.height.equalTo(120)
            $0.bottom.equalToSuperview().offset(-16)
        }
        legendStack.snp.makeConstraints {
            $0.leading.equalTo(chartView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(chartView)
        }
    }

    func update(segments: [(label: String, amount: Double, color: UIColor)]) {
        chartView.segments = segments.map { (CGFloat($0.amount), $0.color) }
        legendStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for seg in segments {
            legendStack.addArrangedSubview(DonutLegendRow(color: seg.color, name: seg.label, amount: seg.amount.hryvnia))
        }
    }
}

private final class DonutLegendRow: UIView {
    init(color: UIColor, name: String, amount: String) {
        super.init(frame: .zero)

        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 5

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 12)
        nameLabel.textColor = AppColors.textPrimary
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let amountLabel = UILabel()
        amountLabel.text = amount
        amountLabel.font = .systemFont(ofSize: 12, weight: .medium)
        amountLabel.textColor = AppColors.textPrimary
        amountLabel.textAlignment = .right
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(dot); addSubview(nameLabel); addSubview(amountLabel)

        dot.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.size.equalTo(10)
        }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(dot.snp.trailing).offset(6)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-4)
        }
        amountLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    override var intrinsicContentSize: CGSize { CGSize(width: UIView.noIntrinsicMetric, height: 22) }
}

final class BarChartView: UIView {
    struct MonthData {
        let label: String
        let income: CGFloat
        let expense: CGFloat
    }

    var data: [MonthData] = [] { didSet { setNeedsDisplay() } }

    private let labelH: CGFloat = 20
    private let barW: CGFloat = 10

    override init(frame: CGRect) { super.init(frame: frame); backgroundColor = .clear }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard !data.isEmpty else { return }
        let maxVal = data.flatMap { [$0.income, $0.expense] }.max() ?? 1
        let chartH = rect.height - labelH
        let slotW = rect.width / CGFloat(data.count)

        for (i, item) in data.enumerated() {
            let midX = CGFloat(i) * slotW + slotW / 2

            if item.income > 0 {
                let h = item.income / maxVal * chartH
                let r = CGRect(x: midX - barW - 2, y: chartH - h, width: barW, height: h)
                let p = UIBezierPath(roundedRect: r, byRoundingCorners: [.topLeft, .topRight],
                                     cornerRadii: CGSize(width: 4, height: 4))
                AppColors.green.setFill(); p.fill()
            }

            if item.expense > 0 {
                let h = item.expense / maxVal * chartH
                let r = CGRect(x: midX + 2, y: chartH - h, width: barW, height: h)
                let p = UIBezierPath(roundedRect: r, byRoundingCorners: [.topLeft, .topRight],
                                     cornerRadii: CGSize(width: 4, height: 4))
                AppColors.red.setFill(); p.fill()
            }

            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: AppColors.textSecondary
            ]
            let s = item.label as NSString
            let sz = s.size(withAttributes: attrs)
            s.draw(at: CGPoint(x: midX - sz.width / 2, y: rect.height - labelH + 4), withAttributes: attrs)
        }
    }
}

final class BarChartCardView: UIView {
    let chartView = BarChartView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColors.card
        layer.cornerRadius = 16
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "Доходи та витрати"
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = AppColors.textPrimary

        let incomeRow = legendItem(color: AppColors.green, text: "Доходи")
        let expenseRow = legendItem(color: AppColors.red, text: "Витрати")
        let legendStack = UIStackView(arrangedSubviews: [incomeRow, expenseRow])
        legendStack.axis = .horizontal
        legendStack.spacing = 16

        addSubview(titleLabel)
        addSubview(legendStack)
        addSubview(chartView)

        titleLabel.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16) }
        legendStack.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalTo(titleLabel)
        }
        chartView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-12)
        }
    }

    private func legendItem(color: UIColor, text: String) -> UIView {
        let dot = UIView(); dot.backgroundColor = color; dot.layer.cornerRadius = 4
        let label = UILabel(); label.text = text
        label.font = .systemFont(ofSize: 12); label.textColor = AppColors.textSecondary
        let stack = UIStackView(arrangedSubviews: [dot, label])
        stack.spacing = 4; stack.alignment = .center
        dot.snp.makeConstraints { $0.size.equalTo(8) }
        return stack
    }

    func update(data: [BarChartView.MonthData]) { chartView.data = data }
}

final class AreaChartView: UIView {
    struct PointData {
        let label: String
        let value: CGFloat
    }

    var data: [PointData] = [] { didSet { setNeedsDisplay() } }

    private let labelH: CGFloat = 20

    override init(frame: CGRect) { super.init(frame: frame); backgroundColor = .clear }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard data.count > 1 else { return }
        let chartH = rect.height - labelH
        let minVal = data.map(\.value).min() ?? 0
        let maxVal = data.map(\.value).max() ?? 1
        let range = max(maxVal - minVal, 1)
        let pad: CGFloat = 12
        let step = (rect.width - pad * 2) / CGFloat(data.count - 1)

        func pt(_ i: Int) -> CGPoint {
            let x = pad + CGFloat(i) * step
            let norm = (data[i].value - minVal) / range
            let y = chartH * 0.9 - norm * chartH * 0.78
            return CGPoint(x: x, y: y)
        }

        let line = UIBezierPath()
        line.move(to: pt(0))
        for i in 1..<data.count {
            let a = pt(i - 1), b = pt(i)
            line.addCurve(to: b,
                          controlPoint1: CGPoint(x: a.x + step / 2.5, y: a.y),
                          controlPoint2: CGPoint(x: b.x - step / 2.5, y: b.y))
        }

        let fill = line.copy() as! UIBezierPath
        fill.addLine(to: CGPoint(x: pt(data.count - 1).x, y: chartH))
        fill.addLine(to: CGPoint(x: pt(0).x, y: chartH))
        fill.close()

        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState()
        fill.addClip()
        let grad = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [AppColors.primary.withAlphaComponent(0.25).cgColor,
                     AppColors.primary.withAlphaComponent(0).cgColor] as CFArray,
            locations: [0, 1]
        )!
        ctx.drawLinearGradient(grad, start: .zero, end: CGPoint(x: 0, y: chartH), options: [])
        ctx.restoreGState()

        AppColors.primary.setStroke()
        line.lineWidth = 2.5
        line.lineCapStyle = .round
        line.lineJoinStyle = .round
        line.stroke()

        for i in 0..<data.count {
            let p = pt(i)
            let outer = UIBezierPath(arcCenter: p, radius: 3.5, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            AppColors.card.setFill(); outer.fill()
            let inner = UIBezierPath(arcCenter: p, radius: 2, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            AppColors.primary.setFill(); inner.fill()
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: AppColors.textSecondary
        ]
        for (i, item) in data.enumerated() {
            let p = pt(i)
            let s = item.label as NSString
            let sz = s.size(withAttributes: attrs)
            let x = max(0, min(rect.width - sz.width, p.x - sz.width / 2))
            s.draw(at: CGPoint(x: x, y: rect.height - labelH + 2), withAttributes: attrs)
        }
    }
}

final class AreaChartCardView: UIView {
    let chartView = AreaChartView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColors.card
        layer.cornerRadius = 16
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "Динаміка балансу"
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = AppColors.textPrimary

        addSubview(titleLabel)
        addSubview(chartView)

        titleLabel.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(16) }
        chartView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-12)
        }
    }

    func update(data: [AreaChartView.PointData]) { chartView.data = data }
}

final class RankedExpenseRowView: UIView {
    init(rank: Int, name: String, amount: String) {
        super.init(frame: .zero)

        let rankBg = UIView()
        rankBg.backgroundColor = AppColors.background
        rankBg.layer.cornerRadius = 16

        let rankLabel = UILabel()
        rankLabel.text = "\(rank)"
        rankLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        rankLabel.textColor = AppColors.textSecondary
        rankLabel.textAlignment = .center

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 15)
        nameLabel.textColor = AppColors.textPrimary
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let amountLabel = UILabel()
        amountLabel.text = "-\(amount)"
        amountLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        amountLabel.textColor = AppColors.red
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)
        amountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addSubview(rankBg); rankBg.addSubview(rankLabel)
        addSubview(nameLabel); addSubview(amountLabel)

        rankBg.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(32)
        }
        rankLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(rankBg.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-8)
        }
        amountLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }
}

final class AnalyticsView: UIView {
    let scrollView    = UIScrollView()
    let contentView   = UIView()
    let headerLabel   = UILabel()
    let periodSegment = UISegmentedControl(items: ["Тиждень", "Місяць", "Рік"])
    let donutCard     = DonutChartCardView()
    let barCard       = BarChartCardView()
    let areaCard      = AreaChartCardView()
    let topLabel      = UILabel()
    let topCard       = UIView()
    private let topStack = UIStackView()
    let emptyLabel    = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    required init?(coder: NSCoder) { fatalError() }

    func refreshTopExpenses(_ items: [(title: String, amount: Double, color: UIColor)]) {
        topStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        emptyLabel.isHidden = !items.isEmpty

        for (i, item) in items.enumerated() {
            if i > 0 {
                let sep = UIView(); sep.backgroundColor = AppColors.separator
                topStack.addArrangedSubview(sep)
                sep.snp.makeConstraints { $0.height.equalTo(0.5) }
            }
            let row = RankedExpenseRowView(rank: i + 1, name: item.title, amount: item.amount.hryvnia)
            topStack.addArrangedSubview(row)
            row.snp.makeConstraints { $0.height.equalTo(56) }
        }
    }

    private func setupUI() {
        backgroundColor = AppColors.background
        scrollView.showsVerticalScrollIndicator = false

        headerLabel.text = "Аналітика"
        headerLabel.font = .systemFont(ofSize: 34, weight: .bold)
        headerLabel.textColor = AppColors.textPrimary

        periodSegment.selectedSegmentIndex = 1
        periodSegment.backgroundColor = AppColors.card

        topLabel.text = "Найбільші витрати"
        topLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        topLabel.textColor = AppColors.textPrimary

        topCard.backgroundColor = AppColors.card
        topCard.layer.cornerRadius = 16
        topCard.clipsToBounds = true

        topStack.axis = .vertical

        emptyLabel.text = "Немає витрат за обраний період"
        emptyLabel.font = .systemFont(ofSize: 14)
        emptyLabel.textColor = AppColors.textSecondary
        emptyLabel.textAlignment = .center
    }

    private func setupConstraints() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(safeAreaLayoutGuide) }
        contentView.snp.makeConstraints { $0.edges.equalToSuperview(); $0.width.equalToSuperview() }

        [headerLabel, periodSegment, donutCard, barCard, areaCard, topLabel, topCard]
            .forEach { contentView.addSubview($0) }

        headerLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
        }
        periodSegment.snp.makeConstraints {
            $0.top.equalTo(headerLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(36)
        }
        donutCard.snp.makeConstraints {
            $0.top.equalTo(periodSegment.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        barCard.snp.makeConstraints {
            $0.top.equalTo(donutCard.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(200)
        }
        areaCard.snp.makeConstraints {
            $0.top.equalTo(barCard.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(180)
        }
        topLabel.snp.makeConstraints {
            $0.top.equalTo(areaCard.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(16)
        }
        topCard.snp.makeConstraints {
            $0.top.equalTo(topLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().offset(-16)
            $0.height.greaterThanOrEqualTo(60)
        }

        topCard.addSubview(topStack)
        topCard.addSubview(emptyLabel)
        topStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }
}
