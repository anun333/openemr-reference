# `patient_reminders`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `active` | `tinyint(1)` | no | `1` |  | 1 if active and 0 if not active |
| `date_inactivated` | `datetime` | yes | `NULL` |  |  |
| `reason_inactivated` | `varchar(31)` | no | `''` |  | Maps to list_options list rule_reminder_inactive_opt |
| `due_status` | `varchar(31)` | no | `''` |  | Maps to list_options list rule_reminder_due_opt |
| `pid` | `bigint(20)` | no |  |  | id from patient_data table |
| `category` | `varchar(31)` | no | `''` |  | Maps to the category item in the rule_action_item table |
| `item` | `varchar(31)` | no | `''` |  | Maps to the item column in the rule_action_item table |
| `date_created` | `datetime` | yes | `NULL` |  |  |
| `date_sent` | `datetime` | yes | `NULL` |  |  |
| `voice_status` | `tinyint(1)` | no | `0` |  | 0 if not sent and 1 if sent |
| `sms_status` | `tinyint(1)` | no | `0` |  | 0 if not sent and 1 if sent |
| `email_status` | `tinyint(1)` | no | `0` |  | 0 if not sent and 1 if sent |
| `mail_status` | `tinyint(1)` | no | `0` |  | 0 if not sent and 1 if sent |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `category` |  | `category`, `item` |
| `pid` |  | `pid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
