#!/usr/bin/env python3
"""A synthetic, Pohnpei-shaped health center for the end-to-end tests. Every person is made up.

    python3 -I preflight/test_site.py [--copays] > site.sql SQL for an OpenEMR 7.0.3 database (--copays: with
                                                          fee-sheet co-pays, which 8.5.0's Receipts by
                                                          Payment Method report can't show)
    python3 -I preflight/test_site.py --documents > d.php   PHP that stores its documents through
                                                          OpenEMR's own Document class (run in the
                                                          7.0.3 folder: php d.php)

A clinic in Kolonia (ZIP 96941) and a dispensary, three providers, the FSM MiCare insurer and a private
one, 420 made-up patients with 2024-2025 visits and fee-sheet codes, and the list and layout edits a
Micronesian site might make. On top of that, what a receipt counts: appointments, prescriptions, lab
orders with results, vitals, SOAP notes and a layout-based form, insurance and patient payments with
adjustments (some voided), co-pays, front-desk receipts, dispensed drugs, and documents. Deterministic:
the first part is the 2026-11-01 Pohnpei prep's seed (seed 2025) unchanged; the rest uses seed 2026.
"""
import random
import sys

R = random.Random(2025)
N = 420
out = []
w = out.append


def q(s):
    return "NULL" if s is None else "'" + str(s).replace("\\", "\\\\").replace("'", "''") + "'"


def pick(weighted, rng=R):
    total = sum(x[1] for x in weighted)
    r = rng.uniform(0, total)
    for v, wt in weighted:
        r -= wt
        if r <= 0:
            return v
    return weighted[-1][0]


w("-- Synthetic Pohnpei-shaped site for OpenEMR 7.0.3. Made-up people only.")
w("SET NAMES utf8mb4;")
# As OpenEMR's own connection does: zero dates, as 7.0.3 writes them, load on MySQL 8 too.
w("SET SESSION sql_mode = '';")

# Sites
w("UPDATE facility SET name='Synthetic Kolonia Health Center', street='PO Box 0 (synthetic)', city='Kolonia', state='FM', "
  "postal_code='96941', country_code='FM', service_location=1, billing_location=1 WHERE id=3;")
w("INSERT INTO facility (id, name, street, city, state, postal_code, country_code, service_location, billing_location, pos_code, color) "
  "VALUES (9702, 'Synthetic Madolenihmw Dispensary', 'Synthetic Road', 'Madolenihmw', 'FM', '96941', 'FM', 1, 0, 11, '#99CCFF');")

# Providers (no logins)
for uid, user, fn, ln, tax, npi in [
    (9701, 'synmd', 'Mara', 'Synthdoc', '207Q00000X', '1003000126'),
    (9702, 'synnp', 'Nik', 'Synthnurse', '363L00000X', '1003000134'),
    (9703, 'syndds', 'Dena', 'Synthdent', '1223G0001X', '1003000142'),
]:
    w(f"INSERT INTO users (id, username, password, authorized, fname, lname, facility, facility_id, active, npi, taxonomy, calendar, info) "
      f"VALUES ({uid}, '{user}', 'NoLogin', 1, '{fn}', '{ln}', 'Synthetic Kolonia Health Center', 3, 1, '{npi}', '{tax}', 1, 'synthetic');")
    w(f"INSERT INTO `groups` (name, user) VALUES ('Default', '{user}');")

# Insurers. FSM MiCare with OpenEMR 7.0.3's default claim type (1, Other HCFA), as a site would leave it.
w("INSERT INTO insurance_companies (id, name, cms_id, ins_type_code, inactive) VALUES "
  "(9701, 'FSM MiCare', 'MICARE', 1, 0), (9702, 'Synthetic Private Health Plan', 'SYNPRV', 17, 0);")

# Lists a Micronesian site might change: FSM languages added (no stock entries in 7.0.3),
# the stock Micronesian race entries switched on, and one race entry added without a CDC code.
for oid, title, code, seq in [('pohnpeian', 'Pohnpeian', 'pon', 1500), ('chuukese', 'Chuukese', 'chk', 1501),
                              ('kosraean', 'Kosraean', 'kos', 1502), ('yapese', 'Yapese', 'yap', 1503),
                              ('mortlockese', 'Mortlockese', 'mrl', 1504)]:
    w(f"INSERT INTO list_options (list_id, option_id, title, seq, notes, activity) VALUES ('language', '{oid}', '{title}', {seq}, '{code}', 1);")
w("UPDATE list_options SET activity=1 WHERE list_id='race' AND option_id IN "
  "('pohnpeian','chuukese','kosraean','yapese','marshallese','palauan','micronesian','filipino','japanese');")
w("INSERT INTO list_options (list_id, option_id, title, seq, notes, activity) VALUES ('race', 'mortlockese', 'Mortlockese', 45, '', 1);")
# Family Size hidden on Demographics (uor 0), as a site that never used it might have it.
w("UPDATE layout_options SET uor=0 WHERE form_id='DEM' AND field_id='family_size';")
# An encounter form recording income, household size, housing and veteran status as form data.
w("INSERT INTO list_options (list_id, option_id, title, seq) VALUES ('lists', 'housing_situation', 'Housing Situation', 1);")
for i, (oid, title) in enumerate([('own', 'Own home'), ('family', 'Staying with family'), ('none', 'No home')]):
    w(f"INSERT INTO list_options (list_id, option_id, title, seq) VALUES ('housing_situation', '{oid}', '{title}', {10 * (i + 1)});")
w("INSERT INTO layout_group_properties (grp_form_id, grp_group_id, grp_title, grp_mapping, grp_activity, grp_repeats, grp_columns, grp_size) "
  "VALUES ('LBFsocial', '', 'Social and Income (synthetic)', 'Clinical', 1, 0, 4, 9), ('LBFsocial', '1', 'Household', '', 1, 0, 0, 0);")
for seq, (fid, title, dtype, lst) in enumerate([
        ('household_income', 'Household Income per Month', 2, ''), ('household_size', 'People in Household', 2, ''),
        ('housing', 'Housing', 1, 'housing_situation'), ('veteran', 'Served in U.S. Military', 1, 'yesno')], start=1):
    w("INSERT INTO layout_options (form_id, field_id, group_id, title, seq, data_type, uor, fld_length, max_length, list_id, titlecols, datacols, "
      f"default_value, edit_options, description, fld_rows) VALUES ('LBFsocial', '{fid}', '1', '{title}', {seq}, {dtype}, 1, 20, 0, '{lst}', 1, 3, '', '', '', 0);")

races = [('pohnpeian', 70), ('chuukese', 8), ('kosraean', 3), ('yapese', 2), ('marshallese', 1), ('palauan', 1),
         ('filipino', 3), ('white', 3), ('japanese', 1), ('pohnpeian|japanese', 2), ('mortlockese', 3), ('', 3)]
langs = [('pohnpeian', 70), ('chuukese', 8), ('kosraean', 3), ('yapese', 2), ('English', 12), ('', 5)]
zips = [('96941', 84), ('96942', 4), ('96943', 1), ('96944', 2), ('96813', 1), ('', 4), ('Kolonia', 2), ('96941-0001', 2)]

enc = 100000
fe_id = 0
visits = []   # (pid, encounter, date, provider, facility, cat, dental, cpt line codes)
patients = []  # (pid, dob, sex)
codes_med = [('ICD10', 'I10', 'Essential (primary) hypertension'), ('ICD10', 'E11.9', 'Type 2 diabetes mellitus without complications'),
             ('ICD10', 'J06.9', 'Acute upper respiratory infection, unspecified'), ('ICD10', 'Z00.00', 'General adult medical examination'),
             ('ICD10', 'Z00.129', 'Routine child health examination'), ('ICD10', 'O09.90', 'Supervision of high risk pregnancy')]
for i in range(1, N + 1):
    pid = i
    age = R.choice([R.randint(0, 17), R.randint(18, 64), R.randint(18, 64), R.randint(65, 85)])
    dob = f"{2025 - age}-{R.randint(1, 12):02d}-{R.randint(1, 28):02d}"
    sex = 'Female' if R.random() < 0.52 else 'Male'
    if i in (17, 233):
        sex = ''  # sex not recorded: a blocking problem on the report
    race = pick(races)
    eth = pick([('not_hisp_or_latin', 90), ('', 8), ('declne_to_specfy', 2)])
    lang = pick(langs)
    interp = ''
    if lang == 'English' and R.random() < 0.2:
        interp = 'yes'
    elif lang in ('pohnpeian', 'chuukese') and R.random() < 0.1:
        interp = R.choice(['yes', 'no', 'Pohnpeian'])
    zipc = pick(zips)
    income, fam, review = '', '', None
    r = R.random()
    if r < 0.70:
        income = str(R.choice([R.randint(50, 900), R.randint(100, 1500), R.randint(800, 3000)]))
        if R.random() < 0.05:
            income = f"${int(income):,}"
        fam = str(R.randint(1, 10))
        review = f"2025-{R.randint(1, 12):02d}-{R.randint(1, 28):02d} 00:00:00"
    elif r < 0.75:
        income, fam, review = str(R.randint(100, 900)), str(R.randint(1, 8)), "2023-06-01 00:00:00"  # stale
    elif r < 0.78:
        income, fam, review = '500-700', str(R.randint(1, 8)), "2025-03-01 00:00:00"  # a range: not one amount
    homeless = 'no' if R.random() < 0.3 else ''
    if R.random() < 0.01:
        homeless = 'yes'
    migrant = 'seasonal copra' if R.random() < 0.01 else ''
    w("INSERT INTO patient_data (pid, pubpid, fname, lname, DOB, sex, race, ethnicity, language, interpretter, postal_code, city, state, country_code, "
      "monthly_income, family_size, financial_review, homeless, migrantseasonal, date, regdate, providerID) VALUES "
      f"({pid}, 'SYN{pid:04d}', 'Pat{pid:04d}', 'Synthetic', '{dob}', {q(sex)}, {q(race)}, {q(eth)}, {q(lang)}, {q(interp)}, {q(zipc)}, "
      f"'Kolonia', 'FM', 'FM', {q(income)}, {q(fam)}, {q(review)}, {q(homeless)}, {q(migrant)}, '2019-01-01 00:00:00', '2019-01-01 00:00:00', 9701);")
    patients.append((pid, dob, sex))
    ins = pick([(None, 58), (9701, 34), (9702, 8)])
    if ins:
        w(f"INSERT INTO insurance_data (type, provider, plan_name, policy_number, subscriber_lname, subscriber_fname, subscriber_relationship, "
          f"subscriber_DOB, subscriber_sex, date, pid, accept_assignment) VALUES ('primary', '{ins}', '', 'SYN{pid:05d}', 'Synthetic', 'Pat{pid:04d}', "
          f"'self', '{dob}', {q(sex)}, '2020-01-01', {pid}, 'TRUE');")
    # Visits: most in 2025; a few only in 2024; a few only No Show in 2025.
    kind = 'normal'
    if i % 41 == 0:
        kind = 'only2024'
    elif i % 53 == 0:
        kind = 'noshow'
    for v in range(R.randint(1, 5)):
        enc += 1
        fe_id += 1
        year = 2024 if kind == 'only2024' else 2025
        date = f"{year}-{R.randint(1, 12):02d}-{R.randint(1, 28):02d} {R.randint(8, 16):02d}:00:00"
        dental = R.random() < 0.15
        prov = 9703 if dental else R.choice([9701, 9701, 9702])
        cat = 1 if kind == 'noshow' else R.choice([5, 5, 9, 10])
        fac, facname = (9702, 'Synthetic Madolenihmw Dispensary') if R.random() < 0.15 else (3, 'Synthetic Kolonia Health Center')
        w("INSERT INTO form_encounter (id, date, reason, facility, facility_id, pid, encounter, sensitivity, pc_catid, provider_id, billing_facility, pos_code) "
          f"VALUES ({fe_id}, '{date}', 'Synthetic visit', '{facname}', {fac}, {pid}, {enc}, 'normal', {cat}, {prov}, 3, 11);")
        w("INSERT INTO forms (date, encounter, form_name, form_id, pid, user, groupname, authorized, deleted, formdir) "
          f"VALUES ('{date}', {enc}, 'New Patient Encounter', {fe_id}, {pid}, 'admin', 'Default', 1, 0, 'newpatient');")
        if cat == 1:
            continue
        if dental:
            bills = [('HCPCS', 'D0120', 'Periodic oral evaluation'), ('ICD10', 'K02.9', 'Dental caries, unspecified')]
            if R.random() < 0.3:
                bills.append(('HCPCS', 'D1206', 'Topical application of fluoride varnish'))
        else:
            bills = [('CPT4', R.choice(['99213', '99214', '99203']), 'Office visit'), R.choice(codes_med)]
        for ct, code, text in bills:
            w("INSERT INTO billing (date, code_type, code, pid, provider_id, user, groupname, authorized, encounter, code_text, billed, activity, units, fee) "
              f"VALUES ('{date}', '{ct}', '{code}', {pid}, {prov}, 1, 'Default', 1, {enc}, {q(text)}, 0, 1, 1, {'25.00' if ct != 'ICD10' else '0.00'});")
        visits.append((pid, enc, date, prov, fac, ins, [(ct, code) for ct, code, _ in bills if ct != 'ICD10']))
w(f"UPDATE sequences SET id = GREATEST(id, {enc + 1});")

# ---- What a receipt counts, beyond the prep's seed. Seed 2026, so the part above is unchanged.
S = random.Random(2026)
RECURR = 'a:6:{s:17:"event_repeat_freq";s:1:"0";s:22:"event_repeat_freq_type";s:1:"0";s:19:"event_repeat_on_num";s:1:"1";s:19:"event_repeat_on_day";s:1:"0";s:20:"event_repeat_on_freq";s:1:"0";s:6:"exdate";s:0:"";}'
LOCATION = 'a:6:{s:14:"event_location";s:0:"";s:13:"event_street1";s:0:"";s:13:"event_street2";s:0:"";s:10:"event_city";s:0:"";s:11:"event_state";s:0:"";s:12:"event_postal";s:0:"";}'

# Appointments, as 7.0.3's calendar writes them (pc_endDate '0000-00-00' for a single visit).
for pid, enc_, date, prov, fac, ins, lines in visits:
    if S.random() < 0.6:
        status = pick([('>', 70), ('@', 10), ('?', 10), ('x', 10)], S)
        d, t = date.split(' ')
        end = f"{int(t[:2]):02d}:15:00"
        w("INSERT INTO openemr_postcalendar_events (pc_catid, pc_multiple, pc_aid, pc_pid, pc_gid, pc_title, pc_time, pc_hometext, pc_informant, "
          "pc_eventDate, pc_endDate, pc_duration, pc_recurrtype, pc_recurrspec, pc_startTime, pc_endTime, pc_alldayevent, pc_apptstatus, "
          "pc_prefcatid, pc_location, pc_eventstatus, pc_sharing, pc_facility, pc_billing_location, pc_room) VALUES "
          f"(5, 0, '{prov}', '{pid}', 0, 'Office Visit', '{d} 07:30:00', '', '1', '{d}', '0000-00-00', 900, 0, {q(RECURR)}, '{t}', '{end}', 0, "
          f"'{status}', 0, {q(LOCATION)}, 1, 1, {fac}, 3, '');")
# A few future appointments, and a clinic meeting with no patient (pc_pid empty: not a patient's).
for pid in S.sample(range(1, N + 1), 25):
    w("INSERT INTO openemr_postcalendar_events (pc_catid, pc_multiple, pc_aid, pc_pid, pc_gid, pc_title, pc_time, pc_hometext, pc_informant, "
      "pc_eventDate, pc_endDate, pc_duration, pc_recurrtype, pc_recurrspec, pc_startTime, pc_endTime, pc_alldayevent, pc_apptstatus, "
      "pc_prefcatid, pc_location, pc_eventstatus, pc_sharing, pc_facility, pc_billing_location, pc_room) VALUES "
      f"(9, 0, '9701', '{pid}', 0, 'Established Patient', '2026-10-01 08:00:00', '', '1', '2026-{S.randint(11, 12)}-{S.randint(1, 28):02d}', "
      f"'0000-00-00', 900, 0, {q(RECURR)}, '09:00:00', '09:15:00', 0, '-', 0, {q(LOCATION)}, 1, 1, 3, 3, '');")
w("INSERT INTO openemr_postcalendar_events (pc_catid, pc_multiple, pc_aid, pc_pid, pc_gid, pc_title, pc_time, pc_hometext, pc_informant, "
  "pc_eventDate, pc_endDate, pc_duration, pc_recurrtype, pc_recurrspec, pc_startTime, pc_endTime, pc_alldayevent, pc_apptstatus, "
  "pc_prefcatid, pc_location, pc_eventstatus, pc_sharing, pc_facility, pc_billing_location, pc_room) VALUES "
  f"(2, 0, '9701', '', 0, 'Staff meeting', '2025-01-01 08:00:00', '', '1', '2025-02-03', '0000-00-00', 3600, 0, {q(RECURR)}, "
  f"'12:00:00', '13:00:00', 0, '-', 0, {q(LOCATION)}, 1, 1, 3, 3, '');")

# Encounter forms beyond the visit itself: vitals, SOAP notes, the site's own layout-based form.
vit = soap = lbf = 0
for pid, enc_, date, prov, fac, ins, lines in visits:
    if S.random() < 0.5:
        vit += 1
        h = S.randint(140, 185)
        wt = S.randint(50, 120)
        w("INSERT INTO form_vitals (id, date, pid, user, groupname, authorized, activity, bps, bpd, weight, height, temperature, pulse, respiration, "
          f"BMI, oxygen_saturation) VALUES ({vit}, '{date}', {pid}, 'admin', 'Default', 1, 1, '{S.randint(100, 160)}', '{S.randint(60, 100)}', "
          f"{wt * 2.2046:.2f}, {h / 2.54:.2f}, {S.uniform(97.0, 99.5):.1f}, {S.randint(55, 100)}, {S.randint(12, 20)}, {wt / (h / 100) ** 2:.1f}, {S.randint(94, 100)});")
        w("INSERT INTO forms (date, encounter, form_name, form_id, pid, user, groupname, authorized, deleted, formdir) "
          f"VALUES ('{date}', {enc_}, 'Vitals', {vit}, {pid}, 'admin', 'Default', 1, 0, 'vitals');")
    if S.random() < 0.15:
        soap += 1
        w("INSERT INTO form_soap (id, date, pid, user, groupname, authorized, activity, subjective, objective, assessment, plan) VALUES "
          f"({soap}, '{date}', {pid}, 'admin', 'Default', 1, 1, 'Synthetic: feels well', 'Synthetic: no distress', 'Synthetic: stable', 'Synthetic: return in 3 months');")
        w("INSERT INTO forms (date, encounter, form_name, form_id, pid, user, groupname, authorized, deleted, formdir) "
          f"VALUES ('{date}', {enc_}, 'SOAP', {soap}, {pid}, 'admin', 'Default', 1, 0, 'soap');")
    if S.random() < 0.1:
        lbf += 1
        for fid, val in [('household_income', str(S.randint(100, 2000))), ('household_size', str(S.randint(1, 9))),
                         ('housing', pick([('own', 6), ('family', 3), ('none', 1)], S)), ('veteran', S.choice(['YES', 'NO']))]:
            w(f"INSERT INTO lbf_data (form_id, field_id, field_value) VALUES ({lbf}, '{fid}', '{val}');")
        w("INSERT INTO forms (date, encounter, form_name, form_id, pid, user, groupname, authorized, deleted, formdir) "
          f"VALUES ('{date}', {enc_}, 'Social and Income (synthetic)', {lbf}, {pid}, 'admin', 'Default', 1, 0, 'LBFsocial');")

# Prescriptions.
rx = 0
drugs = [('Metformin 500 mg tablet', '861007', '1 tablet twice daily', '60'), ('Lisinopril 10 mg tablet', '314076', '1 tablet daily', '30'),
         ('Amoxicillin 500 mg capsule', '308191', '1 capsule three times daily', '21'), ('Ferrous sulfate 325 mg tablet', '310325', '1 tablet daily', '30')]
for pid, enc_, date, prov, fac, ins, lines in visits:
    if prov != 9703 and S.random() < 0.25:
        rx += 1
        name, rxn, dose, qty = S.choice(drugs)
        w("INSERT INTO prescriptions (id, patient_id, date_added, date_modified, provider_id, encounter, start_date, drug, drug_id, rxnorm_drugcode, "
          f"dosage, quantity, refills, active, datetime, user, txDate, usage_category_title, request_intent_title) VALUES ({rx}, {pid}, '{date}', '{date}', {prov}, {enc_}, "
          f"'{date[:10]}', '{name}', 0, '{rxn}', '{dose}', '{qty}', {S.randint(0, 3)}, 1, '{date}', 'admin', '{date[:10]}', '', '');")

# Lab orders with results: a lab, an order on the visit (an encounter form too), a report, results.
w("INSERT INTO procedure_providers (ppid, name, npi, protocol, active) VALUES (9701, 'Synthetic Island Lab', '1003000159', 'DL', 1);")
po = rep = res = 0
tests = [('4548-4', 'Hemoglobin A1c', '%', '4.0-5.6', lambda: f"{S.uniform(4.8, 11.0):.1f}"),
         ('2345-7', 'Glucose', 'mg/dL', '70-99', lambda: str(S.randint(70, 260))),
         ('718-7', 'Hemoglobin', 'g/dL', '12.0-17.5', lambda: f"{S.uniform(9.0, 16.5):.1f}")]
for pid, enc_, date, prov, fac, ins, lines in visits:
    if prov != 9703 and S.random() < 0.2:
        po += 1
        rep += 1
        w("INSERT INTO procedure_order (procedure_order_id, provider_id, patient_id, encounter_id, date_ordered, date_collected, order_priority, "
          f"order_status, activity, lab_id, history_order) VALUES ({po}, {prov}, {pid}, {enc_}, '{date}', '{date}', 'normal', 'complete', 1, 9701, '0');")
        picked = S.sample(tests, S.randint(1, 3))
        for seq, (code, name, *_rest) in enumerate(picked, start=1):
            w("INSERT INTO procedure_order_code (procedure_order_id, procedure_order_seq, procedure_code, procedure_name, procedure_source, diagnoses, "
              f"do_not_send, procedure_order_title, procedure_type) VALUES ({po}, {seq}, '{code}', '{name}', '1', '', 0, '{name}', 'laboratory_test');")
        w("INSERT INTO forms (date, encounter, form_name, form_id, pid, user, groupname, authorized, deleted, formdir) "
          f"VALUES ('{date}', {enc_}, 'Lab order (Synthetic Island Lab)', {po}, {pid}, 'admin', 'Default', 1, 0, 'procedure_order');")
        w("INSERT INTO procedure_report (procedure_report_id, procedure_order_id, procedure_order_seq, date_collected, date_report, source, "
          f"report_status, review_status) VALUES ({rep}, {po}, 1, '{date}', '{date[:10]} 17:00:00', {prov}, 'final', 'reviewed');")
        for code, name, units, rng, val in picked:
            res += 1
            w("INSERT INTO procedure_result (procedure_result_id, procedure_report_id, result_data_type, result_code, result_text, date, units, "
              f"result, `range`, abnormal, result_status) VALUES ({res}, {rep}, 'N', '{code}', '{name}', '{date}', '{units}', '{val()}', '{rng}', '', 'final');")

# Money. Insurance pays most MiCare visits by check, with a contractual adjustment; patients pay cash
# at the window (a front-desk receipt too); a few payments are voided (deleted), a few visits carry a
# co-pay line, one fee-sheet line was removed (activity 0), and the dispensary sells drugs.
w("INSERT INTO drugs (drug_id, name, ndc_number, form, size, unit, route, active) VALUES (9701, 'Amoxicillin 500 mg capsule (synthetic stock)', '', '1', '500', '1', '1', 1);")
w("INSERT INTO drug_inventory (inventory_id, drug_id, lot_number, expiration, manufacturer, on_hand) VALUES (9701, 9701, 'SYN-LOT-1', '2027-12-31', 'Synthetic', 500);")
sess = 0
sale = 0
pay_row = 0
for pid, enc_, date, prov, fac, ins, lines in visits:
    d = date[:10]
    year = int(d[:4])
    seqno = 0
    if ins == 9701 and S.random() < 0.8:
        sess += 1
        dep = f"{year}-{min(12, int(d[5:7]) + 1):02d}-{S.randint(1, 28):02d}"
        paid = adj = 0
        acts = []
        for ct, code in lines:
            p, a = 18.00, 7.00
            paid += p
            adj += a
            seqno += 1
            acts.append((seqno, ct, code, p, 0.0, 'Ins1', ''))
            seqno += 1
            acts.append((seqno, ct, code, 0.0, a, 'Ins1', 'Adj code CO-45'))
        w("INSERT INTO ar_session (session_id, payer_id, user_id, closed, reference, check_date, deposit_date, pay_total, created_time, modified_time, "
          "global_amount, payment_type, description, adjustment_code, post_to_date, patient_id, payment_method) VALUES "
          f"({sess}, 9701, 1, 0, 'SYNCHK{sess:05d}', '{dep}', '{dep}', {paid:.2f}, '{dep} 10:00:00', '{dep} 10:00:00', 0.00, 'insurance', '', "
          f"'insurance_payment', '{dep}', 0, 'check_payment');")
        for sq, ct, code, p, a, acct, memo in acts:
            deleted = "'2025-12-15 09:00:00'" if (sess % 37 == 0 and p) else 'NULL'
            w("INSERT INTO ar_activity (pid, encounter, sequence_no, code_type, code, modifier, payer_type, post_time, post_user, session_id, memo, "
              "pay_amount, adj_amount, modified_time, follow_up, follow_up_note, account_code, reason_code, deleted, post_date) VALUES "
              f"({pid}, {enc_}, {sq}, '{ct}', '{code}', '', 1, '{dep} 10:00:00', 1, {sess}, '{memo}', {p:.2f}, {a:.2f}, '{dep} 10:00:00', '', '', '{acct}', "
              f"NULL, {deleted}, '{dep}');")
    if S.random() < 0.35:
        sess += 1
        amt = S.choice([5.00, 7.00, 10.00, 25.00])
        w("INSERT INTO ar_session (session_id, payer_id, user_id, closed, reference, check_date, deposit_date, pay_total, created_time, modified_time, "
          "global_amount, payment_type, description, adjustment_code, post_to_date, patient_id, payment_method) VALUES "
          f"({sess}, 0, 1, 0, '', '{d}', '{d}', {amt:.2f}, '{date}', '{date}', 0.00, 'patient', '', 'patient_payment', '{d}', {pid}, 'cash');")
        seqno += 1
        ct, code = lines[0]
        w("INSERT INTO ar_activity (pid, encounter, sequence_no, code_type, code, modifier, payer_type, post_time, post_user, session_id, memo, "
          "pay_amount, adj_amount, modified_time, follow_up, follow_up_note, account_code, reason_code, deleted, post_date) VALUES "
          f"({pid}, {enc_}, {seqno}, '{ct}', '{code}', '', 0, '{date}', 1, {sess}, '', {amt:.2f}, 0.00, '{date}', '', '', 'PP', NULL, NULL, '{d}');")
        pay_row += 1
        w("INSERT INTO payments (id, pid, dtime, encounter, user, method, source, amount1, amount2, posted1, posted2) VALUES "
          f"({pay_row}, {pid}, '{date}', {enc_}, 'admin', 'cash', '', {amt:.2f}, 0.00, {amt:.2f}, 0.00);")
    if S.random() < 0.05 and '--copays' in sys.argv:
        # Off by default: OpenEMR 8.5.0's Receipts by Payment Method report stops with a TypeError on a
        # fee-sheet co-pay (its co-pay query doesn't select code_text), so a site with them can't run it.
        w("INSERT INTO billing (date, code_type, code, pid, provider_id, user, groupname, authorized, encounter, code_text, billed, activity, units, fee) "
          f"VALUES ('{date}', 'COPAY', '', {pid}, {prov}, 1, 'Default', 1, {enc_}, 'Co-pay (synthetic)', 0, 1, 1, -5.00);")
    if S.random() < 0.02:
        w("INSERT INTO billing (date, code_type, code, pid, provider_id, user, groupname, authorized, encounter, code_text, billed, activity, units, fee) "
          f"VALUES ('{date}', 'CPT4', '99211', {pid}, {prov}, 1, 'Default', 1, {enc_}, 'Removed from the fee sheet (synthetic)', 0, 0, 1, 15.00);")
    if fac == 9702 and S.random() < 0.4:
        sale += 1
        w("INSERT INTO drug_sales (sale_id, drug_id, inventory_id, prescription_id, pid, encounter, user, sale_date, quantity, fee, billed, trans_type) "
          f"VALUES ({sale}, 9701, 9701, 0, {pid}, {enc_}, 'admin', '{d}', 21, 4.50, 0, 1);")

sys.stderr.write(f"-- {N} patients, {fe_id} encounters, {vit} vitals, {soap} SOAP, {lbf} LBF, {rx} prescriptions, {po} lab orders, "
                 f"{res} results, {sess} payment sessions, {pay_row} front-desk receipts, {sale} drug sales\n")

DOCUMENTS_PHP = r'''<?php
// Stores the synthetic site's documents through OpenEMR's own Document class, as an upload does:
// on disk under sites/default/documents/<pid>/, encrypted when the site's setting says so, with
// the hash OpenEMR keeps. Run from the 7.0.3 folder (php documents.php). Made-up content only.
$_GET['site'] = 'default';
$ignoreAuth = true;
$sessionAllowWrite = true;
require_once __DIR__ . '/interface/globals.php';
require_once $GLOBALS['fileroot'] . '/library/classes/Document.class.php';
$cat = sqlQuery("SELECT id FROM categories WHERE name = 'Medical Record'")['id'] ?? 1;
$made = 0;
foreach (%s as [$pid, $n]) {
    for ($i = 1; $i <= $n; $i++) {
        $data = "%%PDF-1.4\n%% Synthetic document $i for synthetic patient $pid. Made up.\n" . str_repeat("synthetic line $i\n", 20 + $i * 7) . "%%%%EOF\n";
        $d = new Document();
        $err = $d->createDocument($pid, $cat, "synthetic-$pid-$i.pdf", 'application/pdf', $data);
        if ($err) {
            fwrite(STDERR, "document for $pid: $err\n");
            exit(1);
        }
        $made++;
    }
}
echo "stored $made documents (drive_encryption " . ($GLOBALS['drive_encryption'] ? 'on' : 'off') . ")\n";
'''

if '--documents' in sys.argv:
    D = random.Random(2027)
    pairs = [(pid, D.randint(1, 3)) for pid in sorted(D.sample(range(1, N + 1), 60))]
    if N not in [p for p, _ in pairs]:
        pairs.append((N, 2))  # the newest patient has documents too
    print(DOCUMENTS_PHP % ('[' + ', '.join(f'[{p}, {n}]' for p, n in pairs) + ']'))
else:
    print("\n".join(out))
