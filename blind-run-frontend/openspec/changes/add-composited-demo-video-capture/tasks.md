## 1. Capture Scene Startup

- [x] 1.1 Add explicit startup configuration for demo video capture scenes so the app can boot directly into named volunteer or blind recording checkpoints.
- [x] 1.2 Route each capture scene into the correct existing product screen without showing visible demo or recording controls.

## 2. Story-Aligned Demo Checkpoints

- [x] 2.1 Extend the demo seed/store layer with the volunteer-side and blind-side capture checkpoints needed to cover the planned review narrative.
- [x] 2.2 Align curated place names, addresses, order statuses, and contact visibility across the paired blind and volunteer capture scenes so separately recorded clips can be composed credibly.
- [x] 2.3 Add focused validation for capture-scene bootstrapping and checkpoint data consistency.

## 3. Recording Playbook

- [x] 3.1 Add a repository playbook that defines the required clip list, recording order, expected operator actions, and source file names for the final two-sided review video.
- [x] 3.2 Define the local raw-clip and final-export directory conventions, including the desktop output target and any gitignored working paths.

## 4. Composition And Export Tooling

- [x] 4.1 Implement a local composition utility that reads the expected recorded clips and renders a side-by-side blind-and-volunteer MP4.
- [x] 4.2 Add a small command wrapper or invocation guide for running the composition/export flow on macOS with the repository’s expected clip layout.
- [x] 4.3 Verify the composition flow fails cleanly when clips are missing or incompatible and succeeds with the expected output shape when all inputs are present.

## 5. Final Video Production

- [x] 5.1 Record the blind-side clip set from the defined capture scenes on the target demo environment.
- [x] 5.2 Record the volunteer-side clip set from the defined capture scenes on the target demo environment.
- [x] 5.3 Run the composition/export workflow and save the final review-ready video to the desktop.
- [x] 5.4 Review the exported video for narrative continuity, visual polish, and absence of visible demo-only UI inside the app panes.
