;; Billing Manager Contract
;; Manages utility billing cycles, payments, and account management

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ACCOUNT-EXISTS (err u101))
(define-constant ERR-ACCOUNT-NOT-FOUND (err u102))
(define-constant ERR-INSUFFICIENT-BALANCE (err u103))
(define-constant ERR-INVALID-AMOUNT (err u104))

;; Data variables
(define-data-var contract-owner principal tx-sender)
(define-data-var billing-cycle-length uint u30) ;; 30 days

;; Account structure
(define-map accounts
  { account-id: principal }
  {
    service-address: (string-ascii 100),
    account-status: (string-ascii 20),
    current-balance: int,
    last-billing-date: uint,
    payment-plan: (string-ascii 20)
  }
)

;; Payment history
(define-map payment-history
  { account-id: principal, payment-id: uint }
  {
    amount: uint,
    payment-date: uint,
    payment-method: (string-ascii 20)
  }
)

;; Billing history
(define-map billing-history
  { account-id: principal, billing-period: uint }
  {
    usage-amount: uint,
    bill-amount: uint,
    due-date: uint,
    paid: bool
  }
)

;; Payment counter for unique IDs
(define-map payment-counters { account-id: principal } { counter: uint })

;; Create new utility account
(define-public (create-account (account-id principal) (service-address (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? accounts { account-id: account-id })) ERR-ACCOUNT-EXISTS)

    (map-set accounts
      { account-id: account-id }
      {
        service-address: service-address,
        account-status: "active",
        current-balance: 0,
        last-billing-date: block-height,
        payment-plan: "standard"
      }
    )

    (map-set payment-counters { account-id: account-id } { counter: u0 })
    (ok true)
  )
)

;; Process billing cycle for an account
(define-public (process-billing-cycle (account-id principal) (usage-amount uint) (bill-amount uint))
  (let (
    (account (unwrap! (map-get? accounts { account-id: account-id }) ERR-ACCOUNT-NOT-FOUND))
    (billing-period (/ block-height (var-get billing-cycle-length)))
  )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (> bill-amount u0) ERR-INVALID-AMOUNT)

    ;; Update account balance
    (map-set accounts
      { account-id: account-id }
      (merge account {
        current-balance: (+ (get current-balance account) (to-int bill-amount)),
        last-billing-date: block-height
      })
    )

    ;; Record billing history
    (map-set billing-history
      { account-id: account-id, billing-period: billing-period }
      {
        usage-amount: usage-amount,
        bill-amount: bill-amount,
        due-date: (+ block-height (var-get billing-cycle-length)),
        paid: false
      }
    )

    (ok bill-amount)
  )
)

;; Record payment
(define-public (record-payment (account-id principal) (amount uint) (payment-method (string-ascii 20)))
  (let (
    (account (unwrap! (map-get? accounts { account-id: account-id }) ERR-ACCOUNT-NOT-FOUND))
    (counter-data (unwrap! (map-get? payment-counters { account-id: account-id }) ERR-ACCOUNT-NOT-FOUND))
    (new-counter (+ (get counter counter-data) u1))
    (current-balance (get current-balance account))
  )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (>= current-balance (to-int amount)) ERR-INSUFFICIENT-BALANCE)

    ;; Update account balance
    (map-set accounts
      { account-id: account-id }
      (merge account {
        current-balance: (- current-balance (to-int amount))
      })
    )

    ;; Record payment
    (map-set payment-history
      { account-id: account-id, payment-id: new-counter }
      {
        amount: amount,
        payment-date: block-height,
        payment-method: payment-method
      }
    )

    ;; Update counter
    (map-set payment-counters { account-id: account-id } { counter: new-counter })

    (ok new-counter)
  )
)

;; Get account information
(define-read-only (get-account-info (account-id principal))
  (map-get? accounts { account-id: account-id })
)

;; Get account balance
(define-read-only (get-account-balance (account-id principal))
  (match (map-get? accounts { account-id: account-id })
    account (ok (get current-balance account))
    ERR-ACCOUNT-NOT-FOUND
  )
)

;; Get payment history
(define-read-only (get-payment-info (account-id principal) (payment-id uint))
  (map-get? payment-history { account-id: account-id, payment-id: payment-id })
)

;; Get billing history
(define-read-only (get-billing-info (account-id principal) (billing-period uint))
  (map-get? billing-history { account-id: account-id, billing-period: billing-period })
)

;; Set payment plan
(define-public (set-payment-plan (account-id principal) (plan (string-ascii 20)))
  (let (
    (account (unwrap! (map-get? accounts { account-id: account-id }) ERR-ACCOUNT-NOT-FOUND))
  )
    (asserts! (or (is-eq tx-sender account-id) (is-eq tx-sender (var-get contract-owner))) ERR-NOT-AUTHORIZED)

    (map-set accounts
      { account-id: account-id }
      (merge account { payment-plan: plan })
    )

    (ok true)
  )
)
