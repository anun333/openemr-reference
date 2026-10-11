# `form_eye_vitals`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  |  | Links to forms.form_id |
| `pid` | `bigint(20)` | yes | `NULL` |  |  |
| `alert` | `char(3)` | yes | `'yes'` |  |  |
| `oriented` | `char(3)` | yes | `'TPP'` |  |  |
| `confused` | `char(3)` | yes | `'nml'` |  |  |
| `ODIOPAP` | `varchar(10)` | yes | `NULL` |  |  |
| `OSIOPAP` | `varchar(10)` | yes | `NULL` |  |  |
| `ODIOPTPN` | `varchar(10)` | yes | `NULL` |  |  |
| `OSIOPTPN` | `varchar(10)` | yes | `NULL` |  |  |
| `ODIOPFTN` | `varchar(10)` | yes | `NULL` |  |  |
| `OSIOPFTN` | `varchar(10)` | yes | `NULL` |  |  |
| `IOPTIME` | `time` | no |  |  |  |
| `ODIOPPOST` | `varchar(10)` | no |  |  |  |
| `OSIOPPOST` | `varchar(10)` | no |  |  |  |
| `IOPPOSTTIME` | `time` | yes | `NULL` |  |  |
| `ODIOPTARGET` | `varchar(10)` | no |  |  |  |
| `OSIOPTARGET` | `varchar(10)` | no |  |  |  |
| `AMSLEROD` | `smallint(1)` | yes | `NULL` |  |  |
| `AMSLEROS` | `smallint(1)` | yes | `NULL` |  |  |
| `ODVF1` | `tinyint(1)` | yes | `NULL` |  |  |
| `ODVF2` | `tinyint(1)` | yes | `NULL` |  |  |
| `ODVF3` | `tinyint(1)` | yes | `NULL` |  |  |
| `ODVF4` | `tinyint(1)` | yes | `NULL` |  |  |
| `OSVF1` | `tinyint(1)` | yes | `NULL` |  |  |
| `OSVF2` | `tinyint(1)` | yes | `NULL` |  |  |
| `OSVF3` | `tinyint(1)` | yes | `NULL` |  |  |
| `OSVF4` | `tinyint(1)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `id_pid` | yes | `id`, `pid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
