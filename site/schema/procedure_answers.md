# `procedure_answers`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `procedure_order_id` | `bigint(20)` | no | `0` |  | references procedure_order.procedure_order_id |
| `procedure_order_seq` | `int(11)` | no | `0` |  | references procedure_order_code.procedure_order_seq |
| `question_code` | `varchar(31)` | no | `''` |  | references procedure_questions.question_code |
| `answer_seq` | `int(11)` | no |  |  | supports multiple-choice questions. answer_seq, incremented in code |
| `answer` | `varchar(255)` | no | `''` |  | answer data |
| `procedure_code` | `varchar(31)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `procedure_order_id`, `procedure_order_seq`, `question_code`, `answer_seq` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
