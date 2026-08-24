# Phase 17: SQL Database, Built and Removed

## Goal

Add an Azure SQL database with Entra-only authentication, for the API to reach through its managed identity rather than a connection string.

## Completed

- Deployed an Azure SQL server and serverless database with Entra-only authentication and no SQL login.
- Fixed a plan check that had reported success on failing plans since phase 12.
- Stopped the plan comment publishing the subscription ID on a public repository.
- Moved the database to `swedencentral` after the subscription proved unable to provision SQL in the platform region.
- Removed the database, because nothing connected to it.

## Validated

- Entra-only authentication enabled, with no SQL login present.
- One firewall rule, the Azure services rule, and no personal address anywhere.
- Auditing enabled at server level with the diagnostic setting on the `master` database.
- Destroy plan limited to the five database resources, with the rest of the platform untouched.

## Left open

- The API was never connected, so contained user grants were never needed.
- Any future attempt should place the database behind a private endpoint, which requires rebuilding the environment on workload profiles.
