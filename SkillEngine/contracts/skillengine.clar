;; Skill Engine - A Decentralized Skill Verification and Marketplace System
;; Version: 1.0.0
;; Network: Stacks

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-skill (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-not-found (err u103))
(define-constant err-insufficient-balance (err u104))
(define-constant err-invalid-validator (err u105))
(define-constant err-validation-pending (err u106))
(define-constant err-task-not-active (err u107))
(define-constant err-invalid-amount (err u108))
(define-constant err-already-validated (err u109))
(define-constant err-self-validation (err u110))
(define-constant err-insufficient-stake (err u111))
(define-constant err-cooldown-active (err u112))

;; Data Variables
(define-data-var skill-counter uint u0)
(define-data-var task-counter uint u0)
(define-data-var validation-fee uint u1000000) ;; 1 STX
(define-data-var min-validators uint u3)
(define-data-var validator-stake uint u5000000) ;; 5 STX
(define-data-var platform-fee-percentage uint u250) ;; 2.5%
(define-data-var treasury-balance uint u0)

;; Data Maps
;; Skill NFT metadata
(define-map skills
    uint ;; skill-id
    {
        owner: principal,
        name: (string-ascii 50),
        category: (string-ascii 30),
        level: uint, ;; 1-100
        experience-points: uint,
        validated: bool,
        validator-count: uint,
        creation-block: uint,
        last-updated: uint,
        metadata-uri: (optional (string-ascii 256))
    }
)

;; User profile
(define-map user-profiles
    principal
    {
        reputation-score: uint,
        skills-owned: uint,
        validations-given: uint,
        validations-received: uint,
        tasks-completed: uint,
        tasks-posted: uint,
        total-earned: uint,
        total-spent: uint,
        joined-block: uint
    }
)

;; Skill validation records
(define-map validations
    { skill-id: uint, validator: principal }
    {
        validated: bool,
        validation-score: uint, ;; 1-10
        timestamp: uint,
        feedback: (optional (string-ascii 256))
    }
)

;; Validator stakes
(define-map validator-stakes
    principal
    {
        amount: uint,
        locked-until: uint,
        slashed-amount: uint
    }
)

;; Task marketplace
(define-map tasks
    uint ;; task-id
    {
        poster: principal,
        title: (string-ascii 100),
        description: (string-ascii 500),
        required-skills: (list 5 uint),
        budget: uint,
        deadline: uint,
        status: (string-ascii 20), ;; open, in-progress, completed, cancelled
        assignee: (optional principal),
        completion-proof: (optional (string-ascii 256))
    }
)

;; Task applications
(define-map task-applications
    { task-id: uint, applicant: principal }
    {
        bid-amount: uint,
        proposal: (string-ascii 500),
        applied-at: uint,
        status: (string-ascii 20) ;; pending, accepted, rejected
    }
)

;; Skill endorsements (peer-to-peer)
(define-map endorsements
    { skill-id: uint, endorser: principal }
    {
        endorsed: bool,
        weight: uint, ;; Based on endorser's reputation
        timestamp: uint
    }
)

;; Read-only functions
(define-read-only (get-skill (skill-id uint))
    (map-get? skills skill-id)
)

(define-read-only (get-user-profile (user principal))
    (default-to 
        {
            reputation-score: u0,
            skills-owned: u0,
            validations-given: u0,
            validations-received: u0,
            tasks-completed: u0,
            tasks-posted: u0,
            total-earned: u0,
            total-spent: u0,
            joined-block: stacks-block-height
        }
        (map-get? user-profiles user)
    )
)

(define-read-only (get-task (task-id uint))
    (map-get? tasks task-id)
)

(define-read-only (calculate-reputation (user principal))
    (let ((profile (get-user-profile user)))
        (+ 
            (* (get validations-received profile) u10)
            (* (get tasks-completed profile) u20)
            (* (get validations-given profile) u5)
            (/ (get total-earned profile) u1000000)
        )
    )
)

(define-read-only (get-validation-status (skill-id uint) (validator principal))
    (map-get? validations { skill-id: skill-id, validator: validator })
)

(define-read-only (get-platform-fee (amount uint))
    (/ (* amount (var-get platform-fee-percentage)) u10000)
)

;; Private functions
(define-private (initialize-user-profile (user principal))
    (map-set user-profiles user {
        reputation-score: u0,
        skills-owned: u0,
        validations-given: u0,
        validations-received: u0,
        tasks-completed: u0,
        tasks-posted: u0,
        total-earned: u0,
        total-spent: u0,
        joined-block: stacks-block-height
    })
)

(define-private (update-user-stats (user principal) (field (string-ascii 20)) (increment uint))
    (let ((profile (get-user-profile user)))
        (map-set user-profiles user
            (if (is-eq field "skills-owned")
                (merge profile { skills-owned: (+ (get skills-owned profile) increment) })
            (if (is-eq field "validations-given")
                (merge profile { validations-given: (+ (get validations-given profile) increment) })
            (if (is-eq field "validations-received")
                (merge profile { validations-received: (+ (get validations-received profile) increment) })
            (if (is-eq field "tasks-completed")
                (merge profile { tasks-completed: (+ (get tasks-completed profile) increment) })
            (if (is-eq field "tasks-posted")
                (merge profile { tasks-posted: (+ (get tasks-posted profile) increment) })
            (if (is-eq field "total-earned")
                (merge profile { total-earned: (+ (get total-earned profile) increment) })
            (if (is-eq field "total-spent")
                (merge profile { total-spent: (+ (get total-spent profile) increment) })
                profile
            )))))))
        )
    )
)

;; Public functions
;; Mint a new skill NFT
(define-public (mint-skill (name (string-ascii 50)) (category (string-ascii 30)) (metadata-uri (optional (string-ascii 256))))
    (let (
        (skill-id (+ (var-get skill-counter) u1))
        (sender tx-sender)
    )
        ;; Initialize user profile if needed
        (if (is-none (map-get? user-profiles sender))
            (initialize-user-profile sender)
            true
        )
        
        ;; Create the skill NFT
        (map-set skills skill-id {
            owner: sender,
            name: name,
            category: category,
            level: u1,
            experience-points: u0,
            validated: false,
            validator-count: u0,
            creation-block: stacks-block-height,
            last-updated: stacks-block-height,
            metadata-uri: metadata-uri
        })
        
        ;; Update counters
        (var-set skill-counter skill-id)
        (update-user-stats sender "skills-owned" u1)
        
        (ok skill-id)
    )
)

;; Stake STX to become a validator
(define-public (stake-as-validator (amount uint))
    (let ((sender tx-sender))
        (asserts! (>= amount (var-get validator-stake)) err-insufficient-stake)
        
        ;; Transfer STX to contract
        (try! (stx-transfer? amount sender (as-contract tx-sender)))
        
        ;; Record stake
        (map-set validator-stakes sender {
            amount: amount,
            locked-until: (+ stacks-block-height u1440), ;; ~10 days
            slashed-amount: u0
        })
        
        (ok true)
    )
)

;; Validate a skill
(define-public (validate-skill (skill-id uint) (score uint) (feedback (optional (string-ascii 256))))
    (let (
        (validator tx-sender)
        (skill (unwrap! (get-skill skill-id) err-not-found))
        (stake-info (unwrap! (map-get? validator-stakes validator) err-invalid-validator))
    )
        ;; Validations checks
        (asserts! (not (is-eq (get owner skill) validator)) err-self-validation)
        (asserts! (<= score u10) err-invalid-amount)
        (asserts! (>= score u1) err-invalid-amount)
        (asserts! (is-none (map-get? validations { skill-id: skill-id, validator: validator })) err-already-validated)
        
        ;; Pay validation fee
        (try! (stx-transfer? (var-get validation-fee) validator (as-contract tx-sender)))
        
        ;; Record validation
        (map-set validations 
            { skill-id: skill-id, validator: validator }
            {
                validated: true,
                validation-score: score,
                timestamp: stacks-block-height,
                feedback: feedback
            }
        )
        
        ;; Update skill validation count
        (map-set skills skill-id 
            (merge skill { 
                validator-count: (+ (get validator-count skill) u1),
                validated: (>= (+ (get validator-count skill) u1) (var-get min-validators))
            })
        )
        
        ;; Update validator stats
        (update-user-stats validator "validations-given" u1)
        (update-user-stats (get owner skill) "validations-received" u1)
        
        ;; Add to treasury
        (var-set treasury-balance (+ (var-get treasury-balance) (var-get validation-fee)))
        
        (ok true)
    )
)

;; Level up a skill through experience
(define-public (add-experience (skill-id uint) (experience uint))
    (let (
        (skill (unwrap! (get-skill skill-id) err-not-found))
        (sender tx-sender)
    )
        (asserts! (is-eq (get owner skill) sender) err-unauthorized)
        
        (let (
            (new-xp (+ (get experience-points skill) experience))
            (new-level (+ u1 (/ new-xp u1000))) ;; 1000 XP per level
        )
            (map-set skills skill-id
                (merge skill {
                    experience-points: new-xp,
                    level: (if (> new-level u100) u100 new-level),
                    last-updated: stacks-block-height
                })
            )
            
            (ok true)
        )
    )
)

;; Create a task in the marketplace
(define-public (create-task 
    (title (string-ascii 100)) 
    (description (string-ascii 500))
    (required-skills (list 5 uint))
    (budget uint)
    (deadline uint))
    (let (
        (task-id (+ (var-get task-counter) u1))
        (sender tx-sender)
    )
        (asserts! (> budget u0) err-invalid-amount)
        (asserts! (> deadline stacks-block-height) err-invalid-amount)
        
        ;; Initialize user profile if needed
        (if (is-none (map-get? user-profiles sender))
            (initialize-user-profile sender)
            true
        )
        
        ;; Escrow the budget
        (try! (stx-transfer? budget sender (as-contract tx-sender)))
        
        ;; Create task
        (map-set tasks task-id {
            poster: sender,
            title: title,
            description: description,
            required-skills: required-skills,
            budget: budget,
            deadline: deadline,
            status: "open",
            assignee: none,
            completion-proof: none
        })
        
        ;; Update counters
        (var-set task-counter task-id)
        (update-user-stats sender "tasks-posted" u1)
        (update-user-stats sender "total-spent" budget)
        
        (ok task-id)
    )
)

;; Apply for a task
(define-public (apply-for-task (task-id uint) (bid-amount uint) (proposal (string-ascii 500)))
    (let (
        (task (unwrap! (get-task task-id) err-not-found))
        (applicant tx-sender)
    )
        (asserts! (is-eq (get status task) "open") err-task-not-active)
        (asserts! (<= bid-amount (get budget task)) err-invalid-amount)
        (asserts! (not (is-eq (get poster task) applicant)) err-unauthorized)
        
        ;; Record application
        (map-set task-applications
            { task-id: task-id, applicant: applicant }
            {
                bid-amount: bid-amount,
                proposal: proposal,
                applied-at: stacks-block-height,
                status: "pending"
            }
        )
        
        (ok true)
    )
)

;; Accept a task application
(define-public (accept-application (task-id uint) (applicant principal))
    (let (
        (task (unwrap! (get-task task-id) err-not-found))
        (application (unwrap! (map-get? task-applications { task-id: task-id, applicant: applicant }) err-not-found))
    )
        (asserts! (is-eq (get poster task) tx-sender) err-unauthorized)
        (asserts! (is-eq (get status task) "open") err-task-not-active)
        
        ;; Update task
        (map-set tasks task-id
            (merge task {
                status: "in-progress",
                assignee: (some applicant)
            })
        )
        
        ;; Update application
        (map-set task-applications
            { task-id: task-id, applicant: applicant }
            (merge application { status: "accepted" })
        )
        
        (ok true)
    )
)

;; Complete a task
(define-public (complete-task (task-id uint) (completion-proof (string-ascii 256)))
    (let (
        (task (unwrap! (get-task task-id) err-not-found))
        (assignee (unwrap! (get assignee task) err-unauthorized))
    )
        (asserts! (is-eq assignee tx-sender) err-unauthorized)
        (asserts! (is-eq (get status task) "in-progress") err-task-not-active)
        
        ;; Update task
        (map-set tasks task-id
            (merge task {
                status: "completed",
                completion-proof: (some completion-proof)
            })
        )
        
        ;; Calculate payment
        (let (
            (platform-fee (get-platform-fee (get budget task)))
            (payment-amount (- (get budget task) platform-fee))
        )
            ;; Pay the assignee
            (try! (as-contract (stx-transfer? payment-amount tx-sender assignee)))
            
            ;; Update treasury
            (var-set treasury-balance (+ (var-get treasury-balance) platform-fee))
            
            ;; Update user stats
            (update-user-stats assignee "tasks-completed" u1)
            (update-user-stats assignee "total-earned" payment-amount)
        )
        
        (ok true)
    )
)

;; Endorse a skill (peer-to-peer validation)
(define-public (endorse-skill (skill-id uint))
    (let (
        (skill (unwrap! (get-skill skill-id) err-not-found))
        (endorser tx-sender)
        (endorser-reputation (calculate-reputation endorser))
    )
        (asserts! (not (is-eq (get owner skill) endorser)) err-self-validation)
        (asserts! (is-none (map-get? endorsements { skill-id: skill-id, endorser: endorser })) err-already-validated)
        
        ;; Record endorsement with weight based on reputation
        (map-set endorsements
            { skill-id: skill-id, endorser: endorser }
            {
                endorsed: true,
                weight: (/ endorser-reputation u100), ;; Normalize weight
                timestamp: stacks-block-height
            }
        )
        
        (ok true)
    )
)

;; Withdraw validator stake
(define-public (withdraw-stake)
    (let (
        (sender tx-sender)
        (stake-info (unwrap! (map-get? validator-stakes sender) err-not-found))
    )
        (asserts! (>= stacks-block-height (get locked-until stake-info)) err-cooldown-active)
        
        (let ((withdraw-amount (- (get amount stake-info) (get slashed-amount stake-info))))
            ;; Transfer back the stake minus any slashed amount
            (try! (as-contract (stx-transfer? withdraw-amount tx-sender sender)))
            
            ;; Remove stake record
            (map-delete validator-stakes sender)
            
            (ok withdraw-amount)
        )
    )
)

;; Admin functions
(define-public (set-validation-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
        (var-set validation-fee new-fee)
        (ok true)
    )
)

(define-public (set-min-validators (new-min uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
        (var-set min-validators new-min)
        (ok true)
    )
)

(define-public (withdraw-treasury (amount uint) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
        (asserts! (<= amount (var-get treasury-balance)) err-insufficient-balance)
        
        (try! (as-contract (stx-transfer? amount tx-sender recipient)))
        (var-set treasury-balance (- (var-get treasury-balance) amount))
        
        (ok true)
    )
)

;; Transfer skill ownership
(define-public (transfer-skill (skill-id uint) (new-owner principal))
    (let ((skill (unwrap! (get-skill skill-id) err-not-found)))
        (asserts! (is-eq (get owner skill) tx-sender) err-unauthorized)
        
        ;; Update skill owner
        (map-set skills skill-id (merge skill { owner: new-owner }))
        
        ;; Update user stats
        (update-user-stats tx-sender "skills-owned" u0) ;; Decrement by passing 0 (would need separate function)
        (update-user-stats new-owner "skills-owned" u1)
        
        (ok true)
    )
)