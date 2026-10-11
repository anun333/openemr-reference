# `chart_tracker`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `ct_pid` | `int(11)` | no |  |  |  |
| `ct_when` | `datetime` | no |  |  |  |
| `ct_userid` | `bigint(20)` | no | `0` |  |  |
| `ct_location` | `varchar(31)` | no | `''` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `ct_pid`, `ct_when` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
