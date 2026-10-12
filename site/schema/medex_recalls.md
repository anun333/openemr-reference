# `medex_recalls`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `r_ID` | `int(11)` | no |  | auto_increment |  |
| `r_PRACTID` | `int(11)` | no |  |  |  |
| `r_pid` | `int(11)` | no |  |  | PatientID from pat_data |
| `r_eventDate` | `date` | no |  |  | Date of Appt or Recall |
| `r_facility` | `int(11)` | no |  |  |  |
| `r_provider` | `int(11)` | no |  |  |  |
| `r_reason` | `varchar(255)` | yes | `NULL` |  |  |
| `r_created` | `timestamp` | no | `current_timestamp()` | on update current_timestamp() |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `r_ID` |
| `r_PRACTID` | yes | `r_PRACTID`, `r_pid` |

## Changes since 7.0.0

- **8.1.0:** `r_created` default '0000-00-00 00:00:00' → current_timestamp()

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
