# `procedure_questions`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `lab_id` | `bigint(20)` | no | `0` |  | references procedure_providers.ppid to identify the lab |
| `procedure_code` | `varchar(31)` | no | `''` |  | references procedure_type.procedure_code to identify this order type |
| `question_code` | `varchar(31)` | no | `''` |  | code identifying this question |
| `seq` | `int(11)` | no | `0` |  | sequence number for ordering |
| `question_text` | `varchar(255)` | no | `''` |  | descriptive text for question_code |
| `required` | `tinyint(1)` | no | `0` |  | 1 = required, 0 = not |
| `maxsize` | `int(11)` | no | `0` |  | maximum length if text input field |
| `fldtype` | `char(1)` | no | `'T'` |  | Text, Number, Select, Multiselect, Date, Gestational-age |
| `options` | `text` | yes | `NULL` |  | choices for fldtype S and T |
| `tips` | `varchar(255)` | no | `''` |  | Additional instructions for answering the question |
| `activity` | `tinyint(1)` | no | `1` |  | 1 = active, 0 = inactive |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `lab_id`, `procedure_code`, `question_code` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
