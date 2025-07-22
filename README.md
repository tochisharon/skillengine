# Skill Engine - Decentralized Skill Verification & Marketplace

A revolutionary smart contract system on the Stacks blockchain that transforms how skills are verified, validated, and monetized through a decentralized marketplace.

[![Stacks](https://img.shields.io/badge/Stacks-2.0-blue)](https://www.stacks.co/)
[![Clarity](https://img.shields.io/badge/Clarity-Smart%20Contract-purple)](https://clarity.tools/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

## 🚀 Overview

Skill Engine creates a trustless ecosystem where:
- **Professionals** mint their skills as evolving NFTs
- **Validators** stake STX to verify skills and earn rewards
- **Employers** post tasks and hire verified talent
- **Community** builds reputation through peer endorsements

## ✨ Key Features

### 🎯 Dynamic Skill NFTs
- Mint skills as NFTs that evolve with experience points
- Level progression system (1-100)
- Metadata support for rich skill descriptions
- Transferable ownership

### 🔐 Stake-Based Validation
- Validators stake STX to participate
- Economic incentives for honest validation
- Slashing mechanisms for bad actors
- Time-locked stakes with withdrawal periods

### 💼 Decentralized Task Marketplace
- Post tasks with STX budgets
- Escrow-based payment system
- Skill-based matching
- Automatic payment distribution

### ⭐ Multi-Layer Reputation System
- Reputation calculated from:
  - Validations received
  - Tasks completed
  - Peer endorsements
  - Total earnings
- Weighted endorsement system

### 💰 Economic Model
- Platform fees for sustainability
- Validation fees for quality control
- Treasury management
- Fair payment distribution

## 🛠️ Technical Architecture

### Smart Contract Structure
```
skillengine.clar
├── Constants & Errors
├── Data Variables
├── Data Maps
│   ├── skills
│   ├── user-profiles
│   ├── validations
│   ├── validator-stakes
│   ├── tasks
│   ├── task-applications
│   └── endorsements
├── Read-only Functions
├── Private Functions
├── Public Functions
└── Admin Functions
```

### Core Data Structures

#### Skill NFT
```clarity
{
    owner: principal,
    name: (string-ascii 50),
    category: (string-ascii 30),
    level: uint,
    experience-points: uint,
    validated: bool,
    validator-count: uint,
    creation-block: uint,
    last-updated: uint,
    metadata-uri: (optional (string-ascii 256))
}
```

#### User Profile
```clarity
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
```

## 📦 Installation

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) v1.0+
- [Stacks CLI](https://docs.stacks.co/references/stacks-cli)
- Node.js 16+

### Setup
```bash
# Clone the repository
git clone https://github.com/yourusername/skill-engine.git
cd skill-engine

# Install dependencies
npm install

# Run tests
clarinet test

# Check contract syntax
clarinet check
```

## 📚 Usage Examples

### Minting a Skill
```clarity
(contract-call? .skillengine mint-skill 
    "Solidity Development" 
    "Programming" 
    (some "ipfs://QmSkillMetadata"))
```

### Becoming a Validator
```clarity
;; Stake 5 STX to become a validator
(contract-call? .skillengine stake-as-validator u5000000)
```

### Validating a Skill
```clarity
(contract-call? .skillengine validate-skill 
    u1 ;; skill-id
    u8 ;; score (1-10)
    (some "Excellent Solidity knowledge demonstrated"))
```

### Creating a Task
```clarity
(contract-call? .skillengine create-task
    "Build DEX Smart Contract"
    "Need experienced Solidity dev for DEX"
    (list u1 u5 u10) ;; required skill IDs
    u50000000 ;; 50 STX budget
    u144000) ;; deadline block
```

### Applying for a Task
```clarity
(contract-call? .skillengine apply-for-task
    u1 ;; task-id
    u45000000 ;; bid amount
    "I can build your DEX with advanced features")
```

## 📖 API Reference

### Read Functions

#### `get-skill (skill-id uint)`
Returns skill NFT details

#### `get-user-profile (user principal)`
Returns complete user profile with statistics

#### `calculate-reputation (user principal)`
Calculates user's reputation score

#### `get-task (task-id uint)`
Returns task marketplace details

### Write Functions

#### `mint-skill`
Create a new skill NFT

#### `validate-skill`
Validate another user's skill (requires stake)

#### `add-experience`
Add experience points to your skill

#### `create-task`
Post a new task to the marketplace

#### `complete-task`
Mark a task as completed and trigger payment

### Admin Functions

#### `set-validation-fee`
Update validation fee amount

#### `withdraw-treasury`
Withdraw accumulated platform fees

## 🔒 Security Considerations

### Built-in Protections
- ✅ Self-validation prevention
- ✅ Double-spending protection
- ✅ Escrow-based payments
- ✅ Time-locked validator stakes
- ✅ Access control for admin functions

### Best Practices
- Always verify skill ownership before transfers
- Check validator stake status before validating
- Ensure sufficient STX balance for operations
- Monitor deadline blocks for tasks

## 🧪 Testing

```bash
# Run all tests
clarinet test

# Run specific test suite
clarinet test tests/skill-validation-test.ts

# Generate coverage report
clarinet test --coverage
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md).

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🗺️ Roadmap

### Phase 1 (Current)
- ✅ Core skill NFT functionality
- ✅ Validation system
- ✅ Task marketplace
- ✅ Basic reputation system

### Phase 2 (Q2 2025)
- [ ] Skill categories and subcategories
- [ ] Advanced matching algorithms
- [ ] Dispute resolution system
- [ ] Multi-signature validations

### Phase 3 (Q3 2025)
- [ ] Cross-chain skill portability
- [ ] AI-assisted skill assessments
- [ ] Enterprise integration APIs
- [ ] Mobile app support

## 📊 Contract Economics

| Parameter | Value | Description |
|-----------|-------|-------------|
| Validation Fee | 1 STX | Fee paid by validators |
| Min Validators | 3 | Minimum validations for verification |
| Validator Stake | 5 STX | Required stake to become validator |
| Platform Fee | 2.5% | Fee on completed tasks |
| Stake Lock Period | ~10 days | Cooldown for stake withdrawal |

## 🔗 Resources

- [Documentation](https://docs.skillengine.io)
- [Discord Community](https://discord.gg/skillengine)
- [Twitter](https://twitter.com/skillengine)
- [Blog](https://blog.skillengine.io)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Stacks Foundation for blockchain infrastructure
- Clarity language developers
- Early validators and testers
- Open-source contributors

---

**Built with ❤️ for the decentralized future of work**
