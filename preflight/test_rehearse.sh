#!/usr/bin/env bash
# End-to-end test of openemr-rehearse.sh, both ways, on the synthetic Pohnpei-shaped site:
#   1. a throwaway OpenEMR 7.0.3 (official image, patch 4, MariaDB 10.6) loaded with test_site.py's
#      site, its documents stored by OpenEMR's own code (encrypted, as 7.0.3 does by default); its
#      database dumped and its sites/ archived, as a site does for the rehearsal;
#   2. a clean rehearsal to 8.5.0: the copy needs room it states, its containers are capped, the
#      receipts match, the doctor finds nothing, and the access check passes: every patient through
#      the API with counts per patient as the receipt has them, every document through OpenEMR's
#      document route as stored, the money reports and every balance as the receipt, and a sample
#      of charts that open without a PHP error. Verdict: ready;
#   3. a rehearsal of the same site with faults planted in the source: one document's file missing,
#      another's stored hash wrong, and an encounter form whose code isn't in 8.5.0 (a site's own
#      form, left behind), and with fee-sheet co-pays, which 8.5.0's Receipts by Payment Method
#      report can't show (a bug in 8.5.0). The access check must fail and name each one.
# The source is only read; everything runs in containers deleted at the end (KEEP=1 keeps the 7.0.3 site).
set -euo pipefail
cd "$(dirname "$0")"
. ./test_lib.sh
serial
W="$(mktemp -d)"; P=rehearse-test; C=$P-openemr-1; D=$P-mysql-1; OE=/var/www/localhost/htdocs/openemr; TO=${TO:-8.5.0}
export DB_IMAGE=mariadb:10.6
docker compose -p $P -f test-upgrade-compose.yml up -d >/dev/null
[[ "${KEEP:-0}" == 1 ]] || trap 'docker compose -p $P -f test-upgrade-compose.yml down -v >/dev/null 2>&1; rm -rf "$W"' EXIT
echo "waiting for OpenEMR 7.0.3 to install itself (about 6 minutes)... (work in $W)"
wait_ready $C $OE
q() { docker exec $D mariadb -uroot -proot -N openemr -e "$1"; }
python3 -I test_site.py 2>/dev/null | docker exec -i $D mariadb -uroot -proot openemr
python3 -I test_site.py --documents 2>/dev/null > "$W/documents.php"
docker cp "$W/documents.php" $C:$OE/synthetic-documents.php
docker exec -u apache -w $OE $C php synthetic-documents.php 2>/dev/null | sed 's/^/  /'
docker exec $C rm -f $OE/synthetic-documents.php
fails=0
check() { if [[ "$1" == "$2" ]]; then echo "ok   $3"; else echo "FAIL $3: got '$1', expected '$2'"; fails=$((fails + 1)); fi; }
has() { if grep -qE -- "$2" "$1"; then echo "ok   $3"; else echo "FAIL $3: no line matching /$2/ in $1"; fails=$((fails + 1)); fi; }
check "$(q 'SELECT COUNT(*) FROM documents WHERE encrypted = 1')" 122 "source: 122 documents, stored encrypted by OpenEMR 7.0.3 (its default), so the copy needs the site's keys"

# What a site hands the rehearsal: a dump and its sites/ folder.
snapshot() {  # snapshot NAME
    docker exec $D sh -c 'mariadb-dump -uroot -proot --single-transaction --routines --triggers openemr' > "$W/$1.sql"
    docker exec $C tar -czf - -C $OE sites > "$W/$1-sites.tar.gz"
}
snapshot clean

# The faults, planted in the source: a document's file gone, another's stored hash wrong, an encounter
# form whose code 8.5.0 doesn't have (registered, as a site's own form is), and fee-sheet co-pays.
read -r MISSING MISSING_PID MISSING_URL <<<"$(q "SELECT id, foreign_id, url FROM documents ORDER BY id LIMIT 1")"
read -r BADHASH BADHASH_PID <<<"$(q "SELECT id, foreign_id FROM documents ORDER BY id LIMIT 1 OFFSET 5")"
docker exec $C rm "$OE/sites/default/documents/$(basename "$(dirname "$MISSING_URL")")/$(basename "$MISSING_URL")"
q "UPDATE documents SET hash = SHA2('synthetic: not this file', 512) WHERE id = $BADHASH"
read -r FPID FENC <<<"$(q "SELECT pid, encounter FROM form_encounter ORDER BY id LIMIT 1 OFFSET 10")"
q "INSERT INTO registry (name, state, directory, sql_run, unpackaged, date, priority, category, nickname) VALUES ('Synthetic Intake', 1, 'synthetic_intake', 1, 1, NOW(), 0, 'Clinical', '')"
q "INSERT INTO forms (date, encounter, form_name, form_id, pid, user, groupname, authorized, deleted, formdir) VALUES (NOW(), $FENC, 'Synthetic Intake', 1, $FPID, 'admin', 'Default', 1, 0, 'synthetic_intake')"
q "INSERT INTO billing (date, code_type, code, pid, provider_id, user, groupname, authorized, encounter, code_text, billed, activity, units, fee) SELECT date, 'COPAY', '', pid, provider_id, 1, 'Default', 1, encounter, 'Co-pay (synthetic)', 0, 1, 1, -5.00 FROM form_encounter WHERE date >= '2025-01-01' ORDER BY id LIMIT 3"
snapshot planted
docker compose -p $P -f test-upgrade-compose.yml stop >/dev/null 2>&1   # its CPUs back for the rehearsals
echo "planted: document $MISSING (patient $MISSING_PID) without its file; document $BADHASH (patient $BADHASH_PID) with a wrong hash; form synthetic_intake in patient $FPID's encounter $FENC; 3 co-pays"

# The caps, read from Docker while the rehearsal runs.
watch_caps() {
    for _ in $(seq 1 1200); do
        docker ps --filter name=oe-rehearse- --format '{{.Names}}' | while read -r n; do docker inspect -f '{{.Name}} {{.HostConfig.NanoCpus}} {{.HostConfig.Memory}}' "$n" 2>/dev/null; done
        sleep 2
    done
}
rehearse() {  # rehearse NAME [options]
    local name="$1"; shift
    watch_caps > "$W/$name-caps.txt" & local watcher=$!
    set +e; ./openemr-rehearse.sh --dump="$W/$name.sql" --sites="$W/$name-sites.tar.gz" --from=7.0.3 --to="$TO" --out="$W/$name" "$@" > "$W/$name.txt" 2>&1; rc=$?; set -e
    kill $watcher 2>/dev/null || true; wait $watcher 2>/dev/null || true
    sort -u "$W/$name-caps.txt" -o "$W/$name-caps.txt"
}

echo "== a clean rehearsal"
rehearse clean
sed -n '/^Access check/,/^ACCESS/p' "$W/clean.txt" | sed 's/^/    /' | cut -c1-200
check "$rc" 0 "clean: the rehearsal exits 0"
has "$W/clean.txt" '^VERDICT: ready$' "clean: the verdict is ready"
has "$W/clean.txt" '^  the copy needs about [0-9]+ MB under .*; [0-9]+ MB free$' "clean: it says how much room the copy needs, and how much is free"
has "$W/clean.txt" '^  check: sites/default copied whole into the copy \([0-9]+ files\)$' "clean: sites/ is copied whole into the copy"
check "$(awk '{print $1}' "$W/clean-caps.txt" | sort -u | grep -cE 'oe-rehearse-[0-9]+-(mysql-1|openemr-1|browser)$')" 3 "clean: the database, OpenEMR and the browser all ran"
check "$(awk '$2 != 1000000000 || $3 != 2147483648' "$W/clean-caps.txt" | wc -l)" 0 "clean: each capped at 1 CPU and 2 GB by default (3 CPUs and 6 GB in all)"
has "$W/clean/receipts-compared.txt" '^RESULT: MATCH' "clean: the receipts of the copy before and after the upgrade match"
has "$W/clean/receipts-compared.txt" '^  same Patients +420$' "clean: and they counted the patients (420), not nothing"
has "$W/clean/receipts-compared.txt" '^  same Document files on disk +122$' "clean: and the documents on disk (122)"
has "$W/clean/receipts-compared.txt" '^  same Payments +[1-9][0-9,]*\.[0-9]{2}$' "clean: and the payments"
has "$W/clean.txt" '^  [0-9]+ checks pass, 0 fail, 0 warn$' "clean: the doctor finds nothing on the upgraded copy"
has "$W/clean/access-check.txt" "^  ok   every patient read through OpenEMR's API: 420 of 420$" "clean: every patient is read through the API"
for k in encounters appointments prescriptions 'lab orders'; do
    has "$W/clean/access-check.txt" "^  ok   $k per patient: the API's counts match the receipt for all [1-9][0-9]* patients" "clean: $k per patient through the API match the receipt"
done
has "$W/clean/access-check.txt" "^  ok   every document fetched through OpenEMR's document route matches the hash OpenEMR stored: 122 of 122" "clean: every document reads back through OpenEMR as stored (decrypted with the site's keys)"
has "$W/clean/access-check.txt" '^  ok   Reports > Financial > Receipts by Payment Method, 2024 ' "clean: the 2024 receipts report agrees with the receipt"
has "$W/clean/access-check.txt" '^  ok   Reports > Financial > Receipts by Payment Method, 2025 ' "clean: the 2025 receipts report agrees with the receipt"
has "$W/clean/access-check.txt" "^  ok   every patient's balance by OpenEMR's own get_patient_balance" "clean: every patient's balance, by OpenEMR's own function, agrees with the receipt"
has "$W/clean/access-check.txt" "^  ok   the dashboard's Billing card shows each sampled patient's balance" "clean: the dashboard shows the sampled patients' balances as the receipt"
has "$W/clean/access-check.txt" "^  ok   [0-9]+ pages of [0-9]+ patients' charts opened in a browser without a PHP error" "clean: the sampled charts open without a PHP error"
for why in 'first registered \(1\)' 'last registered \(420\)' 'oldest \([0-9]+\)' 'most encounters \([0-9]+\)' 'has documents \([0-9]+, [0-9]+\)' 'has a balance \([0-9]+, [0-9]+\)' 'has lab results \([0-9]+\)' 'has prescriptions \([0-9]+\)' 'random \(([0-9]+, ){9}[0-9]+\)'; do
    has "$W/clean/access-check.txt" "^       opened: .*$why" "clean: the sample has: ${why%% \\(*}"
done
for f in vitals soap LBFsocial procedure_order newpatient; do
    has "$W/clean/access-check.txt" "a form of the kind '$f'" "clean: a form of each kind is opened ($f)"
done
has "$W/clean/access-check.txt" '^ACCESS: PASS$' "clean: the access check passes"
check "$(ls "$W/clean" | sort | tr '\n' ' ')" "access-check.txt access-results.json doctor.txt php-errors.log receipt-after.json receipt-after.txt receipt-before.json receipt-before.txt receipts-compared.txt report.txt " "clean: the report, receipts, comparison, doctor and access check are kept in --out"
check "$(grep -c "oe-rehearsal-check" "$W/clean/receipt-after.json" "$W/clean/receipt-before.json" | awk -F: '{n += $2} END {print n + 0}')" 0 "clean: the receipts were taken before the access check's temporary user existed"

echo "== a rehearsal with faults planted in the source (and --cpus=2.4 --memory=4500m)"
rehearse planted --cpus=2.4 --memory=4500m
sed -n '/^Access check/,/^ACCESS/p' "$W/planted.txt" | sed 's/^/    /' | cut -c1-220
check "$rc" 1 "planted: the rehearsal exits 1"
has "$W/planted.txt" '^VERDICT: not ready$' "planted: the verdict is not ready"
check "$(awk '$2 != 800000000 || $3 != 1572864000' "$W/planted-caps.txt" | wc -l)" 0 "planted: --cpus and --memory set each container's cap (0.8 CPU and 1500 MB here)"
has "$W/planted/receipts-compared.txt" '^RESULT: MATCH' "planted: the receipts still match (the faults were there before the upgrade, and the upgrade changed nothing)"
has "$W/planted/receipt-before.txt" '^  Document files missing +1$' "planted: the receipt shows the missing file"
has "$W/planted/access-check.txt" "^         document $MISSING \(patient $MISSING_PID\): OpenEMR returned nothing \(the file is missing or unreadable\)$" "planted: the document without its file is named"
has "$W/planted/access-check.txt" "^         document $BADHASH \(patient $BADHASH_PID\): OpenEMR returned [0-9]+ bytes that don't match the hash it stored$" "planted: the document with the wrong hash is named"
has "$W/planted/access-check.txt" '^  FAIL 2 of 122 documents unreadable or not as stored:$' "planted: and only those two"
has "$W/planted/access-check.txt" "^  FAIL patient $FPID \(a form of the kind 'synthetic_intake'\), form 'synthetic_intake': HTTP 500" "planted: the chart with the form 8.5.0 can't open is named"
has "$W/planted/access-check.txt" "^  FAIL PHP error while loading patient $FPID: form 'synthetic_intake': .*synthetic_intake" "planted: with the PHP error OpenEMR logged"
has "$W/planted/access-check.txt" '^  FAIL Receipts by Payment Method, 2025: ' "planted: the 2025 receipts report, which 8.5.0 can't show with a co-pay in it, fails"
has "$W/planted/access-check.txt" "receiptsByMethodLineItem\(\): Argument #3 \(\\\$memo\) must be of type string, null given" "planted: with 8.5.0's own TypeError"
has "$W/planted/access-check.txt" "^  ok   every patient read through OpenEMR's API: 420 of 420$" "planted: control: everything else still reads (the API)"
has "$W/planted/access-check.txt" "^  ok   every patient's balance by OpenEMR's own get_patient_balance" "planted: control: and every balance, co-pays included, agrees with the receipt"
has "$W/planted/access-check.txt" '^ACCESS: FAIL ' "planted: the access check fails"
echo "logs: $W/clean.txt, $W/planted.txt and the --out folders beside them"
echo; [ $fails -eq 0 ] && echo "PASSED" || { echo "FAILED: $fails"; exit 1; }
