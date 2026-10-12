# `version`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `v_major` | `int(11)` | no | `0` |  |  |
| `v_minor` | `int(11)` | no | `0` |  |  |
| `v_patch` | `int(11)` | no | `0` |  |  |
| `v_realpatch` | `int(11)` | no | `0` |  |  |
| `v_tag` | `varchar(31)` | no | `''` |  |  |
| `v_database` | `int(11)` | no | `0` |  |  |
| `v_acl` | `int(11)` | no | `0` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
