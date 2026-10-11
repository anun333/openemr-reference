# `registry`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `name` | `varchar(255)` | yes | `NULL` |  |  |
| `state` | `tinyint(4)` | yes | `NULL` |  |  |
| `directory` | `varchar(255)` | yes | `NULL` |  |  |
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `sql_run` | `tinyint(4)` | yes | `NULL` |  |  |
| `unpackaged` | `tinyint(4)` | yes | `NULL` |  |  |
| `date` | `datetime` | yes | `NULL` |  |  |
| `priority` | `int(11)` | yes | `0` |  |  |
| `category` | `varchar(255)` | yes | `NULL` |  |  |
| `nickname` | `varchar(255)` | yes | `NULL` |  |  |
| `patient_encounter` | `tinyint(4)` | no | `1` |  |  |
| `therapy_group_encounter` | `tinyint(4)` | no | `0` |  |  |
| `aco_spec` | `varchar(63)` | no | `'encounters\|notes'` |  |  |
| `form_foreign_id` | `bigint(21)` | yes | `NULL` |  | An id to a form repository. Primarily questionnaire_repository. |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |

## Changes since 7.0.0

- **7.0.1:** added `form_foreign_id` bigint(21)

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
