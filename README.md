# 🔗 TalentChain - Decentralized Professional Network

## 🌟 Overview

TalentChain is a revolutionary Web3-powered professional network built on Stacks blockchain using Clarity smart contracts. It enables professionals to truly own their career data, get rewarded for referrals, and participate in community-driven job boards.

## ✨ Key Features

### 🎯 Soulbound Professional Resumes
- **Non-transferable NFTs** representing professional credentials
- **Immutable career history** stored on-chain
- **Verification system** for trusted credentials
- **True ownership** of professional identity

### 💰 Tokenized Referral System
- **Earn STX rewards** for successful job referrals
- **Smart contract automation** ensures transparent payouts
- **Track referral performance** on-chain
- **Incentivize network growth** through economic rewards

### 🗳️ DAO-Driven Job Boards
- **Community voting** determines job listing visibility
- **Stake-to-post** mechanism prevents spam
- **Democratic job curation** by network participants
- **Transparent hiring process**

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet with STX for transactions
- Basic understanding of Clarity smart contracts

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/talentchain
cd talentchain
```

2. Check contract syntax:
```bash
clarinet check
```

3. Deploy to testnet:
```bash
clarinet deploy --testnet
```

## 📋 Contract Functions

### 👤 Resume Management

#### `create-resume`
Create your professional profile as a soulbound NFT
```clarity
(create-resume "John Doe" "Blockchain, Rust, JavaScript" "5 years Web3 development" "Computer Science Degree")
```

#### `update-resume`
Update your existing resume information
```clarity
(update-resume "John Doe" "Blockchain, Rust, JavaScript, Clarity" "6 years Web3 development" "Computer Science Degree, Blockchain Certification")
```

#### `get-resume`
Retrieve resume data by ID
```clarity
(get-resume u1)
```

#### `get-user-resume`
Get resume for a specific user
```clarity
(get-user-resume 'SP1ABC...)
```

### 💼 Job Management

#### `post-job`
Post a new job (requires staking 1 STX)
```clarity
(post-job "Senior Blockchain Developer" "Build DeFi protocols..." "5+ years experience" u80000 u120000)
```

#### `vote-job`
Vote on job listing quality
```clarity
(vote-job u1 true)  ; Vote in favor
(vote-job u1 false) ; Vote against
```

#### `activate-job`
Activate job after successful community vote
```clarity
(activate-job u1)
```

#### `get-job`
Retrieve job details
```clarity
(get-job u1)
```

### 🤝 Referral System

#### `create-referral`
Create a referral for a candidate
```clarity
(create-referral 'SP1CANDIDATE... u1)
```

#### `mark-hired`
Mark a candidate as hired (company only)
```clarity
(mark-hired u1)
```

#### `claim-referral-reward`
Claim reward for successful referral
```clarity
(claim-referral-reward u1)
```

### 🏆 Endorsement System

#### `add-endorsement`
Endorse someone's skills
```clarity
(add-endorsement 'SP1USER... "Smart Contracts" "Excellent Clarity developer")
```

#### `get-endorsement`
View endorsement details
```clarity
(get-endorsement 'SP1ENDORSER... 'SP1ENDORSED...)
```

## 🎮 Usage Examples

### Creating Your Professional Identity
1. **Create Resume**: Mint your soulbound professional NFT
2. **Get Endorsements**: Ask colleagues to endorse your skills
3. **Stay Updated**: Keep your resume current with latest achievements

### Earning Through Referrals
1. **Find Opportunities**: Browse active job listings
2. **Refer Candidates**: Create referrals for qualified professionals
3. **Get Rewarded**: Claim STX rewards when referrals are hired

### Participating in Job Curation
1. **Review Jobs**: Vote on job listing quality
2. **Earn Influence**: Build reputation through thoughtful voting
3. **Shape Community**: Help maintain high-quality job board

## 🔧 Technical Details

### Constants
- `MIN_JOB_STAKE`: 1 STX minimum stake for job posting
- `VOTING_PERIOD`: 144 blocks (~24 hours) for job voting
- `REFERRAL_REWARD`: 0.1 STX reward for successful referrals

### Error Codes
- `u100`: Not authorized owner
- `u101`: Already exists
- `u102`: Not found
- `u103`: Insufficient stake
- `u104`: Invalid vote
- `u105`: Already voted
- `u106`: Job expired
- `u107`: Unauthorized
- `u108`: Invalid referral

## 🛡️ Security Features

- **Soulbound tokens** prevent resume forgery
- **Staking mechanism** prevents job spam
- **Multi-sig verification** for critical operations
- **Time-locked voting** ensures fair evaluation
- **Non-transferable credentials** maintain identity integrity

## 🌍 Network Benefits

### For Professionals
- ✅ Own your professional data
- ✅ Verified, tamper-proof credentials
- ✅ Earn from your network connections
- ✅ Transparent job matching

### For Companies
- ✅ Access to verified talent pool
- ✅ Community-curated quality candidates
- ✅ Transparent hiring metrics
- ✅ Reduced recruitment fraud

### For the Network
- ✅ Self-sustaining referral economy
- ✅ Democratic job curation
- ✅ Reduced platform dependency
- ✅ Verifiable professional ecosystem

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Links

- **Documentation**: [Coming Soon]
- **Testnet Deploy**: [Coming Soon]
- **Discord Community**: [Coming Soon]
- **Twitter**: [Coming Soon]

## 💡 Future Roadmap

- 🔮 **Reputation Scoring**: Algorithm-based professional ratings
- 🎯 **Skills Verification**: Integration with coding platforms
- 🌐 **Cross-chain Identity**: Multi-blockchain professional profiles
- 🤖 **AI Matching**: Smart job-candidate pairing
- 📊 **Analytics Dashboard**: Professional network insights

---

Built with ❤️ on Stacks blockchain | Powered by Clarity smart contracts

*TalentChain - Where professionals truly own their career journey* 🚀
