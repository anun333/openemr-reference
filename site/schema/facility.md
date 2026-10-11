# `facility`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no |  | auto_increment |  |
| `uuid` | `binary(16)` | yes | `NULL` |  |  |
| `name` | `varchar(255)` | yes | `NULL` |  |  |
| `phone` | `varchar(30)` | yes | `NULL` |  |  |
| `fax` | `varchar(30)` | yes | `NULL` |  |  |
| `street` | `varchar(255)` | yes | `NULL` |  |  |
| `city` | `varchar(255)` | yes | `NULL` |  |  |
| `state` | `varchar(50)` | yes | `NULL` |  |  |
| `postal_code` | `varchar(11)` | yes | `NULL` |  |  |
| `country_code` | `varchar(30)` | no | `''` |  |  |
| `federal_ein` | `varchar(15)` | yes | `NULL` |  |  |
| `website` | `varchar(255)` | yes | `NULL` |  |  |
| `email` | `varchar(255)` | yes | `NULL` |  |  |
| `service_location` | `tinyint(1)` | no | `1` |  |  |
| `billing_location` | `tinyint(1)` | no | `1` |  |  |
| `accepts_assignment` | `tinyint(1)` | no | `1` |  |  |
| `pos_code` | `tinyint(4)` | yes | `NULL` |  |  |
| `x12_sender_id` | `varchar(25)` | yes | `NULL` |  |  |
| `attn` | `varchar(65)` | yes | `NULL` |  |  |
| `domain_identifier` | `varchar(60)` | yes | `NULL` |  |  |
| `facility_npi` | `varchar(15)` | yes | `NULL` |  |  |
| `facility_taxonomy` | `varchar(15)` | yes | `NULL` |  |  |
| `tax_id_type` | `varchar(31)` | no | `''` |  |  |
| `color` | `varchar(7)` | no | `''` |  |  |
| `primary_business_entity` | `int(10)` | no | `1` |  | 0-Not Set as business entity 1-Set as business entity |
| `facility_code` | `varchar(31)` | yes | `NULL` |  |  |
| `extra_validation` | `tinyint(1)` | no | `1` |  |  |
| `mail_street` | `varchar(30)` | yes | `NULL` |  |  |
| `mail_street2` | `varchar(30)` | yes | `NULL` |  |  |
| `mail_city` | `varchar(50)` | yes | `NULL` |  |  |
| `mail_state` | `varchar(3)` | yes | `NULL` |  |  |
| `mail_zip` | `varchar(10)` | yes | `NULL` |  |  |
| `oid` | `varchar(255)` | no | `''` |  | HIEs CCDA and FHIR an OID is required/wanted |
| `iban` | `varchar(50)` | yes | `NULL` |  |  |
| `info` | `text` | yes | `NULL` |  |  |
| `weno_id` | `varchar(10)` | yes | `NULL` |  |  |
| `inactive` | `tinyint(1)` | no | `0` |  |  |
| `date_created` | `datetime` | no | `current_timestamp()` |  |  |
| `last_updated` | `datetime` | no | `current_timestamp()` | on update current_timestamp() |  |
| `organization_type` | `varchar(50)` | no | `'prov'` |  | Organization type as defined by HL7 Value Set: OrganizationType |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `uuid` | yes | `uuid` |

## Changes since 7.0.0

- **7.0.2:** added `inactive` tinyint(1)
- **7.0.3:** added `date_created` datetime; added `last_updated` datetime
- **8.1.0:** added `organization_type` varchar(50)

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
