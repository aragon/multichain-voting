

# L1L2 Token Voting Plugin for Aragon OSx 🔄🔗

## Description 📄
This repository hosts a Solidity Foundry project for an Aragon OSx plugin that powers decentralized, multi-chain governance. The plugin facilitates voting across different chains using ERC20Votes-standard tokens, employing the LayerZero bridge for message relaying. It's fully compatible with zkSync and LayerZero OFTs, ensuring a flexible and forward-compatible solution for DAO voting across chains.

🚀 Aragon OSx is an upgraded framework for Aragon DAOs, emphasizing efficiency, security, and user-friendliness. Discover more about Aragon OSx at the [Aragon Developer Portal](https://devs.aragon.org).

## Project Architecture 🏗️
The project consists of two parts:
- **DAOs**: There is one DAO per chain.
- **Plugins**: `L1TokenVoting` for the Layer 1 DAO and `L2TokenVoting` for the Layer 2 DAO.
- **Bridge**: Using `LayerZero`, both plugins will communicate with each other to sync data (proposals and votes).

## Setup 🛠️
Explore the Foundry tests for a detailed, step-by-step guide to setting up the DAOs and plugins. These tests provide essential insights into the correct use and configuration of the system.

## Development & Testing 🧪
Developers can use the following command to run exhaustive tests with a detailed gas report and verbose logging:

```shell
$ forge test --gas-report -vvvv
```

## Important Notice ⚠️
Please note that this plugin has **not yet been audited** for security. Use it at your own risk. An audit is recommended before deploying in a production environment.

## Usage Guide 📖
For deployment details, refer to the `tests/` directory. Following the provided tests is crucial to ensure proper operation of your DAOs on multiple chains.

## Contributions 🤝
We warmly welcome contributions from the community. Feel free to fork the project, make your changes, and submit a pull request. Be sure to test your changes thoroughly.

## License 📜
This project is licensed under AGPL-3.0-or-later.

## Support & Contact 🆘
If you need help or have queries, please post an issue in the issue tracker of this repository.

👉 Keep in mind that for any development work, the safety and correctness of the code are of utmost importance, especially due to the lack of an audit.

