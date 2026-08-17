# Phase 12: GitHub Actions Pipeline

## Goal

Replace manual image builds and local applies with a pipeline that plans on every pull request and deploys from `main` behind an approval gate.

## Completed

- Created a CI identity with federated credentials, so no client secret exists at any point.
- Placed the identity and its role assignments in the bootstrap root, which only a human applies, so the pipeline cannot widen its own permissions.
- Scoped its access to Contributor on one resource group, state blob access, and registry push without delete.
- Added a workflow that runs format, validate, and plan on pull requests and posts the plan as a comment.
- Added a deploy workflow gated by a GitHub environment with a required reviewer.
- Made the deploy build any image whose tag is not already published, then apply, then smoke test.

## Validated

- The full pipeline runs green in under three minutes.
- The approval gate holds the run until a reviewer approves.
- The smoke test caught a real defect on its first run, where an image predated the change it was meant to carry.

![The dev environment requires a reviewer before deploying](../images/phase-12-environment-approval-gate.png)

![The pipeline runs green end to end](../images/phase-12-pipeline-green.png)
