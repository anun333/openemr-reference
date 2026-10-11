# `form_eye_ros`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  |  | Links to forms.form_id |
| `pid` | `bigint(20)` | yes | `NULL` |  |  |
| `ROSGENERAL` | `text` | yes | `NULL` |  |  |
| `ROSHEENT` | `text` | yes | `NULL` |  |  |
| `ROSCV` | `text` | yes | `NULL` |  |  |
| `ROSPULM` | `text` | yes | `NULL` |  |  |
| `ROSGI` | `text` | yes | `NULL` |  |  |
| `ROSGU` | `text` | yes | `NULL` |  |  |
| `ROSDERM` | `text` | yes | `NULL` |  |  |
| `ROSNEURO` | `text` | yes | `NULL` |  |  |
| `ROSPSYCH` | `text` | yes | `NULL` |  |  |
| `ROSMUSCULO` | `text` | yes | `NULL` |  |  |
| `ROSIMMUNO` | `text` | yes | `NULL` |  |  |
| `ROSENDOCRINE` | `text` | yes | `NULL` |  |  |
| `ROSCOMMENTS` | `text` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `id_pid` | yes | `id`, `pid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
