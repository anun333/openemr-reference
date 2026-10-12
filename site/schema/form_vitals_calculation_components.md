# `form_vitals_calculation_components`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB. Component values for calculations (e.g., systolic=120, diastolic=80)

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no |  | auto_increment |  |
| `fvc_uuid` | `binary(16)` | no |  |  | fk to form_vitals_calculation.uuid |
| `vitals_column` | `varchar(64)` | no |  |  | Component type: bps, bpd, pulse, etc. |
| `value` | `decimal(12,6)` | yes | `NULL` |  | Calculated numeric component value |
| `value_string` | `varchar(255)` | yes | `NULL` |  | Calculated non-numeric component value |
| `value_unit` | `varchar(16)` | yes | `NULL` |  | Unit for this component value |
| `component_order` | `int(11)` | no | `0` |  | Display order for components |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `idx_component_order` |  | `fvc_uuid`, `component_order` |
| `idx_vitals_column` |  | `vitals_column` |
| `unq_fvc_component` | yes | `fvc_uuid`, `vitals_column` |

## Changes since 7.0.0

- **7.0.4:** table added

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
