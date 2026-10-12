# `ar_activity`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `pid` | `int(11)` | no |  |  |  |
| `encounter` | `int(11)` | no |  |  |  |
| `sequence_no` | `int(10) unsigned` | no |  |  | Ar_activity sequence_no, incremented in code |
| `code_type` | `varchar(12)` | no | `''` |  |  |
| `code` | `varchar(20)` | no |  |  | empty means claim level |
| `modifier` | `varchar(12)` | no | `''` |  |  |
| `payer_type` | `int(11)` | no |  |  | 0=pt, 1=ins1, 2=ins2, etc |
| `post_time` | `datetime` | no |  |  |  |
| `post_user` | `int(11)` | no |  |  | references users.id |
| `session_id` | `int(10) unsigned` | no |  |  | references ar_session.session_id |
| `memo` | `varchar(255)` | no | `''` |  | adjustment reasons go here |
| `pay_amount` | `decimal(12,2)` | no | `0.00` |  | either pay or adj will always be 0 |
| `adj_amount` | `decimal(12,2)` | no | `0.00` |  |  |
| `modified_time` | `datetime` | no |  |  |  |
| `follow_up` | `char(1)` | no |  |  |  |
| `follow_up_note` | `text` | yes | `NULL` |  |  |
| `account_code` | `varchar(15)` | no |  |  |  |
| `reason_code` | `varchar(255)` | yes | `NULL` |  | Use as needed to show the primary payer adjustment reason code |
| `deleted` | `datetime` | yes | `NULL` |  | NULL if active, otherwise when voided |
| `post_date` | `date` | yes | `NULL` |  | Posting date if specified at payment time |
| `payer_claim_number` | `varchar(30)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `pid`, `encounter`, `sequence_no` |
| `session_id` |  | `session_id` |

## Changes since 7.0.0

- **7.0.1:** added `payer_claim_number` varchar(30)

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
