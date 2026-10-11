# `care_team_member`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB. Stores members of a care team for a patient

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `id` | `int(11)` | no |  | auto_increment |  |
| `care_team_id` | `int(11)` | no |  |  |  |
| `user_id` | `bigint(20)` | yes | `NULL` |  | fk to users.id represents a provider or staff member |
| `contact_id` | `bigint(20)` | yes | `NULL` |  | fk to contact.id which represents a contact person not in users or facility table |
| `role` | `varchar(50)` | no |  |  | fk to list_options.option_id WHERE list_id=care_team_roles |
| `facility_id` | `bigint(20)` | yes | `NULL` |  | fk to facility.id represents an organization or location |
| `provider_since` | `date` | yes | `NULL` |  |  |
| `status` | `varchar(100)` | yes | `'active'` |  | fk to list_options.option_id where list_id=Care_Team_Status |
| `date_created` | `datetime` | yes | `current_timestamp()` |  |  |
| `date_updated` | `datetime` | yes | `current_timestamp()` | on update current_timestamp() |  |
| `created_by` | `bigint(20)` | yes | `NULL` |  | fk to users.id and is the user that added this team member |
| `updated_by` | `bigint(20)` | yes | `NULL` |  | fk to users.id and is the user that last updated this team member |
| `note` | `text` | yes | `NULL` |  |  |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `id` |
| `care_team_member_unique` | yes | `care_team_id`, `user_id`, `facility_id`, `contact_id` |

## Changes since 7.0.0

- **7.0.4:** table added

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
