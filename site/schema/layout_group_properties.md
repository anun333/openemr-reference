# `layout_group_properties`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `grp_form_id` | `varchar(31)` | no |  |  |  |
| `grp_group_id` | `varchar(31)` | no | `''` |  | empty when representing the whole form |
| `grp_title` | `varchar(63)` | no | `''` |  | descriptive name of the form or group |
| `grp_subtitle` | `varchar(63)` | no | `''` |  | for display under the title |
| `grp_mapping` | `varchar(31)` | no | `''` |  | the form category |
| `grp_seq` | `int(11)` | no | `0` |  | optional order within mapping |
| `grp_activity` | `tinyint(1)` | no | `1` |  |  |
| `grp_repeats` | `int(11)` | no | `0` |  |  |
| `grp_columns` | `int(11)` | no | `0` |  |  |
| `grp_size` | `int(11)` | no | `0` |  |  |
| `grp_issue_type` | `varchar(75)` | no | `''` |  |  |
| `grp_aco_spec` | `varchar(63)` | no | `''` |  |  |
| `grp_save_close` | `tinyint(1)` | no | `0` |  |  |
| `grp_init_open` | `tinyint(1)` | no | `0` |  |  |
| `grp_referrals` | `tinyint(1)` | no | `0` |  |  |
| `grp_unchecked` | `tinyint(1)` | no | `0` |  |  |
| `grp_services` | `varchar(4095)` | no | `''` |  |  |
| `grp_products` | `varchar(4095)` | no | `''` |  |  |
| `grp_diags` | `varchar(4095)` | no | `''` |  |  |
| `grp_last_update` | `timestamp` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `grp_form_id`, `grp_group_id` |

## Changes since 7.0.0

- **7.0.1:** added `grp_unchecked` tinyint(1)

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
