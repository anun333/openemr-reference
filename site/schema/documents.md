# `documents`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no | `0` |  |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `type` | `enum('file_url','blob','web_url')` | yes | `NULL` |  |  |
| `size` | `int(11)` | yes | `NULL` |  |  |
| `date` | `datetime` | yes | `NULL` |  |  |
| `date_expires` | `datetime` | yes | `NULL` |  |  |
| `url` | `varchar(255)` | yes | `NULL` |  |  |
| `thumb_url` | `varchar(255)` | yes | `NULL` |  |  |
| `mimetype` | `varchar(255)` | yes | `NULL` |  |  |
| `pages` | `int(11)` | yes | `NULL` |  |  |
| `owner` | `int(11)` | yes | `NULL` |  |  |
| `revision` | `timestamp` | no |  |  |  |
| `foreign_id` | `bigint(20)` | yes | `NULL` |  |  |
| `docdate` | `date` | yes | `NULL` |  |  |
| `hash` | `varchar(255)` | yes | `NULL` |  |  |
| `list_id` | `bigint(20)` | no | `0` |  |  |
| `name` | `varchar(255)` | yes | `NULL` |  |  |
| `drive_uuid` | `binary(16)` | yes | `NULL` |  |  |
| `couch_docid` | `varchar(100)` | yes | `NULL` |  |  |
| `couch_revid` | `varchar(100)` | yes | `NULL` |  |  |
| `storagemethod` | `tinyint(4)` | no | `0` |  | 0->Harddisk,1->CouchDB |
| `path_depth` | `tinyint(4)` | yes | `1` |  | Depth of path to use in url to find document. Not applicable for CouchDB. |
| `imported` | `tinyint(4)` | yes | `0` |  | Parsing status for CCR/CCD/CCDA importing |
| `encounter_id` | `bigint(20)` | no | `0` |  | Encounter id if tagged |
| `encounter_check` | `tinyint(1)` | no | `0` |  | If encounter is created while tagging |
| `audit_master_approval_status` | `tinyint(4)` | no | `1` |  | approval_status from audit_master table |
| `audit_master_id` | `int(11)` | yes | `NULL` |  |  |
| `documentationOf` | `varchar(255)` | yes | `NULL` |  |  |
| `encrypted` | `tinyint(4)` | no | `0` |  | 0->No,1->Yes |
| `document_data` | `mediumtext` | yes | `NULL` |  |  |
| `deleted` | `tinyint(1)` | no | `0` |  |  |
| `foreign_reference_id` | `bigint(20)` | yes | `NULL` |  |  |
| `foreign_reference_table` | `varchar(40)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `drive_uuid` | yes | `drive_uuid` |
| `foreign_id` |  | `foreign_id` |
| `foreign_reference` |  | `foreign_reference_id`, `foreign_reference_table` |
| `owner` |  | `owner` |
| `revision` |  | `revision` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
