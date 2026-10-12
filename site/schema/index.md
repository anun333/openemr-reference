# Database schema, OpenEMR 8.4.1

283 tables, as a fresh install creates them (`sql/database.sql` loaded into MariaDB and read back). Modules add their own tables when installed; those aren't here.

| Table | Columns | Since | Comment |
|---|---|---|---|
| [`addresses`](addresses.md) | 10 | 7.0.0 or earlier |  |
| [`amc_misc_data`](amc_misc_data.md) | 7 | 7.0.0 or earlier |  |
| [`amendments`](amendments.md) | 10 | 7.0.0 or earlier |  |
| [`amendments_history`](amendments_history.md) | 5 | 7.0.0 or earlier |  |
| [`api_log`](api_log.md) | 12 | 7.0.0 or earlier |  |
| [`api_refresh_token`](api_refresh_token.md) | 6 | 7.0.0 or earlier | Holds information about api refresh tokens. |
| [`api_token`](api_token.md) | 8 | 7.0.0 or earlier |  |
| [`ar_activity`](ar_activity.md) | 21 | 7.0.0 or earlier |  |
| [`ar_session`](ar_session.md) | 17 | 7.0.0 or earlier |  |
| [`audit_details`](audit_details.md) | 6 | 7.0.0 or earlier |  |
| [`audit_master`](audit_master.md) | 11 | 7.0.0 or earlier |  |
| [`automatic_notification`](automatic_notification.md) | 7 | 7.0.0 or earlier |  |
| [`background_services`](background_services.md) | 10 | 7.0.0 or earlier |  |
| [`batchcom`](batchcom.md) | 7 | 7.0.0 or earlier |  |
| [`benefit_eligibility`](benefit_eligibility.md) | 18 | 7.0.0 or earlier |  |
| [`billing`](billing.md) | 30 | 7.0.0 or earlier |  |
| [`calendar_external`](calendar_external.md) | 4 | 7.0.0 or earlier |  |
| [`care_team_member`](care_team_member.md) | 13 | 7.0.4 | Stores members of a care team for a patient |
| [`care_teams`](care_teams.md) | 10 | 7.0.4 |  |
| [`categories`](categories.md) | 8 | 7.0.0 or earlier |  |
| [`categories_seq`](categories_seq.md) | 1 | 7.0.0 or earlier |  |
| [`categories_to_documents`](categories_to_documents.md) | 2 | 7.0.0 or earlier |  |
| [`ccda`](ccda.md) | 17 | 7.0.0 or earlier |  |
| [`ccda_components`](ccda_components.md) | 4 | 7.0.0 or earlier |  |
| [`ccda_field_mapping`](ccda_field_mapping.md) | 3 | 7.0.0 or earlier |  |
| [`ccda_sections`](ccda_sections.md) | 5 | 7.0.0 or earlier |  |
| [`ccda_table_mapping`](ccda_table_mapping.md) | 9 | 7.0.0 or earlier |  |
| [`chart_tracker`](chart_tracker.md) | 4 | 7.0.0 or earlier |  |
| [`claims`](claims.md) | 13 | 7.0.0 or earlier |  |
| [`clinical_notes_documents`](clinical_notes_documents.md) | 5 | 7.0.4 | Links clinical notes to patient documents |
| [`clinical_notes_procedure_results`](clinical_notes_procedure_results.md) | 5 | 7.0.4 | Links clinical notes to procedure results/lab values |
| [`clinical_plans`](clinical_plans.md) | 7 | 7.0.0 or earlier |  |
| [`clinical_plans_rules`](clinical_plans_rules.md) | 2 | 7.0.0 or earlier |  |
| [`clinical_rules`](clinical_rules.md) | 35 | 7.0.0 or earlier |  |
| [`clinical_rules_log`](clinical_rules_log.md) | 8 | 7.0.0 or earlier |  |
| [`code_types`](code_types.md) | 18 | 7.0.0 or earlier |  |
| [`codes`](codes.md) | 16 | 7.0.0 or earlier |  |
| [`codes_history`](codes_history.md) | 14 | 7.0.0 or earlier |  |
| [`contact`](contact.md) | 3 | 7.0.0 or earlier |  |
| [`contact_address`](contact_address.md) | 16 | 7.0.0 or earlier |  |
| [`contact_relation`](contact_relation.md) | 19 | 7.0.4 |  |
| [`contact_telecom`](contact_telecom.md) | 16 | 7.0.4 |  |
| [`customlists`](customlists.md) | 10 | 7.0.0 or earlier |  |
| [`dated_reminders`](dated_reminders.md) | 10 | 7.0.0 or earlier |  |
| [`dated_reminders_link`](dated_reminders_link.md) | 3 | 7.0.0 or earlier |  |
| [`direct_message_log`](direct_message_log.md) | 11 | 7.0.0 or earlier |  |
| [`document_template_profiles`](document_template_profiles.md) | 14 | 7.0.0 or earlier |  |
| [`document_templates`](document_templates.md) | 15 | 7.0.0 or earlier |  |
| [`documents`](documents.md) | 33 | 7.0.0 or earlier |  |
| [`documents_legal_categories`](documents_legal_categories.md) | 4 | 7.0.0 or earlier |  |
| [`documents_legal_detail`](documents_legal_detail.md) | 17 | 7.0.0 or earlier |  |
| [`documents_legal_master`](documents_legal_master.md) | 16 | 7.0.0 or earlier | List of Master Docs to be signed |
| [`drug_inventory`](drug_inventory.md) | 13 | 7.0.0 or earlier |  |
| [`drug_sales`](drug_sales.md) | 25 | 7.0.0 or earlier |  |
| [`drug_templates`](drug_templates.md) | 8 | 7.0.0 or earlier |  |
| [`drugs`](drugs.md) | 24 | 7.0.0 or earlier |  |
| [`dsi_source_attributes`](dsi_source_attributes.md) | 10 | 7.0.3 | Holds information about decision support intervention system source attributes |
| [`edi_sequences`](edi_sequences.md) | 1 | 7.0.2 |  |
| [`eligibility_verification`](eligibility_verification.md) | 8 | 7.0.0 or earlier |  |
| [`email_queue`](email_queue.md) | 12 | 7.0.2 |  |
| [`employer_data`](employer_data.md) | 16 | 7.0.0 or earlier |  |
| [`enc_category_map`](enc_category_map.md) | 2 | 7.0.0 or earlier |  |
| [`erx_narcotics`](erx_narcotics.md) | 6 | 7.0.0 or earlier |  |
| [`erx_rx_log`](erx_rx_log.md) | 8 | 7.0.0 or earlier |  |
| [`erx_ttl_touch`](erx_ttl_touch.md) | 3 | 7.0.0 or earlier | Store records last update per patient data process |
| [`esign_signatures`](esign_signatures.md) | 9 | 7.0.0 or earlier |  |
| [`export_job`](export_job.md) | 13 | 7.0.0 or earlier | fhir export jobs |
| [`extended_log`](extended_log.md) | 7 | 7.0.0 or earlier |  |
| [`external_encounters`](external_encounters.md) | 7 | 7.0.0 or earlier |  |
| [`external_procedures`](external_procedures.md) | 9 | 7.0.0 or earlier |  |
| [`facility`](facility.md) | 40 | 7.0.0 or earlier |  |
| [`facility_user_ids`](facility_user_ids.md) | 8 | 7.0.0 or earlier |  |
| [`fee_schedule`](fee_schedule.md) | 8 | 7.0.2 |  |
| [`fee_sheet_options`](fee_sheet_options.md) | 3 | 7.0.0 or earlier |  |
| [`form_care_plan`](form_care_plan.md) | 23 | 7.0.0 or earlier |  |
| [`form_clinical_instructions`](form_clinical_instructions.md) | 7 | 7.0.0 or earlier |  |
| [`form_clinical_notes`](form_clinical_notes.md) | 18 | 7.0.0 or earlier |  |
| [`form_dictation`](form_dictation.md) | 9 | 7.0.0 or earlier |  |
| [`form_encounter`](form_encounter.md) | 35 | 7.0.0 or earlier |  |
| [`form_eye_acuity`](form_eye_acuity.md) | 30 | 7.0.0 or earlier |  |
| [`form_eye_antseg`](form_eye_antseg.md) | 39 | 7.0.0 or earlier |  |
| [`form_eye_base`](form_eye_base.md) | 7 | 7.0.0 or earlier |  |
| [`form_eye_biometrics`](form_eye_biometrics.md) | 18 | 7.0.0 or earlier |  |
| [`form_eye_external`](form_eye_external.md) | 30 | 7.0.0 or earlier |  |
| [`form_eye_hpi`](form_eye_hpi.md) | 35 | 7.0.0 or earlier |  |
| [`form_eye_locking`](form_eye_locking.md) | 9 | 7.0.0 or earlier |  |
| [`form_eye_mag_dispense`](form_eye_mag_dispense.md) | 55 | 7.0.0 or earlier |  |
| [`form_eye_mag_impplan`](form_eye_mag_impplan.md) | 11 | 7.0.0 or earlier |  |
| [`form_eye_mag_orders`](form_eye_mag_orders.md) | 10 | 7.0.0 or earlier |  |
| [`form_eye_mag_prefs`](form_eye_mag_prefs.md) | 12 | 7.0.0 or earlier |  |
| [`form_eye_mag_wearing`](form_eye_mag_wearing.md) | 41 | 7.0.0 or earlier |  |
| [`form_eye_neuro`](form_eye_neuro.md) | 81 | 7.0.0 or earlier |  |
| [`form_eye_postseg`](form_eye_postseg.md) | 25 | 7.0.0 or earlier |  |
| [`form_eye_refraction`](form_eye_refraction.md) | 65 | 7.0.0 or earlier |  |
| [`form_eye_ros`](form_eye_ros.md) | 15 | 7.0.0 or earlier |  |
| [`form_eye_vitals`](form_eye_vitals.md) | 27 | 7.0.0 or earlier |  |
| [`form_functional_cognitive_status`](form_functional_cognitive_status.md) | 12 | 7.0.0 or earlier |  |
| [`form_group_attendance`](form_group_attendance.md) | 8 | 7.0.0 or earlier |  |
| [`form_groups_encounter`](form_groups_encounter.md) | 24 | 7.0.0 or earlier |  |
| [`form_history_sdoh`](form_history_sdoh.md) | 49 | 7.0.4 |  |
| [`form_history_sdoh_health_concerns`](form_history_sdoh_health_concerns.md) | 5 | 7.0.4 | Links SDOH assessments to health concern conditions |
| [`form_misc_billing_options`](form_misc_billing_options.md) | 34 | 7.0.0 or earlier |  |
| [`form_observation`](form_observation.md) | 31 | 7.0.0 or earlier |  |
| [`form_questionnaire_assessments`](form_questionnaire_assessments.md) | 17 | 7.0.1 |  |
| [`form_reviewofs`](form_reviewofs.md) | 115 | 7.0.0 or earlier |  |
| [`form_ros`](form_ros.md) | 142 | 7.0.0 or earlier |  |
| [`form_soap`](form_soap.md) | 11 | 7.0.0 or earlier |  |
| [`form_taskman`](form_taskman.md) | 13 | 7.0.0 or earlier |  |
| [`form_vital_details`](form_vital_details.md) | 10 | 7.0.0 or earlier | Detailed information of each vital_forms observation column |
| [`form_vitals`](form_vitals.md) | 29 | 7.0.0 or earlier |  |
| [`form_vitals_calculation`](form_vitals_calculation.md) | 11 | 7.0.4 | Main calculation records - one per logical calculation (e.g., average BP) |
| [`form_vitals_calculation_components`](form_vitals_calculation_components.md) | 7 | 7.0.4 | Component values for calculations (e.g., systolic=120, diastolic=80) |
| [`form_vitals_calculation_form_vitals`](form_vitals_calculation_form_vitals.md) | 2 | 7.0.4 | Join table between form_vitals_calculation and form_vitals table representing the derivative observation relationship between the calculation and the source records |
| [`forms`](forms.md) | 14 | 7.0.0 or earlier |  |
| [`gacl_acl`](gacl_acl.md) | 7 | 7.0.0 or earlier |  |
| [`gacl_acl_sections`](gacl_acl_sections.md) | 5 | 7.0.0 or earlier |  |
| [`gacl_acl_seq`](gacl_acl_seq.md) | 1 | 7.0.0 or earlier |  |
| [`gacl_aco`](gacl_aco.md) | 6 | 7.0.0 or earlier |  |
| [`gacl_aco_map`](gacl_aco_map.md) | 3 | 7.0.0 or earlier |  |
| [`gacl_aco_sections`](gacl_aco_sections.md) | 5 | 7.0.0 or earlier |  |
| [`gacl_aco_sections_seq`](gacl_aco_sections_seq.md) | 1 | 7.0.0 or earlier |  |
| [`gacl_aco_seq`](gacl_aco_seq.md) | 1 | 7.0.0 or earlier |  |
| [`gacl_aro`](gacl_aro.md) | 6 | 7.0.0 or earlier |  |
| [`gacl_aro_groups`](gacl_aro_groups.md) | 6 | 7.0.0 or earlier |  |
| [`gacl_aro_groups_id_seq`](gacl_aro_groups_id_seq.md) | 1 | 7.0.0 or earlier |  |
| [`gacl_aro_groups_map`](gacl_aro_groups_map.md) | 2 | 7.0.0 or earlier |  |
| [`gacl_aro_map`](gacl_aro_map.md) | 3 | 7.0.0 or earlier |  |
| [`gacl_aro_sections`](gacl_aro_sections.md) | 5 | 7.0.0 or earlier |  |
| [`gacl_aro_sections_seq`](gacl_aro_sections_seq.md) | 1 | 7.0.0 or earlier |  |
| [`gacl_aro_seq`](gacl_aro_seq.md) | 1 | 7.0.0 or earlier |  |
| [`gacl_axo`](gacl_axo.md) | 6 | 7.0.0 or earlier |  |
| [`gacl_axo_groups`](gacl_axo_groups.md) | 6 | 7.0.0 or earlier |  |
| [`gacl_axo_groups_map`](gacl_axo_groups_map.md) | 2 | 7.0.0 or earlier |  |
| [`gacl_axo_map`](gacl_axo_map.md) | 3 | 7.0.0 or earlier |  |
| [`gacl_axo_sections`](gacl_axo_sections.md) | 5 | 7.0.0 or earlier |  |
| [`gacl_groups_aro_map`](gacl_groups_aro_map.md) | 2 | 7.0.0 or earlier |  |
| [`gacl_groups_axo_map`](gacl_groups_axo_map.md) | 2 | 7.0.0 or earlier |  |
| [`gacl_phpgacl`](gacl_phpgacl.md) | 2 | 7.0.0 or earlier |  |
| [`globals`](globals.md) | 3 | 7.0.0 or earlier |  |
| [`gprelations`](gprelations.md) | 4 | 7.0.0 or earlier | general purpose relations |
| [`groups`](groups.md) | 3 | 7.0.0 or earlier |  |
| [`history_data`](history_data.md) | 91 | 7.0.0 or earlier |  |
| [`icd10_dx_order_code`](icd10_dx_order_code.md) | 8 | 7.0.0 or earlier |  |
| [`icd10_gem_dx_10_9`](icd10_gem_dx_10_9.md) | 6 | 7.0.0 or earlier |  |
| [`icd10_gem_dx_9_10`](icd10_gem_dx_9_10.md) | 6 | 7.0.0 or earlier |  |
| [`icd10_gem_pcs_10_9`](icd10_gem_pcs_10_9.md) | 6 | 7.0.0 or earlier |  |
| [`icd10_gem_pcs_9_10`](icd10_gem_pcs_9_10.md) | 6 | 7.0.0 or earlier |  |
| [`icd10_pcs_order_code`](icd10_pcs_order_code.md) | 7 | 7.0.0 or earlier |  |
| [`icd10_reimbr_dx_9_10`](icd10_reimbr_dx_9_10.md) | 11 | 7.0.0 or earlier |  |
| [`icd10_reimbr_pcs_9_10`](icd10_reimbr_pcs_9_10.md) | 11 | 7.0.0 or earlier |  |
| [`icd9_dx_code`](icd9_dx_code.md) | 7 | 7.0.0 or earlier |  |
| [`icd9_dx_long_code`](icd9_dx_long_code.md) | 5 | 7.0.0 or earlier |  |
| [`icd9_sg_code`](icd9_sg_code.md) | 7 | 7.0.0 or earlier |  |
| [`icd9_sg_long_code`](icd9_sg_long_code.md) | 5 | 7.0.0 or earlier |  |
| [`immunization_observation`](immunization_observation.md) | 12 | 7.0.0 or earlier |  |
| [`immunizations`](immunizations.md) | 31 | 7.0.0 or earlier |  |
| [`insurance_companies`](insurance_companies.md) | 15 | 7.0.0 or earlier |  |
| [`insurance_data`](insurance_data.md) | 34 | 7.0.0 or earlier |  |
| [`insurance_numbers`](insurance_numbers.md) | 8 | 7.0.0 or earlier |  |
| [`insurance_type_codes`](insurance_type_codes.md) | 3 | 7.0.0 or earlier |  |
| [`ip_tracking`](ip_tracking.md) | 8 | 7.0.2 |  |
| [`issue_encounter`](issue_encounter.md) | 10 | 7.0.0 or earlier |  |
| [`issue_types`](issue_types.md) | 10 | 7.0.0 or earlier |  |
| [`jwt_grant_history`](jwt_grant_history.md) | 5 | 7.0.0 or earlier | Holds JWT authorization grant ids to prevent replay attacks |
| [`keys`](keys.md) | 3 | 7.0.0 or earlier |  |
| [`lang_constants`](lang_constants.md) | 2 | 7.0.0 or earlier |  |
| [`lang_custom`](lang_custom.md) | 4 | 7.0.0 or earlier |  |
| [`lang_definitions`](lang_definitions.md) | 4 | 7.0.0 or earlier |  |
| [`lang_languages`](lang_languages.md) | 4 | 7.0.0 or earlier |  |
| [`layout_group_properties`](layout_group_properties.md) | 20 | 7.0.0 or earlier |  |
| [`layout_options`](layout_options.md) | 21 | 7.0.0 or earlier |  |
| [`lbf_data`](lbf_data.md) | 3 | 7.0.0 or earlier | contains all data from layout-based forms |
| [`lbt_data`](lbt_data.md) | 3 | 7.0.0 or earlier | contains all data from layout-based transactions |
| [`list_options`](list_options.md) | 16 | 7.0.0 or earlier |  |
| [`lists`](lists.md) | 36 | 7.0.0 or earlier |  |
| [`lists_medication`](lists_medication.md) | 13 | 7.0.0 or earlier | Holds additional data about patient medications. |
| [`lists_touch`](lists_touch.md) | 3 | 7.0.0 or earlier |  |
| [`log`](log.md) | 15 | 7.0.0 or earlier |  |
| [`log_comment_encrypt`](log_comment_encrypt.md) | 6 | 7.0.0 or earlier |  |
| [`login_mfa_registrations`](login_mfa_registrations.md) | 6 | 7.0.0 or earlier |  |
| [`medex_icons`](medex_icons.md) | 6 | 7.0.0 or earlier |  |
| [`medex_outgoing`](medex_outgoing.md) | 9 | 7.0.0 or earlier |  |
| [`medex_prefs`](medex_prefs.md) | 16 | 7.0.0 or earlier |  |
| [`medex_recalls`](medex_recalls.md) | 8 | 7.0.0 or earlier |  |
| [`migrations`](migrations.md) | 3 | 8.1.0 |  |
| [`misc_address_book`](misc_address_book.md) | 9 | 7.0.0 or earlier |  |
| [`module_acl_group_settings`](module_acl_group_settings.md) | 4 | 7.0.0 or earlier |  |
| [`module_acl_sections`](module_acl_sections.md) | 5 | 7.0.0 or earlier |  |
| [`module_acl_user_settings`](module_acl_user_settings.md) | 4 | 7.0.0 or earlier |  |
| [`module_configuration`](module_configuration.md) | 9 | 7.0.0 or earlier |  |
| [`modules`](modules.md) | 20 | 7.0.0 or earlier |  |
| [`modules_hooks_settings`](modules_hooks_settings.md) | 4 | 7.0.0 or earlier |  |
| [`modules_settings`](modules_settings.md) | 5 | 7.0.0 or earlier |  |
| [`notes`](notes.md) | 6 | 7.0.0 or earlier |  |
| [`notification_log`](notification_log.md) | 15 | 7.0.0 or earlier |  |
| [`notification_settings`](notification_settings.md) | 7 | 7.0.0 or earlier |  |
| [`oauth_clients`](oauth_clients.md) | 25 | 7.0.0 or earlier |  |
| [`oauth_trusted_user`](oauth_trusted_user.md) | 9 | 7.0.0 or earlier |  |
| [`onetime_auth`](onetime_auth.md) | 15 | 7.0.1 |  |
| [`onotes`](onotes.md) | 6 | 7.0.0 or earlier |  |
| [`onsite_documents`](onsite_documents.md) | 20 | 7.0.0 or earlier |  |
| [`onsite_mail`](onsite_mail.md) | 22 | 7.0.0 or earlier |  |
| [`onsite_messages`](onsite_messages.md) | 7 | 7.0.0 or earlier | Portal messages |
| [`onsite_online`](onsite_online.md) | 5 | 7.0.0 or earlier |  |
| [`onsite_portal_activity`](onsite_portal_activity.md) | 14 | 7.0.0 or earlier |  |
| [`onsite_signatures`](onsite_signatures.md) | 15 | 7.0.0 or earlier |  |
| [`openemr_module_vars`](openemr_module_vars.md) | 4 | 7.0.0 or earlier |  |
| [`openemr_modules`](openemr_modules.md) | 11 | 7.0.0 or earlier |  |
| [`openemr_postcalendar_categories`](openemr_postcalendar_categories.md) | 20 | 7.0.0 or earlier |  |
| [`openemr_postcalendar_events`](openemr_postcalendar_events.md) | 39 | 7.0.0 or earlier |  |
| [`patient_access_onsite`](patient_access_onsite.md) | 8 | 7.0.0 or earlier |  |
| [`patient_birthday_alert`](patient_birthday_alert.md) | 3 | 7.0.0 or earlier |  |
| [`patient_care_experience_preferences`](patient_care_experience_preferences.md) | 14 | 7.0.4 |  |
| [`patient_data`](patient_data.md) | 132 | 7.0.0 or earlier |  |
| [`patient_history`](patient_history.md) | 14 | 7.0.0 or earlier |  |
| [`patient_portal_menu`](patient_portal_menu.md) | 5 | 7.0.0 or earlier |  |
| [`patient_reminders`](patient_reminders.md) | 14 | 7.0.0 or earlier |  |
| [`patient_settings`](patient_settings.md) | 3 | 7.0.2 |  |
| [`patient_tracker`](patient_tracker.md) | 11 | 7.0.0 or earlier |  |
| [`patient_tracker_element`](patient_tracker_element.md) | 6 | 7.0.0 or earlier |  |
| [`patient_treatment_intervention_preferences`](patient_treatment_intervention_preferences.md) | 14 | 7.0.4 |  |
| [`payment_gateway_details`](payment_gateway_details.md) | 5 | 7.0.0 or earlier |  |
| [`payment_processing_audit`](payment_processing_audit.md) | 17 | 7.0.0 or earlier |  |
| [`payments`](payments.md) | 11 | 7.0.0 or earlier |  |
| [`person`](person.md) | 24 | 7.0.4 | Core person demographics - contact info in contact_telecom |
| [`person_patient_link`](person_patient_link.md) | 8 | 7.0.4 | Links person records to patient_data records when person becomes patient |
| [`pharmacies`](pharmacies.md) | 6 | 7.0.0 or earlier |  |
| [`phone_numbers`](phone_numbers.md) | 7 | 7.0.0 or earlier |  |
| [`pnotes`](pnotes.md) | 16 | 7.0.0 or earlier |  |
| [`preference_value_sets`](preference_value_sets.md) | 8 | 7.0.4 | Answer lists for preference codes |
| [`prescriptions`](prescriptions.md) | 49 | 7.0.0 or earlier |  |
| [`prices`](prices.md) | 4 | 7.0.0 or earlier |  |
| [`pro_assessments`](pro_assessments.md) | 12 | 7.0.0 or earlier |  |
| [`procedure_answers`](procedure_answers.md) | 6 | 7.0.0 or earlier |  |
| [`procedure_order`](procedure_order.md) | 36 | 7.0.0 or earlier |  |
| [`procedure_order_code`](procedure_order_code.md) | 16 | 7.0.0 or earlier |  |
| [`procedure_order_relationships`](procedure_order_relationships.md) | 7 | 7.0.4 | Links ServiceRequests to supporting clinical information |
| [`procedure_providers`](procedure_providers.md) | 22 | 7.0.0 or earlier |  |
| [`procedure_questions`](procedure_questions.md) | 11 | 7.0.0 or earlier |  |
| [`procedure_report`](procedure_report.md) | 13 | 7.0.0 or earlier |  |
| [`procedure_result`](procedure_result.md) | 16 | 7.0.0 or earlier |  |
| [`procedure_specimen`](procedure_specimen.md) | 25 | 7.0.4 |  |
| [`procedure_type`](procedure_type.md) | 20 | 7.0.0 or earlier |  |
| [`product_registration`](product_registration.md) | 8 | 7.0.0 or earlier |  |
| [`product_warehouse`](product_warehouse.md) | 4 | 7.0.0 or earlier |  |
| [`questionnaire_repository`](questionnaire_repository.md) | 18 | 7.0.1 |  |
| [`questionnaire_response`](questionnaire_response.md) | 20 | 7.0.1 |  |
| [`recent_patients`](recent_patients.md) | 2 | 7.0.2 |  |
| [`registry`](registry.md) | 14 | 7.0.0 or earlier |  |
| [`report_itemized`](report_itemized.md) | 7 | 7.0.0 or earlier |  |
| [`report_results`](report_results.md) | 3 | 7.0.0 or earlier |  |
| [`rule_action`](rule_action.md) | 4 | 7.0.0 or earlier |  |
| [`rule_action_item`](rule_action_item.md) | 5 | 7.0.0 or earlier |  |
| [`rule_filter`](rule_filter.md) | 6 | 7.0.0 or earlier |  |
| [`rule_patient_data`](rule_patient_data.md) | 7 | 7.0.0 or earlier |  |
| [`rule_reminder`](rule_reminder.md) | 4 | 7.0.0 or earlier |  |
| [`rule_target`](rule_target.md) | 7 | 7.0.0 or earlier |  |
| [`sequences`](sequences.md) | 1 | 7.0.0 or earlier |  |
| [`session_tracker`](session_tracker.md) | 4 | 7.0.0 or earlier |  |
| [`shared_attributes`](shared_attributes.md) | 6 | 7.0.0 or earlier |  |
| [`standardized_tables_track`](standardized_tables_track.md) | 6 | 7.0.0 or earlier |  |
| [`supported_external_dataloads`](supported_external_dataloads.md) | 6 | 7.0.0 or earlier |  |
| [`syndromic_surveillance`](syndromic_surveillance.md) | 4 | 7.0.0 or earlier |  |
| [`template_users`](template_users.md) | 5 | 7.0.0 or earlier |  |
| [`therapy_groups`](therapy_groups.md) | 9 | 7.0.0 or earlier |  |
| [`therapy_groups_counselors`](therapy_groups_counselors.md) | 2 | 7.0.0 or earlier |  |
| [`therapy_groups_participant_attendance`](therapy_groups_participant_attendance.md) | 4 | 7.0.0 or earlier |  |
| [`therapy_groups_participants`](therapy_groups_participants.md) | 6 | 7.0.0 or earlier |  |
| [`track_events`](track_events.md) | 8 | 7.0.4 | Telemetry Event Data |
| [`transactions`](transactions.md) | 7 | 7.0.0 or earlier |  |
| [`user_settings`](user_settings.md) | 3 | 7.0.0 or earlier |  |
| [`users`](users.md) | 66 | 7.0.0 or earlier |  |
| [`users_facility`](users_facility.md) | 4 | 7.0.0 or earlier | joins users or patient_data to facility table |
| [`users_secure`](users_secure.md) | 15 | 7.0.0 or earlier |  |
| [`uuid_mapping`](uuid_mapping.md) | 7 | 7.0.0 or earlier |  |
| [`uuid_registry`](uuid_registry.md) | 8 | 7.0.0 or earlier |  |
| [`valueset`](valueset.md) | 7 | 7.0.0 or earlier |  |
| [`valueset_oid`](valueset_oid.md) | 7 | 7.0.0 or earlier |  |
| [`verify_email`](verify_email.md) | 10 | 7.0.0 or earlier |  |
| [`version`](version.md) | 7 | 7.0.0 or earlier |  |
| [`voids`](voids.md) | 12 | 7.0.0 or earlier |  |
| [`x12_partners`](x12_partners.md) | 32 | 7.0.0 or earlier |  |
| [`x12_remote_tracker`](x12_remote_tracker.md) | 8 | 7.0.0 or earlier |  |

## Removed since 7.0.0

- `erx_weno_drugs`
- `multiple_db`

---

*Generated by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
