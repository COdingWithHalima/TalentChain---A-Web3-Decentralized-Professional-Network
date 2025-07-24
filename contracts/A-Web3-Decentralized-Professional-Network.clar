(define-constant ERR_NOT_OWNER (err u100))
(define-constant ERR_ALREADY_EXISTS (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INSUFFICIENT_STAKE (err u103))
(define-constant ERR_INVALID_VOTE (err u104))
(define-constant ERR_ALREADY_VOTED (err u105))
(define-constant ERR_JOB_EXPIRED (err u106))
(define-constant ERR_UNAUTHORIZED (err u107))
(define-constant ERR_INVALID_REFERRAL (err u108))

(define-constant MIN_JOB_STAKE u1000000)
(define-constant VOTING_PERIOD u144)
(define-constant REFERRAL_REWARD u100000)

(define-data-var contract-owner principal tx-sender)
(define-data-var next-resume-id uint u1)
(define-data-var next-job-id uint u1)
(define-data-var next-referral-id uint u1)

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
