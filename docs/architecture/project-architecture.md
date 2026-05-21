# Prediction Market Architecture Draft

## Objective

Build a production-style decentralized prediction market that satisfies the mandatory course requirements while remaining realistic for a solo implementation workflow.

## Core Components

### 1. Market Factory

Responsible for deploying individual binary markets.

- must support both `CREATE` and `CREATE2`
- records metadata and emitted addresses
- later upgrade path: deterministic deployments for predictable market addresses

### 2. Prediction Market Core

Represents a single market with two outcomes.

- outcome A and outcome B share accounting
- AMM pricing / buy / sell functions
- resolution state machine
- payout redemption after resolution

### 3. Outcome Token

`ERC-1155`-style token contract for outcome shares.

- token id `0`: NO
- token id `1`: YES
- minted/burned by authorized market contracts

### 4. Governance Layer

- governance token with delegated voting
- governor + timelock
- treasury under timelock control
- parameters updated through proposals only

### 5. Oracle Adapter

- wraps Chainlink feed integration
- enforces staleness threshold
- provides normalized values to market resolution logic

### 6. Vault / Treasury

- accumulates protocol fees
- ERC-4626 fee vault used for tokenized fee/yield accounting
- direct asset donations increase assets-per-share and model protocol yield accrual

## Mandatory Requirement Mapping

- upgradeability: UUPS-managed admin or treasury path
- factory: `CREATE` and `CREATE2`
- token standards: governance ERC-20, ERC-1155 outcome token, ERC-4626 vault
- DeFi primitive: custom AMM for market pricing
- oracle: Chainlink adapter + mocks
- governance: OpenZeppelin Governor stack
- indexing: subgraph for markets, trades, proposals, vault activity
- L2: Base Sepolia or Arbitrum Sepolia deployment

## Risks

- solo-submission policy may require instructor exception
- governance + vault + subgraph integration is the largest scope risk
- 80-test minimum and 90% coverage need to be planned from the start
