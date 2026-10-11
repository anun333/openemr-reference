# `form_vitals_calculation_form_vitals`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB. Join table between form_vitals_calculation and form_vitals table representing the derivative observation relationship between the calculation and the source records

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `fvc_uuid` | `binary(16)` | no |  |  | fk to form_vitals_calculation.uuid |
| `vitals_id` | `bigint(20)` | no |  |  | fk to form_vitals.id |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `fvc_uuid`, `vitals_id` |

## Changes since 7.0.0

- **7.0.4:** table added

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
