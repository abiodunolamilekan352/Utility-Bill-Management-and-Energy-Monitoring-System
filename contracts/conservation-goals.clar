;; Conservation Goals Contract
;; Manages energy conservation targets and rewards

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-INVALID-GOAL (err u301))
(define-constant ERR-GOAL-NOT-FOUND (err u302))
(define-constant ERR-INVALID-PERCENTAGE (err u303))

;; Data variables
(define-data-var contract-owner principal tx-sender)
(define-data-var base-reward-rate uint u10) ;; 10 credits per percentage saved

;; Conservation goals
(define-map conservation-goals
  { account-id: principal, goal-id: uint }
  {
    target-reduction: uint, ;; Percentage reduction target
    baseline-usage: uint,
    start-date: uint,
    end-date: uint,
    goal-status: (string-ascii 20),
    reward-credits: uint
  }
)

;; Goal progress tracking
(define-map goal-progress
  { account-id: principal, goal-id: uint, period: uint }
  {
    actual-usage: uint,
    target-usage: uint,
    reduction-achieved: uint,
    credits-earned: uint,
    progress-date: uint
  }
)

;; Conservation achievements
(define-map conservation-achievements
  { account-id: principal, achievement-id: uint }
  {
    achievement-type: (string-ascii 30),
    credits-awarded: uint,
    achievement-date: uint,
    description: (string-ascii 100)
  }
)

;; Goal counters
(define-map goal-counters { account-id: principal } { counter: uint })
(define-map achievement-counters { account-id: principal } { counter: uint })

;; Set conservation goal
(define-public (set-conservation-goal (account-id principal) (target-reduction uint) (baseline-usage uint) (duration uint))
  (let (
    (counter-data (default-to { counter: u0 } (map-get? goal-counters { account-id: account-id })))
    (new-goal-id (+ (get counter counter-data) u1))
  )
    (asserts! (or (is-eq tx-sender account-id) (is-eq tx-sender (var-get contract-owner))) ERR-NOT-AUTHORIZED)
    (asserts! (and (> target-reduction u0) (<= target-reduction u50)) ERR-INVALID-PERCENTAGE)
    (asserts! (> baseline-usage u0) ERR-INVALID-GOAL)
    (asserts! (> duration u0) ERR-INVALID-GOAL)

    (map-set conservation-goals
      { account-id: account-id, goal-id: new-goal-id }
      {
        target-reduction: target-reduction,
        baseline-usage: baseline-usage,
        start-date: block-height,
        end-date: (+ block-height duration),
        goal-status: "active",
        reward-credits: u0
      }
    )

    (map-set goal-counters { account-id: account-id } { counter: new-goal-id })

    (ok new-goal-id)
  )
)

;; Track goal progress
(define-public (track-goal-progress (account-id principal) (goal-id uint) (actual-usage uint) (period uint))
  (let (
    (goal (unwrap! (map-get? conservation-goals { account-id: account-id, goal-id: goal-id }) ERR-GOAL-NOT-FOUND))
    (target-usage (calculate-target-usage (get baseline-usage goal) (get target-reduction goal)))
    (reduction-achieved (calculate-reduction-achieved (get baseline-usage goal) actual-usage))
    (credits-earned (calculate-credits-earned reduction-achieved))
  )
    (asserts! (or (is-eq tx-sender account-id) (is-eq tx-sender (var-get contract-owner))) ERR-NOT-AUTHORIZED)
    (asserts! (> actual-usage u0) ERR-INVALID-GOAL)

    (map-set goal-progress
      { account-id: account-id, goal-id: goal-id, period: period }
      {
        actual-usage: actual-usage,
        target-usage: target-usage,
        reduction-achieved: reduction-achieved,
        credits-earned: credits-earned,
        progress-date: block-height
      }
    )

    ;; Update goal with earned credits
    (map-set conservation-goals
      { account-id: account-id, goal-id: goal-id }
      (merge goal {
        reward-credits: (+ (get reward-credits goal) credits-earned)
      })
    )

    (ok credits-earned)
  )
)

;; Calculate target usage based on reduction percentage
(define-private (calculate-target-usage (baseline uint) (reduction-percent uint))
  (- baseline (/ (* baseline reduction-percent) u100))
)

;; Calculate actual reduction achieved
(define-private (calculate-reduction-achieved (baseline uint) (actual uint))
  (if (< actual baseline)
    (/ (* (- baseline actual) u100) baseline)
    u0
  )
)

;; Calculate credits earned based on reduction
(define-private (calculate-credits-earned (reduction-percent uint))
  (* reduction-percent (var-get base-reward-rate))
)

;; Award conservation achievement
(define-public (award-conservation-achievement (account-id principal) (achievement-type (string-ascii 30)) (credits uint) (description (string-ascii 100)))
  (let (
    (counter-data (default-to { counter: u0 } (map-get? achievement-counters { account-id: account-id })))
    (new-achievement-id (+ (get counter counter-data) u1))
  )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (> credits u0) ERR-INVALID-GOAL)

    (map-set conservation-achievements
      { account-id: account-id, achievement-id: new-achievement-id }
      {
        achievement-type: achievement-type,
        credits-awarded: credits,
        achievement-date: block-height,
        description: description
      }
    )

    (map-set achievement-counters { account-id: account-id } { counter: new-achievement-id })

    (ok new-achievement-id)
  )
)

;; Calculate total savings
(define-public (calculate-savings (account-id principal) (goal-id uint) (rate-per-kwh uint))
  (let (
    (goal (unwrap! (map-get? conservation-goals { account-id: account-id, goal-id: goal-id }) ERR-GOAL-NOT-FOUND))
    (baseline (get baseline-usage goal))
    (target (calculate-target-usage baseline (get target-reduction goal)))
    (kwh-saved (- baseline target))
    (cost-savings (* kwh-saved rate-per-kwh))
  )
    (asserts! (or (is-eq tx-sender account-id) (is-eq tx-sender (var-get contract-owner))) ERR-NOT-AUTHORIZED)

    (ok {
      kwh-saved: kwh-saved,
      cost-savings: cost-savings,
      credits-available: (get reward-credits goal)
    })
  )
)

;; Get conservation goal
(define-read-only (get-conservation-goal (account-id principal) (goal-id uint))
  (map-get? conservation-goals { account-id: account-id, goal-id: goal-id })
)

;; Get goal progress
(define-read-only (get-goal-progress (account-id principal) (goal-id uint) (period uint))
  (map-get? goal-progress { account-id: account-id, goal-id: goal-id, period: period })
)

;; Get conservation achievement
(define-read-only (get-conservation-achievement (account-id principal) (achievement-id uint))
  (map-get? conservation-achievements { account-id: account-id, achievement-id: achievement-id })
)

;; Get total credits earned
(define-read-only (get-total-credits (account-id principal))
  (let (
    (goal1 (default-to { reward-credits: u0 } (map-get? conservation-goals { account-id: account-id, goal-id: u1 })))
    (goal2 (default-to { reward-credits: u0 } (map-get? conservation-goals { account-id: account-id, goal-id: u2 })))
  )
    (+ (get reward-credits goal1) (get reward-credits goal2))
  )
)
