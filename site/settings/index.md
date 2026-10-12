# Settings, OpenEMR 8.4.1

Every setting under Administration > Config, from `library/globals.inc.php`. A default shown as *set at run time* is computed when OpenEMR starts. Modules add their own settings when they're enabled (Care Coordination adds six in its own section, for example); those aren't here.

## Appearance

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `theme_tabs_layout` | Tabs Layout Theme* | tabs_css | `tabs_style_full.css` | Theme of the tabs layout (need to logout and then login to see this new setting). |  |
| `css_header` | General Theme* | css | `style_light.css` | Pick a general theme (need to logout/login after changing this setting). |  |
| `hide_dashboard_cards` | Hide selected cards on patient dashboard | m_dashboard_cards |  | Multi (Shift or CTRL) Select the cards you want to hide on the patient dashboard. | 7.0.3 |
| `window_title_add_patient_name` | Add Patient Name To Window Title | bool | `0` | Adds the patient name to the end of the window title. |  |
| `enable_compact_mode` | Enable Compact Mode | bool | `0` | Changes the current theme to be more compact. |  |
| `search_any_patient` | Search Patient By Any Demographics | one of: `dual` Dual; `comprehensive` Comprehensive; `fixed` Fixed; `none` None | `dual` | Search Patient By Any Demographics, Dual additionally lets direct access to Patient Finder, Comprehensive has collapsed input box, Fixed is similar to Dual with fixed size, None is do not show |  |
| `default_encounter_view` | Default Encounter View | one of: `0` Clinical View; `1` Billing View | `0` | Choose your default encounter view |  |
| `enable_group_therapy` | Enable Group Therapy | bool | `0` | Enables groups module in system. |  |
| `full_new_patient_form` | New Patient Form | one of: `0` Old-style static form without search or duplication check; `1` All demographics fields, with search and duplication check; `2` Mandatory or specified fields only, search and dup check; `3` Mandatory or specified fields only, dup check, no search; `4` Mandatory or specified fields only, use patient validation Zend module | `1` | Style of form used for adding new patients |  |
| `gbl_edit_patient_form` | Modify Patient Form | one of: `0` Standard check; `1` Zend Module check in addition to standard check | `0` | Validation mechanism for when modifying patient demographics. |  |
| `patient_search_results_style` | Patient Search Results Style | one of: `0` Encounter statistics; `1` Mandatory and specified fields | `0` | Type of columns displayed for patient search results |  |
| `simplified_prescriptions` | Simplified Prescriptions | bool | `0` | Omit form, route and interval which then become part of dosage |  |
| `simplified_copay` | Simplified Co-Pay | bool | `0` | Omit method of payment from the co-pay panel |  |
| `use_charges_panel` | Use Charges Panel | bool | `0` | Enables the old Charges panel for entering billing codes and payments. Not recommended, use the Fee Sheet instead. |  |
| `enable_fees_in_left_menu` | Enable Fees Submenu | bool | `1` | Enable Fees Submenu |  |
| `enable_batch_payment` | Enable Batch Payment | bool | `1` | Enable Batch Payment |  |
| `enable_posting` | Enable Posting | bool | `1` | Enable Posting |  |
| `enable_edihistory_in_left_menu` | Enable EDI History | bool | `1` | EDI History (under Fees) for storing and interpreting EDI claim response files |  |
| `encounter_page_size` | Encounter Page Size | one of: `0` Show All; `5` 5; `10` 10; `15` 15; `20` 20; `25` 25; `50` 50 | `20` | Number of encounters to display per page. |  |
| `gbl_pt_list_page_size` | Patient List Page Size | one of: `10` 10; `25` 25; `50` 50; `100` 100 | `10` | Number of patients to display per page in the patient list. |  |
| `gbl_pt_list_new_window` | Patient List New Window | bool | `0` | Default state of New Window checkbox in the patient list. |  |
| `right_justify_labels_demographics` | Right Justify Labels in Demographics | bool | `0` | Right justify labels in Demographics for easier readability. |  |
| `num_of_messages_displayed` | Number of Messages Displayed in Patient Summary | num | `3` | This is the number of messages that will be displayed in the messages widget in the patient summary screen. |  |
| `recent_patient_count` | Maximum number of patients on Recent Patient list | num | `20` | The maximum number of patients on the Recent Patient list | 7.0.2 |
| `gbl_vitals_options` | Vitals Form Options | one of: `0` Standard; `1` Omit circumferences | `0` | Special treatment for the Vitals form |  |
| `gbl_vitals_max_history_cols` | Vitals Form Max Historical Columns To Display | num | `2` | The number of historical vital columns to display on medium to large screen displays | 7.0.1 |
| `gb_how_sort_list` | How to sort a drop-lists | one of: `0` Sort by seq; `1` Sort alphabetically | `0` | What kind of sorting will be in the drop lists. |  |
| `prevent_browser_refresh` | Prevent Web Browser Refresh* | one of: `0` Do not warn or prevent web browser refresh; `1` Warn, but do not prevent web browser refresh; `2` Warn and prevent web browser refresh | `2` | Recommended setting is warn and prevent web browser refresh. Only use other settings if needed and use at own risk. |  |
| `form_actionbar_position` | Form ActionBar (save, cancel, etc) position | set at run time: `FormActionBarSettings::getGlobalSettingsList()` | set at run time: `FormActionBarSettings::getDefaultSetting()` | Placement of the save/cancel, and other buttons where supported (Demographics, Encounter Forms, etc). | 7.0.3 |

## Branding

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `openemr_name` | Application Title | text | `OpenEMR` | Application name used throughout the user interface. |  |
| `display_main_menu_logo` | Display main menu logo | bool | `1` | Display main menu logo |  |
| `main_menu_logo_link` | Main menu logo link URL | text | `https://www.open-emr.org/` | URL the main menu logo links to. Leave blank to make the logo non-clickable. | 8.1.0 |
| `main_menu_logo_title` | Main menu logo link title | text |  | Tooltip shown when hovering over the main menu logo. Leave blank to use the default (OpenEMR Website). | 8.1.0 |
| `online_support_link` | Online Support Link | text | `http://open-emr.org/` | URL to a support page. |  |
| `user_manual_link` | User Manual Link Override | text |  | Point to a custom user manual. Leave blank for the default, auto-generated URL for specific version of application |  |
| `support_phone_number` | Support Phone Number | text |  | Phone Number for Vendor Support that Appears on the About Page. |  |
| `display_acknowledgements` | Display links to the acknowledgements page | bool | `1` | Used on the login and about pages |  |
| `display_review_link` | Display the Review link on the About page | bool | `1` | Display the Review link on the About page |  |
| `display_donations_link` | Display the Donations link on the About page | bool | `1` | Display the Donations link on the About page |  |

## Login Page

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `login_page_layout` | Login Page Layout* | one of: `login/layouts/vertical_box.html.twig` Vertical Box; `login/layouts/horizontal_box_left_logo.html.twig` Horizontal Box, Logo on Left; `login/layouts/horizontal_box_right_logo.html.twig` Horizontal Box, Logo on Right; `login/layouts/horizontal_band_right_logo.html.twig` Horizontal Band, Logo on Right; `login/layouts/horizontal_band_left_logo.html.twig` Horizontal Band, Logo on Left; `login/layouts/vertical_band.html.twig` Vertical Band | `login/layouts/vertical_band.html.twig` | Changes the layout of the login page. |  |
| `primary_logo_width` | Width of primary logo compared to the container | one of: `w-25` 25%; `w-50` 50%; `w-75` 75%; `w-100` 100% | `w-50` | Determine the width of the primary logo compared to the container | 7.0.2 |
| `secondary_logo_width` | Width of secondary logo compared to the container | one of: `w-25` 25%; `w-50` 50%; `w-75` 75%; `w-100` 100% | `w-50` | Determine the width of the secondary logo compared to the container | 7.0.2 |
| `logo_position` | Logo Positioning | one of: `flex-column` Stacked; `flex-row` Side by Side | `flex-column` | How the logos will be rendered relative to each other | 7.0.2 |
| `display_acknowledgements_on_login` | Display links to the acknowledgements page | bool | `1` | Used on the login screen | 7.0.1 |
| `show_tagline_on_login` | Show Tagline on Login Page* | bool | `1` | Show the tagline from the login screen |  |
| `login_tagline_text` | Login Page Tagline* | text | `The most popular open-source Electronic Health Record and Medical Practice Management solution.` | Tagline text on the login page |  |
| `show_labels_on_login_form` | Show Username and Password Labels on Login Page* | bool | `1` | Show labels on the login form |  |
| `show_label_login` | Show Title on Login | bool | `0` | Show Title on Login |  |
| `show_primary_logo` | Show primary logo on login | bool | `1` | Show primary logo on login | 7.0.2 |
| `extra_logo_login` | Show Secondary Logo on Login | bool | `0` | Show Secondary Logo on Login |  |
| `secondary_logo_position` | Order of the Secondary logo | one of: `first` First Position; `second` Second Position | `second` | Place the secondary logo first, or second | 7.0.1 |
| `tiny_logo_1` | Show Mini Logo 1 | bool | `0` | Show Mini Logo 1 |  |
| `tiny_logo_2` | Show Mini Logo 2 | bool | `0` | Show Mini Logo 2 |  |

## Locale

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `language_default` | Default Language | lang | `English (Standard)` | Default language if no other is allowed or chosen. |  |
| `language_menu_showall` | All Languages Allowed | bool | `1` | Allow all available languages as choices on menu at login. |  |
| `language_menu_other` | Allowed Languages | m_lang |  | Select which languages, if any, may be chosen at login. (only pertinent if above All Languages Allowed is turned off) |  |
| `allow_debug_language` | Allow Debugging Language | bool | `0` | This will allow selection of the debugging ('dummy') language. |  |
| `translate_no_safe_apostrophe` | Do Not Use Safe Apostrophe | bool | `0` | This will turn off use of safe apostrophe, which is done by converting ' and " to `.(it is highly recommended that this setting is turned off and that safe apostrophe's are used) |  |
| `disable_translation` | Disable Translation Engine | bool | `0` | Completely disable the translation engine. When enabled, xl() returns the input string unchanged. Use this for English-only deployments to eliminate translation overhead. | 8.0.0 |
| `translation_preload_cache` | Preload Translation Cache | bool | `0` | Load all translations into memory at the start of each request. This uses more memory but eliminates database queries for translations, improving performance for sites with many translated strings. | 8.0.0 |
| `translate_layout` | Translate Layouts | bool | `1` | Is text from form layouts to be translated? |  |
| `translate_lists` | Translate Lists | bool | `1` | Is text from lists to be translated? |  |
| `translate_gacl_groups` | Translate Access Control Groups | bool | `1` | Are access control group names to be translated? |  |
| `translate_form_titles` | Translate Patient Note Titles | bool | `1` | Are patient note titles to be translated? |  |
| `translate_document_categories` | Translate Document Categories | bool | `1` | Are document category names to be translated? |  |
| `translate_appt_categories` | Translate Appointment Categories | bool | `1` | Are appointment category names to be translated? |  |
| `units_of_measurement` | Units for Visit Forms | one of: `1` Show both US and metric (main unit is US); `2` Show both US and metric (main unit is metric); `3` Show US only; `4` Show metric only | `1` | Applies to the Vitals form and Growth Chart |  |
| `us_weight_format` | Display Format for US Weights | one of: `1` Show pounds as decimal value; `2` Show pounds and ounces | `1` | Applies to Vitals form |  |
| `phone_country_code` | Telephone Country Code | num | `1` | 1 = North America. See http://www.wtng.info/ for a list of other country codes. |  |
| `date_display_format` | Date Display Format | one of: `0` YYYY-MM-DD; `1` MM/DD/YYYY; `2` DD/MM/YYYY | `0` | Format used to display most dates. |  |
| `time_display_format` | Time Display Format | one of: `0` 24 hr; `1` 12 hr | `0` | Format used to display most times. |  |
| `gbl_time_zone` | Time Zone | set at run time: `gblTimeZones()` |  | If unassigned will default to php.ini setting for date.timezone. |  |
| `currency_decimals` | Currency Decimal Places | one of: `0` 0; `1` 1; `2` 2 | `2` | Number of digits after decimal point for currency, usually 0 or 2. |  |
| `currency_dec_point` | Currency Decimal Point Symbol | one of: `.` Period; `,` Comma | `.` | Symbol used as the decimal point for currency. Not used if Decimal Places is 0. |  |
| `currency_thousands_sep` | Currency Thousands Separator | one of: `,` Comma; `.` Period; ` ` Space; `` None | `,` | Symbol used to separate thousands for currency. |  |
| `gbl_currency_symbol` | Currency Designator | text | `$` | Code or symbol to indicate currency |  |
| `age_display_format` | Age Display Format | one of: `0` Years or months; `1` Years, months and days | `0` | Format for age display |  |
| `age_display_limit` | Age in Years for Display Format Change | num | `3` | If YMD is selected for age display, switch to just Years when patients older than this value in years |  |
| `weekend_days` | Your weekend days | one of: `6,0` set at run time: `DayOfWeek::Saturday->label() . ' - ' . DayOfWeek::Sunday->label()`; `0` set at run time: `DayOfWeek::Sunday->label()`; `5` set at run time: `DayOfWeek::Friday->label()`; `6` set at run time: `DayOfWeek::Saturday->label()`; `5,6` set at run time: `DayOfWeek::Friday->label() . ' - ' . DayOfWeek::Saturday->label()` | `6,0` | which days are your weekend days? |  |

## Features

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `specific_application` | Specific Application | one of: `0` None; `2` IPPF; `3` Weight loss clinic | `0` | Indicator for specialized usage |  |
| `inhouse_pharmacy` | Drugs and Products | one of: `0` Do not inventory and sell any products; `1` Inventory and sell drugs only; `2` Inventory and sell both drugs and non-drug products; `3` Products but no prescription drugs and no templates | `0` | Option to support inventory and sales of products |  |
| `disable_chart_tracker` | Disable Chart Tracker | bool | `0` | Removes the Chart Tracker feature |  |
| `disable_immunizations` | Disable Immunizations | bool | `0` | Removes support for immunizations |  |
| `disable_prescriptions` | Disable Prescriptions | bool | `0` | Removes support for prescriptions |  |
| `text_templates_enabled` | Enable Text Templates in Encounter Forms | bool | `1` | Allow Double Click to select Nation Note text template from any encounter form text area |  |
| `omit_employers` | Omit Employers | bool | `0` | Omit employer information in patient demographics |  |
| `select_multi_providers` | Support Multi-Provider Events | bool | `0` | Support calendar events that apply to multiple providers |  |
| `disable_non_default_groups` | Disable User Groups | bool | `1` | Normally this should be checked. Not related to access control. |  |
| `ignore_pnotes_authorization` | Skip Authorization of Patient Notes | bool | `1` | Do not require patient notes to be authorized |  |
| `support_encounter_claims` | Allow Encounter Claims | bool | `0` | Allow creation of claims containing diagnoses but not procedures or charges. Most clinics do not want this. |  |
| `advance_directives_warning` | Advance Directives Warning | bool | `0` | Display advance directives in the demographics page. |  |
| `restrict_user_facility` | Restrict Users to Facilities | bool | `0` | Restrict non-authorized users to the Schedule Facilities set in User admin. |  |
| `set_facility_cookie` | Remember Selected Facility | bool | `0` | Set a facility cookie to remember the selected facility between logins. |  |
| `login_into_facility` | Login Into Facility | bool | `0` | Select your current facility in the login page |  |
| `receipts_by_provider` | Print Receipts by Provider | bool | `0` | Causes Receipts to Print Encounter/Primary Provider Info |  |
| `discount_by_money` | Discounts as Monetary Amounts | bool | `1` | Discounts at checkout time are entered as money amounts, as opposed to percentage. |  |
| `gbl_form_save_close` | Display Save and Close Visit button in LBFs | bool | `0` | This is helpful if visits usually do not have charges. |  |
| `gbl_mask_patient_id` | Mask for Patient IDs | text |  | Specifies formatting for the external patient ID.  # = digit, @ = alpha, * = any character.  Empty if not used. |  |
| `gbl_mask_invoice_number` | Mask for Invoice Numbers | text |  | Specifies formatting for invoice reference numbers.  # = digit, @ = alpha, * = any character.  Empty if not used. |  |
| `gbl_mask_product_id` | Mask for Product IDs | text |  | Specifies formatting for product NDC fields.  # = digit, @ = alpha, * = any character.  Empty if not used. |  |
| `activate_ccr_ccd_report` | Activate CCR/CCD Reporting | bool | `1` | This will activate the CCR(Continuity of Care Record) and CCD(Continuity of Care Document) reporting. |  |
| `database_encryption` | Enable Encryption of Data Stored in the Database (Keep on unless DB server is encrypted) | bool | `1` | This will enable encryption of certain data stored in the database. This should be left enabled unless the database server itself is encrypted | 8.2.0 |
| `drive_encryption` | Enable Encryption of Items Stored on Drive/CouchDB (Strongly recommend keeping this on) | bool | `1` | This will enable encryption of items that are stored on the drive. Strongly recommend keeping this setting on for security purposes. |  |
| `couchdb_encryption` | UNUSED: Enable Encryption of Items Stored on CouchDB | bool | `1` | This setting has no effect! Use `drive_encryption` instead. |  |
| `hide_document_encryption` | Hide Encryption/Decryption Options In Document Management | bool | `0` | This will deactivate document the encryption and decryption features, and hide them in the UI. |  |
| `use_custom_immun_list` | Use Custom Immunization List | bool | `0` | This will use the custom immunizations list rather than the standard CVX immunization list. |  |
| `amendments` | Amendments | bool | `1` | Enable amendments feature |  |
| `allow_pat_delete` | Allow Administrators to Delete Patients | bool | `0` | Allow Administrators to Delete Patients |  |
| `observation_results_immunization` | Immunization Observation Results | bool | `1` | Observation Results in Immunization |  |
| `enable_help` | Enable Help Modal | one of: `0` Hide Help Modal; `1` Show Help Modal; `2` Disable Help Modal | `1` | This will allow the display of help modal on help enabled pages |  |
| `messages_due_date` | Messages - due date | bool | `0` | Enables choose due date to message |  |
| `expand_form` | Expand Form | bool | `1` | Open all expandable forms in expanded state |  |
| `graph_data_warning` | Graphing Data Warning | bool | `0` | Warn if not enough data to graph | 7.0.1 |

## Report

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `use_custom_daysheet` | Use Custom End of Day Report | one of: `0` None; `1` Print End of Day Report 1; `2` Print End of Day Report 2; `3` Print End of Day Report 3 | `1` | This will allow the use of the custom End of Day report and indicate which report to use. |  |
| `daysheet_provider_totals` | End of Day by Provider or allow Totals Only | one of: `0` Provider; `1` Totals Only | `1` | This specifies the Printing of the Custom End of Day Report grouped Provider or allow the Printing of Totals Only |  |
| `ledger_begin_date` | Beginning Date for Ledger Report | one of: `Y1` One Year Ago; `Y2` Two Years Ago; `M6` Six Months Ago; `M3` Three Months Ago; `M1` One Month Ago; `D1` One Day Ago | `Y1` | This is the Beginning date for the Ledger Report. |  |
| `print_next_appointment_on_ledger` | Print the Next Appointment on the Bottom of the Ledger | bool | `1` | This Will Print the Next Appointment on the Bottom of the Patient Ledger |  |
| `sales_report_invoice` | Display Invoice Number or Patient Name or Both in the Sales Report | one of: `0` Invoice Number; `1` Patient Name and ID; `2` Patient Name and Invoice | `2` | This will Display the Invoice Number in the Sales Report or the Patient Name and ID or Patient Name and Invoice Number. |  |
| `cash_receipts_report_invoice` | Display Invoice Number or Patient Name in the Cash Receipt Report | one of: `0` Invoice Number; `1` Patient Name | `0` | Display Invoice Number or Patient Name in the Cash Receipt Report |  |

## Billing

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `hide_billing_widget` | Hide Billing features | bool | `0` | This will hide billing features throughout the program. |  |
| `force_billing_widget_open` | Force Billing Widget Open | bool | `0` | This will force the Billing Widget in the Patient Summary screen to always be open. |  |
| `ub04_support` | Activate UB04/837I Claim Support | bool | `0` | Allow institutional claims support. |  |
| `top_ubmargin_default` | Default top print margin for UB04 | num | `14` | This is the default top print margin for UB04. It will adjust the final printed output up or down. |  |
| `left_ubmargin_default` | Default left print margin for UB04 | num | `11` | This is the default left print margin for UB04. It will adjust the final printed output left or right. |  |
| `cms_top_margin_default` | Default top print margin for CMS 1500 | num | `24` | This is the default top print margin for CMS 1500. It will adjust the final printed output up or down. |  |
| `cms_left_margin_default` | Default left print margin for CMS 1500 | num | `20` | This is the default left print margin for CMS 1500. It will adjust the final printed output left or right. |  |
| `preprinted_cms_1500` | Prints the CMS 1500 on the Preprinted form | bool | `0` | Overlay CMS 1500 on the Preprinted form |  |
| `cms_1500_box_31_format` | CMS 1500: Box 31 Format | one of: `0` Signature on File; `1` Firstname Lastname; `2` None | `0` | This specifies whether to include date in Box 31. |  |
| `cms_1500_box_31_date` | CMS 1500: Date in Box 31 (Signature) | one of: `0` None; `1` Date of Service; `2` Today | `0` | This specifies whether to include date in Box 31. |  |
| `default_search_code_type` | Default Search Code Type | all_code_types | `ICD10` | The default code type to search for in the Fee Sheet. |  |
| `default_rendering_provider` | Default Rendering Provider in Fee Sheet | one of: `0` Logged in User if provider, otherwise Current Provider; `1` Current Provider; `2` Current Logged in User | `1` | Default selection for rendering provider in fee sheet. |  |
| `posting_adj_disable` | Disable Auto Adjustment Calculations in EOB Posting | bool | `0` | Turn off auto calculations of adjustments in EOB |  |
| `force_claim_balancing` | Force claim balancing in EOB Posting | bool | `1` | Force claim balancing in EOB Posting |  |
| `show_payment_history` | Show all payment history in Patient Ledger | bool | `1` | Turn on to show all payment history in Patient Ledger |  |
| `void_checkout_reopen` | Void Checkout and Reopen in Fee Sheet | bool | `1` | Void Checkout and Reopen in Fee Sheet |  |
| `support_fee_sheet_line_item_provider` | Support provider in line item in fee sheet | bool | `0` | This Enables provider in line item in the fee sheet |  |
| `default_fee_sheet_line_item_provider` | Default to a provider for line item in the fee sheet | bool | `0` | Default to a provider for line item in the fee sheet.(only applicable if Support line item billing in option above) |  |
| `include_inactive_providers` | Include inactive providers in the fee sheet | bool | `0` | Include inactive providers in the fee sheet. |  |
| `replicate_justification` | Automatically replicate justification codes in Fee Sheet | bool | `0` | Automatically replicate justification codes in Fee Sheet (basically fills in the blanks with the justification code above it). |  |
| `display_units_in_billing` | Display the Units Column on the Billing Screen | bool | `0` | Display the Units Column on the Billing Screen |  |
| `notes_to_display_in_Billing` | Which notes are to be displayed in the Billing Screen | one of: `0` None; `1` Encounter Billing Note; `2` Patient Billing Note; `3` All | `3` | Display the Encounter Billing Note or Patient Billing Note or Both in the Billing Screen. |  |
| `MedicareReferrerIsRenderer` | Medicare Referrer Is Renderer | bool | `0` | For Medicare only, forces the referring provider to be the same as the rendering provider. |  |
| `statement_logo` | Statement Logo GIF Filename | text | `practice_logo.gif` | Place your logo in sites/default/images and type the filename including gif extension here. |  |
| `use_custom_statement` | Use Custom Statement | bool | `0` | This will use the custom Statement showing the description instead of the codes. |  |
| `statement_appearance` | Statement Appearance | one of: `0` Plain Text; `1` Modern/images | `1` | Patient statements can be generated as plain text or with a modern graphical appearance. |  |
| `billing_phone_number` | Custom Billing Phone Number | text |  | Phone number for billing inquiries |  |
| `show_aging_on_custom_statement` | Show Aging on Custom Statement | bool | `0` | This will Show Aging on the custom Statement. |  |
| `use_statement_print_exclusion` | Allow Statement Exclusions from Printing | bool | `0` | This will enable the Ability to Exclude Selected Patient Statements from Printing. |  |
| `minimum_amount_to_print` | Total Minimum Amount of Statement to Allow Printing | num | `1.00` | Total Minimum Dollar Amount of Statement to Allow Printing.(only applicable if Allow Statement Exclusions from Printing is enabled) |  |
| `statement_bill_note_print` | Print Patient Billing Note | bool | `0` | This will allow printing of the Patient Billing Note on the statements. |  |
| `number_appointments_on_statement` | Number of Appointments on Statement | num | `0` | The Number of Future Appointments to Display on the Statement. |  |
| `statement_message_to_patient` | Print Custom Message | bool | `0` | This will allow printing of a custom Message on the statements. |  |
| `statement_msg_text` | Custom Statement message | text |  | Text for Custom statement message. |  |
| `use_dunning_message` | Use Custom Dunning Messages | bool | `0` | This will allow use of the custom Dunning Messages on the statements. |  |
| `first_dun_msg_set` | Number of days before showing first account message | num | `30` | Number of days before showing first account message. |  |
| `first_dun_msg_text` | First account message | text |  | Text for first account message. |  |
| `second_dun_msg_set` | Number of days before showing second account message | num | `60` | Number of days before showing second account message |  |
| `second_dun_msg_text` | Second account message | text |  | Text for second account message. |  |
| `third_dun_msg_set` | Number of days before showing third account message | num | `90` | Number of days before showing third account message |  |
| `third_dun_msg_text` | Third account message | text |  | Text for third account message. |  |
| `fourth_dun_msg_set` | Number of days before showing fourth account message | num | `120` | Number of days before showing fourth account message |  |
| `fourth_dun_msg_text` | Fourth account message | text |  | Text for fourth account message. |  |
| `fifth_dun_msg_set` | Number of days before showing fifth account message | num | `150` | Number of days before showing fifth account message |  |
| `fifth_dun_msg_text` | Fifth account message | text |  | Text for fifth account message. |  |
| `save_codes_history` | Save codes history | bool | `1` | Save codes history |  |
| `enable_percent_pricing` | Enable percent-based price levels | bool | `0` | Enable percent-based price levels |  |
| `gen_x12_based_on_ins_co` | Generate X-12 Based On Insurance Company | bool | `0` | For sending claims directly to insurance company, based on X12 Partner Settings |  |
| `auto_sftp_claims_to_x12_partner` | Automatically SFTP Claims To X12 Partner | bool | `0` | For automatically sending claims that are generated in EDI directory to the X12 partner using SFTP credentials X12 Partner Settings |  |
| `enable_swap_secondary_insurance` | Enable Swap Secondary Insurance Editing Demographics | bool | `0` | Enable swap secondary insurance | 7.0.1 |
| `add_unmatched_code_from_ins_co_era_to_billing` | Enable adding unmatched code from insurance company to billing table | bool | `0` | Enable adding unmatched code from insurance company to billing table | 7.0.3 |

## E-Sign

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `esign_all` | Allows E-Sign on the entire encounter | bool | `0` | This will enable signing an entire encounter, rather than individual forms |  |
| `lock_esign_all` | Lock e-signed encounters and their forms | bool | `0` | This will disable the Edit button on all forms whose parent encounter is e-signed |  |
| `esign_individual` | Allows E-Signing Individual Forms | bool | `1` | This will enable signing individual forms separately |  |
| `lock_esign_individual` | Lock an e-signed form individually | bool | `1` | This will disable the Edit button on any form that is e-signed |  |
| `esign_lock_toggle` | Enable lock toggle | bool | `0` | This will give the user the option to lock (separate locking and signing) |  |
| `esign_report_show_only_signed` | Only Include E-Signed Forms On Report | bool | `0` | This will hide any encounter forms not E-Signed on the patient report |  |
| `esign_report_hide_empty_sig` | Hide Empty E-Sign Logs On Report | bool | `1` | This will hide empty e-sign logs on the patient report |  |
| `esign_report_hide_all_sig` | Exclude All E-Sign Logs On Report | bool | `0` | This will hide any e-sign logs on the patient report |  |

## Documents

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `document_storage_method` | Document Storage Method | one of: `0` Hard Disk; `1` CouchDB | `0` | Option to save method of document storage. |  |
| `couchdb_host` | CouchDB HostName | text | `localhost` | CouchDB host |  |
| `couchdb_user` | CouchDB UserName | text |  | Username to connect to CouchDB |  |
| `couchdb_pass` | CouchDB Password | encrypted |  | Password to connect to CouchDB |  |
| `couchdb_port` | CouchDB Port | text | `6984` | CouchDB port |  |
| `couchdb_dbase` | CouchDB Database | text |  | CouchDB database name |  |
| `couchdb_connection_ssl` | CouchDB Connection SSL | bool | `1` | Use SSL (encrypted) connection to CouchDB |  |
| `couchdb_ssl_allow_selfsigned` | CouchDB SSL Allow Selfsigned Certificate | bool | `0` | Allow self-signed certificate for SSL (encrypted) connection to CouchDB |  |
| `couchdb_log` | CouchDB Log Enable | bool | `0` | Enable log for document uploads/downloads to CouchDB |  |
| `expand_document_tree` | Expand All Document Categories | bool | `0` | Expand All Document Categories by Default |  |
| `patient_id_category_name` | Patient ID Category Name | text | `Patient ID card` | Optional category name for an ID Card image that can be viewed from the patient summary page. |  |
| `patient_photo_category_name` | Patient Photo Category Name | text | `Patient Photograph` | Optional category name for photo images that can be viewed from the patient summary page. |  |
| `lab_results_category_name` | Lab Results Category Name | text | `Lab Report` | Document category name for storage of electronically received lab results. |  |
| `gbl_mdm_category_name` | MDM Document Category Name | text | `Lab Report` | Document category name for storage of electronically received MDM documents. |  |
| `generate_doc_thumb` | Generate thumbnail | bool | `0` | Generate thumbnail images |  |
| `thumb_doc_max_size` | Thumbnail size | text | `100` | Maximum size of thumbnail file |  |

## Calendar

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `disable_calendar` | Disable Calendar | bool | `0` | Do not display the calendar. |  |
| `schedule_start` | Calendar Starting Hour | hour | `8` | Beginning hour of day for calendar events. |  |
| `schedule_end` | Calendar Ending Hour | hour | `17` | Ending hour of day for calendar events. |  |
| `calendar_interval` | Calendar Interval | one of: `5` 5; `10` 10; `15` 15; `20` 20; `30` 30; `60` 60 | `15` | The time granularity of the calendar and the smallest interval in minutes for an appointment slot. |  |
| `calendar_view_type` | Default Calendar View | one of: `day` Day; `week` Week; `month` Month | `day` | This sets the Default Calendar View, Default is Day. |  |
| `first_day_week` | First day in the week | one of: `1` set at run time: `DayOfWeek::Monday->label()`; `0` set at run time: `DayOfWeek::Sunday->label()`; `6` set at run time: `DayOfWeek::Saturday->label()` | `1` | Your first day of the week. |  |
| `calendar_appt_style` | Appointment Display Style | one of: `1` Last name; `2` Last name, first name; `3` Last name, first name (title); `4` Last name, first name (title: comments); `5` Last name, first name, address (title: comments) | `2` | This determines how appointments display on the calendar. |  |
| `event_color` | Appointment/Event Color | one of: `1` Category Color Schema; `2` Facility Color Schema | `1` | This determines which color schema used for appointment |  |
| `number_of_appts_to_show` | Appointments - Patient Summary - Number to Display | num | `10` | Number of Appointments to display in the Patient Summary |  |
| `number_of_group_appts_to_show` | Appointments - Group Summary - Number to Display | num | `10` | Number of Appointments to display in the Group Summary |  |
| `number_of_ex_appts_to_show` | Excluded Appointments - Tooltip - Number to Display | num | `15` | Number of Excluded Appointments to display in the Tooltip |  |
| `appt_display_sets_option` | Appointment Display Sets - Ignore Display Limit (Last Set) | bool | `1` | Override (if necessary) the appointment display limit to allow all appointments to be displayed for the last set |  |
| `appt_display_sets_color_1` | Appointment Display Sets - Color 1 | color_code | `#FFFFFF` | Color for odd sets (except when last set is odd and all member appointments are displayed and at least one subsequent scheduled appointment exists (not displayed) or not all member appointments are displayed). |  |
| `appt_display_sets_color_2` | Appointment Display Sets - Color 2 | color_code | `#E6E6FF` | Color for even sets (except when last set is even and all member appointments are displayed and at least one subsequent scheduled appointment exists (not displayed) or not all member appointments are displayed). |  |
| `appt_display_sets_color_3` | Appointment Display Sets - Color 3 | color_code | `#E6FFE6` | Color for the last set when all member appointments are displayed and at least one subsequent scheduled appointment exists (not displayed). |  |
| `appt_display_sets_color_4` | Appointment Display Sets - Color 4 | color_code | `#FFE6FF` | Color for the last set when not all member appointments are displayed. |  |
| `appt_recurrences_widget` | Recurrent Appointment Display Widget | bool | `1` | Display the recurrent appointment widget in the patient summary. |  |
| `num_past_appointments_to_show` | Past Appointment Display Widget | num | `0` | A positive number will show that many past appointments on a Widget in the Patient Summary screen (a negative number will show the past appointments in descending order) |  |
| `docs_see_entire_calendar` | Providers See Entire Calendar | bool | `0` | Check this if you want providers to see all appointments by default and not just their own. |  |
| `auto_create_new_encounters` | Auto-Create New Encounters | one of: `0` Off; `1` One Encounter Per Day; `2` Allow Encounter For Each Appointment | `1` | Automatically create a new encounter when an appointment check in status is selected. The Each Appointment option will allow a new encounter regardless of same day visit. The appointment status changes and encounter creations are managed through the Patient Tracker. |  |
| `auto_create_prevent_reason` | Prevent Appointment Comment as Visit Reason | bool | `0` | Check this if you do not want to allow the appointments comment as the visit reason when auto-creating new encounter for appointment. | 7.0.3 |
| `allow_early_check_in` | Allow Early Check In | bool | `1` | Allow Check In before the appointment's time. |  |
| `submit_changes_for_all_appts_at_once` | Submit Changes For All Appts At Once | bool | `1` | Enables to submit changes for all appointments of a recurrence at once. |  |
| `disable_pat_trkr` | Flow Board: Disable | bool | `0` | Completely remove the ability to display the Patient Flow Board. |  |
| `ptkr_visit_reason` | Flow Board: Show Visit Reason | bool | `0` | When Checked, Visit Reason Will Show in Patient Flow Board. |  |
| `ptkr_show_pid` | Flow Board: Show Patient ID | bool | `1` | When Checked, Patient ID Will Show in Patient Flow Board. |  |
| `ptkr_show_encounter` | Flow Board: Show Encounter Number | bool | `1` | When Checked, Patient Encounter Number Will Show in Patient Flow Board. |  |
| `ptkr_show_staff` | Flow Board: Show Staff Action | bool | `1` | When Checked, Last Staff to Update Board Will Show in Patient Flow Board. |  |
| `ptkr_date_range` | Flow Board: Allow Date Range | bool | `1` | This Allows a Date Range to be Selected in Patient Flow Board. |  |
| `ptkr_start_date` | Flow Board: Default Starting Date | one of: `D0` Current Day; `B0` Beginning of Current Work Week | `D0` | This is the default Beginning date for the Patient Flow Board. (only applicable if Allow Date Range in option above is Enabled) |  |
| `ptkr_end_date` | Flow Board: Default Ending Date | one of: `Y1` One Year Ahead; `Y2` Two Years Ahead; `M6` Six Months Ahead; `M3` Three Months Ahead; `M1` One Month Ahead; `D7` One Week Ahead; `D1` One Day Ahead; `D0` Current Day | `D0` | This is the default Ending date for the Patient Flow Board. (only applicable if Allow Date Range in option above is Enabled) |  |
| `pat_trkr_timer` | Flow Board: Timer Refresh Interval | one of: `0` No automatic refresh; `0:10` 10; `0:20` 20; `0:30` 30; `0:40` 40; `0:50` 50; `0:59` 60 | `0:20` | The screen refresh time in Seconds for the Patient Flow Board Screen. |  |
| `checkout_roll_off` | Flow Board: display completed checkouts (minutes) | num | `0` | Flow Board will only display completed checkouts for this many minutes. Zero is continuous display. |  |
| `drug_screen` | Flow Board: Enable Random Drug Testing | bool | `0` | Allow Patient Flow Board to Select Patients for Drug Testing. |  |
| `drug_testing_percentage` | Flow Board: Percentage of Patients to Drug Test | num | `33` | Percentage of Patients to select for Random Drug Testing. |  |
| `maximum_drug_test_yearly` | Flow Board: Max tests per Patient per year | num | `0` | Maximum number of times a Patient can be tested in a year. Zero is no limit. |  |
| `disable_rcb` | Recall Board: Disable | bool | `0` | Do not display the Recall Board. |  |

## Insurance

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `enable_eligibility_requests` | Enable Insurance Eligibility | bool | `0` | Allow insurance eligibility checks using an X12 Partner | 7.0.2 |
| `simplified_demographics` | Simplified Demographics | bool | `0` | Omit insurance and some other things from the demographics form |  |
| `insurance_information` | Show Additional Insurance Information | one of: `0` None; `1` Address Only; `2` Address and Postal Code; `3` Address and State; `4` Address, State and Postal Code; `5` Address, City, State and Postal Code; `6` Address, City, State, Postal Code, Payer ID; `7` Postal Code and Box Number | `6` | Show Insurance Address Information in the Insurance Panel of Demographics. |  |
| `disable_eligibility_log` | Disable Insurance Eligibility Reports Download | bool | `0` | Do not allow insurance eligibility report log download |  |
| `insurance_only_one` | Allow only one insurance | bool | `0` | Allow more than one insurance |  |

## Security

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `sql_string_no_show_screen` | Mode - Do Not Show SQL Queries | bool | `0` | Do not allow SQL queries to be outputted to screen. |  |
| `timeout` | Idle Session Timeout Seconds | num | `7200` | Maximum idle time in seconds before logout. Default is 7200 (2 hours). |  |
| `portal_timeout` | Portal Idle Session Timeout Seconds | num | `1800` | Maximum idle time in seconds before logout. Default is 1800 (30 minutes). |  |
| `secure_upload` | Secure Upload Files with White List | bool | `1` | Block all files types that are not found in the White List. Can find interface to edit the White List at Administration->Files. |  |
| `secure_password` | Require Strong Passwords | bool | `1` | Strong password means at least one of each: a number, a lowercase letter, an uppercase letter, a special character. |  |
| `gbl_minimum_password_length` | Minimum Password Length | one of: `0` No Minimum; `4` 4; `5` 5; `6` 6; `7` 7; `8` 8; `9` 9; `10` 10; `11` 11; `12` 12; `13` 13; `14` 14; `15` 15; `16` 16; `17` 17; `18` 18; `19` 19; `20` 20 | `9` | Minimum length of password. |  |
| `gbl_maximum_password_length` | Maximum Password Length | one of: `0` No Maximum; `72` 72 | `72` | Maximum length of password (Recommend using the default value of 72 unless you know what you are doing). |  |
| `password_history` | Require Unique Passwords | one of: `0` No; `1` 1; `2` 2; `3` 3; `4` 4; `5` 5 | `5` | Set to the number of prior passwords that are not allowed to use when changing a password. |  |
| `password_expiration_days` | Password Expiration Days | num | `180` | Password expiration period in days. 0 means this feature is disabled. |  |
| `password_grace_time` | Password Expiration Grace Period | num | `30` | Period in days where a user may login with an expired password. |  |
| `password_max_failed_logins` | Maximum Failed Login Attempts For User | num | `20` | Maximum Failed Login Attempts For User (0 for no maximum). |  |
| `time_reset_password_max_failed_logins` | Time (seconds) to Reset Maximum Failed Login Attempts For User | num | `3600` | Time (seconds) to Reset Maximum Failed Login Attempts Counter For User (0 for no reset). | 7.0.2 |
| `ip_max_failed_logins` | Maximum Failed Login Attempts From IP Address | num | `100` | Maximum Failed Login Attempts From IP Address (0 for no maximum). | 7.0.2 |
| `ip_time_reset_password_max_failed_logins` | Time (seconds) to Reset Maximum Failed Login Attempts From IP Address | num | `3600` | Time (seconds) to Reset Maximum Failed Login Attempts Counter From IP Address (0 for no reset). | 7.0.2 |
| `portal_onetime_max_pin_attempts` | Portal One-Time Token Maximum PIN Attempts | num | `5` | Maximum PIN attempts allowed for a patient portal one-time (e.g. invoice) token before it is refused. 0 or blank uses the built-in default. | 8.4.0 |
| `gbl_fac_warehouse_restrictions` | Enable Facility/Warehouse Permissions | bool | `0` | Enable facility/warehouse restrictions in the user administration form. |  |
| `Emergency_Login_email_id` | Emergency Login Email Address | text |  | Email address, if any, to receive emergency login user activation messages. |  |
| `new_validate` | New form validation | bool | `1` | New form validation |  |
| `google_signin_enabled` | Enable Google Sign-In | bool | `0` | Enable Authentication Using Google Sign-in |  |
| `google_signin_client_id` | Google Sign-In Client ID | text |  | This Client ID Is Provided By Google For Your App (Required For Google Sign-in) |  |
| `gbl_ldap_enabled` | Use LDAP for Authentication | bool | `0` | If enabled, use LDAP for login and authentication. |  |
| `gbl_ldap_host` | LDAP - Server Name or URI | text |  | The hostname or URI of your LDAP or Active Directory server. |  |
| `gbl_ldap_dn` | LDAP - Distinguished Name of User | text |  | Embed {login} where the OpenEMR login name of the user is to be; for example: uid={login},dc=example,dc=com |  |
| `gbl_ldap_exclusions` | LDAP - Login Exclusions | text |  | Comma-separated list of login names to use normal authentication instead of LDAP; useful for setup and debugging. |  |
| `gbl_debug_hash_verify_execution_time` | Debug Hash Verification Time | bool | `0` | If enabled, this will send the execution time it took to verify hash to the php error log. |  |
| `gbl_auth_hash_algo` | Hash Algorithm for Authentication | one of: `DEFAULT` PHP Default; `BCRYPT` Bcrypt; `ARGON2I` Argon2I; `ARGON2ID` Argon2ID; `SHA512HASH` SHA512 (ONC 2015) | `DEFAULT` | Hashing algorithm for authentication. Suggest PHP Default unless you know what you are doing. |  |
| `gbl_auth_bcrypt_hash_cost` | Authentication Bcrypt Hash Cost | one of: `DEFAULT` PHP Default; `5` 5; `6` 6; `7` 7; `8` 8; `9` 9; `10` 10; `11` 11; `12` 12; `13` 13; `14` 14; `15` 15; `16` 16; `17` 17; `18` 18; `19` 19; `20` 20 | `DEFAULT` | Authentication bcrypt hash cost. Suggest PHP Default unless you know what you are doing. |  |
| `gbl_auth_argon_hash_memory_cost` | Authentication Argon Hash Memory Cost | one of: `DEFAULT` PHP Default; `512` 512; `1024` 1024; `2048` 2048; `4096` 4096; `8192` 8192; `16384` 16384; `32768` 32768; `65536` 65536; `131072` 131072; `262144` 262144; `524288` 524288; `1048576` 1048576; `2097152` 2097152 | `DEFAULT` | Authentication argon hash memory cost. Suggest PHP Default unless you know what you are doing. |  |
| `gbl_auth_argon_hash_time_cost` | Authentication Argon Hash Time Cost | one of: `DEFAULT` PHP Default; `1` 1; `2` 2; `3` 3; `4` 4; `5` 5; `6` 6; `7` 7; `8` 8; `9` 9; `10` 10; `11` 11; `12` 12; `13` 13; `14` 14; `15` 15; `16` 16; `17` 17; `18` 18; `19` 19; `20` 20 | `DEFAULT` | Authentication argon hash time cost. Suggest PHP Default unless you know what you are doing. |  |
| `gbl_auth_argon_hash_thread_cost` | Authentication Argon Hash Thread Number | one of: `DEFAULT` PHP Default; `1` 1; `2` 2; `3` 3; `4` 4; `5` 5; `6` 6; `7` 7; `8` 8; `9` 9; `10` 10; `11` 11; `12` 12; `13` 13; `14` 14; `15` 15; `16` 16; `17` 17; `18` 18; `19` 19; `20` 20 | `DEFAULT` | Authentication argon hash thread number. Suggest PHP Default unless you know what you are doing. |  |
| `gbl_auth_sha512_rounds` | Authentication SHA512 Hash Rounds Number | one of: `1000` 1000; `5000` 5000; `10000` 10000; `15000` 15000; `20000` 20000; `30000` 30000; `40000` 40000; `50000` 50000; `75000` 75000; `100000` 100000; `200000` 200000; `300000` 300000; `400000` 400000; `500000` 500000; `750000` 750000; `1000000` 1000000; `2000000` 2000000; `3000000` 3000000; `4000000` 4000000; `5000000` 5000000; `6000000` 6000000; `7000000` 7000000; `8000000` 8000000; `9000000` 9000000 | `100000` | Authentication SHA512 hash rounds number. |  |

## Notifications

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `patient_reminder_sender_name` | Patient Reminder Sender Name | text |  | Name of the sender for patient reminders. |  |
| `patient_reminder_sender_email` | Patient Reminder Sender Email | text |  | Email address of the sender for patient reminders. Replies to patient reminders will be directed to this address. It is important to use an address from your clinic's domain to avoid help prevent patient reminders from going to junk mail folders. |  |
| `practice_return_email_path` | Notification Email Address | text |  | Email address, if any, to receive administrative notifications. |  |
| `EMAIL_METHOD` | Email Transport Method | one of: `PHPMAIL` PHPMAIL; `SENDMAIL` SENDMAIL; `SMTP` SMTP | `SMTP` | Method for sending outgoing email. |  |
| `SMTP_HOST` | SMTP Server Hostname | text | `localhost` | If SMTP is used, the server`s hostname or IP address. |  |
| `SMTP_PORT` | SMTP Server Port Number | num | `25` | If SMTP is used, the server`s TCP port number (usually 25). |  |
| `SMTP_USER` | SMTP User for Authentication | text |  | Must be empty if SMTP authentication is not used. |  |
| `SMTP_PASS` | SMTP Password for Authentication | encrypted |  | Must be empty if SMTP authentication is not used. |  |
| `SMTP_SECURE` | SMTP Security Protocol | one of: `` None; `ssl` SSL; `tls` TLS |  | SMTP security protocol to connect with. Required by some servers such as gmail. |  |
| `EMAIL_NOTIFICATION_HOUR` | Email Notification Hours | num | `50` | Number of hours in advance to send email notifications. |  |
| `SMS_NOTIFICATION_HOUR` | SMS Notification Hours | num | `50` | Number of hours in advance to send SMS notifications. |  |
| `SMS_GATEWAY_USENAME` | SMS Gateway Username | text |  | Username for SMS Gateway. |  |
| `SMS_GATEWAY_PASSWORD` | SMS Gateway Password | text |  | Password for SMS Gateway. |  |
| `SMS_GATEWAY_APIKEY` | SMS Gateway API Key | text |  | API key for SMS Gateway. |  |
| `phone_notification_hour` | Phone Notification Hour | num | `50` | Number of hours in advance to send Phone notification. |  |
| `phone_gateway_username` | Phone Gateway Username | text |  | Username for Phone Gateway. |  |
| `phone_gateway_password` | Phone Gateway Password | encrypted |  | Password for Phone Gateway. |  |
| `phone_gateway_url` | Phone Gateway URL | text |  | URL for Phone Gateway. |  |

## CDR

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `enable_cdr` | Enable Clinical Decisions Rules (CDR) | bool | `1` | Enable Clinical Decisions Rules (CDR) |  |
| `enable_allergy_check` | Enable Allergy Check | bool | `1` | Enable Allergy Check Against Medications and Prescriptions |  |
| `enable_alert_log` | Enable Alert Log | bool | `1` | Enable Alert Logging |  |
| `enable_cdr_new_crp` | Enable Clinical Passive New Reminder(s) Popup | bool | `1` | Enable Clinical Passive New Reminder(s) Popup |  |
| `enable_cdr_crw` | Enable Clinical Passive Reminder Widget | bool | `1` | Enable Clinical Passive Reminder Widget |  |
| `enable_cdr_crp` | Enable Clinical Active Reminder Popup | bool | `1` | Enable Clinical Active Reminder Popup |  |
| `enable_cdr_prw` | Enable Patient Reminder Widget | bool | `1` | Enable Patient Reminder Widget |  |
| `enable_cqm` | Enable CQM Reporting | bool | `1` | Enable Clinical Quality Measure (CQM) Reporting |  |
| `pqri_registry_name` | PQRI Registry Name | text | `Model Registry` | PQRI Registry Name |  |
| `pqri_registry_id` | PQRI Registry ID | text | `125789123` | PQRI Registry ID |  |
| `cqm_performance_period` | Eligible Clinician eCQM Performance Period | text | `2025` | Enter the eCQM Performance Period year. For example 2025 |  |
| `enable_amc` | Enable AMC Reporting | bool | `1` | Enable Automated Measure Calculations (AMC) Reporting |  |
| `enable_amc_prompting` | Enable AMC Prompting | bool | `1` | Enable Prompting For Automated Measure Calculations (AMC) Required Data |  |
| `cdr_report_nice` | CDR Reports Processing Priority | one of: `` Default Priority; `5` Moderate Priority; `10` Moderate/Low Priority; `15` Low Priority; `20` Lowest Priority |  | Set processing priority for CDR engine based reports. |  |
| `pat_rem_clin_nice` | Patient Reminder Creation Processing Priority | one of: `` Default Priority; `5` Moderate Priority; `10` Moderate/Low Priority; `15` Low Priority; `20` Lowest Priority |  | Set processing priority for creation of Patient Reminders (in full clinic mode). |  |
| `report_itemizing_standard` | Enable Standard Report Itemization | bool | `1` | Enable Itemization of Standard Clinical Rules Reports |  |
| `report_itemizing_cqm` | Enable CQM Report Itemization | bool | `1` | Enable Itemization of CQM Reports |  |
| `report_itemizing_amc` | Enable AMC Report Itemization | bool | `1` | Enable Itemization of AMC Reports |  |
| `dated_reminders_max_alerts_to_show` | Dated reminders maximum alerts to show | num | `5` | Dated reminders maximum alerts to show |  |
| `patient_birthday_alert` | Alert on patient birthday | one of: `0` No alert; `1` Alert only on birthday; `2` Alert on and after birthday; `3` Alert on and up to 28 days after birthday | `1` | Alert on patient birthday |  |
| `patient_birthday_alert_manual_off` | Patient birthday alert requires turning off | bool | `0` | Patient birthday alert requires turning off |  |

## Logging

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `user_php_debug` | User Debug PHP Reporting Options | one of: `0` Use Server Defaults (Display off); `2` Display Errors Only; `3` Display Errors and Warnings Only; `4` Display Current Runtime Reporting | `0` | Controls PHP error display/debug behavior without overriding server defaults unless explicitly selected. | 8.2.0 |
| `user_debug` | Display Window Console Errors | bool | `0` | Console errors |  |
| `enable_auditlog` | Enable Audit Logging | bool | `1` | Enable Audit Logging |  |
| `audit_events_patient-record` | Audit Logging Patient Record | bool | `1` | Enable logging of patient record modifications. (Note that Audit Logging needs to be enabled above) |  |
| `audit_events_scheduling` | Audit Logging Scheduling | bool | `1` | Enable logging of scheduling activities. (Note that Audit Logging needs to be enabled above) |  |
| `audit_events_order` | Audit Logging Order | bool | `1` | Enable logging of ordering activities. (Note that Audit Logging needs to be enabled above) |  |
| `audit_events_lab-results` | Audit Logging Lab Results | bool | `1` | Enable logging of lab result activities. (Note that Audit Logging needs to be enabled above) | 7.0.4 |
| `audit_events_security-administration` | Audit Logging Security Administration | bool | `1` | Enable logging of security and administration activities. (Note that Audit Logging needs to be enabled above) |  |
| `audit_events_other` | Audit Logging Miscellaneous | bool | `1` | Enable logging of miscellaneous activities. (Note that Audit Logging needs to be enabled above) |  |
| `audit_events_query` | Audit Logging SELECT Query | bool | `0` | Enable logging of all SQL SELECT queries. (Note that Audit Logging needs to be enabled above) Required for ONC certified deployments. Warning: this logs every SELECT, so the audit log grows with query volume and can become far larger than the clinical data it describes. |  |
| `audit_events_cdr` | Audit CDR Engine Queries | bool | `0` | Enable logging of CDR Engine Queries. (Note that Audit Logging needs to be enabled above) |  |
| `audit_events_http-request` | Audit Logging user page history. | bool | `1` | Enable logging of HTTP page requests as the user utilizes the web interface. (Note that Audit Logging needs to be enabled above) | 7.0.4 |
| `gbl_force_log_breakglass` | Audit all Emergency User Queries | bool | `1` | Force logging of all Emergency User (ie. breakglass) activities. |  |
| `enable_atna_audit` | Enable ATNA Auditing | bool | `0` | Enable Audit Trail and Node Authentication (ATNA). |  |
| `atna_audit_host` | ATNA audit host | text |  | The hostname of the ATNA audit repository machine. |  |
| `atna_audit_port` | ATNA audit port | text | `6514` | Listening port of the RFC 5425 TLS syslog server. |  |
| `atna_audit_localcert` | ATNA audit local certificate | text |  | Certificate to send to RFC 5425 TLS syslog server. |  |
| `atna_audit_cacert` | ATNA audit CA certificate | text |  | CA Certificate for verifying the RFC 5425 TLS syslog server. |  |
| `api_log_option` | API Log Option | one of: `0` No logging; `1` Minimal Logging; `2` Full Logging | `2` | API Log Option (Full includes requests and responses). |  |
| `billing_log_option` | Billing Log Option | one of: `1` Billing Log Append; `2` Billing Log Overwrite | `1` | Billing log setting to append or overwrite the log file. |  |
| `gbl_print_log_option` | Printing Log Option | one of: `0` No logging; `1` Hide print feature; `2` Log entire document | `2` | Individual pages can override 2nd and 3rd options by implementing a log message. |  |
| `system_error_logging` | System Error Logging Options | one of: `WARNING` Standard Error Logging; `DEBUG` Debug Error Logging | `WARNING` | System Error Logging Options. |  |

## Miscellaneous

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `duplicate_patient_rescore_on_load` | Recompute Duplicate Scores On Every Report Load | bool | `1` | The Duplicate Patient Management report rescores every patient each time it loads. That keeps it accurate after a bulk import, but is slow on large installs. Turn this off where scores are already kept current when demographics change; the Recalculate Scores button still runs a full pass on demand. | 8.4.0 |
| `enable_database_connection_pooling` | Enable Database Connection Pooling | bool | `1` | Enable Database Connection Pooling |  |
| `temporary_files_dir` | Path to Temporary Files | text | set at run time: `$temporary_files_dir` | Full path to directory used for temporary files. |  |
| `backup_log_dir` | Path for Event Log Backup | text | set at run time: `$backup_log_dir` | Full path to directory for event log backup. |  |
| `state_data_type` | State Data Type | one of: `2` Text field; `1` Single-selection list; `26` Single-selection list with ability to add to the list | `26` | Field type to use for employer or subscriber state in demographics. |  |
| `state_list` | State list | text | `state` | List used by above State Data Type option. |  |
| `state_custom_addlist_widget` | State List Widget Custom Fields | bool | `1` | Show the custom state form for the add list widget (will ask for title and abbreviation). |  |
| `country_data_type` | Country Data Type | one of: `2` Text field; `1` Single-selection list; `26` Single-selection list with ability to add to the list | `26` | Field type to use for employer or subscriber country in demographics. |  |
| `country_list` | Country list | text | `country` | List used by above Country Data Type option. |  |
| `post_to_date_benchmark` | Financial Close Date (yyyy-mm-dd) | text | set at run time: `date('Y-m-d', time() - 10 * 24 * 60 * 60)` | The payments posted cannot go below this date.This ensures that after taking the final report nobody post for previous dates. |  |
| `enable_hylafax` | Enable Hylafax Support | bool | `0` | Enable Hylafax Support |  |
| `hylafax_server` | Hylafax Server | text | `localhost` | Hylafax server hostname. |  |
| `hylafax_basedir` | Hylafax Directory | text | `/var/spool/hylafax` | Location where Hylafax stores faxes. |  |
| `enable_scanner` | Enable Scanner Support | bool | `0` | Enable Scanner Support |  |
| `scanner_output_directory` | Scanner Directory | text | `/mnt/scan_docs` | Location where scans are stored. |  |
| `unique_installation_id` | Unique Installation ID | if_empty_create_random_uuid |  | Unique installation ID. Creates a random UUID if empty. |  |

## Portal

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `portal_onsite_two_enable` | Enable Patient Portal | bool | `0` | Enable Patient Portal |  |
| `portal_onsite_two_address` | Patient Portal Site Address | text | `https://your_web_site.com/openemr/portal` | Website link for the Patient Portal. |  |
| `portal_css_header` | Portal Default Theme | one of: `style_light.css` Light; `style_dark.css` Dark | `style_light.css` | Pick a default portal theme. | 7.0.2 |
| `portal_force_credential_reset` | Portal Login Forced Credential Reset | one of: `0` Allow (Recommended); `1` Disable; `2` User optional from credential dialog. | `0` | Select the credentials create or reset behavior for forcing patient to change password on portal login.User optional persists the options checkbox state in the credential dialog to allow deciding on a patient by patient basis. | 7.0.2 |
| `portal_onsite_two_basepath` | Portal Uses Server Base Path (internal) | bool | `0` | Use servers protocol and host in urls (portal internal only). |  |
| `use_email_for_portal_username` | Use Patients on-record E-Mail for new Portal Login Username | bool | `1` | Use contact email when creating portal credentials. | 7.0.3 |
| `enforce_signin_email` | Require Patients to enter their on-record email for Portal Login | bool | `1` | Patient is required to enter their contact e-mail if present in Demographics Contact. |  |
| `google_recaptcha_site_key` | Google reCAPTCHA V2 site key | text |  | Google reCAPTCHA V2 site key |  |
| `google_recaptcha_secret_key` | Google reCAPTCHA V2 secret key | encrypted |  | Google reCAPTCHA V2 secret key |  |
| `portal_primary_menu_logo_height` | Primary Menu Logo Height | text | `30` | The height of the portal logo located on the primary navbar in pixels without a suffix | 7.0.2 |
| `portal_onsite_two_register` | Allow New Patient Registration Widget This requires reCAPTCHA to be setup | bool | `0` | Enable Patient Portal new patient to self register. |  |
| `portal_two_pass_reset` | Allow Patients to Reset Credentials This requires reCAPTCHA to be setup | bool | `0` | Patient may change their logon from portal login dialog. |  |
| `allow_portal_appointments` | Allow Online Appointments | bool | `1` | Allow Patient to make and view appointments online. |  |
| `view_only_portal_appointments` | Allow Online Appointments View Only. | bool | `0` | Allow Patient only to view appointments online. Overrides the above setting to allow only view of appointments. | 8.2.0 |
| `allow_custom_report` | Allow Online Custom Content Report | bool | `1` | Allow Patient to use Custom Content Report. | 7.0.3 |
| `portal_two_ledger` | Allow Patient Billing Summary Report Online | bool | `1` | Allow Patient to view their accounting ledger online. |  |
| `portal_two_payments` | Allow Online Payments | bool | `0` | Allow Patient to make payments online. |  |
| `portal_onsite_document_download` | Enable Patient Portal Document Download | bool | `1` | Enables the ability to download documents in the Patient Portal by the user. |  |
| `allow_portal_uploads` | Allow Patient Uploads from Portal Documents | bool | `1` | Enables the ability for patient to upload documents to Documents Onsite Patient category. | 7.0.3 |
| `show_insurance_in_profile` | Allow Insurances in Patient Profile | bool | `1` | UnCheck to not show insurances in Profile. | 7.0.3 |
| `show_portal_primary_logo` | Show Primary Logo on portal login page | bool | `1` | Show primary logo on login | 7.0.3 |
| `extra_portal_logo_login` | Show Secondary Logo on portal Login page | bool | `0` | Show Secondary Logo on Login | 7.0.3 |
| `secondary_portal_logo_position` | Order of the Secondary logo | one of: `first` First Position; `second` Second Position | `second` | Place the secondary logo first, or second | 7.0.3 |

## Connectors

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `site_addr_oath` | Site Address Override (if needed for OAuth2, FHIR, CCDA, or Payment Processing) | text |  | The hostname for OAuth2, FHIR, CCDA, and Payment Processing, pointing back back to this OpenEMR instance. e.g. https://localhost:9300. |  |
| `rest_fhir_api` | Enable OpenEMR Standard FHIR REST API | bool | `0` | Enable OpenEMR Standard FHIR RESTful API. |  |
| `smart_context_test_launches` | Enable OpenEMR SMART ON FHIR Context Test Launches (Turn on only if you know what you are doing) | bool | `0` | Enable OpenEMR SMART ON FHIR Current Context Test Launches. | 8.3.0 |
| `rest_system_scopes_api` | Enable OpenEMR FHIR System Scopes (Turn on only if you know what you are doing) | bool | `0` | Enable OpenEMR FHIR System Scopes. |  |
| `rest_api` | Enable OpenEMR Standard REST API | bool | `0` | Enable OpenEMR Standard RESTful API. |  |
| `rest_portal_api` | Enable OpenEMR Patient Portal REST API (EXPERIMENTAL) | bool | `0` | Enable OpenEMR Patient Portal RESTful API. |  |
| `oauth_password_grant` | Enable OAuth2 Password Grant (Not considered secure) | one of: `0` Off (Recommended setting); `1` On for Users Role; `2` On for Patient Role; `3` On for Both Roles | `0` | Enable OAuth2 Password Grant. Recommend turning this setting off for production server. Recommend only using for testing. |  |
| `oauth_app_manual_approval` | OAuth2 App Manual Approval Settings | one of: `0` Patient standalone apps Auto Approved, EHR-Launch,Provider&System Apps require manual approval; `1` Manually Approve All Apps (USA jurisdictions must approve all patient standalone apps within 48 hours) | `0` | Approval settings for 3rd party app/api access | 7.0.1 |
| `oauth_ehr_launch_authorization_flow_skip` | OAuth2 EHR-Launch Authorization Flow Skip Enable App Setting | bool | `1` | Enable an OAuth2 Client application to be configured to skip the login screen and the scope authorization screen if the user is already logged into the EHR. | 7.0.2 |
| `fhir_us_core_profile_version` | Maximum supported version for US Core FHIR Implementation Guide -- note if a resource/profile is forwards compatible it will still be supported | one of: `3.1.1` US Core 3.1.1; `7.0.0` US Core 7.0.0; `8.0.0` US Core 8.0.0 | `8.0.0` | Set the maximum compatibility version of US Core IG to support.  If a resource profile has breaking changes it will not exceed the given profile. If a profile has backwards breaking changes it will skip that profile version if a later version is supported. | 7.0.4 |
| `cc_front_payments` | Accept Credit Card transactions from Front Payments | bool | `0` | Allow manual entry and authorise credit card payments. Ensure a gateway is enabled. |  |
| `cc_stripe_terminal` | In person payments with Stripe Verifone P400 | bool | `0` | Allow in person credit card payments using Stripe Verifone P400. Ensure Stripe gateway is enabled. |  |
| `payment_gateway` | Select Credit Card Payment Gateway | one of: `InHouse` In House Authorize Payments; `AuthorizeNet` Gateway for AuthorizeNet Manual Payments; `Sphere` Gateway for Sphere Payments; `Stripe` Gateway for Stripe Manual Payments; `Rainforest` Gateway for Rainforest payments | `InHouse` | Enable a Payment Gateway Service for processing credit card transactions |  |
| `gateway_mode_production` | Set Gateway to Production Mode | bool | `0` | Check this to go live. Not checked is testing mode. |  |
| `gateway_public_key` | Gateway Publishable Key | encrypted |  | The public access key for secure tokenize of credit or debit card authorization. PCI compliance |  |
| `gateway_api_key` | Gateway API Login Auth Name or Secret | encrypted |  | The Auth Name or API key for selected account. API Login ID for Authorize.Net and API Secret for Stripe. |  |
| `gateway_transaction_key` | Gateway Transaction Key | encrypted |  | Mainly Authorize.Net uses two keys |  |
| `rainforest_api_key` | Rainforest API Key | encrypted |  | Used when payment_gateway is Rainforest. Stored encrypted | 8.1.0 |
| `rainforest_merchant_id` | Rainforest Merchant ID | text |  | Used when payment_gateway is Rainforest. | 8.1.0 |
| `rainforest_platform_id` | Rainforest Platform ID | text |  | Used when payment_gateway is Rainforest. | 8.1.0 |
| `rainforest_webhook_secret` | Rainforest Webhook Secret | encrypted |  | Used when payment_gateway is Rainforest. Stored encrypted | 8.1.0 |
| `sphere_clinicfront_trxcustid` | Sphere Clinicfront over phone (MOTO) Transaction CustID | encrypted |  | Sphere Clinicfront over phone (MOTO) Transaction CustID |  |
| `sphere_clinicfront_trxcustid_licensekey` | Sphere Clinicfront over phone (MOTO) Transaction CustID License Key | encrypted |  | Sphere Clinicfront over phone (MOTO) Transaction CustID License Key |  |
| `sphere_moto_tc_link_pass` | Sphere MOTO TC Link Password | encrypted |  | Sphere MOTO TC Link Password |  |
| `sphere_clinicfront_retail_trxcustid` | Sphere Clinicfront in person (RETAIL) Transaction CustID | encrypted |  | Sphere Clinicfront in person (RETAIL) Transaction CustID |  |
| `sphere_clinicfront_retail_trxcustid_licensekey` | Sphere Clinicfront in person (RETAIL) Transaction CustID License Key | encrypted |  | Sphere Clinicfront in person (RETAIL) Transaction CustID License Key |  |
| `sphere_retail_tc_link_pass` | Sphere RETAIL TC Link Password | encrypted |  | Sphere RETAIL TC Link Password |  |
| `sphere_patientfront_trxcustid` | Sphere Patientfront (Ecomm) Transaction CustID | encrypted |  | Sphere Patientfront (Ecomm) Transaction CustID |  |
| `sphere_patientfront_trxcustid_licensekey` | Sphere Patientfront (Ecomm) Transaction CustID License Key | encrypted |  | Sphere Patientfront (Ecomm) Transaction CustID License Key |  |
| `sphere_ecomm_tc_link_pass` | Sphere Ecomm TC Link Password | encrypted |  | Sphere Ecomm TC Link Password |  |
| `sphere_credit_void_confirm_pin` | Sphere Void/Credit Confirmation PIN | encrypted_hash |  | Sphere Void/Credit Confirmation Password. OpenEMR confirms pin/password before proceeding with void/credit. |  |
| `medex_enable` | Enable MedEx Communication Service | bool | `0` | Enable MedEx Communication Service |  |
| `erx_enable` | Enable Ensora eRx Service | bool | `0` | Enable Ensora eRx Service. |  |
| `erx_newcrop_path` | Ensora eRx Site Address | text | `https://secure.newcropaccounts.com/ux2/InterfaceV7/RxEntry.aspx` | URL for Ensora eRx Site Address. |  |
| `erx_newcrop_path_soap` | Ensora eRx Web Service Address | text | `https://secure.newcropaccounts.com/v7/WebServices/Update1.asmx?WSDL;https://secure.newcropaccounts.com/v7/WebServices/Patient.asmx?WSDL` | URLs for Ensora eRx Service Address, separated by a semi-colon. |  |
| `erx_soap_ttl_allergies` | Ensora eRx SOAP Request Time-To-Live for Allergies | num | `21600` | Time-To-Live for Ensora eRx Allergies SOAP Request in seconds. |  |
| `erx_soap_ttl_medications` | Ensora eRx SOAP Request Time-To-Live for Medications | num | `21600` | Time-To-Live for Ensora eRx Medications SOAP Request in seconds. |  |
| `erx_account_partner_name` | Ensora eRx Partner Name | text |  | Partner Name issued for Ensora eRx service. |  |
| `erx_account_name` | Ensora eRx Name | text |  | Account Name issued for Ensora eRx service. |  |
| `erx_account_password` | Ensora eRx Password | encrypted |  | Account Password issued for Ensora eRx service. |  |
| `erx_account_id` | Ensora eRx Account Id | text | `1` | Account Id issued for Ensora eRx service, used to separate multi-facility accounts. |  |
| `erx_upload_active` | Only upload active prescriptions | bool | `0` | Only upload active prescriptions to Ensora eRx. |  |
| `erx_import_status_message` | Enable Ensora eRx import status message | bool | `0` | Enable import status message after visiting Ensora eRx. |  |
| `erx_medication_display` | Do not display Ensora eRx Medications uploaded | bool | `0` | Do not display Medications uploaded after visiting Ensora eRx. |  |
| `erx_allergy_display` | Do not display Ensora eRx Allergy uploaded | bool | `0` | Do not display Allergies uploaded after visiting Ensora eRx. |  |
| `erx_default_patient_country` | Ensora eRx Default Patient Country | one of: `` ; `US` USA; `CA` Canada; `MX` Mexico |  | Default Patient Country sent to Ensora eRx, only if patient country is not set. |  |
| `erx_debug_setting` | Ensora eRx Debug Setting | one of: `0` None; `1` Request Only; `2` Response Only; `3` Request & Response | `0` | Log all Ensora eRx Requests and / or Responses. |  |
| `ccda_alt_service_enable` | Enable C-CDA Service | one of: `0` Off; `1` Care Coordination Only; `2` Portal Only; `3` Both | `0` | Enable C-CDA Service |  |
| `phimail_enable` | Enable phiMail Direct Messaging Service | bool | `0` | Enable phiMail Direct Messaging Service |  |
| `phimail_testmode_disabled` | Disable phiMail Test Mode | bool | `0` | When you are ready to run phiMail in production mode. Turn on this flag. |  |
| `phimail_verifyrecipientreceived_enable` | phiMail default force message receipt confirmation to on | bool | `0` | Marks a message as successful only if recipient confirms they received the message.  This can fail messages that otherwise would have been received if the recipient's system does not support confirmation receipt |  |
| `phimail_server_address` | phiMail Server Address | text | `https://phimail.example.com:32541` | Contact EMR Direct to subscribe to the phiMail Direct messaging service |  |
| `phimail_username` | phiMail Username | text |  | Contact EMR Direct to subscribe to the phiMail Direct messaging service |  |
| `phimail_password` | phiMail Password | encrypted |  | Contact EMR Direct to subscribe to the phiMail Direct messaging service |  |
| `phimail_notify` | phiMail notification user | text | `admin` | This user will receive notification of new incoming Direct messages |  |
| `phimail_interval` | phiMail Message Check Interval (minutes) | num | `5` | Interval between message checks (set to zero for manual checks only) |  |
| `phimail_ccd_enable` | phiMail Allow CCD Send | bool | `0` | phiMail Allow CCD Send |  |
| `phimail_ccr_enable` | phiMail Allow CCR Send | bool | `0` | phiMail Allow CCR Send |  |
| `easipro_enable` | Enable Easipro | bool | `0` | Enable Easipro. For licensing options for this feature, please contact api@assessmentcenter.net |  |
| `easipro_server` | Easipro Server | text |  | Easipro Server |  |
| `easipro_name` | Easipro Server Username | text |  | Easipro Server Username |  |
| `easipro_pass` | Easipro Server Password | encrypted |  | Easipro Server Password |  |
| `usps_apiv3_client_id` | USPS API Client ID | encrypted |  | Client ID for USPS API v3 | 7.0.4 |
| `usps_apiv3_client_secret` | USPS API Client Secret | encrypted |  | Client Secret for USPS API v3 | 7.0.4 |
| `ccda_validation_disable` | Disable All import CDA Validation Reporting | bool | `0` | Disable All CDA conformance and validation services to improve import performance | 7.0.1 |
| `mdht_conformance_server_enable` | Use MDHT External Validation Service | bool | `0` | Enable CCDA conformance and validation API service |  |
| `mdht_conformance_server` | CCDA MDHT Validation API Server Address | text |  | CCDA conformance and validation API service URL. For testing (using ONLY test data) you can default to http://ccda.healthit.gov which should not be used to transmit PHI. Production sites can deploy their own by following instructions here https://github.com/onc-healthit/reference-ccda-validator. |  |

## Rx

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `rx_enable_DEA` | Rx Enable DEA # | bool | `1` | Rx Enable DEA # |  |
| `rx_show_DEA` | Rx Show DEA # | bool | `0` | Rx Show DEA # |  |
| `rx_enable_NPI` | Rx Enable NPI | bool | `0` | Rx Enable NPI |  |
| `rx_show_NPI` | Rx Show NPI | bool | `0` | Rx Show NPI |  |
| `rx_enable_SLN` | Rx Enable State Lic. # | bool | `0` | Rx Enable State Lic. # |  |
| `rx_show_SLN` | Rx Show State Lic. # | bool | `0` | Rx Show State Lic. # |  |
| `rx_show_drug_drug` | Rx NLM Drug-Drug | bool | `0` | Rx NLM Drug-Drug |  |
| `rx_paper_size` | Rx Paper Size | one of: `LETTER` Letter Paper Size; `LEGAL` Legal Paper Size; `FOLIO` Folio Paper Size; `EXECUTIVE` Executive Paper Size; `4A0` 4A0 Paper Size; `2A0` 2A0 Paper Size; `A0` A0 Paper Size; `A1` A1 Paper Size; `A2` A2 Paper Size; `A3` A3 Paper Size; `A4` A4 Paper Size; `A5` A5 Paper Size; `A6` A6 Paper Size; `A7` A7 Paper Size; `A8` A8 Paper Size; `A9` A9 Paper Size; `A10` A10 Paper Size; `B0` B0 Paper Size; `B1` B1 Paper Size; `B2` B2 Paper Size; `B3` B3 Paper Size; `B4` B4 Paper Size; `B5` B5 Paper Size; `B6` B6 Paper Size; `B7` B7 Paper Size; `B8` B8 Paper Size; `B9` B9 Paper Size; `B10` B10 Paper Size; `C0` C0 Paper Size; `C1` C1 Paper Size; `C2` C2 Paper Size; `C3` C3 Paper Size; `C4` C4 Paper Size; `C5` C5 Paper Size; `C6` C6 Paper Size; `C7` C7 Paper Size; `C8` C8 Paper Size; `C9` C9 Paper Size; `C10` C10 Paper Size; `RA0` RA0 Paper Size; `RA1` RA1 Paper Size; `RA2` RA2 Paper Size; `RA3` RA3 Paper Size; `RA4` RA4 Paper Size; `SRA0` SRA0 Paper Size; `SRA1` SRA1 Paper Size; `SRA2` SRA2 Paper Size; `SRA3` SRA3 Paper Size; `SRA4` SRA4 Paper Size | `LETTER` | Rx Paper Size |  |
| `rx_left_margin` | Rx Left Margin (px) | num | `30` | Rx Left Margin (px) |  |
| `rx_right_margin` | Rx Right Margin (px) | num | `30` | Rx Right Margin (px) |  |
| `rx_top_margin` | Rx Top Margin (px) | num | `72` | Rx Top Margin (px) |  |
| `rx_bottom_margin` | Rx Bottom Margin (px) | num | `30` | Rx Bottom Margin (px) |  |
| `rx_use_fax_template` | Show button for download fax template | bool | `1` | Show button in the prescription list for download fax template |  |
| `rx_zend_html_template` | Rx html print - zend module | bool | `0` | Use an html template from zend module |  |
| `rx_zend_html_action` | Name of zend template for html print | text | `default` | Name of zend template for html print, possible to add custom template in the PrescriptionTemplate module |  |
| `rx_zend_pdf_template` | Rx pdf - zend template | bool | `0` | Use a pdf template from zend module |  |
| `rx_zend_pdf_action` | Name of zend template for pdf export | text | `default` | Name of zend template for pdf export, possible to add custom template in the PrescriptionTemplate module |  |
| `rx_send_email` | Allow email sending of prescriptions | bool | `1` | Enable email option (available on prescriptions list screen) for emailing prescriptions | 7.0.3 |

## PDF

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `pdf_layout` | Layout | one of: `P` Portrait; `L` Landscape | `P` | Choose Layout Direction |  |
| `pdf_language` | PDF Language | one of: `aa` Afar; `af` Afrikaans; `ak` Akan; `sq` Albanian; `am` Amharic; `ar` Arabic; `an` Aragonese; `hy` Armenian; `as` Assamese; `av` Avaric; `ae` Avestan; `ay` Aymara; `az` Azerbaijani; `bm` Bambara; `ba` Bashkir; `eu` Basque; `be` Belarusian; `bn` Bengali- Bangla; `bh` Bihari; `bi` Bislama; `bs` Bosnian; `br` Breton; `bg` Bulgarian; `my` Burmese; `ca` Catalan- Valencian; `ch` Chamorro; `ce` Chechen; `ny` Chichewa- Chewa- Nyanja; `zh` Chinese; `cv` Chuvash; `kw` Cornish; `co` Corsican; `cr` Cree; `hr` Croatian; `cs` Czech; `da` Danish; `dv` Divehi- Dhivehi- Maldivian-; `nl` Dutch; `dz` Dzongkha; `en` English; `eo` Esperanto; `et` Estonian; `ee` Ewe; `fo` Faroese; `fj` Fijian; `fi` Finnish; `fr` French; `ff` Fula- Fulah- Pulaar- Pular; `gl` Galician; `ka` Georgian; `de` German; `el` Greek, Modern; `gn` Guarani; `gu` Gujarati; `ht` Haitian- Haitian Creole; `ha` Hausa; `he` Hebrew (modern); `hz` Herero; `hi` Hindi; `ho` Hiri Motu; `hu` Hungarian; `ia` Interlingua; `id` Indonesian; `ie` Interlingue; `ga` Irish; `ig` Igbo; `ik` Inupiaq; `io` Ido; `is` Icelandic; `it` Italian; `iu` Inuktitut; `ja` Japanese; `jv` Javanese; `kl` Kalaallisut, Greenlandic; `kn` Kannada; `kr` Kanuri; `ks` Kashmiri; `kk` Kazakh; `km` Khmer; `ki` Kikuyu, Gikuyu; `rw` Kinyarwanda; `ky` Kyrgyz; `kv` Komi; `kg` Kongo; `ko` Korean; `ku` Kurdish; `kj` Kwanyama, Kuanyama; `la` Latin; `lb` Luxembourgish, Letzeburgesch; `lg` Ganda; `li` Limburgish, Limburgan, Limburger; `ln` Lingala; `lo` Lao; `lt` Lithuanian; `lu` Luba-Katanga; `lv` Latvian; `gv` Manx; `mk` Macedonian; `mg` Malagasy; `ms` Malay; `ml` Malayalam; `mt` Maltese; `mi` Maori; `mr` Marathi (Marathi); `mh` Marshallese; `mn` Mongolian; `na` Nauru; `nv` Navajo, Navaho; `nb` Norwegian Bokmal; `nd` North Ndebele; `ne` Nepali; `ng` Ndonga; `nn` Norwegian Nynorsk; `no` Norwegian; `ii` Nuosu; `nr` South Ndebele; `oc` Occitan; `oj` Ojibwe, Ojibwa; `cu` Old Church Slavonic, Church Slavonic, Old Bulgarian; `om` Oromo; `or` Oriya; `os` Ossetian, Ossetic; `pa` Panjabi, Punjabi; `pi` Pali; `fa` Persian (Farsi); `pl` Polish; `ps` Pashto, Pushto; `pt` Portuguese; `qu` Quechua; `rm` Romansh; `rn` Kirundi; `ro` Romanian; `ru` Russian; `sa` Sanskrit (Samskrta); `sc` Sardinian; `sd` Sindhi; `se` Northern Sami; `sm` Samoan; `sg` Sango; `sr` Serbian; `gd` Scottish Gaelic- Gaelic; `sn` Shona; `si` Sinhala, Sinhalese; `sk` Slovak; `sl` Slovene; `so` Somali; `st` Southern Sotho; `es` Spanish- Castilian; `su` Sundanese; `sw` Swahili; `ss` Swati; `sv` Swedish; `ta` Tamil; `te` Telugu; `tg` Tajik; `th` Thai; `ti` Tigrinya; `bo` Tibetan Standard, Tibetan, Central; `tk` Turkmen; `tl` Tagalog; `tn` Tswana; `to` Tonga (Tonga Islands); `tr` Turkish; `ts` Tsonga; `tt` Tatar; `tw` Twi; `ty` Tahitian; `ug` Uyghur, Uighur; `uk` Ukrainian; `ur` Urdu; `uz` Uzbek; `ve` Venda; `vi` Vietnamese; `vo` Volapuk; `wa` Walloon; `cy` Welsh; `wo` Wolof; `fy` Western Frisian; `xh` Xhosa; `yi` Yiddish; `yo` Yoruba; `za` Zhuang, Chuang; `zu` Zulu | `en` | Choose PDF language Preference |  |
| `pdf_size` | Paper Size | one of: `LETTER` Letter Paper Size; `LEGAL` Legal Paper Size; `FOLIO` Folio Paper Size; `EXECUTIVE` Executive Paper Size; `4A0` 4A0 Paper Size; `2A0` 2A0 Paper Size; `A0` A0 Paper Size; `A1` A1 Paper Size; `A2` A2 Paper Size; `A3` A3 Paper Size; `A4` A4 Paper Size; `A5` A5 Paper Size; `A6` A6 Paper Size; `A7` A7 Paper Size; `A8` A8 Paper Size; `A9` A9 Paper Size; `A10` A10 Paper Size; `B0` B0 Paper Size; `B1` B1 Paper Size; `B2` B2 Paper Size; `B3` B3 Paper Size; `B4` B4 Paper Size; `B5` B5 Paper Size; `B6` B6 Paper Size; `B7` B7 Paper Size; `B8` B8 Paper Size; `B9` B9 Paper Size; `B10` B10 Paper Size; `C0` C0 Paper Size; `C1` C1 Paper Size; `C2` C2 Paper Size; `C3` C3 Paper Size; `C4` C4 Paper Size; `C5` C5 Paper Size; `C6` C6 Paper Size; `C7` C7 Paper Size; `C8` C8 Paper Size; `C9` C9 Paper Size; `C10` C10 Paper Size; `RA0` RA0 Paper Size; `RA1` RA1 Paper Size; `RA2` RA2 Paper Size; `RA3` RA3 Paper Size; `RA4` RA4 Paper Size; `SRA0` SRA0 Paper Size; `SRA1` SRA1 Paper Size; `SRA2` SRA2 Paper Size; `SRA3` SRA3 Paper Size; `SRA4` SRA4 Paper Size | `LETTER` | Choose Paper Size |  |
| `pdf_font_size` | PDF Font Size in Pt | num | `10` | Sets the font size for most PDF text in pt | 7.0.3 |
| `pdf_left_margin` | Left Margin (mm) | num | `5` | Left Margin (mm) |  |
| `pdf_right_margin` | Right Margin (mm) | num | `5` | Right Margin (mm) |  |
| `pdf_top_margin` | Top Margin (mm) | num | `5` | Top Margin (mm) |  |
| `pdf_bottom_margin` | Bottom Margin (px) | num | `8` | Bottom Margin (px) |  |
| `pdf_output` | Output Type | one of: `D` Download; `I` Inline | `D` | Choose Download or Display Inline |  |
| `chart_label_type` | Patient Label Type | one of: `0` None; `1` 5160; `2` 5161; `3` 5162 | `1` | Avery Label type for printing patient labels from popups in left nav screen |  |
| `barcode_label_type` | Barcode Label Type | one of: `0` None; `1` std25; `2` int25; `3` ean8; `4` ean13; `5` upc; `6` code11; `7` code39; `8` code93; `9` code128; `10` codabar; `11` msi; `12` datamatrix | `9` | Barcode type for printing barcode labels from popups in left nav screen. |  |
| `addr_label_type` | Print Patient Address Label | bool | `1` | Select to print patient address labels from popups in left nav screen. |  |
| `env_x_width` | Envelope Width in mm | num | `104.775` | In Portrait mode, determines the width of the envelope along the x-axis in mm |  |
| `env_y_height` | Envelope Height in mm | num | `241.3` | In Portrait mode, determines the height of the envelope along the y-axis in mm |  |
| `env_font_size` | Envelope Font Size in Pt | num | `14` | Sets the font of the address text on the envelope in mm |  |
| `env_x_dist` | Envelope x-axis starting pt | num | `65` | Distance from the 'top' of the envelope in mm |  |
| `env_y_dist` | Envelope y-axis starting pt | num | `220` | Distance from the right most edge of the envelope in portrait position in mm |  |

## Patient Banner Bar

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `patient_name_display` | Patient Name Display | one of: `btn` As Button; `text` As Text Link; `text-large` As Large Text Link | `text-large` | How to display the patient name |  |

## Encounter Form

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `default_chief_complaint` | Default Reason for Visit | text |  | You may put text here as the default complaint in the New Patient Encounter form. |  |
| `default_visit_category` | Default Visit Category | default_visit_category | `_blank` | Define a default visit category |  |
| `enable_follow_up_encounters` | Enable follow-up encounters | bool | `0` | Enable follow-up encounters feature |  |
| `gbl_visit_referral_source` | Referral Source for Encounters | bool | `0` | A referral source may be specified for each visit. |  |
| `gbl_visit_onset_date` | Onset/Hosp Date for Encounters | bool | `1` | An onset/hospitalization date may be specified for each visit. |  |
| `set_pos_code_encounter` | Set POS code in Encounter | bool | `0` | This feature will allow the default POS facility code to be overridden from the encounter. |  |
| `set_service_facility_encounter` | Set Service Facility in Encounter To First Care Team Facility | bool | `0` | This feature will allow the default service facility to be selected by the care team facility in Choices. | 7.0.1 |
| `enc_service_date` | Show Date of Service on Encounter Form | set at run time: `getDefaultRenderListOptions()` | set at run time: `RenderFormFieldHelper::SHOW_ALL` | How to display the Date of Service on the Encounter form. Defaults to the current time on a new form |  |
| `enc_sensitivity_visibility` | Show Sensitivity on Encounter Form | set at run time: `getDefaultRenderListOptions()` | set at run time: `RenderFormFieldHelper::SHOW_ALL` | How to display the sensitivity option |  |
| `enc_in_collection` | Show In Collection on Encounter Form | set at run time: `getDefaultRenderListOptions()` | set at run time: `RenderFormFieldHelper::SHOW_ALL` | How to display the 'In Collection' option. May be overridden by Hide Billing Widget setting | 7.0.2 |
| `enc_enable_issues` | Allow Linking/Adding Issues on Encounter | set at run time: `getDefaultRenderListOptions()` | set at run time: `RenderFormFieldHelper::SHOW_ALL` | Allow issues to be linked or added to an encounter |  |
| `enc_enable_referring_provider` | Show Referring Provider option on Encounters | set at run time: `getDefaultRenderListOptions()` | set at run time: `RenderFormFieldHelper::SHOW_ALL` | Display the Referring Provider option on Encounters |  |
| `enc_enable_facility` | Show Facility option on Encounters | set at run time: `getDefaultRenderListOptions()` | set at run time: `RenderFormFieldHelper::SHOW_ALL` | Display the Referring Provider option on Encounters |  |
| `enc_enable_discharge_disposition` | Show Discharge Disposition option on Encounters | set at run time: `getDefaultRenderListOptions()` | set at run time: `RenderFormFieldHelper::SHOW_ALL` | Display the Discharge Disposition option on the Encounter form |  |
| `enc_enable_visit_category` | Show Visit Category option on Encounters | set at run time: `getDefaultRenderListOptions()` | set at run time: `RenderFormFieldHelper::SHOW_ALL` | Show Visit Category option on Encounters |  |
| `enc_enable_class` | Show Encounter Class option on Encounters | set at run time: `getDefaultRenderListOptions()` | set at run time: `RenderFormFieldHelper::SHOW_ALL` | Show Encounter Class option on Encounters |  |
| `enc_enable_type` | Show Encounter Type option on Encounters | set at run time: `getDefaultRenderListOptions()` | set at run time: `RenderFormFieldHelper::SHOW_ALL` | Show Encounter Type option on Encounters |  |
| `enc_enable_ordering_provider` | Show Ordering Provider option on Encounters | set at run time: `getDefaultRenderListOptions()` | set at run time: `RenderFormFieldHelper::HIDE_ALL` | Display the Ordering Provider option on Encounters | 7.0.3 |

## Questionnaires

| Setting | Label | Type | Default | Description | New in |
|---|---|---|---|---|---|
| `questionnaire_display_LOINCnote` | Display LOINC note on questionnaires | one of: `0` At the top of the page only; `1` At the foot of the page only; `2` At the top of the page and at the foot of the page; `3` Do not display the note | `3` | Configure where LOINC statement should be displayed | 7.0.3 |
| `questionnaire_display_style` | Questionnaire Form Display Style | one of: `0` OpenEMR Auto Select Dark/Light Theme; `3` OpenEMR Light Theme Always; `4` OpenEMR Dark Theme Always | `0` | Choose automatic theme selection or always use the light or dark Questionnaire theme. | 7.0.3 |
| `questionnaire_display_fullscreen` | Turn off full screen display for Questionnaire Forms | bool | `0` | Default form width of Questionnaire display. | 7.0.3 |

## Removed since 7.0.0

- `default_second_tab`: removed in 7.0.2
- `default_top_pane`: removed in 7.0.2
- `enable_oa`: removed in 7.0.2
- `gbl_nav_area_width`: removed in 7.0.2
- `gbl_tall_nav_area`: removed in 7.0.2
- `allow_portal_chat`: removed in 7.0.3
- `weno_encryption_key`: removed in 7.0.3
- `weno_provider_password`: removed in 7.0.3
- `weno_rx_enable`: removed in 7.0.3
- `weno_rx_enable_test`: removed in 7.0.3
- `menu_styling_vertical`: removed in 7.0.4
- `usps_webtools_enable`: removed in 7.0.4
- `usps_webtools_username`: removed in 7.0.4
- `allow_multiple_databases`: removed in 8.1.0
- `enable_amc_tracking`: removed in 8.1.0
- `gbl_nav_visit_forms`: removed in 8.1.0
- `machine_name`: removed in 8.1.0
- `safe_key_database`: removed in 8.1.0
- `certificate_authority_crt`: removed in 8.2.0
- `certificate_authority_key`: removed in 8.2.0
- `client_certificate_valid_in_days`: removed in 8.2.0
- `enable_auditlog_encryption`: removed in 8.2.0
- `is_client_ssl_enabled`: removed in 8.2.0
- `audit_events_backup`: removed in 8.3.0
- `configuration_import_export`: removed in 8.3.0
- `mysql_bin_dir`: removed in 8.3.0
- `perl_bin_dir`: removed in 8.3.0

---

*Generated by [openemr-reference](../../README.md) from OpenEMR `v8_4_1` (a43edad9ea). Every statement on this page was read from the source at those tags; nothing is written by hand.*
