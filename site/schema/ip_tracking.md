# `ip_tracking`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `ip_string` | `varchar(255)` | yes | `''` |  |  |
| `total_ip_login_fail_counter` | `bigint(20)` | yes | `0` |  |  |
| `ip_login_fail_counter` | `bigint(20)` | yes | `0` |  |  |
| `ip_last_login_fail` | `datetime` | yes | `NULL` |  |  |
| `ip_auto_block_emailed` | `tinyint(4)` | yes | `0` |  |  |
| `ip_force_block` | `tinyint(4)` | yes | `0` |  |  |
| `ip_no_prevent_timing_attack` | `tinyint(4)` | yes | `0` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `ip_string` | yes | `ip_string` |

## Changes since 7.0.0

- **7.0.2:** table added

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
