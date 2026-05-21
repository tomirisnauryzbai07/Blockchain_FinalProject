# ADR-001: Choose Option D Prediction Market

## Context

The project must satisfy a large set of mandatory smart contract, governance, testing, oracle, frontend, and DevOps requirements.

## Options Considered

- Option A: rich feature set but too large for a solo workflow
- Option C: easier compliance but weaker alignment with ERC-1155 and AMM requirements
- Option D: naturally fits AMM, ERC-1155, governance, oracle, and subgraph requirements

## Decision

Use `Option D — On-Chain Prediction Market` as the primary protocol direction.

## Consequences

- positive: strong fit with mandatory checklist
- positive: clear user flows for frontend and demo
- negative: outcome resolution and payout logic need careful security review
- negative: LMSR would add math complexity, so CPMM-style design is preferred initially

