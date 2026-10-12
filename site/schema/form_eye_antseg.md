# `form_eye_antseg`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  |  | Links to forms.form_id |
| `pid` | `bigint(20)` | yes | `NULL` |  |  |
| `ODSCHIRMER1` | `varchar(25)` | yes | `NULL` |  |  |
| `OSSCHIRMER1` | `varchar(25)` | yes | `NULL` |  |  |
| `ODSCHIRMER2` | `varchar(25)` | yes | `NULL` |  |  |
| `OSSCHIRMER2` | `varchar(25)` | yes | `NULL` |  |  |
| `ODTBUT` | `varchar(25)` | yes | `NULL` |  |  |
| `OSTBUT` | `varchar(25)` | yes | `NULL` |  |  |
| `OSCONJ` | `text` | yes | `NULL` |  |  |
| `ODCONJ` | `text` | yes | `NULL` |  |  |
| `ODCORNEA` | `text` | yes | `NULL` |  |  |
| `OSCORNEA` | `text` | yes | `NULL` |  |  |
| `ODAC` | `text` | yes | `NULL` |  |  |
| `OSAC` | `text` | yes | `NULL` |  |  |
| `ODLENS` | `text` | yes | `NULL` |  |  |
| `OSLENS` | `text` | yes | `NULL` |  |  |
| `ODIRIS` | `text` | yes | `NULL` |  |  |
| `OSIRIS` | `text` | yes | `NULL` |  |  |
| `PUPIL_NORMAL` | `varchar(2)` | yes | `'1'` |  |  |
| `ODPUPILSIZE1` | `varchar(25)` | yes | `NULL` |  |  |
| `ODPUPILSIZE2` | `varchar(25)` | yes | `NULL` |  |  |
| `ODPUPILREACTIVITY` | `char(25)` | yes | `NULL` |  |  |
| `ODAPD` | `varchar(25)` | yes | `NULL` |  |  |
| `OSPUPILSIZE1` | `varchar(25)` | yes | `NULL` |  |  |
| `OSPUPILSIZE2` | `varchar(25)` | yes | `NULL` |  |  |
| `OSPUPILREACTIVITY` | `char(25)` | yes | `NULL` |  |  |
| `OSAPD` | `varchar(25)` | yes | `NULL` |  |  |
| `DIMODPUPILSIZE1` | `varchar(25)` | yes | `NULL` |  |  |
| `DIMODPUPILSIZE2` | `varchar(25)` | yes | `NULL` |  |  |
| `DIMODPUPILREACTIVITY` | `varchar(25)` | yes | `NULL` |  |  |
| `DIMOSPUPILSIZE1` | `varchar(25)` | yes | `NULL` |  |  |
| `DIMOSPUPILSIZE2` | `varchar(25)` | yes | `NULL` |  |  |
| `DIMOSPUPILREACTIVITY` | `varchar(25)` | yes | `NULL` |  |  |
| `PUPIL_COMMENTS` | `text` | yes | `NULL` |  |  |
| `ODKTHICKNESS` | `varchar(25)` | yes | `NULL` |  |  |
| `OSKTHICKNESS` | `varchar(25)` | yes | `NULL` |  |  |
| `ODGONIO` | `varchar(25)` | yes | `NULL` |  |  |
| `OSGONIO` | `varchar(25)` | yes | `NULL` |  |  |
| `ANTSEG_COMMENTS` | `text` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `id_pid` | yes | `id`, `pid` |

## Changes since 7.0.0

- **8.1.0:** `OSCONJ` type varchar(25) → text

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
