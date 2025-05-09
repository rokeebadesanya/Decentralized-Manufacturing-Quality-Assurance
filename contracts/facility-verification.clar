;; Facility Verification Contract
;; Validates legitimate production sites in the supply chain

(define-data-var contract-owner principal tx-sender)

;; Data map to store verified facilities
(define-map verified-facilities
  { facility-id: (string-ascii 32) }
  {
    name: (string-ascii 64),
    location: (string-ascii 128),
    verified: bool,
    verification-date: uint,
    verifier: principal
  }
)

;; List of all facility IDs for enumeration
(define-data-var facility-ids (list 100 (string-ascii 32)) (list))

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Transfer ownership of the contract
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-contract-owner) (err u403))
    (ok (var-set contract-owner new-owner))
  )
)

;; Register a new facility
(define-public (register-facility
    (facility-id (string-ascii 32))
    (name (string-ascii 64))
    (location (string-ascii 128)))
  (begin
    (asserts! (is-contract-owner) (err u403))
    (asserts! (is-none (map-get? verified-facilities { facility-id: facility-id })) (err u100))

    (map-set verified-facilities
      { facility-id: facility-id }
      {
        name: name,
        location: location,
        verified: false,
        verification-date: u0,
        verifier: tx-sender
      }
    )

    ;; Add to list of facility IDs
    (var-set facility-ids (unwrap! (as-max-len? (append (var-get facility-ids) facility-id) u100) (err u101)))

    (ok true)
  )
)

;; Verify a facility
(define-public (verify-facility (facility-id (string-ascii 32)))
  (begin
    (asserts! (is-contract-owner) (err u403))
    (asserts! (is-some (map-get? verified-facilities { facility-id: facility-id })) (err u102))

    (map-set verified-facilities
      { facility-id: facility-id }
      (merge (unwrap-panic (map-get? verified-facilities { facility-id: facility-id }))
        {
          verified: true,
          verification-date: block-height,
          verifier: tx-sender
        }
      )
    )

    (ok true)
  )
)

;; Revoke verification for a facility
(define-public (revoke-verification (facility-id (string-ascii 32)))
  (begin
    (asserts! (is-contract-owner) (err u403))
    (asserts! (is-some (map-get? verified-facilities { facility-id: facility-id })) (err u102))

    (map-set verified-facilities
      { facility-id: facility-id }
      (merge (unwrap-panic (map-get? verified-facilities { facility-id: facility-id }))
        {
          verified: false,
          verification-date: block-height,
          verifier: tx-sender
        }
      )
    )

    (ok true)
  )
)

;; Get facility details - public read function
(define-read-only (get-facility (facility-id (string-ascii 32)))
  (map-get? verified-facilities { facility-id: facility-id })
)

;; Check if a facility is verified - public read function
(define-read-only (is-facility-verified (facility-id (string-ascii 32)))
  (default-to false (get verified (map-get? verified-facilities { facility-id: facility-id })))
)

;; Get all facility IDs
(define-read-only (get-all-facility-ids)
  (var-get facility-ids)
)
