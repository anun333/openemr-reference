# `external_encounters`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `ee_id` | `int(11)` | no |  | auto_increment |  |
| `ee_date` | `date` | yes | `NULL` |  |  |
| `ee_pid` | `int(11)` | yes | `NULL` |  |  |
| `ee_provider_id` | `varchar(255)` | yes | `NULL` |  |  |
| `ee_facility_id` | `varchar(255)` | yes | `NULL` |  |  |
| `ee_encounter_diagnosis` | `varchar(255)` | yes | `NULL` |  |  |
| `ee_external_id` | `varchar(255)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `ee_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
