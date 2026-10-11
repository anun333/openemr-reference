# `background_services`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `name` | `varchar(31)` | no |  |  |  |
| `title` | `varchar(127)` | no |  |  | name for reports |
| `active` | `tinyint(1)` | no | `0` |  |  |
| `running` | `tinyint(1)` | no | `-1` |  | True indicates managed service is busy. Skip this interval |
| `next_run` | `timestamp` | no | `current_timestamp()` |  |  |
| `execute_interval` | `int(11)` | no | `0` |  | minimum number of minutes between function calls,0=manual mode |
| `function` | `varchar(127)` | no |  |  | name of background service function |
| `require_once` | `varchar(255)` | yes | `NULL` |  | include file (if necessary) |
| `sort_order` | `int(11)` | no | `100` |  | lower numbers will be run first |
| `lock_expires_at` | `datetime` | yes | `NULL` |  | Lease expiration. Compared with NOW() on acquire, so the stored value uses whatever session timezone is in effect (OpenEMR syncs it to gbl_time_zone). Set on acquire, cleared on release. Expired leases are automatically stolen by the next worker. |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `name` |

## Changes since 7.0.0

- **8.1.0:** added `lock_expires_at` datetime

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
