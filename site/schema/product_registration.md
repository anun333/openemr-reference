# `product_registration`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no |  | auto_increment |  |
| `email` | `varchar(255)` | yes | `NULL` |  |  |
| `opt_out` | `tinyint(1)` | yes | `NULL` |  |  |
| `auth_by_id` | `int(11)` | yes | `NULL` |  |  |
| `telemetry_disabled` | `tinyint(1)` | yes | `NULL` |  | 1 opted out, disabled. NULL ask. 0 use option scopes |
| `last_ask_date` | `datetime` | yes | `NULL` |  |  |
| `last_ask_version` | `tinytext` | yes | `NULL` |  |  |
| `options` | `text` | yes | `NULL` |  | JSON array of scope options |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |

## Changes since 7.0.0

- **7.0.4:** added `auth_by_id` int(11); added `telemetry_disabled` tinyint(1); added `last_ask_date` datetime; added `last_ask_version` tinytext; added `options` text

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
