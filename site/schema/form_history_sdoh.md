# `form_history_sdoh`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(21) unsigned` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `pid` | `int(10) unsigned` | no |  |  |  |
| `encounter` | `int(10) unsigned` | yes | `NULL` |  |  |
| `created_at` | `datetime` | no | `current_timestamp()` |  |  |
| `updated_at` | `datetime` | no | `current_timestamp()` | on update current_timestamp() |  |
| `created_by` | `int(10) unsigned` | yes | `NULL` |  | fk to users.id user that created this record |
| `updated_by` | `int(10) unsigned` | yes | `NULL` |  | fk to users.id user that last modified this record |
| `assessment_date` | `date` | yes | `NULL` |  |  |
| `screening_tool` | `varchar(255)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=sdoh_instruments represents the assessment tool used to administer this assessment |
| `assessor` | `varchar(255)` | yes | `NULL` |  | fk to users.username the user that administered the assessment |
| `food_insecurity` | `varchar(50)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=sdoh_food_insecurity_risk |
| `food_insecurity_notes` | `text` | yes | `NULL` |  |  |
| `housing_instability` | `varchar(50)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=sdoh_housing_worry |
| `housing_instability_notes` | `text` | yes | `NULL` |  |  |
| `transportation_insecurity` | `varchar(50)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=sdoh_transportation_barrier |
| `transportation_insecurity_notes` | `text` | yes | `NULL` |  |  |
| `utilities_insecurity` | `varchar(50)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=sdoh_utilities_shutoff |
| `utilities_insecurity_notes` | `text` | yes | `NULL` |  |  |
| `interpersonal_safety` | `varchar(50)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=sdoh_financial_strain |
| `interpersonal_safety_notes` | `text` | yes | `NULL` |  |  |
| `financial_strain` | `varchar(50)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=sdoh_financial_strain |
| `financial_strain_notes` | `text` | yes | `NULL` |  |  |
| `social_isolation` | `varchar(50)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=sdoh_social_isolation_freq |
| `social_isolation_notes` | `text` | yes | `NULL` |  |  |
| `childcare_needs` | `varchar(50)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=sdoh_childcare_needs |
| `childcare_needs_notes` | `text` | yes | `NULL` |  |  |
| `digital_access` | `varchar(50)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=sdoh_digital_access |
| `digital_access_notes` | `text` | yes | `NULL` |  |  |
| `employment_status` | `varchar(50)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=sdoh_food_insecurity_risk |
| `education_level` | `varchar(50)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=sdoh_education_level |
| `caregiver_status` | `varchar(20)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=sdoh_food_insecurity_risk |
| `veteran_status` | `varchar(20)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=sdoh_food_insecurity_risk |
| `pregnancy_status` | `varchar(20)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=pregnancy_status |
| `pregnancy_edd` | `date` | yes | `NULL` |  | Estimated due date for pregnancy |
| `pregnancy_intent` | `varchar(32)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=pregnancy_intent Pregnancy Intent Over Next Year (codes from PregnancyIntent list) |
| `postpartum_status` | `varchar(20)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=postpartum_status |
| `postpartum_end` | `date` | yes | `NULL` |  | PostPartum end date |
| `goals` | `text` | yes | `NULL` |  |  |
| `interventions` | `text` | yes | `NULL` |  |  |
| `instrument_score` | `int(11)` | yes | `NULL` |  |  |
| `positive_domain_count` | `int(11)` | yes | `NULL` |  |  |
| `declined_flag` | `tinyint(1)` | yes | `NULL` |  |  |
| `disability_status` | `varchar(50)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=disability_status |
| `disability_status_notes` | `text` | yes | `NULL` |  |  |
| `disability_scale` | `text` | yes | `NULL` |  |  |
| `hunger_q1` | `varchar(50)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=vital_signs_answers |
| `hunger_q2` | `varchar(50)` | yes | `NULL` |  | fk to list_options.option_id WHERE list_id=vital_signs_answers |
| `hunger_score` | `int(11)` | yes | `NULL` |  | Calculated HVS score |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `assessment_idx` |  | `assessment_date` |
| `encounter_idx` |  | `encounter` |
| `pid_idx` |  | `pid` |
| `uuid_idx` |  | `uuid` |

## Changes since 7.0.0

- **7.0.4:** table added

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
