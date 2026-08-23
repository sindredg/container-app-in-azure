# Phase 13: Scaling and Release Mechanics

## Goal

Prove the platform scales under load, and that a bad release can be undone without redeploying.

## Completed

- Moved the web app to multiple revision mode, so the previous revision stays alive as a rollback target.
- Made rollback a traffic weight change driven by two variables rather than a redeployment.
- Replaced hardcoded scaling limits with variables, so a test is a reviewed change and the baseline is restored by reverting two values.
- Ran a controlled load test at a ceiling of five replicas.
- Fixed revision naming so names stay unique for configuration changes, not just image releases.
- Restarted a running replica to confirm the health probes actually protect traffic.

## Validated

- The app scaled from zero to five replicas under sustained load.
- No request failed while replicas were being added.
- Replicas returned to zero after the cooldown.
- Both scaling values were returned to their baseline afterwards.
- A replica restart replaced containers with no failed request, because the readiness probe kept unready replicas out of the load balancer.

![No replicas before the test, the app had scaled to zero](../images/phase-13-replicas-at-zero.png)

![Five replicas serving load](../images/phase-13-five-replicas-under-load.png)

![Traffic continues uninterrupted through a replica restart](../images/phase-13-traffic-uninterrupted.png)
