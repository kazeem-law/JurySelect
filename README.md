# JurySelect

JurySelect is a decentralized voting system smart contract built on the Stacks blockchain for jury selection and verdict systems. It provides a transparent, secure, and automated way to manage jury pools, select jurors for cases, and conduct voting for legal verdicts.

## Features

### Core Functionality
- **Jury Member Registration**: Citizens can register to become eligible jury members
- **Case Management**: Judges and administrators can create and manage legal cases
- **Automated Jury Selection**: Systematic selection of qualified jurors for specific cases
- **Secure Voting System**: Anonymous and tamper-proof voting mechanism for verdicts
- **Transparent Verdict Calculation**: Automatic tallying of votes with public visibility
- **Role-Based Access Control**: Different permissions for judges, administrators, and jurors

### Key Capabilities
- **Multi-Case Support**: Handle multiple concurrent legal cases
- **Deadline Management**: Automatic enforcement of voting deadlines
- **Vote Privacy**: Individual votes are private while totals remain transparent
- **Audit Trail**: Complete history of case creation, jury selection, and voting
- **Status Tracking**: Real-time case status (Pending, Active, Completed, Cancelled)
- **Jury Pool Management**: Dynamic tracking of available jury members

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity
- **Contract Version**: 1.0.0
- **Clarity Version**: 2
- **Epoch**: 2.5

### Smart Contract Architecture

#### Data Structures
- **Jury Members**: Principal-mapped registry with registration status and service history
- **Cases**: Detailed case information including metadata, deadlines, and vote counts  
- **Case Jurors**: Mapping of selected jurors to specific cases
- **Votes**: Secure storage of individual juror votes per case
- **Administrators**: Role-based access control for case management

#### Constants
```clarity
;; Error codes
ERR_NOT_AUTHORIZED (u100)
ERR_NOT_FOUND (u101)
ERR_ALREADY_EXISTS (u102)
ERR_INVALID_STATUS (u103)
ERR_ALREADY_VOTED (u104)
ERR_CASE_NOT_ACTIVE (u105)
ERR_NOT_JURY_MEMBER (u106)
ERR_INSUFFICIENT_JURORS (u107)

;; Case statuses
STATUS_PENDING (u0)
STATUS_ACTIVE (u1) 
STATUS_COMPLETED (u2)
STATUS_CANCELLED (u3)

;; Verdict options
VERDICT_GUILTY (u1)
VERDICT_NOT_GUILTY (u2)
```

## Installation

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) (v14 or higher)
- [Stacks CLI](https://docs.stacks.co/references/stacks-cli)

### Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd JurySelect
   ```

2. **Install Dependencies**
   ```bash
   cd JurySelect_contract
   npm install
   ```

3. **Verify Installation**
   ```bash
   clarinet check
   ```

4. **Run Tests**
   ```bash
   npm test
   ```

## Usage Examples

### Contract Initialization

```clarity
;; Initialize the contract (only contract owner)
(contract-call? .JurySelect initialize)
```

### Jury Member Registration

```clarity
;; Register as a jury member
(contract-call? .JurySelect register-as-juror)
```

### Case Creation

```clarity
;; Create a new legal case (administrators only)
(contract-call? .JurySelect create-case 
  "Criminal Case #2024-001" 
  "Armed robbery case requiring jury verdict" 
  u12  ;; 12 jurors required
  u1000 ;; voting duration in blocks
)
```

### Jury Selection

```clarity
;; Select a juror for a specific case (judge only)
(contract-call? .JurySelect select-juror 
  u1  ;; case-id
  'SP1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE ;; juror principal
)
```

### Case Activation

```clarity
;; Activate case for voting once jury is selected (judge only)
(contract-call? .JurySelect activate-case u1)
```

### Voting

```clarity
;; Cast a verdict vote (selected jurors only)
(contract-call? .JurySelect cast-vote 
  u1  ;; case-id
  u1  ;; verdict (1 = guilty, 2 = not guilty)
)
```

### Case Finalization

```clarity
;; Finalize case after voting deadline (anyone can call)
(contract-call? .JurySelect finalize-case u1)
```

## Contract Functions Documentation

### Public Functions

#### Administrative Functions
- `initialize()` - Initialize contract and set deployer as administrator
- `add-case-administrator(admin: principal)` - Add new case administrator

#### Jury Management
- `register-as-juror()` - Register caller as eligible jury member
- `select-juror(case-id: uint, juror: principal)` - Select juror for specific case

#### Case Management  
- `create-case(title, description, jurors-required, voting-duration)` - Create new legal case
- `activate-case(case-id: uint)` - Activate case for voting
- `finalize-case(case-id: uint)` - Close case after voting deadline

#### Voting
- `cast-vote(case-id: uint, verdict: uint)` - Submit jury verdict vote

### Read-Only Functions

#### Data Retrieval
- `get-case(case-id: uint)` - Get complete case information
- `get-jury-member(member: principal)` - Get jury member details
- `get-juror-vote(case-id: uint, juror: principal)` - Get specific vote
- `get-case-verdict(case-id: uint)` - Get final verdict result

#### Status Checks
- `is-case-administrator(admin: principal)` - Check admin privileges
- `is-case-juror(case-id: uint, juror: principal)` - Check jury selection
- `get-case-counter()` - Get total number of cases
- `get-jury-pool-size()` - Get registered jury member count

## Deployment Guide

### Local Development (Clarinet)

1. **Start Development Environment**
   ```bash
   clarinet console
   ```

2. **Deploy Contract**
   ```clarity
   ::deploy_contracts
   ```

3. **Test Functions**
   ```clarity
   (contract-call? .JurySelect initialize)
   ```

### Testnet Deployment

1. **Configure Network**
   ```bash
   # Edit settings/Testnet.toml with your account details
   ```

2. **Deploy to Testnet**
   ```bash
   clarinet deployments generate --testnet
   clarinet deployments apply --testnet
   ```

### Mainnet Deployment

1. **Configure Mainnet Settings**
   ```bash
   # Edit settings/Mainnet.toml
   ```

2. **Deploy to Mainnet**
   ```bash
   clarinet deployments generate --mainnet  
   clarinet deployments apply --mainnet
   ```

## Security Notes

### Access Control
- **Contract Owner**: Only the deployer can initialize the contract and add the first administrator
- **Administrators**: Can create cases and select jurors
- **Judges**: Case creators have exclusive rights to manage their cases
- **Jurors**: Can only vote on cases where they are selected

### Voting Security
- **Deadline Enforcement**: Votes cannot be cast after the voting deadline
- **Single Vote**: Each juror can only vote once per case
- **Immutable Votes**: Votes cannot be changed once submitted
- **Anonymous Totals**: Individual votes are private, only totals are publicly visible

### Smart Contract Security
- **Input Validation**: All parameters are validated before execution
- **State Consistency**: Contract state is protected against invalid transitions
- **Error Handling**: Comprehensive error codes for debugging and user feedback
- **Reentrancy Protection**: Functions are designed to prevent reentrancy attacks

### Best Practices
1. **Always initialize** the contract after deployment
2. **Verify jury pool size** before creating cases requiring many jurors
3. **Set appropriate voting deadlines** to allow sufficient time for deliberation
4. **Monitor case status** to ensure proper progression through workflow
5. **Regularly audit** administrator and juror registrations

### Known Limitations
- Cases cannot be modified once created
- Jury selection is manual (not automated random selection)
- No mechanism for jury member removal or suspension
- Voting is binary (guilty/not guilty) with no abstention option
- No built-in appeal or retrial mechanism

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## Support

For questions, issues, or contributions, please refer to the project's issue tracker or contact the development team.

---

**Disclaimer**: This smart contract is provided as-is for educational and development purposes. Thoroughly audit and test before using in production environments, especially for actual legal proceedings.