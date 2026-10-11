# `users`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `bigint(20)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `username` | `varchar(255)` | yes | `NULL` |  |  |
| `password` | `longtext` | yes | `NULL` |  |  |
| `authorized` | `tinyint(4)` | yes | `NULL` |  |  |
| `info` | `longtext` | yes | `NULL` |  |  |
| `source` | `tinyint(4)` | yes | `NULL` |  |  |
| `fname` | `varchar(255)` | yes | `NULL` |  |  |
| `mname` | `varchar(255)` | yes | `NULL` |  |  |
| `lname` | `varchar(255)` | yes | `NULL` |  |  |
| `suffix` | `varchar(255)` | yes | `NULL` |  |  |
| `federaltaxid` | `varchar(255)` | yes | `NULL` |  |  |
| `federaldrugid` | `varchar(255)` | yes | `NULL` |  |  |
| `upin` | `varchar(255)` | yes | `NULL` |  |  |
| `facility` | `varchar(255)` | yes | `NULL` |  |  |
| `facility_id` | `int(11)` | no | `0` |  |  |
| `see_auth` | `int(11)` | no | `1` |  |  |
| `active` | `tinyint(1)` | no | `1` |  |  |
| `npi` | `varchar(15)` | yes | `NULL` |  |  |
| `title` | `varchar(30)` | yes | `NULL` |  |  |
| `specialty` | `varchar(255)` | yes | `NULL` |  |  |
| `billname` | `varchar(255)` | yes | `NULL` |  |  |
| `email` | `varchar(255)` | yes | `NULL` |  |  |
| `email_direct` | `varchar(255)` | no | `''` |  |  |
| `google_signin_email` | `varchar(255)` | yes | `NULL` |  |  |
| `url` | `varchar(255)` | yes | `NULL` |  |  |
| `assistant` | `varchar(255)` | yes | `NULL` |  |  |
| `organization` | `varchar(255)` | yes | `NULL` |  |  |
| `valedictory` | `varchar(255)` | yes | `NULL` |  |  |
| `street` | `varchar(60)` | yes | `NULL` |  |  |
| `streetb` | `varchar(60)` | yes | `NULL` |  |  |
| `city` | `varchar(30)` | yes | `NULL` |  |  |
| `state` | `varchar(30)` | yes | `NULL` |  |  |
| `zip` | `varchar(20)` | yes | `NULL` |  |  |
| `country_code` | `varchar(255)` | yes | `NULL` |  | ISO 3166-1 alpha-2 country code for address but can take entire country name for now |
| `street2` | `varchar(60)` | yes | `NULL` |  |  |
| `streetb2` | `varchar(60)` | yes | `NULL` |  |  |
| `city2` | `varchar(30)` | yes | `NULL` |  |  |
| `state2` | `varchar(30)` | yes | `NULL` |  |  |
| `zip2` | `varchar(20)` | yes | `NULL` |  |  |
| `country_code2` | `varchar(255)` | yes | `NULL` |  | ISO 3166-1 alpha-2 country code for address but can take entire country name for now |
| `phone` | `varchar(30)` | yes | `NULL` |  |  |
| `fax` | `varchar(30)` | yes | `NULL` |  |  |
| `phonew1` | `varchar(30)` | yes | `NULL` |  |  |
| `phonew2` | `varchar(30)` | yes | `NULL` |  |  |
| `phonecell` | `varchar(30)` | yes | `NULL` |  |  |
| `notes` | `text` | yes | `NULL` |  |  |
| `cal_ui` | `tinyint(4)` | no | `1` |  |  |
| `taxonomy` | `varchar(30)` | no | `'207Q00000X'` |  |  |
| `calendar` | `tinyint(1)` | no | `0` |  | 1 = appears in calendar |
| `abook_type` | `varchar(31)` | no | `''` |  |  |
| `default_warehouse` | `varchar(31)` | no | `''` |  |  |
| `irnpool` | `varchar(31)` | no | `''` |  |  |
| `state_license_number` | `varchar(25)` | yes | `NULL` |  |  |
| `weno_prov_id` | `varchar(15)` | yes | `NULL` |  |  |
| `newcrop_user_role` | `varchar(30)` | yes | `NULL` |  |  |
| `cpoe` | `tinyint(1)` | yes | `NULL` |  |  |
| `physician_type` | `varchar(50)` | yes | `NULL` |  |  |
| `main_menu_role` | `varchar(50)` | no | `'standard'` |  |  |
| `patient_menu_role` | `varchar(50)` | no | `'standard'` |  |  |
| `portal_user` | `tinyint(1)` | no | `0` |  |  |
| `supervisor_id` | `int(11)` | no | `0` |  |  |
| `billing_facility` | `text` | yes | `NULL` |  |  |
| `billing_facility_id` | `int(11)` | no | `0` |  |  |
| `date_created` | `datetime` | no | `current_timestamp()` |  |  |
| `last_updated` | `datetime` | no | `current_timestamp()` | on update current_timestamp() |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `abook_type` |  | `abook_type` |
| `google_signin_email` | yes | `google_signin_email` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

- **7.0.3:** added `date_created` datetime; added `last_updated` datetime
- **7.0.4:** added `country_code` varchar(255); added `country_code2` varchar(255)

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
