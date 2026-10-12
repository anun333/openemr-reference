# `notification_log`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `iLogId` | `int(11)` | no |  | auto_increment |  |
| `pid` | `bigint(20)` | no |  |  |  |
| `pc_eid` | `int(11) unsigned` | yes | `NULL` |  |  |
| `sms_gateway_type` | `varchar(50)` | no |  |  |  |
| `smsgateway_info` | `varchar(255)` | no |  |  |  |
| `message` | `text` | yes | `NULL` |  |  |
| `email_sender` | `varchar(255)` | no |  |  |  |
| `email_subject` | `varchar(255)` | no |  |  |  |
| `type` | `enum('SMS','Email')` | no |  |  |  |
| `patient_info` | `text` | yes | `NULL` |  |  |
| `pc_eventDate` | `date` | no |  |  |  |
| `pc_endDate` | `date` | no |  |  |  |
| `pc_startTime` | `time` | no |  |  |  |
| `pc_endTime` | `time` | no |  |  |  |
| `dSentDateTime` | `datetime` | no |  |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `iLogId` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
