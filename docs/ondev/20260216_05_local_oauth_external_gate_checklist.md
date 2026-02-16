# Local OAuth External Gate Checklist (P78-T2 / P89)

## Goal
- Close the manual external gate for localhost Google OAuth callback success.

## 1) Collect Redirect Evidence
- Run:
```bash
script/oauth/collect_local_oauth_redirect_evidence.sh
```
- Output:
  - `REPORT_PATH=/tmp/oauth-local-gate/local_oauth_redirect_YYYYMMDD_HHMMSS.txt`
- Verify in report:
  - `redirect_uri=http://127.0.0.1:3000/auth/google_oauth2/callback`
  - `redirect_uri=http://localhost:3000/auth/google_oauth2/callback`

## 2) Google Cloud Console Setup
- Open OAuth client settings for current `GOOGLE_CLIENT_ID`.
- Add all callback URIs:
  - `http://127.0.0.1:3000/auth/google_oauth2/callback`
  - `http://localhost:3000/auth/google_oauth2/callback`
  - `https://soletalk-rails-production.up.railway.app/auth/google_oauth2/callback`
- Save changes.

## 3) Manual Local Verification
- On local app:
  1. Open `/consent`
  2. Click policy link once
  3. Check agreement
  4. Click `Agree and continue`
  5. Click `Continue with Google`
  6. Complete Google consent
- Expected:
  - Redirect back to local app root (`/`)
  - Signed-in home state (`Welcome, ...`) visible

## 4) Automated Regression
- Run:
```bash
script/playwright/run_ui_journey_gap_audit.sh
```
- Expected:
  - `GAP_COUNT=0`
  - No OAuth mismatch/blocked external gate note.
