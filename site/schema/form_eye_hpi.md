# `form_eye_hpi`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  |  | Links to forms.form_id |
| `pid` | `bigint(20)` | yes | `NULL` |  |  |
| `CC1` | `varchar(255)` | yes | `NULL` |  |  |
| `HPI1` | `text` | yes | `NULL` |  |  |
| `QUALITY1` | `varchar(255)` | yes | `NULL` |  |  |
| `TIMING1` | `varchar(255)` | yes | `NULL` |  |  |
| `DURATION1` | `varchar(255)` | yes | `NULL` |  |  |
| `CONTEXT1` | `varchar(255)` | yes | `NULL` |  |  |
| `SEVERITY1` | `varchar(255)` | yes | `NULL` |  |  |
| `MODIFY1` | `varchar(255)` | yes | `NULL` |  |  |
| `ASSOCIATED1` | `varchar(255)` | yes | `NULL` |  |  |
| `LOCATION1` | `varchar(255)` | yes | `NULL` |  |  |
| `CHRONIC1` | `varchar(255)` | yes | `NULL` |  |  |
| `CHRONIC2` | `varchar(255)` | yes | `NULL` |  |  |
| `CHRONIC3` | `varchar(255)` | yes | `NULL` |  |  |
| `CC2` | `text` | yes | `NULL` |  |  |
| `HPI2` | `text` | yes | `NULL` |  |  |
| `QUALITY2` | `text` | yes | `NULL` |  |  |
| `TIMING2` | `text` | yes | `NULL` |  |  |
| `DURATION2` | `text` | yes | `NULL` |  |  |
| `CONTEXT2` | `text` | yes | `NULL` |  |  |
| `SEVERITY2` | `text` | yes | `NULL` |  |  |
| `MODIFY2` | `text` | yes | `NULL` |  |  |
| `ASSOCIATED2` | `text` | yes | `NULL` |  |  |
| `LOCATION2` | `text` | yes | `NULL` |  |  |
| `CC3` | `text` | yes | `NULL` |  |  |
| `HPI3` | `text` | yes | `NULL` |  |  |
| `QUALITY3` | `text` | yes | `NULL` |  |  |
| `TIMING3` | `text` | yes | `NULL` |  |  |
| `DURATION3` | `text` | yes | `NULL` |  |  |
| `CONTEXT3` | `text` | yes | `NULL` |  |  |
| `SEVERITY3` | `text` | yes | `NULL` |  |  |
| `MODIFY3` | `text` | yes | `NULL` |  |  |
| `ASSOCIATED3` | `text` | yes | `NULL` |  |  |
| `LOCATION3` | `text` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `id_pid` | yes | `id`, `pid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
