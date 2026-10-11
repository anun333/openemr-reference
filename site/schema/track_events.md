# `track_events`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB. Telemetry Event Data

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11) unsigned` | no |  | auto_increment |  |
| `event_type` | `text` | yes | `NULL` |  |  |
| `event_label` | `varchar(255)` | yes | `NULL` |  |  |
| `event_url` | `text` | yes | `NULL` |  |  |
| `event_target` | `text` | yes | `NULL` |  |  |
| `first_event` | `datetime` | yes | `NULL` |  |  |
| `last_event` | `datetime` | yes | `NULL` |  |  |
| `label_count` | `int(10) unsigned` | no | `1` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `unique_event_label_target` | yes | `event_label`, `event_url(255)`, `event_target(255)` |

## Changes since 7.0.0

- **7.0.4:** table added

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
