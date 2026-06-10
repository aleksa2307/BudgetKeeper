import UIKit

final class AnalyticsViewController: UIViewController {

    private var analyticsView: AnalyticsView { view as! AnalyticsView }
    private var period: Period = .month

    private enum Period { case week, month, year }

    override func loadView() { view = AnalyticsView() }

    override func viewDidLoad() {
        super.viewDidLoad()
        analyticsView.periodSegment.addTarget(self, action: #selector(periodChanged), for: .valueChanged)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData),
                                               name: DataStore.dataChangedNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
}

private extension AnalyticsViewController {

    @objc func periodChanged() {
        switch analyticsView.periodSegment.selectedSegmentIndex {
        case 0: period = .week
        case 2: period = .year
        default: period = .month
        }
        reloadData()
    }

    @objc func reloadData() {
        let store = DataStore.shared
        let cal   = Calendar.current
        let now   = Date()

        let periodExpenses = store.transactions.filter { t in
            guard t.type == .expense else { return false }
            switch period {
            case .week:  return cal.isDate(t.date, equalTo: now, toGranularity: .weekOfYear)
            case .month: return cal.isDate(t.date, equalTo: now, toGranularity: .month)
            case .year:  return cal.isDate(t.date, equalTo: now, toGranularity: .year)
            }
        }

        var catTotals: [UUID: Double] = [:]
        for t in periodExpenses { catTotals[t.categoryId, default: 0] += t.amount }

        let donutSegments: [(label: String, amount: Double, color: UIColor)] = catTotals
            .sorted { $0.value > $1.value }
            .prefix(6)
            .map { pair in
                let cat   = store.category(for: pair.key)
                let name  = cat?.name ?? "Інше"
                let color = UIColor(hex: cat?.colorHex ?? "") ?? AppColors.orange
                return (name, pair.value, color)
            }
        analyticsView.donutCard.update(segments: donutSegments)

        let topItems: [(title: String, amount: Double, color: UIColor)] = periodExpenses
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map { t in
                let cat   = store.category(for: t.categoryId)
                let name  = cat?.name ?? "Інше"
                let color = UIColor(hex: cat?.colorHex ?? "") ?? AppColors.red
                return (name, t.amount, color)
            }
        analyticsView.refreshTopExpenses(topItems)

        let monthFmt = DateFormatter()
        monthFmt.locale = Locale(identifier: "uk_UA")
        monthFmt.dateFormat = "LLL"

        var barData: [BarChartView.MonthData] = []
        for offset in (0..<6).reversed() {
            guard let date = cal.date(byAdding: .month, value: -offset, to: now) else { continue }
            let y = cal.component(.year,  from: date)
            let m = cal.component(.month, from: date)

            let income = store.transactions
                .filter {
                    $0.type == .income
                        && cal.component(.year,  from: $0.date) == y
                        && cal.component(.month, from: $0.date) == m
                }
                .reduce(0) { $0 + $1.amount }

            let expense = store.transactions
                .filter {
                    $0.type == .expense
                        && cal.component(.year,  from: $0.date) == y
                        && cal.component(.month, from: $0.date) == m
                }
                .reduce(0) { $0 + $1.amount }

            let label = String(monthFmt.string(from: date).prefix(3)).capitalized
            barData.append(BarChartView.MonthData(label: label, income: CGFloat(income), expense: CGFloat(expense)))
        }
        analyticsView.barCard.update(data: barData)

        let currentBalance = store.totalBalance
        var areaData: [AreaChartView.PointData] = []

        for offset in (0..<6).reversed() {
            guard let date = cal.date(byAdding: .month, value: -offset, to: now) else { continue }
            let y = cal.component(.year,  from: date)
            let m = cal.component(.month, from: date)

            guard let monthStart = cal.date(from: DateComponents(year: y, month: m, day: 1)),
                  let nextMonthStart = cal.date(byAdding: .month, value: 1, to: monthStart)
            else { continue }

            let txAfter = store.transactions.filter { $0.date >= nextMonthStart }
            let adjustment = txAfter.reduce(0.0) { acc, t in
                switch t.type {
                case .income:   return acc - t.amount
                case .expense:  return acc + t.amount
                case .transfer: return acc
                }
            }

            let balanceAtEndOfMonth = currentBalance + adjustment
            let label = String(monthFmt.string(from: date).prefix(3)).capitalized
            areaData.append(AreaChartView.PointData(label: label, value: CGFloat(balanceAtEndOfMonth)))
        }
        analyticsView.areaCard.update(data: areaData)
    }
}
