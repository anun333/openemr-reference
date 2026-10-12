# `documents_legal_detail`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `dld_id` | `int(10) unsigned` | no |  | auto_increment |  |
| `dld_pid` | `int(10) unsigned` | yes | `NULL` |  |  |
| `dld_facility` | `int(10) unsigned` | yes | `NULL` |  |  |
| `dld_provider` | `int(10) unsigned` | yes | `NULL` |  |  |
| `dld_encounter` | `int(10) unsigned` | yes | `NULL` |  |  |
| `dld_master_docid` | `int(10) unsigned` | no |  |  |  |
| `dld_signed` | `smallint(5) unsigned` | no |  |  | 0-Not Signed or Cannot Sign(Layout),1-Signed,2-Ready to sign,3-Denied(Pat Regi),4-Patient Upload,10-Save(Layout) |
| `dld_signed_time` | `timestamp` | no | `current_timestamp()` | on update current_timestamp() |  |
| `dld_filepath` | `varchar(75)` | yes | `NULL` |  |  |
| `dld_filename` | `varchar(45)` | no |  |  |  |
| `dld_signing_person` | `varchar(50)` | no |  |  |  |
| `dld_sign_level` | `int(11)` | no |  |  | Sign flow level |
| `dld_content` | `varchar(50)` | no |  |  | Layout sign position |
| `dld_file_for_pdf_generation` | `blob` | no |  |  | The filled details in the fdf file is stored here.Patient Registration Screen |
| `dld_denial_reason` | `longtext` | yes | `NULL` |  |  |
| `dld_moved` | `tinyint(4)` | no | `0` |  |  |
| `dld_patient_comments` | `text` | yes | `NULL` |  | Patient comments stored here |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `dld_id` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
