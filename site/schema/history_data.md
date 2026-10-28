# `history_data`

As OpenEMR 8.5.0's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `coffee` | `longtext` | yes | `NULL` |  |  |
| `tobacco` | `longtext` | yes | `NULL` |  |  |
| `alcohol` | `longtext` | yes | `NULL` |  |  |
| `sleep_patterns` | `longtext` | yes | `NULL` |  |  |
| `exercise_patterns` | `longtext` | yes | `NULL` |  |  |
| `seatbelt_use` | `longtext` | yes | `NULL` |  |  |
| `counseling` | `longtext` | yes | `NULL` |  |  |
| `hazardous_activities` | `longtext` | yes | `NULL` |  |  |
| `recreational_drugs` | `longtext` | yes | `NULL` |  |  |
| `last_breast_exam` | `varchar(255)` | yes | `NULL` |  |  |
| `last_mammogram` | `varchar(255)` | yes | `NULL` |  |  |
| `last_gynocological_exam` | `varchar(255)` | yes | `NULL` |  |  |
| `last_rectal_exam` | `varchar(255)` | yes | `NULL` |  |  |
| `last_prostate_exam` | `varchar(255)` | yes | `NULL` |  |  |
| `last_physical_exam` | `varchar(255)` | yes | `NULL` |  |  |
| `last_sigmoidoscopy_colonoscopy` | `varchar(255)` | yes | `NULL` |  |  |
| `last_ecg` | `varchar(255)` | yes | `NULL` |  |  |
| `last_cardiac_echo` | `varchar(255)` | yes | `NULL` |  |  |
| `last_retinal` | `varchar(255)` | yes | `NULL` |  |  |
| `last_fluvax` | `varchar(255)` | yes | `NULL` |  |  |
| `last_pneuvax` | `varchar(255)` | yes | `NULL` |  |  |
| `last_ldl` | `varchar(255)` | yes | `NULL` |  |  |
| `last_hemoglobin` | `varchar(255)` | yes | `NULL` |  |  |
| `last_psa` | `varchar(255)` | yes | `NULL` |  |  |
| `last_exam_results` | `varchar(255)` | yes | `NULL` |  |  |
| `history_mother` | `longtext` | yes | `NULL` |  |  |
| `dc_mother` | `text` | yes | `NULL` |  |  |
| `history_father` | `longtext` | yes | `NULL` |  |  |
| `dc_father` | `text` | yes | `NULL` |  |  |
| `history_siblings` | `longtext` | yes | `NULL` |  |  |
| `dc_siblings` | `text` | yes | `NULL` |  |  |
| `history_offspring` | `longtext` | yes | `NULL` |  |  |
| `dc_offspring` | `text` | yes | `NULL` |  |  |
| `history_spouse` | `longtext` | yes | `NULL` |  |  |
| `dc_spouse` | `text` | yes | `NULL` |  |  |
| `relatives_cancer` | `longtext` | yes | `NULL` |  |  |
| `relatives_tuberculosis` | `longtext` | yes | `NULL` |  |  |
| `relatives_diabetes` | `longtext` | yes | `NULL` |  |  |
| `relatives_high_blood_pressure` | `longtext` | yes | `NULL` |  |  |
| `relatives_heart_problems` | `longtext` | yes | `NULL` |  |  |
| `relatives_stroke` | `longtext` | yes | `NULL` |  |  |
| `relatives_epilepsy` | `longtext` | yes | `NULL` |  |  |
| `relatives_mental_illness` | `longtext` | yes | `NULL` |  |  |
| `relatives_suicide` | `longtext` | yes | `NULL` |  |  |
| `cataract_surgery` | `datetime` | yes | `NULL` |  |  |
| `tonsillectomy` | `datetime` | yes | `NULL` |  |  |
| `cholecystestomy` | `datetime` | yes | `NULL` |  |  |
| `heart_surgery` | `datetime` | yes | `NULL` |  |  |
| `hysterectomy` | `datetime` | yes | `NULL` |  |  |
| `hernia_repair` | `datetime` | yes | `NULL` |  |  |
| `hip_replacement` | `datetime` | yes | `NULL` |  |  |
| `knee_replacement` | `datetime` | yes | `NULL` |  |  |
| `appendectomy` | `datetime` | yes | `NULL` |  |  |
| `date` | `datetime` | yes | `NULL` |  |  |
| `pid` | `bigint(20)` | no | `0` |  |  |
| `name_1` | `varchar(255)` | yes | `NULL` |  |  |
| `value_1` | `varchar(255)` | yes | `NULL` |  |  |
| `name_2` | `varchar(255)` | yes | `NULL` |  |  |
| `value_2` | `varchar(255)` | yes | `NULL` |  |  |
| `additional_history` | `text` | yes | `NULL` |  |  |
| `exams` | `text` | yes | `NULL` |  |  |
| `usertext11` | `text` | yes | `NULL` |  |  |
| `usertext12` | `varchar(255)` | no | `''` |  |  |
| `usertext13` | `varchar(255)` | no | `''` |  |  |
| `usertext14` | `varchar(255)` | no | `''` |  |  |
| `usertext15` | `varchar(255)` | no | `''` |  |  |
| `usertext16` | `varchar(255)` | no | `''` |  |  |
| `usertext17` | `varchar(255)` | no | `''` |  |  |
| `usertext18` | `varchar(255)` | no | `''` |  |  |
| `usertext19` | `varchar(255)` | no | `''` |  |  |
| `usertext20` | `varchar(255)` | no | `''` |  |  |
| `usertext21` | `varchar(255)` | no | `''` |  |  |
| `usertext22` | `varchar(255)` | no | `''` |  |  |
| `usertext23` | `varchar(255)` | no | `''` |  |  |
| `usertext24` | `varchar(255)` | no | `''` |  |  |
| `usertext25` | `varchar(255)` | no | `''` |  |  |
| `usertext26` | `varchar(255)` | no | `''` |  |  |
| `usertext27` | `varchar(255)` | no | `''` |  |  |
| `usertext28` | `varchar(255)` | no | `''` |  |  |
| `usertext29` | `varchar(255)` | no | `''` |  |  |
| `usertext30` | `varchar(255)` | no | `''` |  |  |
| `userdate11` | `date` | yes | `NULL` |  |  |
| `userdate12` | `date` | yes | `NULL` |  |  |
| `userdate13` | `date` | yes | `NULL` |  |  |
| `userdate14` | `date` | yes | `NULL` |  |  |
| `userdate15` | `date` | yes | `NULL` |  |  |
| `userarea11` | `text` | yes | `NULL` |  |  |
| `userarea12` | `text` | yes | `NULL` |  |  |
| `created_by` | `bigint(20)` | yes | `NULL` |  | users.id the user that first created this record |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `pid` |  | `pid` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

None.

---

*Generated by [openemr-reference](../../README.md) from OpenEMR `v8_5_0` (c1b2b8bcbe). Every statement on this page was read from the source at those tags; nothing is written by hand.*
