# FinalTomi Blockchain

Course capstone scaffold for `Blockchain Technologies 2`.

## Chosen Scenario

`Option D — On-Chain Prediction Market`

The protocol will implement binary outcome markets with:

- an AMM-based pricing layer
- ERC-1155 outcome share tokens
- Chainlink-backed resolution and staleness protection
- DAO governance with timelock-controlled treasury
- L2 deployment and event indexing through The Graph

## Repository Layout

- `src/` smart contracts
- `test/` unit, fuzz, invariant, and fork tests
- `script/` deployment and verification scripts
- `frontend/` dApp client
- `subgraph/` The Graph indexing project
- `docs/architecture/` architecture notes and ADRs
- `docs/audit/` internal audit report drafts
- `docs/gas/` gas benchmark notes

## Project Milestones

- [x] Scenario selected
- [x] Repository initialized
- [ ] Core contracts compile
- [ ] Unit test suite established
- [ ] Governance flow wired end-to-end
- [ ] Oracle integration with staleness checks
- [ ] Subgraph queries documented
- [ ] Frontend write flows completed
- [ ] L2 deployment and verification
- [ ] Audit, architecture, gas, and presentation deliverables

## Planned Contract Set

- `PredictionMarketFactory`
- `PredictionMarket`
- `OutcomeToken`
- `GovernanceToken`
- `TreasuryVault`
- `OracleAdapter`
- governance stack and upgradeable admin components

## Immediate Next Steps

1. Replace scaffold contracts with production implementations.
2. Add OpenZeppelin and Chainlink dependencies.
3. Stand up the first passing test suite in Foundry.
4. Add frontend and subgraph scaffolds against deployed/local ABIs.

