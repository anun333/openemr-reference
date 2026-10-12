# `automatic_notification`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `notification_id` | `int(5)` | no |  | auto_increment |  |
| `sms_gateway_type` | `varchar(255)` | no |  |  |  |
| `provider_name` | `varchar(100)` | no |  |  |  |
| `message` | `text` | yes | `NULL` |  |  |
| `email_sender` | `varchar(100)` | no |  |  |  |
| `email_subject` | `varchar(100)` | no |  |  |  |
| `type` | `enum('SMS','Email')` | no | `'SMS'` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `notification_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
