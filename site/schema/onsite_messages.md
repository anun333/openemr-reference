# `onsite_messages`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB. Portal messages

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no |  | auto_increment |  |
| `username` | `varchar(64)` | no |  |  |  |
| `message` | `longtext` | yes | `NULL` |  |  |
| `ip` | `varchar(15)` | no |  |  |  |
| `date` | `datetime` | no |  |  |  |
| `sender_id` | `varchar(64)` | yes | `NULL` |  | who sent id |
| `recip_id` | `varchar(255)` | no |  |  | who to id array |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
