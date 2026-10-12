# `procedure_result`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `procedure_result_id` | `bigint(20)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `procedure_report_id` | `bigint(20)` | no |  |  | references procedure_report.procedure_report_id |
| `result_data_type` | `char(1)` | no | `'S'` |  | N=Numeric, S=String, F=Formatted, E=External, L=Long text as first line of comments |
| `result_code` | `varchar(31)` | no | `''` |  | LOINC code, might match a procedure_type.procedure_code |
| `result_text` | `varchar(255)` | no | `''` |  | Description of result_code |
| `date` | `datetime` | yes | `NULL` |  | lab-provided date specific to this result |
| `facility` | `varchar(255)` | no | `''` |  | lab-provided testing facility ID |
| `units` | `varchar(31)` | no | `''` |  |  |
| `result` | `varchar(255)` | no | `''` |  |  |
| `range` | `varchar(255)` | no | `''` |  |  |
| `abnormal` | `varchar(31)` | no | `''` |  | no,yes,high,low |
| `comments` | `text` | yes | `NULL` |  | comments from the lab |
| `document_id` | `bigint(20)` | no | `0` |  | references documents.id if this result is a document |
| `result_status` | `varchar(31)` | no | `''` |  | preliminary, cannot be done, final, corrected, incomplete...etc. |
| `date_end` | `datetime` | yes | `NULL` |  | lab-provided end date specific to this result |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `procedure_result_id` |
| `procedure_report_id` |  | `procedure_report_id` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
