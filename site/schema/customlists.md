# `customlists`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `cl_list_slno` | `int(10) unsigned` | no |  | auto_increment |  |
| `cl_list_id` | `int(10) unsigned` | no |  |  | ID OF THE lIST FOR NEW TAKE SELECT MAX(cl_list_id)+1 |
| `cl_list_item_id` | `int(10) unsigned` | yes | `NULL` |  | ID OF THE lIST FOR NEW TAKE SELECT MAX(cl_list_item_id)+1 |
| `cl_list_type` | `int(10) unsigned` | no |  |  | 0=>List Name 1=>list items 2=>Context 3=>Template 4=>Sentence 5=> SavedTemplate 6=>CustomButton |
| `cl_list_item_short` | `varchar(10)` | yes | `NULL` |  |  |
| `cl_list_item_long` | `text` | yes | `NULL` |  |  |
| `cl_list_item_level` | `int(11)` | yes | `NULL` |  | Flow level for List Designation |
| `cl_order` | `int(11)` | yes | `NULL` |  |  |
| `cl_deleted` | `tinyint(1)` | yes | `0` |  |  |
| `cl_creator` | `int(11)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `cl_list_slno` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
