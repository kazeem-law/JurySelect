
;; title: JurySelect
;; version: 1.0.0
;; summary: A voting system smart contract for jury selection and verdict systems
;; description: This contract manages jury member registration, selection, case management, and voting for verdicts

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_STATUS (err u103))
(define-constant ERR_ALREADY_VOTED (err u104))
(define-constant ERR_CASE_NOT_ACTIVE (err u105))
(define-constant ERR_NOT_JURY_MEMBER (err u106))
(define-constant ERR_INSUFFICIENT_JURORS (err u107))

;; Case status constants
(define-constant STATUS_PENDING u0)
(define-constant STATUS_ACTIVE u1)
(define-constant STATUS_COMPLETED u2)
(define-constant STATUS_CANCELLED u3)

;; Verdict options
(define-constant VERDICT_GUILTY u1)
(define-constant VERDICT_NOT_GUILTY u2)

;; data vars
(define-data-var case-counter uint u0)
(define-data-var jury-pool-size uint u0)

;; data maps
;; Jury member registry
(define-map jury-members principal 
  {
    registered: bool,
    active: bool,
    cases-served: uint
  })

;; Case information
(define-map cases uint 
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    judge: principal,
    status: uint,
    jurors-required: uint,
    jurors-selected: uint,
    created-at: uint,
    voting-deadline: uint,
    guilty-votes: uint,
    not-guilty-votes: uint
  })

;; Case jurors mapping
(define-map case-jurors {case-id: uint, juror: principal} bool)

;; Juror votes mapping
(define-map juror-votes {case-id: uint, juror: principal} uint)

;; Case administrators (judges/administrators who can manage cases)
(define-map case-administrators principal bool)

;; public functions

;; Initialize contract - only contract owner can call this
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (map-set case-administrators CONTRACT_OWNER true)
    (ok true)
  )
)

;; Register as a jury member
(define-public (register-as-juror)
  (let ((existing-member (map-get? jury-members tx-sender)))
    (asserts! (is-none existing-member) ERR_ALREADY_EXISTS)
    (map-set jury-members tx-sender {
      registered: true,
      active: true,
      cases-served: u0
    })
    (var-set jury-pool-size (+ (var-get jury-pool-size) u1))
    (ok true)
  )
)

;; Add a case administrator (only existing administrators can add new ones)
(define-public (add-case-administrator (admin principal))
  (begin
    (asserts! (default-to false (map-get? case-administrators tx-sender)) ERR_NOT_AUTHORIZED)
    (map-set case-administrators admin true)
    (ok true)
  )
)

;; Create a new case (only case administrators can create cases)
(define-public (create-case (title (string-ascii 100)) (description (string-ascii 500)) (jurors-required uint) (voting-duration uint))
  (let ((case-id (+ (var-get case-counter) u1)))
    (asserts! (default-to false (map-get? case-administrators tx-sender)) ERR_NOT_AUTHORIZED)
    (asserts! (> jurors-required u0) ERR_INVALID_STATUS)
    (asserts! (<= jurors-required (var-get jury-pool-size)) ERR_INSUFFICIENT_JURORS)
    
    (map-set cases case-id {
      title: title,
      description: description,
      judge: tx-sender,
      status: STATUS_PENDING,
      jurors-required: jurors-required,
      jurors-selected: u0,
      created-at: block-height,
      voting-deadline: (+ block-height voting-duration),
      guilty-votes: u0,
      not-guilty-votes: u0
    })
    
    (var-set case-counter case-id)
    (ok case-id)
  )
)

;; Select a juror for a case (only the case judge can select jurors)
(define-public (select-juror (case-id uint) (juror principal))
  (let ((case-data (unwrap! (map-get? cases case-id) ERR_NOT_FOUND))
        (jury-member (unwrap! (map-get? jury-members juror) ERR_NOT_JURY_MEMBER)))
    
    (asserts! (is-eq tx-sender (get judge case-data)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status case-data) STATUS_PENDING) ERR_INVALID_STATUS)
    (asserts! (get active jury-member) ERR_NOT_JURY_MEMBER)
    (asserts! (is-none (map-get? case-jurors {case-id: case-id, juror: juror})) ERR_ALREADY_EXISTS)
    (asserts! (< (get jurors-selected case-data) (get jurors-required case-data)) ERR_INVALID_STATUS)
    
    (map-set case-jurors {case-id: case-id, juror: juror} true)
    (map-set cases case-id (merge case-data {jurors-selected: (+ (get jurors-selected case-data) u1)}))
    
    ;; Update jury member's cases-served count
    (map-set jury-members juror (merge jury-member {cases-served: (+ (get cases-served jury-member) u1)}))
    
    (ok true)
  )
)

;; Activate a case for voting (only the case judge can activate)
(define-public (activate-case (case-id uint))
  (let ((case-data (unwrap! (map-get? cases case-id) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get judge case-data)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status case-data) STATUS_PENDING) ERR_INVALID_STATUS)
    (asserts! (is-eq (get jurors-selected case-data) (get jurors-required case-data)) ERR_INSUFFICIENT_JURORS)
    
    (map-set cases case-id (merge case-data {status: STATUS_ACTIVE}))
    (ok true)
  )
)

;; Cast a vote (only selected jurors can vote)
(define-public (cast-vote (case-id uint) (verdict uint))
  (let ((case-data (unwrap! (map-get? cases case-id) ERR_NOT_FOUND)))
    (asserts! (is-eq (get status case-data) STATUS_ACTIVE) ERR_CASE_NOT_ACTIVE)
    (asserts! (<= block-height (get voting-deadline case-data)) ERR_INVALID_STATUS)
    (asserts! (default-to false (map-get? case-jurors {case-id: case-id, juror: tx-sender})) ERR_NOT_JURY_MEMBER)
    (asserts! (is-none (map-get? juror-votes {case-id: case-id, juror: tx-sender})) ERR_ALREADY_VOTED)
    (asserts! (or (is-eq verdict VERDICT_GUILTY) (is-eq verdict VERDICT_NOT_GUILTY)) ERR_INVALID_STATUS)
    
    (map-set juror-votes {case-id: case-id, juror: tx-sender} verdict)
    
    (if (is-eq verdict VERDICT_GUILTY)
      (map-set cases case-id (merge case-data {guilty-votes: (+ (get guilty-votes case-data) u1)}))
      (map-set cases case-id (merge case-data {not-guilty-votes: (+ (get not-guilty-votes case-data) u1)}))
    )
    
    (ok true)
  )
)

;; Finalize a case (can be called by anyone once voting deadline has passed)
(define-public (finalize-case (case-id uint))
  (let ((case-data (unwrap! (map-get? cases case-id) ERR_NOT_FOUND)))
    (asserts! (is-eq (get status case-data) STATUS_ACTIVE) ERR_INVALID_STATUS)
    (asserts! (> block-height (get voting-deadline case-data)) ERR_INVALID_STATUS)
    
    (map-set cases case-id (merge case-data {status: STATUS_COMPLETED}))
    (ok true)
  )
)

;; read only functions

;; Get case information
(define-read-only (get-case (case-id uint))
  (map-get? cases case-id)
)

;; Get jury member information
(define-read-only (get-jury-member (member principal))
  (map-get? jury-members member)
)

;; Check if a principal is a case administrator
(define-read-only (is-case-administrator (admin principal))
  (default-to false (map-get? case-administrators admin))
)

;; Check if a juror is selected for a case
(define-read-only (is-case-juror (case-id uint) (juror principal))
  (default-to false (map-get? case-jurors {case-id: case-id, juror: juror}))
)

;; Get a juror's vote for a case
(define-read-only (get-juror-vote (case-id uint) (juror principal))
  (map-get? juror-votes {case-id: case-id, juror: juror})
)

;; Get current case counter
(define-read-only (get-case-counter)
  (var-get case-counter)
)

;; Get jury pool size
(define-read-only (get-jury-pool-size)
  (var-get jury-pool-size)
)

;; Get case verdict (returns the winning verdict or none if tied)
(define-read-only (get-case-verdict (case-id uint))
  (match (map-get? cases case-id)
    case-data 
      (if (> (get guilty-votes case-data) (get not-guilty-votes case-data))
        (some VERDICT_GUILTY)
        (if (> (get not-guilty-votes case-data) (get guilty-votes case-data))
          (some VERDICT_NOT_GUILTY)
          none ;; tied vote
        )
      )
    none
  )
)

;; private functions

