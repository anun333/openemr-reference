# `forms`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `date` | `datetime` | yes | `NULL` |  |  |
| `encounter` | `bigint(20)` | yes | `NULL` |  |  |
| `form_name` | `longtext` | yes | `NULL` |  |  |
| `form_id` | `bigint(20)` | yes | `NULL` |  |  |
| `pid` | `bigint(20)` | yes | `NULL` |  |  |
| `user` | `varchar(255)` | yes | `NULL` |  |  |
| `groupname` | `varchar(255)` | yes | `NULL` |  |  |
| `authorized` | `tinyint(4)` | yes | `NULL` |  |  |
| `deleted` | `tinyint(4)` | no | `0` |  | flag indicates form has been deleted |
| `formdir` | `longtext` | yes | `NULL` |  |  |
| `therapy_group_id` | `int(11)` | yes | `NULL` |  |  |
| `issue_id` | `bigint(20)` | no | `0` |  | references lists.id to identify a case |
| `provider_id` | `bigint(20)` | no | `0` |  | references users.id to identify a provider |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `form_id` |  | `form_id` |
| `pid_encounter` |  | `pid`, `encounter` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
