# `code_types`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `ct_key` | `varchar(15)` | no |  |  | short alphanumeric name |
| `ct_id` | `int(11)` | no |  |  | numeric identifier |
| `ct_seq` | `int(11)` | no | `0` |  | sort order |
| `ct_mod` | `int(11)` | no | `0` |  | length of modifier field |
| `ct_just` | `varchar(15)` | no | `''` |  | ct_key of justify type, if any |
| `ct_mask` | `varchar(9)` | no | `''` |  | formatting mask for code values |
| `ct_fee` | `tinyint(1)` | no | `0` |  | 1 if fees are used |
| `ct_rel` | `tinyint(1)` | no | `0` |  | 1 if can relate to other code types |
| `ct_nofs` | `tinyint(1)` | no | `0` |  | 1 if to be hidden in the fee sheet |
| `ct_diag` | `tinyint(1)` | no | `0` |  | 1 if this is a diagnosis type |
| `ct_active` | `tinyint(1)` | no | `1` |  | 1 if this is active |
| `ct_label` | `varchar(31)` | no | `''` |  | label of this code type |
| `ct_external` | `tinyint(1)` | no | `0` |  | 0 if stored codes in codes tables, 1 or greater if codes stored in external tables |
| `ct_claim` | `tinyint(1)` | no | `0` |  | 1 if this is used in claims |
| `ct_proc` | `tinyint(1)` | no | `0` |  | 1 if this is a procedure type |
| `ct_term` | `tinyint(1)` | no | `0` |  | 1 if this is a clinical term |
| `ct_problem` | `tinyint(1)` | no | `0` |  | 1 if this code type is used as a medical problem |
| `ct_drug` | `tinyint(1)` | no | `0` |  | 1 if this code type is used as a medication |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `ct_key` |
| `ct_id` | yes | `ct_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
