# `notification_settings`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `SettingsId` | `int(3)` | no |  | auto_increment |  |
| `Send_SMS_Before_Hours` | `int(3)` | no |  |  |  |
| `Send_Email_Before_Hours` | `int(3)` | no |  |  |  |
| `SMS_gateway_username` | `varchar(100)` | no |  |  |  |
| `SMS_gateway_password` | `varchar(100)` | no |  |  |  |
| `SMS_gateway_apikey` | `varchar(100)` | no |  |  |  |
| `type` | `varchar(50)` | no |  |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `SettingsId` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
