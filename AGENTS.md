# Repository Instructions

## Graphify

- At session start, identify this repository from its Git origin remote
  and check its Graphify index availability.
- Use Graphify for code discovery and dependency analysis when the index
  is available. Otherwise, continue using the local repository.
- Indexed results may omit local changes and commits made since indexing.
  Verify relevant results against current local files before editing.

## Consumable databases

- Current supported targets are Forever, Classic Era, TBC, Wrath, Cataclysm,
  and MoP Classic; prioritize Forever first.
- Retail source and runtime preparation is back in scope at the user's request.
  Keep it staged: do not add a Retail TOC declaration or activate its dataset
  as part of preparation. Default collection still targets the six clients above.
- Generate separate datasets for Forever, Classic Era, TBC, Wrath, Cataclysm,
  MoP Classic, and Retail. Never reuse another client's values silently.
- Rebuild the existing hand-maintained data from version-specific sources too.
  Keep source provenance and report differences, missing records, and effects
  that cannot be parsed reliably.
- Preserve working addon behavior while database imports are incomplete.
  A client interface declaration or a successful data build does not prove
  in-game compatibility.
