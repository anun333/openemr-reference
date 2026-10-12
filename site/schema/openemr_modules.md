# `openemr_modules`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `pn_id` | `int(11) unsigned` | no |  | auto_increment |  |
| `pn_name` | `varchar(64)` | yes | `NULL` |  |  |
| `pn_type` | `int(6)` | no | `0` |  |  |
| `pn_displayname` | `varchar(64)` | yes | `NULL` |  |  |
| `pn_description` | `varchar(255)` | yes | `NULL` |  |  |
| `pn_regid` | `int(11) unsigned` | no | `0` |  |  |
| `pn_directory` | `varchar(64)` | yes | `NULL` |  |  |
| `pn_version` | `varchar(10)` | yes | `NULL` |  |  |
| `pn_admin_capable` | `tinyint(1)` | no | `0` |  |  |
| `pn_user_capable` | `tinyint(1)` | no | `0` |  |  |
| `pn_state` | `tinyint(1)` | no | `0` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `pn_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
