# Player reference

- `reference_person.jpg` — user-supplied reference photograph (compressed for repo size) used as the third-person player face albedo.
- `reference_person.jpg.b64` / `.b64.part1` + `.b64.part2` — same bytes as base64 (text-safe). The player loads the full `.b64` if present, otherwise concatenates the two parts.
- Decode: `cat reference_person.jpg.b64.part1 reference_person.jpg.b64.part2 | base64 -d > reference_person.jpg`
- Likeness / commercial publicity rights for the photographed person remain the **user's responsibility** (see root CREDITS.md / README.md).
