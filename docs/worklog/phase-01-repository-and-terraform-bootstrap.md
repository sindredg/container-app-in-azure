# Phase 1 worklog: Repository and Terraform Bootstrap

## Goal

Establish the engineering workflow before any Azure resource exists: a local repository, a private GitHub remote, an issue-driven branch, version constraints, and a reviewed pull request. Nothing is applied to Azure in this phase.

Related: [decision log](../decisions.md).

## Repository baseline

The project was initialized on `main` inside WSL at `~/projects/container-app-in-azure`.

![Git repository initialized on main](../images/phase-01-git-init-main.png)

Proves the repository was created on a branch named `main` with no commits yet.

Terraform ignore rules came before the first commit, so state and plans could never be staged by accident.

![Terraform ignore rules](../images/phase-01-terraform-gitignore.png)

Proves `.gitignore` excludes `.terraform/`, state files, saved plans, `*.tfvars`, crash logs, and `.env`.

![Review of staged additions](../images/phase-01-staged-baseline-diff.png)

Proves the baseline contents were reviewed as a diff before committing, and that both files were new.

![First commit recorded in local history](../images/phase-01-first-commit.png)

Proves the root commit `044bb7b` recorded two files and left a clean working tree.

## Private remote and issue

![Private GitHub repository created and pushed](../images/phase-01-github-repo-created.png)

Proves the repository was created with `--private`, and that the remote was registered as `orgin`. That misspelling persists through later phases.

![GitHub issue 1 created](../images/phase-01-issue-one-created.png)

Proves the work was described as issue `#1` before implementation started.

![Feature branch created from the issue number](../images/phase-01-feature-branch-created.png)

Proves branch `1-bootstrap-terraform` links the branch name back to the issue.

## Terraform bootstrap

Three files were added: version constraints, the provider block, and the generated lock file.

![Terraform and AzureRM version constraints](../images/phase-01-terraform-version-constraints.png)

Proves Terraform is pinned to `>= 1.6.0, < 2.0.0` and AzureRM to `~> 4.0`.

![Azure provider configuration](../images/phase-01-azure-provider-config.png)

Proves `providers.tf` holds only the `azurerm` block with an empty `features {}`, and no credentials.

The subscription ID stays out of code entirely.

![Azure subscription supplied through the environment](../images/phase-01-subscription-env-var.png)

Proves the ID was exported into the shell and confirmed with a non-empty test rather than printed.

![Successful Terraform initialization](../images/phase-01-terraform-init.png)

Proves `terraform init` installed AzureRM `v4.81.0` and created the lock file, with no Azure resources created.

![Terraform configuration validated](../images/phase-01-terraform-validate.png)

Proves `terraform validate` passed before any commit or review.

![Provider version recorded in the lock file](../images/phase-01-provider-lock-file.png)

Proves the lock file records the resolved `4.81.0` against the `~> 4.0` constraint.

## Review and merge

![Staged Terraform configuration review](../images/phase-01-staged-terraform-diff.png)

Proves the exact configuration content was reviewed as a staged diff before committing.

![Terraform bootstrap commit](../images/phase-01-bootstrap-commit.png)

Proves commit `c015840` contained exactly three files.

![Feature branch pushed to GitHub](../images/phase-01-feature-branch-pushed.png)

Proves the branch was pushed and tracked without touching `main`.

![Pull request ready to merge](../images/phase-01-pull-request-ready-to-merge.png)

Proves PR `#2` targeted `main`, changed 3 files, and reported no conflicts.

![Local main fast-forwarded after the merge](../images/phase-01-main-fast-forward.png)

Proves `git pull --ff-only` brought the merged files onto local `main` with no merge commit.

![Feature branch deletion warning after a squash merge](../images/phase-01-branch-delete-squash-warning.png)

Proves Git warned the branch commit was not an ancestor of `HEAD`, the expected result of a squash merge.

![Clean main branch and final history](../images/phase-01-final-history.png)

Proves `main` ended clean with the squashed commit on top of the initial commit.
