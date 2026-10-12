# `form_ros`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no |  | auto_increment |  |
| `pid` | `bigint(20)` | no |  |  |  |
| `activity` | `int(11)` | no | `1` |  |  |
| `date` | `datetime` | yes | `NULL` |  |  |
| `weight_change` | `varchar(3)` | yes | `NULL` |  |  |
| `weakness` | `varchar(3)` | yes | `NULL` |  |  |
| `fatigue` | `varchar(3)` | yes | `NULL` |  |  |
| `anorexia` | `varchar(3)` | yes | `NULL` |  |  |
| `fever` | `varchar(3)` | yes | `NULL` |  |  |
| `chills` | `varchar(3)` | yes | `NULL` |  |  |
| `night_sweats` | `varchar(3)` | yes | `NULL` |  |  |
| `insomnia` | `varchar(3)` | yes | `NULL` |  |  |
| `irritability` | `varchar(3)` | yes | `NULL` |  |  |
| `heat_or_cold` | `varchar(3)` | yes | `NULL` |  |  |
| `intolerance` | `varchar(3)` | yes | `NULL` |  |  |
| `change_in_vision` | `varchar(3)` | yes | `NULL` |  |  |
| `glaucoma_history` | `varchar(3)` | yes | `NULL` |  |  |
| `eye_pain` | `varchar(3)` | yes | `NULL` |  |  |
| `irritation` | `varchar(3)` | yes | `NULL` |  |  |
| `redness` | `varchar(3)` | yes | `NULL` |  |  |
| `excessive_tearing` | `varchar(3)` | yes | `NULL` |  |  |
| `double_vision` | `varchar(3)` | yes | `NULL` |  |  |
| `blind_spots` | `varchar(3)` | yes | `NULL` |  |  |
| `photophobia` | `varchar(3)` | yes | `NULL` |  |  |
| `hearing_loss` | `varchar(3)` | yes | `NULL` |  |  |
| `discharge` | `varchar(3)` | yes | `NULL` |  |  |
| `pain` | `varchar(3)` | yes | `NULL` |  |  |
| `vertigo` | `varchar(3)` | yes | `NULL` |  |  |
| `tinnitus` | `varchar(3)` | yes | `NULL` |  |  |
| `frequent_colds` | `varchar(3)` | yes | `NULL` |  |  |
| `sore_throat` | `varchar(3)` | yes | `NULL` |  |  |
| `sinus_problems` | `varchar(3)` | yes | `NULL` |  |  |
| `post_nasal_drip` | `varchar(3)` | yes | `NULL` |  |  |
| `nosebleed` | `varchar(3)` | yes | `NULL` |  |  |
| `snoring` | `varchar(3)` | yes | `NULL` |  |  |
| `apnea` | `varchar(3)` | yes | `NULL` |  |  |
| `breast_mass` | `varchar(3)` | yes | `NULL` |  |  |
| `breast_discharge` | `varchar(3)` | yes | `NULL` |  |  |
| `biopsy` | `varchar(3)` | yes | `NULL` |  |  |
| `abnormal_mammogram` | `varchar(3)` | yes | `NULL` |  |  |
| `cough` | `varchar(3)` | yes | `NULL` |  |  |
| `sputum` | `varchar(3)` | yes | `NULL` |  |  |
| `shortness_of_breath` | `varchar(3)` | yes | `NULL` |  |  |
| `wheezing` | `varchar(3)` | yes | `NULL` |  |  |
| `hemoptsyis` | `varchar(3)` | yes | `NULL` |  |  |
| `asthma` | `varchar(3)` | yes | `NULL` |  |  |
| `copd` | `varchar(3)` | yes | `NULL` |  |  |
| `chest_pain` | `varchar(3)` | yes | `NULL` |  |  |
| `palpitation` | `varchar(3)` | yes | `NULL` |  |  |
| `syncope` | `varchar(3)` | yes | `NULL` |  |  |
| `pnd` | `varchar(3)` | yes | `NULL` |  |  |
| `doe` | `varchar(3)` | yes | `NULL` |  |  |
| `orthopnea` | `varchar(3)` | yes | `NULL` |  |  |
| `peripheal` | `varchar(3)` | yes | `NULL` |  |  |
| `edema` | `varchar(3)` | yes | `NULL` |  |  |
| `legpain_cramping` | `varchar(3)` | yes | `NULL` |  |  |
| `history_murmur` | `varchar(3)` | yes | `NULL` |  |  |
| `arrythmia` | `varchar(3)` | yes | `NULL` |  |  |
| `heart_problem` | `varchar(3)` | yes | `NULL` |  |  |
| `dysphagia` | `varchar(3)` | yes | `NULL` |  |  |
| `heartburn` | `varchar(3)` | yes | `NULL` |  |  |
| `bloating` | `varchar(3)` | yes | `NULL` |  |  |
| `belching` | `varchar(3)` | yes | `NULL` |  |  |
| `flatulence` | `varchar(3)` | yes | `NULL` |  |  |
| `nausea` | `varchar(3)` | yes | `NULL` |  |  |
| `vomiting` | `varchar(3)` | yes | `NULL` |  |  |
| `hematemesis` | `varchar(3)` | yes | `NULL` |  |  |
| `gastro_pain` | `varchar(3)` | yes | `NULL` |  |  |
| `food_intolerance` | `varchar(3)` | yes | `NULL` |  |  |
| `hepatitis` | `varchar(3)` | yes | `NULL` |  |  |
| `jaundice` | `varchar(3)` | yes | `NULL` |  |  |
| `hematochezia` | `varchar(3)` | yes | `NULL` |  |  |
| `changed_bowel` | `varchar(3)` | yes | `NULL` |  |  |
| `diarrhea` | `varchar(3)` | yes | `NULL` |  |  |
| `constipation` | `varchar(3)` | yes | `NULL` |  |  |
| `polyuria` | `varchar(3)` | yes | `NULL` |  |  |
| `polydypsia` | `varchar(3)` | yes | `NULL` |  |  |
| `dysuria` | `varchar(3)` | yes | `NULL` |  |  |
| `hematuria` | `varchar(3)` | yes | `NULL` |  |  |
| `frequency` | `varchar(3)` | yes | `NULL` |  |  |
| `urgency` | `varchar(3)` | yes | `NULL` |  |  |
| `incontinence` | `varchar(3)` | yes | `NULL` |  |  |
| `renal_stones` | `varchar(3)` | yes | `NULL` |  |  |
| `utis` | `varchar(3)` | yes | `NULL` |  |  |
| `hesitancy` | `varchar(3)` | yes | `NULL` |  |  |
| `dribbling` | `varchar(3)` | yes | `NULL` |  |  |
| `stream` | `varchar(3)` | yes | `NULL` |  |  |
| `nocturia` | `varchar(3)` | yes | `NULL` |  |  |
| `erections` | `varchar(3)` | yes | `NULL` |  |  |
| `ejaculations` | `varchar(3)` | yes | `NULL` |  |  |
| `g` | `varchar(3)` | yes | `NULL` |  |  |
| `p` | `varchar(3)` | yes | `NULL` |  |  |
| `ap` | `varchar(3)` | yes | `NULL` |  |  |
| `lc` | `varchar(3)` | yes | `NULL` |  |  |
| `mearche` | `varchar(3)` | yes | `NULL` |  |  |
| `menopause` | `varchar(3)` | yes | `NULL` |  |  |
| `lmp` | `varchar(3)` | yes | `NULL` |  |  |
| `f_frequency` | `varchar(3)` | yes | `NULL` |  |  |
| `f_flow` | `varchar(3)` | yes | `NULL` |  |  |
| `f_symptoms` | `varchar(3)` | yes | `NULL` |  |  |
| `abnormal_hair_growth` | `varchar(3)` | yes | `NULL` |  |  |
| `f_hirsutism` | `varchar(3)` | yes | `NULL` |  |  |
| `joint_pain` | `varchar(3)` | yes | `NULL` |  |  |
| `swelling` | `varchar(3)` | yes | `NULL` |  |  |
| `m_redness` | `varchar(3)` | yes | `NULL` |  |  |
| `m_warm` | `varchar(3)` | yes | `NULL` |  |  |
| `m_stiffness` | `varchar(3)` | yes | `NULL` |  |  |
| `muscle` | `varchar(3)` | yes | `NULL` |  |  |
| `m_aches` | `varchar(3)` | yes | `NULL` |  |  |
| `fms` | `varchar(3)` | yes | `NULL` |  |  |
| `arthritis` | `varchar(3)` | yes | `NULL` |  |  |
| `loc` | `varchar(3)` | yes | `NULL` |  |  |
| `seizures` | `varchar(3)` | yes | `NULL` |  |  |
| `stroke` | `varchar(3)` | yes | `NULL` |  |  |
| `tia` | `varchar(3)` | yes | `NULL` |  |  |
| `n_numbness` | `varchar(3)` | yes | `NULL` |  |  |
| `n_weakness` | `varchar(3)` | yes | `NULL` |  |  |
| `paralysis` | `varchar(3)` | yes | `NULL` |  |  |
| `intellectual_decline` | `varchar(3)` | yes | `NULL` |  |  |
| `memory_problems` | `varchar(3)` | yes | `NULL` |  |  |
| `dementia` | `varchar(3)` | yes | `NULL` |  |  |
| `n_headache` | `varchar(3)` | yes | `NULL` |  |  |
| `s_cancer` | `varchar(3)` | yes | `NULL` |  |  |
| `psoriasis` | `varchar(3)` | yes | `NULL` |  |  |
| `s_acne` | `varchar(3)` | yes | `NULL` |  |  |
| `s_other` | `varchar(3)` | yes | `NULL` |  |  |
| `s_disease` | `varchar(3)` | yes | `NULL` |  |  |
| `p_diagnosis` | `varchar(3)` | yes | `NULL` |  |  |
| `p_medication` | `varchar(3)` | yes | `NULL` |  |  |
| `depression` | `varchar(3)` | yes | `NULL` |  |  |
| `anxiety` | `varchar(3)` | yes | `NULL` |  |  |
| `social_difficulties` | `varchar(3)` | yes | `NULL` |  |  |
| `thyroid_problems` | `varchar(3)` | yes | `NULL` |  |  |
| `diabetes` | `varchar(3)` | yes | `NULL` |  |  |
| `abnormal_blood` | `varchar(3)` | yes | `NULL` |  |  |
| `anemia` | `varchar(3)` | yes | `NULL` |  |  |
| `fh_blood_problems` | `varchar(3)` | yes | `NULL` |  |  |
| `bleeding_problems` | `varchar(3)` | yes | `NULL` |  |  |
| `allergies` | `varchar(3)` | yes | `NULL` |  |  |
| `frequent_illness` | `varchar(3)` | yes | `NULL` |  |  |
| `hiv` | `varchar(3)` | yes | `NULL` |  |  |
| `hai_status` | `varchar(3)` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |

## Changes since 7.0.0

None.

---

*Generated by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
