(define-constant ERR_NOT_OWNER (err u100))
(define-constant ERR_ALREADY_EXISTS (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INSUFFICIENT_STAKE (err u103))
(define-constant ERR_INVALID_VOTE (err u104))
(define-constant ERR_ALREADY_VOTED (err u105))
(define-constant ERR_JOB_EXPIRED (err u106))
(define-constant ERR_UNAUTHORIZED (err u107))
(define-constant ERR_INVALID_REFERRAL (err u108))
(define-constant ERR_SERVICE_NOT_AVAILABLE (err u109))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u110))
(define-constant ERR_SERVICE_COMPLETED (err u111))

(define-constant MIN_JOB_STAKE u1000000)
(define-constant VOTING_PERIOD u144)
(define-constant REFERRAL_REWARD u100000)
(define-constant PLATFORM_FEE_PERCENT u5)
(define-constant DISPUTE_VOTING_PERIOD u144)

(define-data-var contract-owner principal tx-sender)
(define-data-var next-resume-id uint u1)
(define-data-var next-job-id uint u1)
(define-data-var next-referral-id uint u1)
(define-data-var next-service-id uint u1)
(define-data-var next-booking-id uint u1)
(define-data-var next-dispute-id uint u1)

(define-map resumes
  { resume-id: uint }
  {
    owner: principal,
    name: (string-ascii 100),
    skills: (string-ascii 500),
    experience: (string-ascii 1000),
    education: (string-ascii 500),
    created-at: uint,
    verified: bool
  }
)

(define-map user-resumes
  { owner: principal }
  { resume-id: uint }
)

(define-map jobs
  {
    job-id: uint
  }
  {
    company: principal,
    title: (string-ascii 100),
    description: (string-ascii 1000),
    requirements: (string-ascii 500),
    salary-min: uint,
    salary-max: uint,
    stake: uint,
    votes-for: uint,
    votes-against: uint,
    total-voters: uint,
    created-at: uint,
    expires-at: uint,
    active: bool,
    filled: bool
  }
)

(define-map job-votes
  { job-id: uint, voter: principal }
  { voted: bool, vote-type: bool }
)

(define-map referrals
  {
    referral-id: uint
  }
  {
    referrer: principal,
    candidate: principal,
    job-id: uint,
    created-at: uint,
    hired: bool,
    reward-claimed: bool
  }
)

(define-map endorsements
  { endorser: principal, endorsed: principal }
  { skill: (string-ascii 100), message: (string-ascii 200) }
)

(define-map services
  {
    service-id: uint
  }
  {
    provider: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 50),
    price: uint,
    delivery-days: uint,
    active: bool,
    total-orders: uint,
    rating-sum: uint,
    rating-count: uint
  }
)

(define-map service-bookings
  {
    booking-id: uint
  }
  {
    client: principal,
    service-id: uint,
    amount-escrowed: uint,
    created-at: uint,
    completed: bool,
    client-rating: uint,
    payment-released: bool
  }
)
(define-map disputes
  { dispute-id: uint }
  {
    booking-id: uint,
    raiser: principal,
    reason: (string-ascii 200),
    votes-for-client: uint,
    votes-for-provider: uint,
    total-voters: uint,
    created-at: uint,
    resolved: bool,
    outcome: bool
  }
)
(define-map dispute-votes
  { dispute-id: uint, voter: principal }
  { vote-type: bool }
)
(define-map job-applications
  { job-id: uint, applicant: principal }
  { applied-at: uint, status: (string-ascii 20) }
)

(define-public (create-resume (name (string-ascii 100)) (skills (string-ascii 500)) (experience (string-ascii 1000)) (education (string-ascii 500)))
  (let
    (
      (resume-id (var-get next-resume-id))
      (current-block stacks-block-height)
    )
    (asserts! (is-none (map-get? user-resumes { owner: tx-sender })) ERR_ALREADY_EXISTS)
    (map-set resumes
      { resume-id: resume-id }
      {
        owner: tx-sender,
        name: name,
        skills: skills,
        experience: experience,
        education: education,
        created-at: current-block,
        verified: false
      }
    )
    (map-set user-resumes
      { owner: tx-sender }
      { resume-id: resume-id }
    )
    (var-set next-resume-id (+ resume-id u1))
    (ok resume-id)
  )
)

(define-public (update-resume (name (string-ascii 100)) (skills (string-ascii 500)) (experience (string-ascii 1000)) (education (string-ascii 500)))
  (let
    (
      (user-resume (unwrap! (map-get? user-resumes { owner: tx-sender }) ERR_NOT_FOUND))
      (resume-id (get resume-id user-resume))
      (resume-data (unwrap! (map-get? resumes { resume-id: resume-id }) ERR_NOT_FOUND))
    )
    (asserts! (is-eq (get owner resume-data) tx-sender) ERR_NOT_OWNER)
    (map-set resumes
      { resume-id: resume-id }
      (merge resume-data {
        name: name,
        skills: skills,
        experience: experience,
        education: education
      })
    )
    (ok resume-id)
  )
)

(define-public (post-job (title (string-ascii 100)) (description (string-ascii 1000)) (requirements (string-ascii 500)) (salary-min uint) (salary-max uint))
  (let
    (
      (job-id (var-get next-job-id))
      (current-block stacks-block-height)
      (stake-amount MIN_JOB_STAKE)
    )
    (try! (stx-transfer? stake-amount tx-sender (as-contract tx-sender)))
    (map-set jobs
      { job-id: job-id }
      {
        company: tx-sender,
        title: title,
        description: description,
        requirements: requirements,
        salary-min: salary-min,
        salary-max: salary-max,
        stake: stake-amount,
        votes-for: u0,
        votes-against: u0,
        total-voters: u0,
        created-at: current-block,
        expires-at: (+ current-block VOTING_PERIOD),
        active: false,
        filled: false
      }
    )
    (var-set next-job-id (+ job-id u1))
    (ok job-id)
  )
)

(define-public (vote-job (job-id uint) (vote-for bool))
  (let
    (
      (job-data (unwrap! (map-get? jobs { job-id: job-id }) ERR_NOT_FOUND))
      (current-block stacks-block-height)
      (existing-vote (map-get? job-votes { job-id: job-id, voter: tx-sender }))
    )
    (asserts! (< current-block (get expires-at job-data)) ERR_JOB_EXPIRED)
    (asserts! (is-none existing-vote) ERR_ALREADY_VOTED)
    (map-set job-votes
      { job-id: job-id, voter: tx-sender }
      { voted: true, vote-type: vote-for }
    )
    (if vote-for
      (map-set jobs
        { job-id: job-id }
        (merge job-data {
          votes-for: (+ (get votes-for job-data) u1),
          total-voters: (+ (get total-voters job-data) u1)
        })
      )
      (map-set jobs
        { job-id: job-id }
        (merge job-data {
          votes-against: (+ (get votes-against job-data) u1),
          total-voters: (+ (get total-voters job-data) u1)
        })
      )
    )
    (ok true)
  )
)

(define-public (activate-job (job-id uint))
  (let
    (
      (job-data (unwrap! (map-get? jobs { job-id: job-id }) ERR_NOT_FOUND))
      (current-block stacks-block-height)
    )
    (asserts! (is-eq (get company job-data) tx-sender) ERR_NOT_OWNER)
    (asserts! (>= current-block (get expires-at job-data)) ERR_INVALID_VOTE)
    (asserts! (> (get votes-for job-data) (get votes-against job-data)) ERR_INVALID_VOTE)
    (map-set jobs
      { job-id: job-id }
      (merge job-data { active: true })
    )
    (ok true)
  )
)

(define-public (create-referral (candidate principal) (job-id uint))
  (let
    (
      (referral-id (var-get next-referral-id))
      (job-data (unwrap! (map-get? jobs { job-id: job-id }) ERR_NOT_FOUND))
      (current-block stacks-block-height)
    )
    (asserts! (get active job-data) ERR_NOT_FOUND)
    (asserts! (not (get filled job-data)) ERR_INVALID_REFERRAL)
    (map-set referrals
      { referral-id: referral-id }
      {
        referrer: tx-sender,
        candidate: candidate,
        job-id: job-id,
        created-at: current-block,
        hired: false,
        reward-claimed: false
      }
    )
    (var-set next-referral-id (+ referral-id u1))
    (ok referral-id)
  )
)

(define-public (mark-hired (referral-id uint))
  (let
    (
      (referral-data (unwrap! (map-get? referrals { referral-id: referral-id }) ERR_NOT_FOUND))
      (job-data (unwrap! (map-get? jobs { job-id: (get job-id referral-data) }) ERR_NOT_FOUND))
    )
    (asserts! (is-eq (get company job-data) tx-sender) ERR_UNAUTHORIZED)
    (map-set referrals
      { referral-id: referral-id }
      (merge referral-data { hired: true })
    )
    (map-set jobs
      { job-id: (get job-id referral-data) }
      (merge job-data { filled: true })
    )
    (ok true)
  )
)

(define-public (claim-referral-reward (referral-id uint))
  (let
    (
      (referral-data (unwrap! (map-get? referrals { referral-id: referral-id }) ERR_NOT_FOUND))
    )
    (asserts! (is-eq (get referrer referral-data) tx-sender) ERR_UNAUTHORIZED)
    (asserts! (get hired referral-data) ERR_INVALID_REFERRAL)
    (asserts! (not (get reward-claimed referral-data)) ERR_ALREADY_EXISTS)
    (try! (as-contract (stx-transfer? REFERRAL_REWARD tx-sender (get referrer referral-data))))
    (map-set referrals
      { referral-id: referral-id }
      (merge referral-data { reward-claimed: true })
    )
    (ok REFERRAL_REWARD)
  )
)

(define-public (add-endorsement (endorsed principal) (skill (string-ascii 100)) (message (string-ascii 200)))
  (begin
    (map-set endorsements
      { endorser: tx-sender, endorsed: endorsed }
      { skill: skill, message: message }
    )
    (ok true)
  )
)

(define-public (verify-resume (resume-id uint))
  (let
    (
      (resume-data (unwrap! (map-get? resumes { resume-id: resume-id }) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (map-set resumes
      { resume-id: resume-id }
      (merge resume-data { verified: true })
    )
    (ok true)
  )
)

(define-read-only (get-resume (resume-id uint))
  (map-get? resumes { resume-id: resume-id })
)

(define-read-only (get-user-resume (owner principal))
  (match (map-get? user-resumes { owner: owner })
    user-resume (map-get? resumes { resume-id: (get resume-id user-resume) })
    none
  )
)

(define-read-only (get-job (job-id uint))
  (map-get? jobs { job-id: job-id })
)

(define-read-only (get-referral (referral-id uint))
  (map-get? referrals { referral-id: referral-id })
)

(define-read-only (get-endorsement (endorser principal) (endorsed principal))
  (map-get? endorsements { endorser: endorser, endorsed: endorsed })
)

(define-read-only (get-job-vote (job-id uint) (voter principal))
  (map-get? job-votes { job-id: job-id, voter: voter })
)

(define-public (create-service (title (string-ascii 100)) (description (string-ascii 500)) (category (string-ascii 50)) (price uint) (delivery-days uint))
  (let
    (
      (service-id (var-get next-service-id))
    )
    (asserts! (> price u0) ERR_INSUFFICIENT_PAYMENT)
    (asserts! (> delivery-days u0) ERR_INVALID_VOTE)
    (map-set services
      { service-id: service-id }
      {
        provider: tx-sender,
        title: title,
        description: description,
        category: category,
        price: price,
        delivery-days: delivery-days,
        active: true,
        total-orders: u0,
        rating-sum: u0,
        rating-count: u0
      }
    )
    (var-set next-service-id (+ service-id u1))
    (ok service-id)
  )
)

(define-public (book-service (service-id uint))
  (let
    (
      (service-data (unwrap! (map-get? services { service-id: service-id }) ERR_NOT_FOUND))
      (booking-id (var-get next-booking-id))
      (service-price (get price service-data))
      (platform-fee (/ (* service-price PLATFORM_FEE_PERCENT) u100))
      (total-amount (+ service-price platform-fee))
      (current-block stacks-block-height)
    )
    (asserts! (get active service-data) ERR_SERVICE_NOT_AVAILABLE)
    (asserts! (not (is-eq tx-sender (get provider service-data))) ERR_UNAUTHORIZED)
    (try! (stx-transfer? total-amount tx-sender (as-contract tx-sender)))
    (map-set service-bookings
      { booking-id: booking-id }
      {
        client: tx-sender,
        service-id: service-id,
        amount-escrowed: total-amount,
        created-at: current-block,
        completed: false,
        client-rating: u0,
        payment-released: false
      }
    )
    (map-set services
      { service-id: service-id }
      (merge service-data {
        total-orders: (+ (get total-orders service-data) u1)
      })
    )
    (var-set next-booking-id (+ booking-id u1))
    (ok booking-id)
  )
)

(define-public (complete-service (booking-id uint))
  (let
    (
      (booking-data (unwrap! (map-get? service-bookings { booking-id: booking-id }) ERR_NOT_FOUND))
      (service-data (unwrap! (map-get? services { service-id: (get service-id booking-data) }) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get provider service-data)) ERR_UNAUTHORIZED)
    (asserts! (not (get completed booking-data)) ERR_SERVICE_COMPLETED)
    (map-set service-bookings
      { booking-id: booking-id }
      (merge booking-data { completed: true })
    )
    (ok true)
  )
)

(define-public (release-payment (booking-id uint) (rating uint))
  (let
    (
      (booking-data (unwrap! (map-get? service-bookings { booking-id: booking-id }) ERR_NOT_FOUND))
      (service-data (unwrap! (map-get? services { service-id: (get service-id booking-data) }) ERR_NOT_FOUND))
      (escrow-amount (get amount-escrowed booking-data))
      (platform-fee (/ (* (get price service-data) PLATFORM_FEE_PERCENT) u100))
      (provider-payment (- escrow-amount platform-fee))
    )
    (asserts! (is-eq tx-sender (get client booking-data)) ERR_UNAUTHORIZED)
    (asserts! (get completed booking-data) ERR_SERVICE_NOT_AVAILABLE)
    (asserts! (not (get payment-released booking-data)) ERR_ALREADY_EXISTS)
    (asserts! (<= rating u5) ERR_INVALID_VOTE)
    (try! (as-contract (stx-transfer? provider-payment tx-sender (get provider service-data))))
    (map-set service-bookings
      { booking-id: booking-id }
      (merge booking-data {
        payment-released: true,
        client-rating: rating
      })
    )
    (map-set services
      { service-id: (get service-id booking-data) }
      (merge service-data {
        rating-sum: (+ (get rating-sum service-data) rating),
        rating-count: (+ (get rating-count service-data) u1)
      })
    )
    (ok provider-payment)
  )
)

(define-public (toggle-service-status (service-id uint))
  (let
    (
      (service-data (unwrap! (map-get? services { service-id: service-id }) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get provider service-data)) ERR_UNAUTHORIZED)
    (map-set services
      { service-id: service-id }
      (merge service-data { active: (not (get active service-data)) })
    )
    (ok (not (get active service-data)))
  )
)

(define-public (raise-dispute (booking-id uint) (reason (string-ascii 200)))
  (let
    (
      (booking-data (unwrap! (map-get? service-bookings { booking-id: booking-id }) ERR_NOT_FOUND))
      (service-data (unwrap! (map-get? services { service-id: (get service-id booking-data) }) ERR_NOT_FOUND))
      (dispute-id (var-get next-dispute-id))
      (current-block stacks-block-height)
    )
    (asserts! (or (is-eq tx-sender (get client booking-data)) (is-eq tx-sender (get provider service-data))) ERR_UNAUTHORIZED)
    (asserts! (get completed booking-data) ERR_INVALID_REFERRAL)
    (asserts! (not (get payment-released booking-data)) ERR_ALREADY_EXISTS)
    (map-set disputes
      { dispute-id: dispute-id }
      {
        booking-id: booking-id,
        raiser: tx-sender,
        reason: reason,
        votes-for-client: u0,
        votes-for-provider: u0,
        total-voters: u0,
        created-at: current-block,
        resolved: false,
        outcome: false
      }
    )
    (var-set next-dispute-id (+ dispute-id u1))
    (ok dispute-id)
  )
)

(define-public (vote-dispute (dispute-id uint) (vote-for-client bool))
  (let
    (
      (dispute-data (unwrap! (map-get? disputes { dispute-id: dispute-id }) ERR_NOT_FOUND))
      (booking-data (unwrap! (map-get? service-bookings { booking-id: (get booking-id dispute-data) }) ERR_NOT_FOUND))
      (service-data (unwrap! (map-get? services { service-id: (get service-id booking-data) }) ERR_NOT_FOUND))
      (current-block stacks-block-height)
      (existing-vote (map-get? dispute-votes { dispute-id: dispute-id, voter: tx-sender }))
    )
    (asserts! (not (get resolved dispute-data)) ERR_SERVICE_COMPLETED)
    (asserts! (< current-block (+ (get created-at dispute-data) DISPUTE_VOTING_PERIOD)) ERR_JOB_EXPIRED)
    (asserts! (is-none existing-vote) ERR_ALREADY_VOTED)
    (map-set dispute-votes
      { dispute-id: dispute-id, voter: tx-sender }
      { vote-type: vote-for-client }
    )
    (if vote-for-client
      (map-set disputes
        { dispute-id: dispute-id }
        (merge dispute-data {
          votes-for-client: (+ (get votes-for-client dispute-data) u1),
          total-voters: (+ (get total-voters dispute-data) u1)
        })
      )
      (map-set disputes
        { dispute-id: dispute-id }
        (merge dispute-data {
          votes-for-provider: (+ (get votes-for-provider dispute-data) u1),
          total-voters: (+ (get total-voters dispute-data) u1)
        })
      )
    )
    (ok true)
  )
)

(define-public (resolve-dispute (dispute-id uint))
  (let
    (
      (dispute-data (unwrap! (map-get? disputes { dispute-id: dispute-id }) ERR_NOT_FOUND))
      (booking-data (unwrap! (map-get? service-bookings { booking-id: (get booking-id dispute-data) }) ERR_NOT_FOUND))
      (service-data (unwrap! (map-get? services { service-id: (get service-id booking-data) }) ERR_NOT_FOUND))
      (current-block stacks-block-height)
    )
    (asserts! (not (get resolved dispute-data)) ERR_SERVICE_COMPLETED)
    (asserts! (>= current-block (+ (get created-at dispute-data) DISPUTE_VOTING_PERIOD)) ERR_JOB_EXPIRED)
    (let
      (
        (client-votes (get votes-for-client dispute-data))
        (provider-votes (get votes-for-provider dispute-data))
        (outcome (>= client-votes provider-votes))
        (provider-payment (get price service-data))
        (platform-fee (/ (* provider-payment PLATFORM_FEE_PERCENT) u100))
        (payment-to-provider (if outcome u0 (- provider-payment platform-fee)))
        (payment-to-client (if outcome (- provider-payment platform-fee) provider-payment))
      )
      (map-set disputes
        { dispute-id: dispute-id }
        (merge dispute-data {
          resolved: true,
          outcome: outcome
        })
      )
      (map-set service-bookings
        { booking-id: (get booking-id dispute-data) }
        (merge booking-data {
          payment-released: true
        })
      )
      (try! (as-contract (stx-transfer? payment-to-provider tx-sender (get provider service-data))))
      (try! (as-contract (stx-transfer? payment-to-client tx-sender (get client booking-data))))
      (ok outcome)
    )
  )
)

(define-read-only (get-service (service-id uint))
  (map-get? services { service-id: service-id })
)

(define-read-only (get-service-booking (booking-id uint))
  (map-get? service-bookings { booking-id: booking-id })
)

(define-read-only (get-service-rating (service-id uint))
  (match (map-get? services { service-id: service-id })
    service-data 
      (if (> (get rating-count service-data) u0)
        (some (/ (get rating-sum service-data) (get rating-count service-data)))
        (some u0)
      )
    none
  )
)

(define-public (apply-to-job (job-id uint))
  (let
    (
      (job-data (unwrap! (map-get? jobs { job-id: job-id }) ERR_NOT_FOUND))
      (current-block stacks-block-height)
      (existing-application (map-get? job-applications { job-id: job-id, applicant: tx-sender }))
    )
    (asserts! (get active job-data) ERR_NOT_FOUND)
    (asserts! (not (get filled job-data)) ERR_INVALID_REFERRAL)
    (asserts! (is-none existing-application) ERR_ALREADY_EXISTS)
    (map-set job-applications
      { job-id: job-id, applicant: tx-sender }
      { applied-at: current-block, status: "pending" }
    )
    (ok true)
  )
)

(define-read-only (get-job-application (job-id uint) (applicant principal))
  (map-get? job-applications { job-id: job-id, applicant: applicant })
)
