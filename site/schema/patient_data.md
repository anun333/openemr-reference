# `patient_data`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `title` | `varchar(255)` | no | `''` |  |  |
| `language` | `varchar(255)` | no | `''` |  |  |
| `financial` | `varchar(255)` | no | `''` |  |  |
| `fname` | `varchar(255)` | no | `''` |  |  |
| `lname` | `varchar(255)` | no | `''` |  |  |
| `mname` | `varchar(255)` | no | `''` |  |  |
| `DOB` | `date` | yes | `NULL` |  |  |
| `street` | `varchar(255)` | no | `''` |  |  |
| `postal_code` | `varchar(255)` | no | `''` |  |  |
| `city` | `varchar(255)` | no | `''` |  |  |
| `state` | `varchar(255)` | no | `''` |  |  |
| `country_code` | `varchar(255)` | no | `''` |  |  |
| `drivers_license` | `varchar(255)` | no | `''` |  |  |
| `ss` | `varchar(255)` | no | `''` |  |  |
| `occupation` | `longtext` | yes | `NULL` |  |  |
| `phone_home` | `varchar(255)` | no | `''` |  |  |
| `phone_biz` | `varchar(255)` | no | `''` |  |  |
| `phone_contact` | `varchar(255)` | no | `''` |  |  |
| `phone_cell` | `varchar(255)` | no | `''` |  |  |
| `pharmacy_id` | `int(11)` | no | `0` |  |  |
| `status` | `varchar(255)` | no | `''` |  |  |
| `contact_relationship` | `varchar(255)` | no | `''` |  |  |
| `date` | `datetime` | yes | `NULL` |  |  |
| `sex` | `varchar(255)` | no | `''` |  | Sex at birth |
| `referrer` | `varchar(255)` | no | `''` |  |  |
| `referrerID` | `varchar(255)` | no | `''` |  |  |
| `providerID` | `int(11)` | yes | `NULL` |  |  |
| `ref_providerID` | `int(11)` | yes | `NULL` |  |  |
| `email` | `varchar(255)` | no | `''` |  |  |
| `email_direct` | `varchar(255)` | no | `''` |  |  |
| `ethnoracial` | `varchar(255)` | no | `''` |  |  |
| `race` | `varchar(255)` | no | `''` |  |  |
| `ethnicity` | `varchar(255)` | no | `''` |  |  |
| `religion` | `varchar(40)` | no | `''` |  |  |
| `interpreter` | `varchar(255)` | no | `''` |  | original field used for determining if patient needs an interpreter, now used for additional notes about need for interpreter |
| `interpreter_needed` | `text` | yes | `NULL` |  | fk to list_options.option_id where list_id=yes_no_unknown used to determine if patient needs an interpreter |
| `migrantseasonal` | `varchar(255)` | no | `''` |  |  |
| `family_size` | `varchar(255)` | no | `''` |  |  |
| `monthly_income` | `varchar(255)` | no | `''` |  |  |
| `billing_note` | `text` | yes | `NULL` |  |  |
| `homeless` | `varchar(255)` | no | `''` |  |  |
| `financial_review` | `datetime` | yes | `NULL` |  |  |
| `pubpid` | `varchar(255)` | no | `''` |  |  |
| `pid` | `bigint(20)` | no | `0` |  |  |
| `genericname1` | `varchar(255)` | no | `''` |  |  |
| `genericval1` | `varchar(255)` | no | `''` |  |  |
| `genericname2` | `varchar(255)` | no | `''` |  |  |
| `genericval2` | `varchar(255)` | no | `''` |  |  |
| `hipaa_mail` | `varchar(3)` | no | `''` |  |  |
| `hipaa_voice` | `varchar(3)` | no | `''` |  |  |
| `hipaa_notice` | `varchar(3)` | no | `''` |  |  |
| `hipaa_message` | `varchar(20)` | no | `''` |  |  |
| `hipaa_allowsms` | `varchar(3)` | no | `'NO'` |  |  |
| `hipaa_allowemail` | `varchar(3)` | no | `'NO'` |  |  |
| `squad` | `varchar(32)` | no | `''` |  |  |
| `fitness` | `int(11)` | no | `0` |  |  |
| `referral_source` | `varchar(30)` | no | `''` |  |  |
| `usertext1` | `varchar(255)` | no | `''` |  |  |
| `usertext2` | `varchar(255)` | no | `''` |  |  |
| `usertext3` | `varchar(255)` | no | `''` |  |  |
| `usertext4` | `varchar(255)` | no | `''` |  |  |
| `usertext5` | `varchar(255)` | no | `''` |  |  |
| `usertext6` | `varchar(255)` | no | `''` |  |  |
| `usertext7` | `varchar(255)` | no | `''` |  |  |
| `usertext8` | `varchar(255)` | no | `''` |  |  |
| `userlist1` | `varchar(255)` | no | `''` |  |  |
| `userlist2` | `varchar(255)` | no | `''` |  |  |
| `userlist3` | `varchar(255)` | no | `''` |  |  |
| `userlist4` | `varchar(255)` | no | `''` |  |  |
| `userlist5` | `varchar(255)` | no | `''` |  |  |
| `userlist6` | `varchar(255)` | no | `''` |  |  |
| `userlist7` | `varchar(255)` | no | `''` |  |  |
| `pricelevel` | `varchar(255)` | no | `'standard'` |  |  |
| `regdate` | `datetime` | yes | `NULL` |  | Registration Date |
| `contrastart` | `date` | yes | `NULL` |  | Date contraceptives initially used |
| `completed_ad` | `varchar(3)` | no | `'NO'` |  |  |
| `ad_reviewed` | `datetime` | yes | `NULL` |  | Date and time the advance care directive was reviewed and validated by the authenticator user. |
| `advance_directive_user_authenticator` | `bigint(20)` | yes | `NULL` |  | fk to users.id of the user who authenticates that the advance care directive is valid. |
| `vfc` | `varchar(255)` | no | `''` |  |  |
| `mothersname` | `varchar(255)` | no | `''` |  |  |
| `guardiansname` | `text` | yes | `NULL` |  |  |
| `allow_imm_reg_use` | `varchar(255)` | no | `''` |  |  |
| `allow_imm_info_share` | `varchar(255)` | no | `''` |  |  |
| `allow_health_info_ex` | `varchar(255)` | no | `''` |  |  |
| `allow_patient_portal` | `varchar(31)` | no | `''` |  |  |
| `deceased_date` | `datetime` | yes | `NULL` |  |  |
| `deceased_reason` | `varchar(255)` | no | `''` |  |  |
| `soap_import_status` | `tinyint(4)` | yes | `NULL` |  | 1-Prescription Press 2-Prescription Import 3-Allergy Press 4-Allergy Import |
| `cmsportal_login` | `varchar(60)` | no | `''` |  |  |
| `care_team_provider` | `text` | yes | `NULL` |  |  |
| `care_team_facility` | `text` | yes | `NULL` |  |  |
| `care_team_status` | `text` | yes | `NULL` |  |  |
| `county` | `varchar(40)` | no | `''` |  |  |
| `industry` | `text` | yes | `NULL` |  |  |
| `imm_reg_status` | `text` | yes | `NULL` |  |  |
| `imm_reg_stat_effdate` | `text` | yes | `NULL` |  |  |
| `publicity_code` | `text` | yes | `NULL` |  |  |
| `publ_code_eff_date` | `text` | yes | `NULL` |  |  |
| `protect_indicator` | `text` | yes | `NULL` |  |  |
| `prot_indi_effdate` | `text` | yes | `NULL` |  |  |
| `guardianrelationship` | `text` | yes | `NULL` |  |  |
| `guardiansex` | `text` | yes | `NULL` |  |  |
| `guardianaddress` | `text` | yes | `NULL` |  |  |
| `guardiancity` | `text` | yes | `NULL` |  |  |
| `guardianstate` | `text` | yes | `NULL` |  |  |
| `guardianpostalcode` | `text` | yes | `NULL` |  |  |
| `guardiancountry` | `text` | yes | `NULL` |  |  |
| `guardianphone` | `text` | yes | `NULL` |  |  |
| `guardianworkphone` | `text` | yes | `NULL` |  |  |
| `guardianemail` | `text` | yes | `NULL` |  |  |
| `sexual_orientation` | `text` | yes | `NULL` |  |  |
| `gender_identity` | `text` | yes | `NULL` |  |  |
| `birth_fname` | `text` | yes | `NULL` |  |  |
| `birth_lname` | `text` | yes | `NULL` |  |  |
| `birth_mname` | `text` | yes | `NULL` |  |  |
| `dupscore` | `int(11)` | no | `-9` |  |  |
| `name_history` | `tinytext` | yes | `NULL` |  |  |
| `suffix` | `tinytext` | yes | `NULL` |  |  |
| `street_line_2` | `tinytext` | yes | `NULL` |  |  |
| `patient_groups` | `text` | yes | `NULL` |  |  |
| `prevent_portal_apps` | `text` | yes | `NULL` |  |  |
| `provider_since_date` | `tinytext` | yes | `NULL` |  |  |
| `created_by` | `bigint(20)` | yes | `NULL` |  | users.id the user that first created this record |
| `updated_by` | `bigint(20)` | yes | `NULL` |  | users.id the user that last modified this record |
| `preferred_name` | `tinytext` | yes | `NULL` |  |  |
| `nationality_country` | `tinytext` | yes | `NULL` |  |  |
| `last_updated` | `datetime` | no | `current_timestamp()` | on update current_timestamp() |  |
| `tribal_affiliations` | `text` | yes | `NULL` |  |  |
| `sex_identified` | `text` | yes | `NULL` |  | Patient reported current sex |
| `pronoun` | `text` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `id` |  | `id` |
| `idx_patient_dob` |  | `DOB` |
| `idx_patient_name` |  | `lname`, `fname` |
| `pid` | yes | `pid` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

- **7.0.2:** added `preferred_name` tinytext; added `nationality_country` tinytext
- **7.0.3:** added `last_updated` datetime
- **7.0.4:** added `interpreter_needed` text; added `advance_directive_user_authenticator` bigint(20); added `tribal_affiliations` text; added `sex_identified` text; `ad_reviewed` type date → datetime; index `idx_patient_dob` added (DOB); index `idx_patient_name` added (lname, fname)
- **8.0.0:** added `pronoun` text
- **8.1.0:** added `interpreter` varchar(255); removed `interpretter`

---

*Generated by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
