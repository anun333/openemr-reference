# `module_acl_sections`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `section_id` | `int(11)` | yes | `NULL` |  |  |
| `section_name` | `varchar(255)` | yes | `NULL` |  |  |
| `parent_section` | `int(11)` | yes | `NULL` |  |  |
| `section_identifier` | `varchar(50)` | yes | `NULL` |  |  |
| `module_id` | `int(11)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
