(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_USAGE (err u101))
(define-constant ERR_BUILDING_NOT_FOUND (err u102))
(define-constant ERR_INVALID_BENCHMARK (err u103))
(define-constant ERR_INSUFFICIENT_DATA (err u104))
(define-constant ERR_INVALID_EFFICIENCY_SCORE (err u105))

(define-data-var contract-owner principal tx-sender)
(define-data-var total-buildings uint u0)
(define-data-var total-reports uint u0)
(define-data-var benchmark-threshold uint u1000)

(define-map Buildings
  { building-id: uint }
  {
    owner: principal,
    name: (string-ascii 64),
    building-type: (string-ascii 32),
    square-footage: uint,
    created-at: uint,
    is-active: bool
  }
)

(define-map EnergyReports
  { building-id: uint, report-id: uint }
  {
    reporter: principal,
    energy-usage: uint,
    reporting-period: uint,
    timestamp: uint,
    efficiency-score: uint
  }
)

(define-map BuildingStats
  { building-id: uint }
  {
    total-reports: uint,
    average-usage: uint,
    best-efficiency: uint,
    last-updated: uint
  }
)

(define-map BenchmarkData
  { building-type: (string-ascii 32) }
  {
    average-usage-per-sqft: uint,
    sample-size: uint,
    last-calculated: uint
  }
)

(define-map UserRewards
  { user: principal }
  {
    total-reports: uint,
    reward-points: uint,
    last-activity: uint
  }
)

(define-public (register-building (name (string-ascii 64)) (building-type (string-ascii 32)) (square-footage uint))
  (let
    (
      (building-id (+ (var-get total-buildings) u1))
      (current-block stacks-block-height)
    )
    (asserts! (> square-footage u0) ERR_INVALID_USAGE)
    (map-set Buildings
      { building-id: building-id }
      {
        owner: tx-sender,
        name: name,
        building-type: building-type,
        square-footage: square-footage,
        created-at: current-block,
        is-active: true
      }
    )
    (map-set BuildingStats
      { building-id: building-id }
      {
        total-reports: u0,
        average-usage: u0,
        best-efficiency: u0,
        last-updated: current-block
      }
    )
    (var-set total-buildings building-id)
    (ok building-id)
  )
)

(define-public (submit-energy-report (building-id uint) (energy-usage uint) (reporting-period uint))
  (let
    (
      (building-data (unwrap! (map-get? Buildings { building-id: building-id }) ERR_BUILDING_NOT_FOUND))
      (current-block stacks-block-height)
      (report-id (+ (var-get total-reports) u1))
      (efficiency-score (calculate-efficiency-score energy-usage (get square-footage building-data)))
    )
    (asserts! (> energy-usage u0) ERR_INVALID_USAGE)
    (asserts! (> reporting-period u0) ERR_INVALID_USAGE)
    (asserts! (get is-active building-data) ERR_BUILDING_NOT_FOUND)
    (map-set EnergyReports
      { building-id: building-id, report-id: report-id }
      {
        reporter: tx-sender,
        energy-usage: energy-usage,
        reporting-period: reporting-period,
        timestamp: current-block,
        efficiency-score: efficiency-score
      }
    )
    (begin
      (update-building-stats building-id energy-usage efficiency-score)
      (update-user-rewards tx-sender)
      (update-benchmark-data (get building-type building-data) energy-usage (get square-footage building-data))
      (var-set total-reports report-id)
      (ok report-id)
    )
  )
)

(define-private (calculate-efficiency-score (energy-usage uint) (square-footage uint))
  (let
    (
      (usage-per-sqft (/ energy-usage square-footage))
      (efficiency-base u10000)
    )
    (if (<= usage-per-sqft u10)
      (- efficiency-base (* usage-per-sqft u100))
      (if (<= usage-per-sqft u50)
        (- efficiency-base (* usage-per-sqft u200))
        u1000
      )
    )
  )
)

(define-private (update-building-stats (building-id uint) (new-usage uint) (efficiency-score uint))
  (let
    (
      (current-stats (default-to
        { total-reports: u0, average-usage: u0, best-efficiency: u0, last-updated: u0 }
        (map-get? BuildingStats { building-id: building-id })
      ))
      (new-report-count (+ (get total-reports current-stats) u1))
      (current-average (get average-usage current-stats))
      (new-average (/ (+ (* current-average (get total-reports current-stats)) new-usage) new-report-count))
      (best-efficiency (if (> efficiency-score (get best-efficiency current-stats))
        efficiency-score
        (get best-efficiency current-stats)
      ))
    )
    (map-set BuildingStats
      { building-id: building-id }
      {
        total-reports: new-report-count,
        average-usage: new-average,
        best-efficiency: best-efficiency,
        last-updated: stacks-block-height
      }
    )
  )
)

(define-private (update-user-rewards (user principal))
  (let
    (
      (current-rewards (default-to
        { total-reports: u0, reward-points: u0, last-activity: u0 }
        (map-get? UserRewards { user: user })
      ))
      (new-report-count (+ (get total-reports current-rewards) u1))
      (bonus-points (if (> new-report-count u10) u50 u10))
      (new-points (+ (get reward-points current-rewards) bonus-points))
    )
    (map-set UserRewards
      { user: user }
      {
        total-reports: new-report-count,
        reward-points: new-points,
        last-activity: stacks-block-height
      }
    )
  )
)

(define-private (update-benchmark-data (building-type (string-ascii 32)) (energy-usage uint) (square-footage uint))
  (let
    (
      (usage-per-sqft (/ energy-usage square-footage))
      (current-benchmark (map-get? BenchmarkData { building-type: building-type }))
    )
    (match current-benchmark
      benchmark-data
      (let
        (
          (current-average (get average-usage-per-sqft benchmark-data))
          (current-sample-size (get sample-size benchmark-data))
          (new-sample-size (+ current-sample-size u1))
          (new-average (/ (+ (* current-average current-sample-size) usage-per-sqft) new-sample-size))
        )
        (map-set BenchmarkData
          { building-type: building-type }
          {
            average-usage-per-sqft: new-average,
            sample-size: new-sample-size,
            last-calculated: stacks-block-height
          }
        )
      )
      (map-set BenchmarkData
        { building-type: building-type }
        {
          average-usage-per-sqft: usage-per-sqft,
          sample-size: u1,
          last-calculated: stacks-block-height
        }
      )
    )
  )
)

(define-public (update-building-status (building-id uint) (is-active bool))
  (let
    (
      (building-data (unwrap! (map-get? Buildings { building-id: building-id }) ERR_BUILDING_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get owner building-data)) ERR_UNAUTHORIZED)
    (map-set Buildings
      { building-id: building-id }
      (merge building-data { is-active: is-active })
    )
    (ok true)
  )
)

(define-public (set-benchmark-threshold (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (asserts! (> new-threshold u0) ERR_INVALID_BENCHMARK)
    (var-set benchmark-threshold new-threshold)
    (ok true)
  )
)

(define-read-only (get-building-info (building-id uint))
  (map-get? Buildings { building-id: building-id })
)

(define-read-only (get-building-stats (building-id uint))
  (map-get? BuildingStats { building-id: building-id })
)

(define-read-only (get-energy-report (building-id uint) (report-id uint))
  (map-get? EnergyReports { building-id: building-id, report-id: report-id })
)

(define-read-only (get-benchmark-data (building-type (string-ascii 32)))
  (map-get? BenchmarkData { building-type: building-type })
)

(define-read-only (get-user-rewards (user principal))
  (map-get? UserRewards { user: user })
)

(define-read-only (get-contract-stats)
  {
    total-buildings: (var-get total-buildings),
    total-reports: (var-get total-reports),
    benchmark-threshold: (var-get benchmark-threshold),
    contract-owner: (var-get contract-owner)
  }
)

(define-read-only (calculate-building-efficiency (building-id uint))
  (let
    (
      (building-data (unwrap! (map-get? Buildings { building-id: building-id }) (err u404)))
      (stats-data (unwrap! (map-get? BuildingStats { building-id: building-id }) (err u404)))
      (building-type (get building-type building-data))
      (benchmark (map-get? BenchmarkData { building-type: building-type }))
    )
    (match benchmark
      benchmark-data
      (let
        (
          (building-usage-per-sqft (/ (get average-usage stats-data) (get square-footage building-data)))
          (benchmark-usage (get average-usage-per-sqft benchmark-data))
        )
        (ok {
          building-usage-per-sqft: building-usage-per-sqft,
          benchmark-usage: benchmark-usage,
          efficiency-rating: (if (<= building-usage-per-sqft benchmark-usage) "efficient" "needs-improvement"),
          variance-percentage: (if (> benchmark-usage u0)
            (/ (* (if (> building-usage-per-sqft benchmark-usage)
              (- building-usage-per-sqft benchmark-usage)
              (- benchmark-usage building-usage-per-sqft)
            ) u100) benchmark-usage)
            u0
          )
        })
      )
      ERR_INSUFFICIENT_DATA
    )
  )
)

(define-read-only (get-efficiency-leaderboard)
  (ok {
    message: "leaderboard-data-available",
    note: "implement-frontend-aggregation"
  })
)

(define-read-only (validate-energy-data (energy-usage uint) (square-footage uint))
  (let
    (
      (usage-per-sqft (/ energy-usage square-footage))
    )
    (ok {
      is-valid: (and (> energy-usage u0) (> square-footage u0) (< usage-per-sqft u1000)),
      usage-per-sqft: usage-per-sqft,
      efficiency-score: (calculate-efficiency-score energy-usage square-footage)
    })
  )
)
