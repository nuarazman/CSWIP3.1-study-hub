# CSWIP 3.1 Study Hub

A responsive, static study dashboard with topic progress, original practice quizzes, a target-date planner, notes, local autosave, JSON backup/restore, and optional cross-device cloud sync via Supabase recovery code.

## Files
- `index.html` — complete frontend app.
- `supabase-schema.sql` — tables and RPC functions for cloud sync.
- `README.md` — setup and safety notes.

## 1. Use it locally first
Open `index.html` in a modern browser. Your progress saves to that browser's local storage. Export a JSON backup regularly under **Backup & settings**. Local storage is not shared between phone and computer.

## 2. Publish for free with GitHub Pages
1. Create/sign in to GitHub and create a new repository (e.g. `cswip31-study-hub`).
2. Upload `index.html` to the repository root. You may also upload the SQL and README.
3. Open repository **Settings → Pages**.
4. Choose deployment from the `main` branch and `/ (root)`, then save.
5. Wait for the published URL shown on the Pages settings screen. Open that URL on your phone and computer.

GitHub Pages hosts static files only. It does not store or sync study progress by itself.

## 3. Enable cross-device sync with Supabase
1. Create a project at https://supabase.com/ and keep it private to your own account.
2. In the Supabase dashboard, open **SQL Editor → New query**.
3. Paste the full contents of `supabase-schema.sql` and run it.
4. Open **Project Settings → API** (the labels may change). Copy the Project URL and the **anon/public** or **publishable** key. Do not copy or use the `service_role` secret key.
5. Open your published dashboard. Go to **Sync / recovery → Cloud sync setup**.
6. Paste the Project URL and public key; choose **Save connection settings**, then **Test connection**.
7. Click **Create cloud vault**. Your existing local progress will be copied to a new cloud vault.
8. Copy the recovery code shown and save it in a password manager or other safe place. Do not share it. The app does not store the recovery code permanently in local storage; it keeps it in the current browser session. If you close the session, use the code to reconnect.
9. On another device, open the same published website, enter the same Supabase URL and public key, test the connection, paste the recovery code under **Recovery code**, and click **Open existing vault**. Confirm that loading cloud data should replace local progress on that device.
10. Click **Sync now** after changes to push the current device's state to the cloud. This starter version does not perform automatic conflict resolution; avoid editing on two devices at the same time. The last saved payload replaces the previous cloud payload.

## Security notes
- The recovery code is a bearer secret with 256 bits of randomness. Anyone who has it can read and overwrite that vault. Treat it like a password.
- The database stores a SHA-256 hash of the recovery code, not the raw code. Study data itself is stored as JSON in Supabase, so this is not end-to-end encrypted.
- The Supabase public/anon key is expected to be visible in a client-side app. Database access is restricted to the defined RPC functions; do not expose a service-role key.
- This is designed for personal study notes and progress, not sensitive records. Use a private GitHub repository if desired, but note that GitHub Pages availability/plan rules can vary for private repositories; a public repository is the straightforward free path. If using a public repo, only publish app code/config placeholders, never your recovery code or study backup.
- For more robust production use, add rate limits/abuse protection, encrypted payloads, conflict resolution, and monitoring. A long random recovery code makes guessing impractical but does not protect against theft or phishing.
- No email/password is required by this app. Supabase project ownership still requires an account during setup.
- Quiz questions are original practice questions for study, not official CSWIP exam questions. Always use current approved training material and the applicable standards/code editions.

## Troubleshooting
- `Test connection` fails: check the URL/key, confirm SQL ran without errors, and make sure the project is awake/available.
- `function not found`: run the entire SQL script again and check the SQL Editor for errors.
- `Vault not found`: check that you copied the complete recovery code and selected the correct Supabase project.
- Cloud changes do not appear on another device: use **Sync now** on the source device, then reload/open the vault on the other device. Avoid simultaneous edits.
- If a recovery code is lost, it cannot be recovered from the database. If a device is still connected, create a new vault and save its new code, or export a backup.

## Target date range
The planner accepts 7 December 2026 through 31 December 2027. Dates are personal planning targets only; this app does not verify Malaysian course/exam availability.
