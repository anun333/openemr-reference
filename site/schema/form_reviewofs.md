# `form_reviewofs`

As OpenEMR 8.5.0's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `date` | `datetime` | yes | `NULL` |  |  |
| `pid` | `bigint(20)` | yes | `NULL` |  |  |
| `user` | `varchar(255)` | yes | `NULL` |  |  |
| `groupname` | `varchar(255)` | yes | `NULL` |  |  |
| `authorized` | `tinyint(4)` | yes | `NULL` |  |  |
| `activity` | `tinyint(4)` | yes | `NULL` |  |  |
| `fever` | `varchar(5)` | yes | `NULL` |  |  |
| `chills` | `varchar(5)` | yes | `NULL` |  |  |
| `night_sweats` | `varchar(5)` | yes | `NULL` |  |  |
| `weight_loss` | `varchar(5)` | yes | `NULL` |  |  |
| `poor_appetite` | `varchar(5)` | yes | `NULL` |  |  |
| `insomnia` | `varchar(5)` | yes | `NULL` |  |  |
| `fatigued` | `varchar(5)` | yes | `NULL` |  |  |
| `depressed` | `varchar(5)` | yes | `NULL` |  |  |
| `hyperactive` | `varchar(5)` | yes | `NULL` |  |  |
| `exposure_to_foreign_countries` | `varchar(5)` | yes | `NULL` |  |  |
| `cataracts` | `varchar(5)` | yes | `NULL` |  |  |
| `cataract_surgery` | `varchar(5)` | yes | `NULL` |  |  |
| `glaucoma` | `varchar(5)` | yes | `NULL` |  |  |
| `double_vision` | `varchar(5)` | yes | `NULL` |  |  |
| `blurred_vision` | `varchar(5)` | yes | `NULL` |  |  |
| `poor_hearing` | `varchar(5)` | yes | `NULL` |  |  |
| `headaches` | `varchar(5)` | yes | `NULL` |  |  |
| `ringing_in_ears` | `varchar(5)` | yes | `NULL` |  |  |
| `bloody_nose` | `varchar(5)` | yes | `NULL` |  |  |
| `sinusitis` | `varchar(5)` | yes | `NULL` |  |  |
| `sinus_surgery` | `varchar(5)` | yes | `NULL` |  |  |
| `dry_mouth` | `varchar(5)` | yes | `NULL` |  |  |
| `strep_throat` | `varchar(5)` | yes | `NULL` |  |  |
| `tonsillectomy` | `varchar(5)` | yes | `NULL` |  |  |
| `swollen_lymph_nodes` | `varchar(5)` | yes | `NULL` |  |  |
| `throat_cancer` | `varchar(5)` | yes | `NULL` |  |  |
| `throat_cancer_surgery` | `varchar(5)` | yes | `NULL` |  |  |
| `heart_attack` | `varchar(5)` | yes | `NULL` |  |  |
| `irregular_heart_beat` | `varchar(5)` | yes | `NULL` |  |  |
| `chest_pains` | `varchar(5)` | yes | `NULL` |  |  |
| `shortness_of_breath` | `varchar(5)` | yes | `NULL` |  |  |
| `high_blood_pressure` | `varchar(5)` | yes | `NULL` |  |  |
| `heart_failure` | `varchar(5)` | yes | `NULL` |  |  |
| `poor_circulation` | `varchar(5)` | yes | `NULL` |  |  |
| `vascular_surgery` | `varchar(5)` | yes | `NULL` |  |  |
| `cardiac_catheterization` | `varchar(5)` | yes | `NULL` |  |  |
| `coronary_artery_bypass` | `varchar(5)` | yes | `NULL` |  |  |
| `heart_transplant` | `varchar(5)` | yes | `NULL` |  |  |
| `stress_test` | `varchar(5)` | yes | `NULL` |  |  |
| `emphysema` | `varchar(5)` | yes | `NULL` |  |  |
| `chronic_bronchitis` | `varchar(5)` | yes | `NULL` |  |  |
| `interstitial_lung_disease` | `varchar(5)` | yes | `NULL` |  |  |
| `shortness_of_breath_2` | `varchar(5)` | yes | `NULL` |  |  |
| `lung_cancer` | `varchar(5)` | yes | `NULL` |  |  |
| `lung_cancer_surgery` | `varchar(5)` | yes | `NULL` |  |  |
| `pheumothorax` | `varchar(5)` | yes | `NULL` |  |  |
| `stomach_pains` | `varchar(5)` | yes | `NULL` |  |  |
| `peptic_ulcer_disease` | `varchar(5)` | yes | `NULL` |  |  |
| `gastritis` | `varchar(5)` | yes | `NULL` |  |  |
| `endoscopy` | `varchar(5)` | yes | `NULL` |  |  |
| `polyps` | `varchar(5)` | yes | `NULL` |  |  |
| `colonoscopy` | `varchar(5)` | yes | `NULL` |  |  |
| `colon_cancer` | `varchar(5)` | yes | `NULL` |  |  |
| `colon_cancer_surgery` | `varchar(5)` | yes | `NULL` |  |  |
| `ulcerative_colitis` | `varchar(5)` | yes | `NULL` |  |  |
| `crohns_disease` | `varchar(5)` | yes | `NULL` |  |  |
| `appendectomy` | `varchar(5)` | yes | `NULL` |  |  |
| `divirticulitis` | `varchar(5)` | yes | `NULL` |  |  |
| `divirticulitis_surgery` | `varchar(5)` | yes | `NULL` |  |  |
| `gall_stones` | `varchar(5)` | yes | `NULL` |  |  |
| `cholecystectomy` | `varchar(5)` | yes | `NULL` |  |  |
| `hepatitis` | `varchar(5)` | yes | `NULL` |  |  |
| `cirrhosis_of_the_liver` | `varchar(5)` | yes | `NULL` |  |  |
| `splenectomy` | `varchar(5)` | yes | `NULL` |  |  |
| `kidney_failure` | `varchar(5)` | yes | `NULL` |  |  |
| `kidney_stones` | `varchar(5)` | yes | `NULL` |  |  |
| `kidney_cancer` | `varchar(5)` | yes | `NULL` |  |  |
| `kidney_infections` | `varchar(5)` | yes | `NULL` |  |  |
| `bladder_infections` | `varchar(5)` | yes | `NULL` |  |  |
| `bladder_cancer` | `varchar(5)` | yes | `NULL` |  |  |
| `prostate_problems` | `varchar(5)` | yes | `NULL` |  |  |
| `prostate_cancer` | `varchar(5)` | yes | `NULL` |  |  |
| `kidney_transplant` | `varchar(5)` | yes | `NULL` |  |  |
| `sexually_transmitted_disease` | `varchar(5)` | yes | `NULL` |  |  |
| `burning_with_urination` | `varchar(5)` | yes | `NULL` |  |  |
| `discharge_from_urethra` | `varchar(5)` | yes | `NULL` |  |  |
| `rashes` | `varchar(5)` | yes | `NULL` |  |  |
| `infections` | `varchar(5)` | yes | `NULL` |  |  |
| `ulcerations` | `varchar(5)` | yes | `NULL` |  |  |
| `pemphigus` | `varchar(5)` | yes | `NULL` |  |  |
| `herpes` | `varchar(5)` | yes | `NULL` |  |  |
| `osetoarthritis` | `varchar(5)` | yes | `NULL` |  |  |
| `rheumotoid_arthritis` | `varchar(5)` | yes | `NULL` |  |  |
| `lupus` | `varchar(5)` | yes | `NULL` |  |  |
| `ankylosing_sondlilitis` | `varchar(5)` | yes | `NULL` |  |  |
| `swollen_joints` | `varchar(5)` | yes | `NULL` |  |  |
| `stiff_joints` | `varchar(5)` | yes | `NULL` |  |  |
| `broken_bones` | `varchar(5)` | yes | `NULL` |  |  |
| `neck_problems` | `varchar(5)` | yes | `NULL` |  |  |
| `back_problems` | `varchar(5)` | yes | `NULL` |  |  |
| `back_surgery` | `varchar(5)` | yes | `NULL` |  |  |
| `scoliosis` | `varchar(5)` | yes | `NULL` |  |  |
| `herniated_disc` | `varchar(5)` | yes | `NULL` |  |  |
| `shoulder_problems` | `varchar(5)` | yes | `NULL` |  |  |
| `elbow_problems` | `varchar(5)` | yes | `NULL` |  |  |
| `wrist_problems` | `varchar(5)` | yes | `NULL` |  |  |
| `hand_problems` | `varchar(5)` | yes | `NULL` |  |  |
| `hip_problems` | `varchar(5)` | yes | `NULL` |  |  |
| `knee_problems` | `varchar(5)` | yes | `NULL` |  |  |
| `ankle_problems` | `varchar(5)` | yes | `NULL` |  |  |
| `foot_problems` | `varchar(5)` | yes | `NULL` |  |  |
| `insulin_dependent_diabetes` | `varchar(5)` | yes | `NULL` |  |  |
| `noninsulin_dependent_diabetes` | `varchar(5)` | yes | `NULL` |  |  |
| `hypothyroidism` | `varchar(5)` | yes | `NULL` |  |  |
| `hyperthyroidism` | `varchar(5)` | yes | `NULL` |  |  |
| `cushing_syndrom` | `varchar(5)` | yes | `NULL` |  |  |
| `addison_syndrom` | `varchar(5)` | yes | `NULL` |  |  |
| `additional_notes` | `longtext` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |

## Changes since 7.0.0

None.

---

*Generated by [openemr-reference](../../README.md) from OpenEMR `v8_5_0` (c1b2b8bcbe). Every statement on this page was read from the source at those tags; nothing is written by hand.*
