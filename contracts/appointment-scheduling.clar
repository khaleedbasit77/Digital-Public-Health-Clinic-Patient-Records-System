;; Appointment Scheduling Contract
;; Manages clinic visit bookings and reminders

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-APPOINTMENT-NOT-FOUND (err u201))
(define-constant ERR-INVALID-INPUT (err u202))
(define-constant ERR-TIME-CONFLICT (err u203))
(define-constant ERR-PAST-DATE (err u204))

;; Status constants
(define-constant STATUS-SCHEDULED u1)
(define-constant STATUS-CONFIRMED u2)
(define-constant STATUS-COMPLETED u3)
(define-constant STATUS-CANCELLED u4)
(define-constant STATUS-NO-SHOW u5)

;; Data variables
(define-data-var contract-owner principal tx-sender)
(define-data-var next-appointment-id uint u1)

;; Data maps
(define-map appointments
  { appointment-id: uint }
  {
    patient-id: uint,
    provider: principal,
    appointment-date: uint,
    appointment-time: uint,
    duration: uint,
    appointment-type: (string-ascii 50),
    status: uint,
    notes: (string-ascii 500),
    created-at: uint,
    updated-at: uint
  }
)

(define-map provider-schedules
  { provider: principal, date: uint, time-slot: uint }
  { appointment-id: (optional uint), available: bool }
)

(define-map appointment-reminders
  { appointment-id: uint }
  {
    reminder-sent: bool,
    reminder-date: uint,
    confirmation-required: bool,
    confirmed: bool
  }
)

(define-map provider-availability
  { provider: principal, day-of-week: uint }
  {
    start-time: uint,
    end-time: uint,
    slot-duration: uint,
    active: bool
  }
)

;; Authorization functions
(define-private (is-provider-or-owner (provider principal))
  (or
    (is-eq tx-sender (var-get contract-owner))
    (is-eq tx-sender provider)
  )
)

;; Time validation functions
(define-private (is-future-date (date uint) (time uint))
  (let
    (
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (appointment-timestamp (+ (* date u86400) time))
    )
    (> appointment-timestamp current-time)
  )
)

(define-private (check-time-conflict (provider principal) (date uint) (time uint) (duration uint))
  (let
    (
      (end-time (+ time duration))
    )
    (is-none (map-get? provider-schedules { provider: provider, date: date, time-slot: time }))
  )
)

;; Provider availability management
(define-public (set-provider-availability
  (provider principal)
  (day-of-week uint)
  (start-time uint)
  (end-time uint)
  (slot-duration uint)
)
  (begin
    (asserts! (is-provider-or-owner provider) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= day-of-week u1) (<= day-of-week u7)) ERR-INVALID-INPUT)
    (asserts! (< start-time end-time) ERR-INVALID-INPUT)
    (asserts! (> slot-duration u0) ERR-INVALID-INPUT)

    (map-set provider-availability
      { provider: provider, day-of-week: day-of-week }
      {
        start-time: start-time,
        end-time: end-time,
        slot-duration: slot-duration,
        active: true
      }
    )
    (ok true)
  )
)

;; Appointment booking
(define-public (book-appointment
  (patient-id uint)
  (provider principal)
  (appointment-date uint)
  (appointment-time uint)
  (duration uint)
  (appointment-type (string-ascii 50))
  (notes (string-ascii 500))
)
  (let
    (
      (appointment-id (var-get next-appointment-id))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (> patient-id u0) ERR-INVALID-INPUT)
    (asserts! (is-future-date appointment-date appointment-time) ERR-PAST-DATE)
    (asserts! (check-time-conflict provider appointment-date appointment-time duration) ERR-TIME-CONFLICT)
    (asserts! (> (len appointment-type) u0) ERR-INVALID-INPUT)

    ;; Create appointment
    (map-set appointments
      { appointment-id: appointment-id }
      {
        patient-id: patient-id,
        provider: provider,
        appointment-date: appointment-date,
        appointment-time: appointment-time,
        duration: duration,
        appointment-type: appointment-type,
        status: STATUS-SCHEDULED,
        notes: notes,
        created-at: current-time,
        updated-at: current-time
      }
    )

    ;; Block the time slot
    (map-set provider-schedules
      { provider: provider, date: appointment-date, time-slot: appointment-time }
      { appointment-id: (some appointment-id), available: false }
    )

    ;; Set up reminder
    (map-set appointment-reminders
      { appointment-id: appointment-id }
      {
        reminder-sent: false,
        reminder-date: (- appointment-date u86400), ;; 1 day before
        confirmation-required: true,
        confirmed: false
      }
    )

    (var-set next-appointment-id (+ appointment-id u1))
    (ok appointment-id)
  )
)

;; Appointment management
(define-public (update-appointment-status
  (appointment-id uint)
  (new-status uint)
)
  (let
    (
      (appointment (unwrap! (map-get? appointments { appointment-id: appointment-id }) ERR-APPOINTMENT-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (is-provider-or-owner (get provider appointment)) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= new-status u1) (<= new-status u5)) ERR-INVALID-INPUT)

    (map-set appointments
      { appointment-id: appointment-id }
      (merge appointment {
        status: new-status,
        updated-at: current-time
      })
    )

    ;; If cancelled, free up the time slot
    (if (is-eq new-status STATUS-CANCELLED)
      (map-delete provider-schedules {
        provider: (get provider appointment),
        date: (get appointment-date appointment),
        time-slot: (get appointment-time appointment)
      })
      true
    )

    (ok true)
  )
)

(define-public (reschedule-appointment
  (appointment-id uint)
  (new-date uint)
  (new-time uint)
)
  (let
    (
      (appointment (unwrap! (map-get? appointments { appointment-id: appointment-id }) ERR-APPOINTMENT-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (is-provider-or-owner (get provider appointment)) ERR-NOT-AUTHORIZED)
    (asserts! (is-future-date new-date new-time) ERR-PAST-DATE)
    (asserts! (check-time-conflict (get provider appointment) new-date new-time (get duration appointment)) ERR-TIME-CONFLICT)

    ;; Free old time slot
    (map-delete provider-schedules {
      provider: (get provider appointment),
      date: (get appointment-date appointment),
      time-slot: (get appointment-time appointment)
    })

    ;; Book new time slot
    (map-set provider-schedules
      { provider: (get provider appointment), date: new-date, time-slot: new-time }
      { appointment-id: (some appointment-id), available: false }
    )

    ;; Update appointment
    (map-set appointments
      { appointment-id: appointment-id }
      (merge appointment {
        appointment-date: new-date,
        appointment-time: new-time,
        updated-at: current-time
      })
    )

    (ok true)
  )
)

;; Reminder and confirmation functions
(define-public (confirm-appointment (appointment-id uint))
  (let
    (
      (reminder (unwrap! (map-get? appointment-reminders { appointment-id: appointment-id }) ERR-APPOINTMENT-NOT-FOUND))
    )
    (map-set appointment-reminders
      { appointment-id: appointment-id }
      (merge reminder { confirmed: true })
    )

    (try! (update-appointment-status appointment-id STATUS-CONFIRMED))
    (ok true)
  )
)

(define-public (send-reminder (appointment-id uint))
  (let
    (
      (reminder (unwrap! (map-get? appointment-reminders { appointment-id: appointment-id }) ERR-APPOINTMENT-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)

    (map-set appointment-reminders
      { appointment-id: appointment-id }
      (merge reminder { reminder-sent: true })
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-appointment (appointment-id uint))
  (map-get? appointments { appointment-id: appointment-id })
)

(define-read-only (get-provider-schedule (provider principal) (date uint) (time-slot uint))
  (map-get? provider-schedules { provider: provider, date: date, time-slot: time-slot })
)

(define-read-only (get-appointment-reminder (appointment-id uint))
  (map-get? appointment-reminders { appointment-id: appointment-id })
)

(define-read-only (get-provider-availability (provider principal) (day-of-week uint))
  (map-get? provider-availability { provider: provider, day-of-week: day-of-week })
)

(define-read-only (is-time-slot-available (provider principal) (date uint) (time-slot uint))
  (is-none (map-get? provider-schedules { provider: provider, date: date, time-slot: time-slot }))
)
