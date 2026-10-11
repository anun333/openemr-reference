# `modules`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `mod_id` | `int(11)` | no |  | auto_increment |  |
| `mod_name` | `varchar(64)` | no | `'0'` |  |  |
| `mod_directory` | `varchar(64)` | no | `''` |  |  |
| `mod_parent` | `varchar(64)` | no | `''` |  |  |
| `mod_type` | `varchar(64)` | no | `''` |  |  |
| `mod_active` | `int(1) unsigned` | no | `0` |  |  |
| `mod_ui_name` | `varchar(64)` | no | `''` |  |  |
| `mod_relative_link` | `varchar(64)` | no | `''` |  |  |
| `mod_ui_order` | `tinyint(3)` | no | `0` |  |  |
| `mod_ui_active` | `int(1) unsigned` | no | `0` |  |  |
| `mod_description` | `varchar(255)` | no | `''` |  |  |
| `mod_nick_name` | `varchar(25)` | no | `''` |  |  |
| `mod_enc_menu` | `varchar(10)` | no | `'no'` |  |  |
| `permissions_item_table` | `char(100)` | yes | `NULL` |  |  |
| `directory` | `varchar(255)` | no |  |  |  |
| `date` | `datetime` | no |  |  |  |
| `sql_run` | `tinyint(4)` | yes | `0` |  |  |
| `type` | `tinyint(4)` | yes | `0` |  |  |
| `sql_version` | `varchar(150)` | no |  |  |  |
| `acl_version` | `varchar(150)` | no |  |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `mod_id`, `mod_directory` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
