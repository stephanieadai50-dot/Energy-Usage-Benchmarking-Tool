# ⚡ Energy Usage Benchmarking Tool

A Clarity smart contract for tracking and benchmarking building energy consumption on the Stacks blockchain.

## 🏢 Overview

The Energy Usage Benchmarking Tool enables building owners to register their properties, submit energy usage reports, and compare their efficiency against industry benchmarks. The contract incentivizes participation through a reward system and provides comprehensive analytics for energy performance evaluation.

## ✨ Features

- 🏗️ **Building Registration**: Register buildings with metadata (name, type, square footage)
- 📊 **Energy Reporting**: Submit periodic energy usage data with automatic efficiency scoring
- 🎯 **Benchmarking**: Compare building performance against type-specific averages
- 🏆 **Reward System**: Earn points for consistent reporting participation
- 📈 **Analytics**: Track performance trends and efficiency improvements
- 🔐 **Access Control**: Secure ownership-based permissions

## 🚀 Quick Start

### Register a Building
```clarity
(contract-call? .energy-usage-benchmarking-tool register-building "Office Tower" "commercial" u50000)
```

### Submit Energy Report
```clarity
(contract-call? .energy-usage-benchmarking-tool submit-energy-report u1 u75000 u30)
```

### Check Building Efficiency
```clarity
(contract-call? .energy-usage-benchmarking-tool calculate-building-efficiency u1)
```

## 📋 Contract Functions

### Public Functions

#### `register-building`
Register a new building in the system.
- **Parameters**: `name` (string), `building-type` (string), `square-footage` (uint)
- **Returns**: Building ID (uint)

#### `submit-energy-report`
Submit energy usage data for a registered building.
- **Parameters**: `building-id` (uint), `energy-usage` (uint), `reporting-period` (uint)
- **Returns**: Report ID (uint)

#### `update-building-status`
Enable/disable a building (owner only).
- **Parameters**: `building-id` (uint), `is-active` (bool)
- **Returns**: Success boolean

#### `set-benchmark-threshold`
Update benchmark threshold (contract owner only).
- **Parameters**: `new-threshold` (uint)
- **Returns**: Success boolean

### Read-Only Functions

#### `get-building-info`
Retrieve building details by ID.

#### `get-building-stats`
Get aggregated statistics for a building.

#### `get-energy-report`
Fetch specific energy report data.

#### `get-benchmark-data`
Get benchmark data for a building type.

#### `get-user-rewards`
Check user's reward points and activity.

#### `get-contract-stats`
View overall contract statistics.

#### `calculate-building-efficiency`
Compare building performance against benchmarks.

#### `validate-energy-data`
Validate energy usage input before submission.

## 🏗️ Data Structures

### Buildings Map
- `owner`: Principal of building owner
- `name`: Building identifier
- `building-type`: Category (e.g., "commercial", "residential")
- `square-footage`: Total area
- `created-at`: Registration timestamp
- `is-active`: Status flag

### Energy Reports Map
- `reporter`: Principal submitting report
- `energy-usage`: Total consumption for period
- `reporting-period`: Duration in days
- `timestamp`: Submission time
- `efficiency-score`: Calculated performance score

## 🎮 Usage Examples

### Building Owner Workflow
1. Register building: `register-building`
2. Submit monthly reports: `submit-energy-report`
3. Monitor performance: `calculate-building-efficiency`
4. Track improvements over time

### Analyst Workflow
1. Query benchmark data: `get-benchmark-data`
2. Compare building performance: `calculate-building-efficiency`
3. Analyze trends across building types
4. Generate efficiency reports

## 🏆 Reward System

Users earn points for:
- ✅ Submitting energy reports (10 points)
- 🔥 Consistent reporting streak (50 bonus points after 10 reports)
- 📊 Contributing to benchmark data

## 📊 Efficiency Scoring

The contract calculates efficiency scores based on energy usage per square foot:

- **High Efficiency**: ≤10 units/sqft (Score: 9000-10000)
- **Medium Efficiency**: 11-50 units/sqft (Score: 1000-9000)  
- **Low Efficiency**: >50 units/sqft (Score: 1000)

## 🔧 Development

### Prerequisites
- Clarinet CLI installed
- Stacks blockchain environment

### Testing
```bash
clarinet check
clarinet test
```

### Deployment
```bash
clarinet deployments generate --devnet
clarinet deployments apply --devnet
```

## 📈 Contract Statistics

Track platform growth with:
- Total registered buildings
- Number of energy reports submitted
- Active benchmark categories
- User participation metrics

## 🔒 Security Features

- Owner-only building management
- Input validation on all parameters
- Safe arithmetic operations
- Error handling for edge cases

## 📝 Error Codes

- `u100`: Unauthorized access
- `u101`: Invalid usage data
- `u102`: Building not found
- `u103`: Invalid benchmark parameters  
- `u104`: Insufficient data for analysis
- `u105`: Invalid efficiency score

## 🤝 Contributing

This contract is designed for transparency and community participation in energy efficiency initiatives. Building owners, energy analysts, and sustainability professionals can all benefit from the benchmarking insights.

---

**Built with ❤️ for a more energy-efficient future** 🌱
