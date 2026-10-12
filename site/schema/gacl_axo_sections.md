# `gacl_axo_sections`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no | `0` |  |  |
| `value` | `varchar(150)` | no |  |  |  |
| `order_value` | `int(11)` | no | `0` |  |  |
| `name` | `varchar(230)` | no |  |  |  |
| `hidden` | `int(11)` | no | `0` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `gacl_hidden_axo_sections` |  | `hidden` |
| `gacl_value_axo_sections` | yes | `value` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
