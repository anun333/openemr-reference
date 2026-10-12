# `form_eye_biometrics`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  |  | Links to forms.form_id |
| `pid` | `bigint(20)` | yes | `NULL` |  |  |
| `ODK1` | `varchar(10)` | yes | `NULL` |  |  |
| `ODK2` | `varchar(10)` | yes | `NULL` |  |  |
| `ODK2AXIS` | `varchar(10)` | yes | `NULL` |  |  |
| `OSK1` | `varchar(10)` | yes | `NULL` |  |  |
| `OSK2` | `varchar(10)` | yes | `NULL` |  |  |
| `OSK2AXIS` | `varchar(10)` | yes | `NULL` |  |  |
| `ODAXIALLENGTH` | `varchar(20)` | yes | `NULL` |  |  |
| `OSAXIALLENGTH` | `varchar(20)` | yes | `NULL` |  |  |
| `ODPDMeasured` | `varchar(20)` | yes | `NULL` |  |  |
| `OSPDMeasured` | `varchar(20)` | yes | `NULL` |  |  |
| `ODACD` | `varchar(20)` | yes | `NULL` |  |  |
| `OSACD` | `varchar(20)` | yes | `NULL` |  |  |
| `ODW2W` | `varchar(20)` | yes | `NULL` |  |  |
| `OSW2W` | `varchar(20)` | yes | `NULL` |  |  |
| `ODLT` | `varchar(20)` | yes | `NULL` |  |  |
| `OSLT` | `varchar(20)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `id_pid` | yes | `id`, `pid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
