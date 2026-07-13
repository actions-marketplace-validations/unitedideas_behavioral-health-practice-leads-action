# GitHub Action repository design review

Reviewed: 2026-07-13  
Source revision: `f76c527093a1babb3bd8090bee378265793589fa`  
Surface: <https://github.com/unitedideas/behavioral-health-practice-leads-action>

## Conversion contract

- Category: developer-tool and lead-generation Action repository.
- Audience: healthcare data teams, billing and credentialing vendors, territory planners, and developers who already automate exports in GitHub Actions.
- Primary conversion: copy the preview workflow, add the buyer's Apify token, then graduate to a cost-capped $9 full-edition run when the sample is useful.
- Conversion-quality metric: non-owner unique repository cloners and Action workflow executions that precede an external paid `weekly-edition` event and successful dataset delivery.

## Evidence and judgment

- Measured evidence: release `v1.0.0` and floating tag `v1` are public; the hosted Test workflow passed; the repository has no external stars, forks, or watchers at review time.
- Standards: the first README paragraph names the current weekly event, the default preview, the full-edition price, the total-charge cap, and the buyer-funded credential boundary before setup detail.
- Observed pattern: Action buyers scan repository description, release activity, copyable workflow, secret requirements, outputs, and failure/cost controls before adoption.
- Hypothesis: an exact weekly healthcare-data job with a copyable preview workflow will attract more qualified developer intent than a generic Actor API example.

## Rendered QA

- Desktop: `design/renders/github-action-desktop.png` at 1440 x 1000.
- Mobile: `design/renders/github-action-mobile.png` at 390 x 844 after viewport reload.
- Desktop exposes the repository job, release, categories, source tree, and README value/price boundary in the first screen.
- Mobile keeps the repository description and Apify destination readable, but GitHub places the file table ahead of the README and renders that table with horizontal overflow. This is controlled by GitHub rather than repository CSS.
- Copy, price, secret handling, cost cap, data limitations, and explicit non-outreach boundary are consistent across the repository metadata and README.

## Findings

- **Open — high:** the repository is usable by exact tag, but GitHub still offers the owner a separate Marketplace publication step. Until that step is completed, Marketplace search discovery is not proven and this surface is not fully launch-approved as a Marketplace listing.
- **Open — low:** GitHub's mobile file table introduces horizontal scrolling before the README. The value proposition remains readable in the repository description, but the copyable workflow is below the first screen.

Any source, metadata, tag, release, or Marketplace-state change after the revision above invalidates this review.
