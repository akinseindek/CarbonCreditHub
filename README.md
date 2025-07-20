CarbonCreditHub
===============

* * * * *

Table of Contents
-----------------

Overview

Features

Smart Contract Details

Constants

Data Maps and Variables

Private Functions

Public Functions

Errors

Getting Started

Prerequisites

Deployment

Interacting with the Contract

Contribution

License

Contact

* * * * *

Overview
--------

I've created **CarbonCreditHub**, a secure, blockchain-based marketplace designed for the transparent and efficient trading of verified carbon offset credits. This smart contract enables the entire lifecycle of carbon offset tokens, from their creation and rigorous verification to seamless trading and permanent retirement. My aim with this project is to foster a more accessible and trustworthy carbon market, promoting environmental sustainability through decentralized technology.

* * * * *

Features
--------

-   **Project Creation**: Register new carbon offset projects with detailed metadata, including name, description, location, methodology, and total credits.

-   **Credit Ownership & Tracking**: Manage individual carbon credit balances for owners and facilitate transfers.

-   **Verification System**: Authorize independent verifiers to validate carbon projects, ensuring credibility and preventing fraud.

-   **Marketplace Listings**: Create and manage listings for selling carbon credits, specifying amounts and prices.

-   **Secure Trading**: Enable the purchase of carbon credits directly from listings, with automatic fee calculation and credit transfer.

-   **Credit Retirement**: Permanently remove carbon credits from circulation, recording the retirement event for transparency and accountability.

-   **Batch Processing**: Execute multiple credit operations (transfers, retirements) in a single transaction for efficiency.

-   **Transparency**: All project details, transactions, and retirements are immutably recorded on the blockchain.

* * * * *

Smart Contract Details
----------------------

The CarbonCreditHub contract is written in Clarity and consists of several key components:

### Constants

I've defined several constants for error handling and contract ownership:

-   `CONTRACT-OWNER`: The principal address of the contract deployer, holding administrative privileges.

-   `ERR-OWNER-ONLY`: Returned when a function can only be called by the contract owner.

-   `ERR-NOT-FOUND`: Returned when a specified ID (project, listing) does not exist.

-   `ERR-ALREADY-EXISTS`: Returned when attempting to create an entity that already exists (not currently used but reserved for future expansion).

-   `ERR-INSUFFICIENT-BALANCE`: Returned when an account lacks sufficient credits or STX for a transaction.

-   `ERR-INVALID-AMOUNT`: Returned when an amount specified is zero or otherwise invalid.

-   `ERR-NOT-VERIFIED`: Returned when an action requires a verified project, and it's not.

-   `ERR-ALREADY-VERIFIED`: Returned when attempting to verify an already verified project.

-   `ERR-EXPIRED-CREDIT`: Returned if an operation is attempted on an expired credit (not yet implemented but reserved).

-   `ERR-UNAUTHORIZED`: Returned when a sender is not authorized for a specific action (e.g., non-verifier attempting to verify).

-   `ERR-INVALID-PRICE`: Returned when a price specified is zero or otherwise invalid.

-   `ERR-CREDIT-RETIRED`: Returned if an operation is attempted on a retired credit (not yet implemented but reserved).

### Data Maps and Variables

I use various maps and data variables to store the state of the marketplace:

-   `carbon-projects`: Stores detailed metadata for each carbon offset project, indexed by `project-id`.

-   `credit-balances`: Tracks the balance of carbon credits for each owner per project.

-   `retired-credits`: Records details of permanently retired carbon credits.

-   `market-listings`: Stores information about active carbon credit listings on the marketplace.

-   `authorized-verifiers`: Lists principals authorized to verify projects, along with a `reputation-score`.

-   `next-project-id`: A counter for generating unique project IDs.

-   `next-listing-id`: A counter for generating unique listing IDs.

-   `platform-fee-rate`: The percentage fee charged by the platform for transactions (2.5% in basis points).

-   `total-credits-issued`: Tracks the cumulative total of all carbon credits minted.

-   `total-credits-retired`: Tracks the cumulative total of all carbon credits permanently removed.

### Private Functions

I've included several private helper functions to ensure modularity and reusability:

-   `(calculate-platform-fee (amount uint))`: Calculates the platform fee for a given amount.

-   `(is-valid-project (project-id uint))`: Checks if a project exists.

-   `(has-sufficient-credits (owner principal) (project-id uint) (amount uint))`: Verifies if an owner has enough credits for a specific project.

-   `(transfer-credits (from principal) (to principal) (project-id uint) (amount uint))`: Handles the internal transfer of credits between principals.

-   `(process-single-operation (operation ...))`: A helper for `batch-process-credit-operations`, executing individual operations within a batch.

-   `(is-operation-successful (result (response bool uint)))`: Checks if a Clarity response indicates success.

### Public Functions

These functions are accessible to external callers and represent the core functionalities of the marketplace:

-   `(create-carbon-project ...)`: Allows anyone to register a new carbon offset project.

-   `(authorize-verifier (verifier principal))`: Enables the `CONTRACT-OWNER` to authorize new verifiers.

-   `(verify-project (project-id uint))`: Allows an authorized verifier to mark a project as verified.

-   `(create-market-listing (project-id uint) (amount uint) (price-per-credit uint))`: Creates a new listing for selling verified carbon credits.

-   `(purchase-credits (listing-id uint) (amount uint))`: Allows users to purchase credits from an active listing.

-   `(retire-credits (project-id uint) (amount uint) (reason (string-ascii 100)))`: Allows users to permanently retire their carbon credits.

-   `(batch-process-credit-operations (operations (list 10 ...)))`: Enables efficient execution of multiple credit operations (transfers, retirements) in one transaction.

* * * * *

Errors
------

The contract uses specific error codes to indicate the reason for a failed transaction. These are defined as constants at the beginning of the contract and include:

-   `u100`: `ERR-OWNER-ONLY`

-   `u101`: `ERR-NOT-FOUND`

-   `u102`: `ERR-ALREADY-EXISTS`

-   `u103`: `ERR-INSUFFICIENT-BALANCE`

-   `u104`: `ERR-INVALID-AMOUNT`

-   `u105`: `ERR-NOT-VERIFIED`

-   `u106`: `ERR-ALREADY-VERIFIED`

-   `u107`: `ERR-EXPIRED-CREDIT`

-   `u108`: `ERR-UNAUTHORIZED`

-   `u109`: `ERR-INVALID-PRICE`

-   `u110`: `ERR-CREDIT-RETIRED`

-   `u999`: Generic error for `batch-process-credit-operations` if all operations fail.

* * * * *

Getting Started
---------------

### Prerequisites

To interact with this contract, you'll need:

-   A Stacks wallet (e.g., Leather, Xverse).

-   STX tokens for transaction fees.

-   A Clarity development environment if you plan to modify or test the contract locally.

### Deployment

The contract is designed to be deployed on the Stacks blockchain. Once deployed, the deployer becomes the `CONTRACT-OWNER`.

### Interacting with the Contract

You can interact with the contract using a Stacks wallet or through a dApp interface built on top of it. Key interactions include:

1.  **Creating a Project**: Call `create-carbon-project` with the project details.

2.  **Authorizing Verifiers**: The `CONTRACT-OWNER` calls `authorize-verifier`.

3.  **Verifying a Project**: An authorized verifier calls `verify-project`.

4.  **Listing Credits**: A project creator or credit holder calls `create-market-listing`.

5.  **Purchasing Credits**: A buyer calls `purchase-credits`.

6.  **Retiring Credits**: A credit holder calls `retire-credits`.

* * * * *

Contribution
------------

I welcome contributions to enhance CarbonCreditHub! If you have suggestions, bug reports, or want to contribute code, please feel free to:

1.  Fork the repository.

2.  Create a new branch (`git checkout -b feature/your-feature-name`).

3.  Make your changes.

4.  Commit your changes (`git commit -m 'Add new feature'`).

5.  Push to the branch (`git push origin feature/your-feature-name`).

6.  Open a Pull Request.

* * * * *

License
-------

This project is licensed under the MIT License. See the `LICENSE` file for details.

* * * * *

Contact
-------

If you have any questions or feedback, feel free to reach out to me!
