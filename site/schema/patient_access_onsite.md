# `patient_access_onsite`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no |  | auto_increment |  |
| `pid` | `bigint(20)` | yes | `NULL` |  |  |
| `portal_username` | `varchar(100)` | yes | `NULL` |  |  |
| `portal_pwd` | `varchar(255)` | yes | `NULL` |  |  |
| `portal_pwd_status` | `tinyint(4)` | yes | `1` |  | 0=>Password Created Through Demographics by The provider or staff. Patient Should Change it at first time it.1=>Pwd updated or created by patient itself |
| `portal_login_username` | `varchar(100)` | yes | `NULL` |  | User entered username |
| `portal_onetime` | `varchar(255)` | yes | `NULL` |  |  |
| `date_created` | `datetime` | no | `current_timestamp()` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `pid` | yes | `pid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
