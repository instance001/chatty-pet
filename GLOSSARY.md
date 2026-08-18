# Glossary (Repo Excerpt)

For the full glossary, see: https://github.com/instance001/Whatisthisgithub/blob/main/GLOSSARY.md

This file contains only the glossary entries for this repository. Mapping tag legends and global notes live in the full glossary.

## chatty-pet
| Term | Alternate term(s) | Alt map | External map | Relation to existing terminology | What it is | What it is not | Source |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Chatty-Pet | chatty-pet | = | ~ | Local-first consumer-facing pet / care toy | Local-first Flutter pet care toy where the terrarium state, interactions, and support surfaces run without accounts, ads, or cloud dependence | Not a live-service pet game; not an ad-driven mobile app; not a cloud account product | chatty-pet/README.md |
| Reducer owns truth | reducer-owned truth | ~ | ~ | Deterministic state-governance rule | Rule that the reducer is the authority on lasting state changes and the UI renders already-confirmed truth | Not widget-led truth; not freeform UI mutation | chatty-pet/README.md |
| Templates define possibility | template-defined possibility | ~ | ~ | Explicit content-boundary rule | Rule that items, actions, and toy affordances come from explicit templates rather than ad hoc runtime invention | Not unbounded generation; not hidden content spawning | chatty-pet/README.md |
| Support surfaces | help/privacy/about surfaces | ~ | ~ | Embedded user-support layer | In-app `Help`, `Privacy`, and `About` pages that explain what the toy is and how it behaves | Not a remote help center; not a mandatory account portal | chatty-pet/README.md |
| RD Engine doctrine | RD Engine architectural lineage | ~ | ~ | Downstream doctrine / architectural lineage | The broader reducer-governed architectural doctrine this app follows, even though the implementation here is Flutter rather than the Rust `rd-engine` crate | Not a claim that the app literally uses the `rd-engine` crate; not generic mobile MVC language | chatty-pet/README.md |
| Local-first care toy | care toy | ~ | ~ | Self-contained play surface | Small self-contained pet app that keeps play and save data on-device without accounts, ads, or cloud dependency | Not a multiplayer service; not a monetized progression loop | chatty-pet/README.md |
