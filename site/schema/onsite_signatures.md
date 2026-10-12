# `onsite_signatures`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `status` | `varchar(128)` | no | `'waiting'` |  |  |
| `type` | `varchar(128)` | no |  |  |  |
| `created` | `int(11)` | no |  |  |  |
| `lastmod` | `datetime` | no |  |  |  |
| `pid` | `bigint(20)` | yes | `NULL` |  |  |
| `encounter` | `int(11)` | yes | `NULL` |  |  |
| `user` | `varchar(255)` | yes | `NULL` |  |  |
| `activity` | `tinyint(4)` | no | `0` |  |  |
| `authorized` | `tinyint(4)` | yes | `NULL` |  |  |
| `signator` | `varchar(255)` | no |  |  |  |
| `sig_image` | `text` | yes | `NULL` |  |  |
| `signature` | `text` | yes | `NULL` |  |  |
| `sig_hash` | `varchar(255)` | no |  |  |  |
| `ip` | `varchar(46)` | no |  |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `encounter` |  | `encounter` |
| `pid` | yes | `pid`, `user` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
