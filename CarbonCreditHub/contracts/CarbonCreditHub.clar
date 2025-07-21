;; Carbon Offset Market Smart Contract
;; A secure blockchain-based marketplace for trading verified carbon offset credits
;; Enables creation, verification, trading, and retirement of carbon offset tokens

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INSUFFICIENT-BALANCE (err u103))
(define-constant ERR-INVALID-AMOUNT (err u104))
(define-constant ERR-NOT-VERIFIED (err u105))
(define-constant ERR-ALREADY-VERIFIED (err u106))
(define-constant ERR-EXPIRED-CREDIT (err u107))
(define-constant ERR-UNAUTHORIZED (err u108))
(define-constant ERR-INVALID-PRICE (err u109))
(define-constant ERR-CREDIT-RETIRED (err u110))

;; Data maps and variables
;; Storage for carbon offset projects with comprehensive metadata
(define-map carbon-projects
  { project-id: uint }
  {
    creator: principal,
    name: (string-ascii 50),
    description: (string-ascii 200),
    location: (string-ascii 50),
    methodology: (string-ascii 30),
    total-credits: uint,
    available-credits: uint,
    verification-status: bool,
    verifier: (optional principal),
    creation-block: uint,
    expiry-block: uint,
    price-per-credit: uint
  }
)

;; Storage for individual carbon credit ownership and trading
(define-map credit-balances
  { owner: principal, project-id: uint }
  { balance: uint }
)

;; Storage for credit retirement records (permanent removal from circulation)
(define-map retired-credits
  { owner: principal, project-id: uint }
  { amount: uint, retirement-block: uint, reason: (string-ascii 100) }
)

;; Storage for marketplace listings
(define-map market-listings
  { listing-id: uint }
  {
    seller: principal,
    project-id: uint,
    amount: uint,
    price-per-credit: uint,
    listing-block: uint,
    is-active: bool
  }
)

;; Authorized verifiers who can validate carbon projects
(define-map authorized-verifiers
  { verifier: principal }
  { authorized: bool, reputation-score: uint }
)

;; Global state variables
(define-data-var next-project-id uint u1)
(define-data-var next-listing-id uint u1)
(define-data-var platform-fee-rate uint u250) ;; 2.5% in basis points
(define-data-var total-credits-issued uint u0)
(define-data-var total-credits-retired uint u0)

;; Private functions
;; Calculate platform fee for transactions
(define-private (calculate-platform-fee (amount uint))
  (/ (* amount (var-get platform-fee-rate)) u10000)
)

;; Check if a project exists and is valid
(define-private (is-valid-project (project-id uint))
  (is-some (map-get? carbon-projects { project-id: project-id }))
)

;; Verify credit ownership and sufficient balance
(define-private (has-sufficient-credits (owner principal) (project-id uint) (amount uint))
  (let ((current-balance (default-to u0 (get balance (map-get? credit-balances { owner: owner, project-id: project-id })))))
    (>= current-balance amount)
  )
)

;; Transfer credits between accounts with balance validation
(define-private (transfer-credits (from principal) (to principal) (project-id uint) (amount uint))
  (let (
    (from-balance (default-to u0 (get balance (map-get? credit-balances { owner: from, project-id: project-id }))))
    (to-balance (default-to u0 (get balance (map-get? credit-balances { owner: to, project-id: project-id }))))
  )
    (if (>= from-balance amount)
      (begin
        (map-set credit-balances { owner: from, project-id: project-id } { balance: (- from-balance amount) })
        (map-set credit-balances { owner: to, project-id: project-id } { balance: (+ to-balance amount) })
        (ok true)
      )
      ERR-INSUFFICIENT-BALANCE
    )
  )
)

;; Public functions
;; Register a new carbon offset project with comprehensive validation
(define-public (create-carbon-project 
  (name (string-ascii 50))
  (description (string-ascii 200))
  (location (string-ascii 50))
  (methodology (string-ascii 30))
  (total-credits uint)
  (duration-blocks uint)
  (price-per-credit uint)
)
  (let ((project-id (var-get next-project-id)))
    (if (and (> total-credits u0) (> duration-blocks u0) (> price-per-credit u0))
      (begin
        (map-set carbon-projects
          { project-id: project-id }
          {
            creator: tx-sender,
            name: name,
            description: description,
            location: location,
            methodology: methodology,
            total-credits: total-credits,
            available-credits: total-credits,
            verification-status: false,
            verifier: none,
            creation-block: block-height,
            expiry-block: (+ block-height duration-blocks),
            price-per-credit: price-per-credit
          }
        )
        (map-set credit-balances 
          { owner: tx-sender, project-id: project-id } 
          { balance: total-credits }
        )
        (var-set next-project-id (+ project-id u1))
        (var-set total-credits-issued (+ (var-get total-credits-issued) total-credits))
        (ok project-id)
      )
      ERR-INVALID-AMOUNT
    )
  )
)

;; Authorize a verifier to validate carbon projects
(define-public (authorize-verifier (verifier principal))
  (if (is-eq tx-sender CONTRACT-OWNER)
    (begin
      (map-set authorized-verifiers { verifier: verifier } { authorized: true, reputation-score: u100 })
      (ok true)
    )
    ERR-OWNER-ONLY
  )
)

;; Verify a carbon project (verifiers only)
(define-public (verify-project (project-id uint))
  (let (
    (project-data (unwrap! (map-get? carbon-projects { project-id: project-id }) ERR-NOT-FOUND))
    (verifier-status (map-get? authorized-verifiers { verifier: tx-sender }))
  )
    (if (and 
          (is-some verifier-status)
          (get authorized (unwrap-panic verifier-status))
          (not (get verification-status project-data))
        )
      (begin
        (map-set carbon-projects
          { project-id: project-id }
          (merge project-data { verification-status: true, verifier: (some tx-sender) })
        )
        (ok true)
      )
      ERR-UNAUTHORIZED
    )
  )
)

;; Create a marketplace listing for carbon credits
(define-public (create-market-listing (project-id uint) (amount uint) (price-per-credit uint))
  (let (
    (listing-id (var-get next-listing-id))
    (project-data (unwrap! (map-get? carbon-projects { project-id: project-id }) ERR-NOT-FOUND))
  )
    (if (and 
          (get verification-status project-data)
          (has-sufficient-credits tx-sender project-id amount)
          (> amount u0)
          (> price-per-credit u0)
        )
      (begin
        (map-set market-listings
          { listing-id: listing-id }
          {
            seller: tx-sender,
            project-id: project-id,
            amount: amount,
            price-per-credit: price-per-credit,
            listing-block: block-height,
            is-active: true
          }
        )
        (var-set next-listing-id (+ listing-id u1))
        (ok listing-id)
      )
      ERR-NOT-VERIFIED
    )
  )
)

;; Purchase carbon credits from marketplace listing
(define-public (purchase-credits (listing-id uint) (amount uint))
  (let (
    (listing-data (unwrap! (map-get? market-listings { listing-id: listing-id }) ERR-NOT-FOUND))
    (total-cost (* amount (get price-per-credit listing-data)))
    (platform-fee (calculate-platform-fee total-cost))
    (seller-payment (- total-cost platform-fee))
  )
    (if (and 
          (get is-active listing-data)
          (<= amount (get amount listing-data))
          (> amount u0)
        )
      (match (stx-transfer? total-cost tx-sender (get seller listing-data))
        success (begin
          (try! (transfer-credits (get seller listing-data) tx-sender (get project-id listing-data) amount))
          (if (is-eq amount (get amount listing-data))
            (map-set market-listings 
              { listing-id: listing-id }
              (merge listing-data { is-active: false })
            )
            (map-set market-listings 
              { listing-id: listing-id }
              (merge listing-data { amount: (- (get amount listing-data) amount) })
            )
          )
          (ok true)
        )
        error ERR-INSUFFICIENT-BALANCE
      )
      ERR-INVALID-AMOUNT
    )
  )
)

;; Retire carbon credits permanently (remove from circulation)
(define-public (retire-credits (project-id uint) (amount uint) (reason (string-ascii 100)))
  (let (
    (project-data (unwrap! (map-get? carbon-projects { project-id: project-id }) ERR-NOT-FOUND))
    (current-retired (default-to u0 (get amount (map-get? retired-credits { owner: tx-sender, project-id: project-id }))))
  )
    (if (and 
          (get verification-status project-data)
          (has-sufficient-credits tx-sender project-id amount)
          (> amount u0)
        )
      (begin
        (try! (transfer-credits tx-sender CONTRACT-OWNER project-id amount))
        (map-set retired-credits
          { owner: tx-sender, project-id: project-id }
          { 
            amount: (+ current-retired amount), 
            retirement-block: block-height,
            reason: reason
          }
        )
        (var-set total-credits-retired (+ (var-get total-credits-retired) amount))
        (ok true)
      )
      ERR-INSUFFICIENT-BALANCE
    )
  )
)

;; Helper function for batch processing individual operations
(define-private (process-single-operation 
  (operation { operation-type: uint, project-id: uint, amount: uint, target: (optional principal) }))
  (let (
    (op-type (get operation-type operation))
    (project-id (get project-id operation))
    (amount (get amount operation))
    (target (get target operation))
  )
    (if (is-eq op-type u1) ;; Transfer operation
      (match target
        recipient (if (has-sufficient-credits tx-sender project-id amount)
                    (transfer-credits tx-sender recipient project-id amount)
                    ERR-INSUFFICIENT-BALANCE)
        ERR-INVALID-AMOUNT
      )
      (if (is-eq op-type u2) ;; Retirement operation
        (if (has-sufficient-credits tx-sender project-id amount)
          (begin
            (try! (transfer-credits tx-sender CONTRACT-OWNER project-id amount))
            (var-set total-credits-retired (+ (var-get total-credits-retired) amount))
            (ok true)
          )
          ERR-INSUFFICIENT-BALANCE
        )
        ERR-INVALID-AMOUNT ;; Unknown operation type
      )
    )
  )
)

;; Helper function to check if operation was successful
(define-private (is-operation-successful (result (response bool uint)))
  (is-ok result)
)




