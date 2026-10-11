# `dated_reminders_link`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `dr_link_id` | `int(11)` | no |  | auto_increment |  |
| `dr_id` | `int(11)` | no |  |  |  |
| `to_id` | `int(11)` | no |  |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `dr_link_id` |
| `dr_id` |  | `dr_id` |
| `to_id` |  | `to_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
