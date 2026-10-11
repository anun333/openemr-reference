# `oauth_clients`

As OpenEMR 8.4.1's `sql/database.sql` creates it. Engine InnoDB.

## Columns

| Column | Type | Null | Default | Extra | Comment |
|---|---|---|---|---|---|
| `client_id` | `varchar(80)` | no |  |  |  |
| `client_role` | `varchar(20)` | yes | `NULL` |  |  |
| `client_name` | `varchar(80)` | no |  |  |  |
| `client_secret` | `text` | yes | `NULL` |  |  |
| `registration_token` | `varchar(80)` | yes | `NULL` |  |  |
| `registration_uri_path` | `varchar(40)` | yes | `NULL` |  |  |
| `register_date` | `datetime` | yes | `NULL` |  |  |
| `revoke_date` | `datetime` | yes | `NULL` |  |  |
| `contacts` | `text` | yes | `NULL` |  |  |
| `redirect_uri` | `text` | yes | `NULL` |  |  |
| `grant_types` | `varchar(80)` | yes | `NULL` |  |  |
| `scope` | `text` | yes | `NULL` |  |  |
| `user_id` | `varchar(40)` | yes | `NULL` |  |  |
| `site_id` | `varchar(64)` | yes | `NULL` |  |  |
| `is_confidential` | `tinyint(1)` | no | `1` |  |  |
| `logout_redirect_uris` | `text` | yes | `NULL` |  |  |
| `jwks_uri` | `text` | yes | `NULL` |  |  |
| `jwks` | `text` | yes | `NULL` |  |  |
| `initiate_login_uri` | `text` | yes | `NULL` |  |  |
| `endorsements` | `text` | yes | `NULL` |  |  |
| `policy_uri` | `text` | yes | `NULL` |  |  |
| `tos_uri` | `text` | yes | `NULL` |  |  |
| `is_enabled` | `tinyint(1)` | no | `0` |  |  |
| `skip_ehr_launch_authorization_flow` | `tinyint(1)` | no | `0` |  |  |
| `dsi_type` | `tinyint(3) unsigned` | no | `1` |  | 0=none, 1=evidence-based,2=predictive |

## Indexes

| Index | Unique | Columns |
|---|---|---|
| `PRIMARY` | yes | `client_id` |

## Changes since 7.0.0

- **7.0.2:** added `skip_ehr_launch_authorization_flow` tinyint(1)
- **7.0.3:** added `dsi_type` tinyint(3) unsigned

---

*Generated 2026-10-11 by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
