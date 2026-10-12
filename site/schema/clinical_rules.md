# `clinical_rules`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `varchar(31)` | no | `''` |  | Unique and maps to list_options list clinical_rules |
| `pid` | `bigint(20)` | no | `0` |  | 0 is default for all patients, while > 0 is id from patient_data table |
| `active_alert_flag` | `tinyint(1)` | yes | `NULL` |  | Active Alert Widget Module flag - note not yet utilized |
| `passive_alert_flag` | `tinyint(1)` | yes | `NULL` |  | Passive Alert Widget Module flag |
| `cqm_flag` | `tinyint(1)` | yes | `NULL` |  | Clinical Quality Measure flag (unable to customize per patient) |
| `cqm_2011_flag` | `tinyint(1)` | yes | `NULL` |  | 2011 Clinical Quality Measure flag (unable to customize per patient) |
| `cqm_2014_flag` | `tinyint(1)` | yes | `NULL` |  | 2014 Clinical Quality Measure flag (unable to customize per patient) |
| `cqm_nqf_code` | `varchar(10)` | no | `''` |  | Clinical Quality Measure NQF identifier |
| `cqm_pqri_code` | `varchar(10)` | no | `''` |  | Clinical Quality Measure PQRI identifier |
| `amc_flag` | `tinyint(1)` | yes | `NULL` |  | Automated Measure Calculation flag (unable to customize per patient) |
| `amc_2011_flag` | `tinyint(1)` | yes | `NULL` |  | 2011 Automated Measure Calculation flag for (unable to customize per patient) |
| `amc_2014_flag` | `tinyint(1)` | yes | `NULL` |  | 2014 Automated Measure Calculation flag for (unable to customize per patient) |
| `amc_2015_flag` | `tinyint(1)` | yes | `NULL` |  | 2015 Automated Measure Calculation flag for (unable to customize per patient) |
| `amc_code` | `varchar(10)` | no | `''` |  | Automated Measure Calculation identifier (MU rule) |
| `amc_code_2014` | `varchar(30)` | no | `''` |  | Automated Measure Calculation 2014 identifier (MU rule) |
| `amc_code_2015` | `varchar(30)` | no | `''` |  | Automated Measure Calculation 2014 identifier (MU rule) |
| `amc_2014_stage1_flag` | `tinyint(1)` | yes | `NULL` |  | 2014 Stage 1 - Automated Measure Calculation flag for (unable to customize per patient) |
| `amc_2014_stage2_flag` | `tinyint(1)` | yes | `NULL` |  | 2014 Stage 2 - Automated Measure Calculation flag for (unable to customize per patient) |
| `patient_reminder_flag` | `tinyint(1)` | yes | `NULL` |  | Clinical Reminder Module flag |
| `bibliographic_citation` | `varchar(255)` | no | `''` |  |  |
| `developer` | `varchar(255)` | no | `''` |  | Clinical Rule Developer |
| `funding_source` | `varchar(255)` | no | `''` |  | Clinical Rule Funding Source |
| `release_version` | `varchar(255)` | no | `''` |  | Clinical Rule Release Version |
| `web_reference` | `varchar(255)` | no | `''` |  | Clinical Rule Web Reference |
| `linked_referential_cds` | `varchar(50)` | no | `''` |  |  |
| `access_control` | `varchar(255)` | no | `'patients:med'` |  | ACO link for access control |
| `patient_dob_usage` | `text` | yes | `NULL` |  | Description of how patient DOB is used by this rule |
| `patient_ethnicity_usage` | `text` | yes | `NULL` |  | Description of how patient ethnicity is used by this rule |
| `patient_health_status_usage` | `text` | yes | `NULL` |  | Description of how patient health status assessments are used by this rule |
| `patient_gender_identity_usage` | `text` | yes | `NULL` |  | Description of how patient gender identity information is used by this rule |
| `patient_language_usage` | `text` | yes | `NULL` |  | Description of how patient language information is used by this rule |
| `patient_race_usage` | `text` | yes | `NULL` |  | Description of how patient race information is used by this rule |
| `patient_sex_usage` | `text` | yes | `NULL` |  | Description of how patient birth sex information is used by this rule |
| `patient_sexual_orientation_usage` | `text` | yes | `NULL` |  | Description of how patient sexual orientation is used by this rule |
| `patient_sodh_usage` | `text` | yes | `NULL` |  | Description of how patient social determinants of health are used by this rule |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id`, `pid` |

## Changes since 7.0.0

- **7.0.3:** added `patient_dob_usage` text; added `patient_ethnicity_usage` text; added `patient_health_status_usage` text; added `patient_gender_identity_usage` text; added `patient_language_usage` text; added `patient_race_usage` text; added `patient_sex_usage` text; added `patient_sexual_orientation_usage` text; added `patient_sodh_usage` text

---

*Generated 2026-10-12 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
