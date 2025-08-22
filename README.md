# Utility Bill Management and Energy Monitoring System

A comprehensive Clarity smart contract system for managing utility billing cycles, energy usage tracking, and conservation programs.

## Overview

This system provides a decentralized solution for utility companies and consumers to manage:

- **Billing Cycles**: Automated billing period management and payment coordination
- **Energy Usage Tracking**: Real-time monitoring and historical usage data
- **Conservation Goals**: Setting and tracking energy efficiency targets
- **Rate Structures**: Transparent pricing with tiered rate systems
- **Budget Billing**: Predictable monthly payment plans
- **Renewable Energy Programs**: Integration with green energy initiatives

## Smart Contracts

### 1. `billing-manager.clar`
Manages billing cycles, payment processing, and account management.

**Key Functions:**
- `create-account`: Register new utility accounts
- `process-billing-cycle`: Generate monthly bills
- `record-payment`: Process customer payments
- `get-account-balance`: Check current account status

### 2. `energy-tracker.clar`
Tracks energy consumption and usage patterns.

**Key Functions:**
- `record-usage`: Log daily energy consumption
- `get-usage-history`: Retrieve historical usage data
- `calculate-monthly-usage`: Aggregate usage for billing periods
- `compare-usage`: Compare current vs previous periods

### 3. `conservation-goals.clar`
Manages energy conservation targets and rewards.

**Key Functions:**
- `set-conservation-goal`: Establish efficiency targets
- `track-goal-progress`: Monitor conservation achievements
- `calculate-savings`: Determine energy and cost savings
- `award-conservation-credits`: Reward goal achievement

### 4. `rate-structure.clar`
Defines and manages utility rate structures and pricing tiers.

**Key Functions:**
- `set-base-rate`: Configure standard pricing
- `define-tier-rates`: Set tiered pricing structures
- `calculate-bill-amount`: Compute charges based on usage
- `get-current-rates`: Retrieve active rate information

### 5. `renewable-programs.clar`
Manages renewable energy programs and green energy credits.

**Key Functions:**
- `enroll-renewable-program`: Join green energy initiatives
- `track-renewable-usage`: Monitor clean energy consumption
- `calculate-green-credits`: Determine renewable energy benefits
- `get-program-status`: Check enrollment and benefits

## Data Structures

### Account Information
- Account ID (principal)
- Service address
- Account status
- Current balance
- Payment history

### Usage Data
- Daily consumption readings
- Monthly aggregates
- Historical comparisons
- Peak usage periods

### Conservation Metrics
- Goal targets
- Achievement progress
- Savings calculations
- Reward credits

## Installation

1. Install Clarinet CLI
2. Clone this repository
3. Run `clarinet check` to validate contracts
4. Run `npm test` to execute test suite

## Testing

The system includes comprehensive Vitest tests covering:
- Contract deployment and initialization
- Account management operations
- Usage tracking and calculations
- Conservation goal management
- Rate structure applications
- Renewable program enrollment

## Usage Examples

### Creating a New Account
```clarity
(contract-call? .billing-manager create-account tx-sender "123 Main St")
