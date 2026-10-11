# `form_eye_mag_wearing`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no |  | auto_increment |  |
| `ENCOUNTER` | `int(11)` | no |  |  |  |
| `FORM_ID` | `smallint(6)` | no |  |  |  |
| `PID` | `bigint(20)` | no |  |  |  |
| `RX_NUMBER` | `int(11)` | no |  |  |  |
| `ODSPH` | `varchar(10)` | yes | `NULL` |  |  |
| `ODCYL` | `varchar(10)` | yes | `NULL` |  |  |
| `ODAXIS` | `varchar(10)` | yes | `NULL` |  |  |
| `OSSPH` | `varchar(10)` | yes | `NULL` |  |  |
| `OSCYL` | `varchar(10)` | yes | `NULL` |  |  |
| `OSAXIS` | `varchar(10)` | yes | `NULL` |  |  |
| `ODMIDADD` | `varchar(10)` | yes | `NULL` |  |  |
| `OSMIDADD` | `varchar(10)` | yes | `NULL` |  |  |
| `ODADD` | `varchar(10)` | yes | `NULL` |  |  |
| `OSADD` | `varchar(10)` | yes | `NULL` |  |  |
| `ODVA` | `varchar(10)` | yes | `NULL` |  |  |
| `OSVA` | `varchar(10)` | yes | `NULL` |  |  |
| `ODNEARVA` | `varchar(10)` | yes | `NULL` |  |  |
| `OSNEARVA` | `varchar(10)` | yes | `NULL` |  |  |
| `ODHPD` | `varchar(20)` | yes | `NULL` |  |  |
| `ODHBASE` | `varchar(20)` | yes | `NULL` |  |  |
| `ODVPD` | `varchar(20)` | yes | `NULL` |  |  |
| `ODVBASE` | `varchar(20)` | yes | `NULL` |  |  |
| `ODSLABOFF` | `varchar(20)` | yes | `NULL` |  |  |
| `ODVERTEXDIST` | `varchar(20)` | yes | `NULL` |  |  |
| `OSHPD` | `varchar(20)` | yes | `NULL` |  |  |
| `OSHBASE` | `varchar(20)` | yes | `NULL` |  |  |
| `OSVPD` | `varchar(20)` | yes | `NULL` |  |  |
| `OSVBASE` | `varchar(20)` | yes | `NULL` |  |  |
| `OSSLABOFF` | `varchar(20)` | yes | `NULL` |  |  |
| `OSVERTEXDIST` | `varchar(20)` | yes | `NULL` |  |  |
| `ODMPDD` | `varchar(20)` | yes | `NULL` |  |  |
| `ODMPDN` | `varchar(20)` | yes | `NULL` |  |  |
| `OSMPDD` | `varchar(20)` | yes | `NULL` |  |  |
| `OSMPDN` | `varchar(20)` | yes | `NULL` |  |  |
| `BPDD` | `varchar(20)` | yes | `NULL` |  |  |
| `BPDN` | `varchar(20)` | yes | `NULL` |  |  |
| `LENS_MATERIAL` | `varchar(20)` | yes | `NULL` |  |  |
| `LENS_TREATMENTS` | `varchar(100)` | yes | `NULL` |  |  |
| `RX_TYPE` | `varchar(25)` | yes | `NULL` |  |  |
| `COMMENTS` | `text` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `FORM_ID` | yes | `FORM_ID`, `ENCOUNTER`, `PID`, `RX_NUMBER` |
| `id` | yes | `id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
