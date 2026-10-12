# `procedure_type`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `procedure_type_id` | `bigint(20)` | no |  | auto_increment |  |
| `parent` | `bigint(20)` | no | `0` |  | references procedure_type.procedure_type_id |
| `name` | `varchar(63)` | no | `''` |  | name for this category, procedure or result type |
| `lab_id` | `bigint(20)` | no | `0` |  | references procedure_providers.ppid, 0 means default to parent |
| `procedure_code` | `varchar(64)` | no | `''` |  | code identifying this procedure |
| `procedure_type` | `varchar(31)` | no | `''` |  | see list proc_type |
| `body_site` | `varchar(31)` | no | `''` |  | where to do injection, e.g. arm, buttock |
| `specimen` | `varchar(31)` | no | `''` |  | blood, urine, saliva, etc. |
| `route_admin` | `varchar(31)` | no | `''` |  | oral, injection |
| `laterality` | `varchar(31)` | no | `''` |  | left, right, ... |
| `description` | `varchar(255)` | no | `''` |  | descriptive text for procedure_code |
| `standard_code` | `varchar(255)` | no | `''` |  | industry standard code type and code (e.g. CPT4:12345) |
| `related_code` | `varchar(255)` | no | `''` |  | suggested code(s) for followup services if result is abnormal |
| `units` | `varchar(31)` | no | `''` |  | default for procedure_result.units |
| `range` | `varchar(255)` | no | `''` |  | default for procedure_result.range |
| `seq` | `int(11)` | no | `0` |  | sequence number for ordering |
| `activity` | `tinyint(1)` | no | `1` |  | 1=active, 0=inactive |
| `notes` | `varchar(255)` | no | `''` |  | additional notes to enhance description |
| `transport` | `varchar(31)` | yes | `NULL` |  |  |
| `procedure_type_name` | `varchar(64)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `procedure_type_id` |
| `parent` |  | `parent` |
| `ptype_procedure_code` |  | `procedure_code` |

## Changes since 7.0.0

None.

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
