# Repository Instructions

## Graphify

- At session start, identify this repository from its Git origin remote
  and check its Graphify index availability.
- Use Graphify for code discovery and dependency analysis when the index
  is available. Otherwise, continue using the local repository.
- Indexed results may omit local changes and commits made since indexing.
  Verify relevant results against current local files before editing.

## Consumable databases

- Version 2.0.0 supports Forever, Classic Era, TBC, Wrath, Cataclysm,
  MoP Classic, and Retail; prioritize Forever first.
- Retail is declared in the TOC and uses its own published dataset. Retain
  runtime-dependent source metadata and never replace it with another client's
  fixed amounts.
- Generate separate datasets for Forever, Classic Era, TBC, Wrath, Cataclysm,
  MoP Classic, and Retail. Never reuse another client's values silently.
- Rebuild the existing hand-maintained data from version-specific sources too.
  Keep source provenance and report differences, missing records, and effects
  that cannot be parsed reliably.
- Preserve working addon behavior while database imports are incomplete.
  A client interface declaration or a successful data build does not prove
  in-game compatibility.
