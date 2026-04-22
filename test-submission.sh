#!/bin/bash
# Post-deploy smoke test for GT Commute Survey
# Run after every push to verify submissions reach the Google Sheet
#
# Usage: ./test-submission.sh
# Then check the spreadsheet for the test entry.

set -euo pipefail

ENDPOINT="https://script.google.com/macros/s/AKfycbwhfq-1XT_WcIdPCrQK-MhFzzPYuGDcE_WPia8HhclMEh1YCdb_gAorGX-pS38so9emPg/exec"
SHEET_URL="https://docs.google.com/spreadsheets/d/1wrMHVOKa2Uf4Iz-E0ZOsfpuT2GbzH3L0iNAJ0tVNXEk/edit"
TEST_ID="SMOKE_TEST_$(date +%Y%m%d_%H%M%S)"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "=== GT Commute Survey - Post-Deploy Smoke Test ==="
echo ""
echo "Test ID: $TEST_ID"
echo "Timestamp: $TIMESTAMP"
echo ""

# Test 1: Check Vercel deployment has new code
echo "[1/4] Checking Vercel deployment..."
LIVE_CODE=$(curl -s 'https://gt-commute-survey.vercel.app/')
if echo "$LIVE_CODE" | grep -q "sendPayload"; then
  echo "  ✓ New submission code detected (sendPayload)"
else
  echo "  ✗ WARNING: sendPayload not found in live code!"
  echo "  Vercel may not have deployed yet. Wait 1-2 minutes and retry."
fi

if echo "$LIVE_CODE" | grep -q "gt_commute_archive"; then
  echo "  ✓ Archive system detected"
else
  echo "  ⚠ Archive system not found (may be old deployment)"
fi
echo ""

# Test 2: Send test submission via curl (matching browser behavior)
echo "[2/4] Sending test submission..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L \
  -X POST \
  -H 'Content-Type: text/plain' \
  -d "{\"timestamp\":\"$TIMESTAMP\",\"office\":\"$TEST_ID\",\"department\":\"SMOKE_TEST\",\"employment_pct\":\"100\",\"commute_days\":\"5\",\"work_weeks\":\"47\",\"transport_modes\":\"bike\",\"distances_km\":\"bike:10\",\"car_fuel\":\"\",\"car_size\":\"\",\"carpool\":\"1\",\"carpool_pct\":\"0\",\"mc_fuel\":\"\",\"mode_details\":\"Cykel:10km:5d:100%:0kg\",\"total_co2e_kg\":0}" \
  "$ENDPOINT" 2>/dev/null)

if [ "$HTTP_CODE" = "302" ] || [ "$HTTP_CODE" = "200" ]; then
  echo "  ✓ Server responded with HTTP $HTTP_CODE (expected: 302 = success)"
else
  echo "  ✗ Server responded with HTTP $HTTP_CODE (unexpected!)"
fi
echo ""

# Test 3: Wait and check sheet
echo "[3/4] Waiting 5 seconds for Google Sheets to update..."
sleep 5

# Try to fetch sheet as CSV to verify
SHEET_CSV_URL="https://docs.google.com/spreadsheets/d/1wrMHVOKa2Uf4Iz-E0ZOsfpuT2GbzH3L0iNAJ0tVNXEk/export?format=csv&gid=0"
echo "[4/4] Checking spreadsheet for test entry..."
SHEET_DATA=$(curl -s -L "$SHEET_CSV_URL" 2>/dev/null)

if echo "$SHEET_DATA" | grep -q "$TEST_ID"; then
  echo "  ✓ SUCCESS! Test entry '$TEST_ID' found in spreadsheet!"
  echo ""
  echo "  ✅ ALL TESTS PASSED - Deployment is working correctly."
else
  echo "  ✗ Test entry '$TEST_ID' NOT found in spreadsheet."
  echo "  This could mean:"
  echo "    - Google Sheets hasn't synced yet (wait 30s and check manually)"
  echo "    - The Apps Script is broken"
  echo "    - The spreadsheet is not the correct one"
  echo ""
  echo "  Check manually: $SHEET_URL"
fi

echo ""
echo "Spreadsheet: $SHEET_URL"
echo "Live form: https://gt-commute-survey.vercel.app/"
echo ""
echo "Remember to delete the test row ($TEST_ID) from the spreadsheet after verifying."
