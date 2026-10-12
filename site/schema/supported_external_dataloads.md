# `supported_external_dataloads`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `load_id` | `bigint(20) unsigned` | no |  | auto_increment |  |
| `load_type` | `varchar(24)` | no | `''` |  |  |
| `load_source` | `varchar(24)` | no | `'CMS'` |  |  |
| `load_release_date` | `date` | no |  |  |  |
| `load_filename` | `varchar(256)` | no | `''` |  |  |
| `load_checksum` | `varchar(32)` | no | `''` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `load_id` | yes | `load_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
