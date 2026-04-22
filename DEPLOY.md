# GT Commute Survey - Deployment Guide

## Pre-deploy checklist
- [ ] Changes tested locally (open index.html in browser)
- [ ] SHEETS_URL is correct and not a placeholder

## Deploy
```bash
cd deploy/commute-survey
git add -A
git commit -m "description of changes"
git push origin main
# Vercel auto-deploys from main branch
```

## Post-deploy verification (MANDATORY)
```bash
./test-submission.sh
```

This sends a test submission and verifies it appears in the Google Sheet within seconds.

## If submissions stop working
1. Run `./test-submission.sh` to diagnose
2. Check Google Apps Script execution logs: script.google.com → project → Executions
3. Check Vercel deployment: vercel.com → gt-commute-survey → Deployments
4. Users can export their locally cached answers via the "Exportera svar" link on the thank-you page

## Architecture
- Static HTML hosted on Vercel (auto-deploys from GitHub main branch)
- Submissions → Google Apps Script (doPost) → Google Sheet
- Local backup: all submissions cached in localStorage (gt_commute_archive)
- Pending retry: failed submissions queued in localStorage (gt_commute_pending) and retried on next page load

## Spreadsheet
https://docs.google.com/spreadsheets/d/1wrMHVOKa2Uf4Iz-E0ZOsfpuT2GbzH3L0iNAJ0tVNXEk/edit
