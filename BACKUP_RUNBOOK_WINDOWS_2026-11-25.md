# SWEKSHA Supabase backup runbook (Windows)

Project: `sweksha-cvd-service`
Project ref: `xotqafgkubodqpirfpfb`
Plan checked: Free

## Important limits

- Do not run restore commands against production as part of this backup.
- Supabase CLI `db dump` excludes Supabase-managed `auth`, `storage`, and extension schemas. This runbook backs up the project-managed database schema/data and custom roles; it is not a full Auth or Storage backup.
- Storage file bytes must be copied separately using the Storage dashboard or an S3-compatible client. A database dump only preserves Storage metadata.
- Free projects do not receive scheduled daily backups. Keep encrypted copies outside the laptop (for example, a restricted company drive).
- Never paste a database password, Supabase access token, service-role key, or S3 secret into ChatGPT, GitHub, a public issue, or a source file.

## 1. Install prerequisites

1. Install the Supabase CLI using the official Windows instructions: https://supabase.com/docs/guides/local-development/cli/getting-started
2. Install Docker Desktop: https://www.docker.com/products/docker-desktop/
3. Install PostgreSQL command-line tools if needed, then verify `psql --version`.
4. Open a new PowerShell window.

## 2. Prepare a private backup folder

```powershell
New-Item -ItemType Directory -Force -Path "$HOME\SWEKSHA-Backups\2026-11-25" | Out-Null
Set-Location "$HOME\SWEKSHA-Backups\2026-11-25"
```

## 3. Get the database connection string safely

1. Open Supabase Dashboard → project `sweksha-cvd-service` → **Connect**.
2. Choose the **Session pooler** connection string unless your network supports the direct connection.
3. Keep the database password private. Do not send it in chat.
4. In PowerShell, set it only in the current session:

```powershell
$env:SUPABASE_DB_URL = Read-Host "Paste the Session pooler connection string (input is visible)"
```

The connection string contains a password. Do not save it in a script or commit it to Git.

## 4. Create schema, custom-role, and data dumps

```powershell
supabase db dump --db-url "$env:SUPABASE_DB_URL" -f roles.sql --role-only
supabase db dump --db-url "$env:SUPABASE_DB_URL" -f schema.sql
supabase db dump --db-url "$env:SUPABASE_DB_URL" -f data.sql --use-copy --data-only -x "storage.buckets_vectors" -x "storage.vector_indexes"
```

If the command fails, stop and keep the error message. Do not reset the project or run restore commands to fix it.

## 5. Verify the files

```powershell
Get-Item roles.sql, schema.sql, data.sql | Select-Object Name, Length, LastWriteTime
Get-FileHash roles.sql, schema.sql, data.sql -Algorithm SHA256
```

All three files should exist and be non-empty. Save the SHA-256 output separately. A successful dump is not considered verified until files have been copied to a second, access-controlled location.

## 6. Back up Storage files separately

The current project has three public image buckets:
- `machine-listing-images`
- `machine-part-images`
- `diamond-trading-images`

Use Supabase Dashboard → **Storage → Files** to download every existing object, or configure an S3-compatible client using credentials generated in **Storage → Configuration → S3**. Store those credentials privately and revoke them when the copy is complete. Compare the downloaded file count with the current inventory before marking this step complete.

## 7. Finish securely

```powershell
Remove-Item Env:SUPABASE_DB_URL
```

Keep the backup folder encrypted and restrict access. Do not upload raw dumps to the public GitHub repository. Keep one second copy on a separate secure device or company drive.

## 8. What this does not back up

This CLI procedure does not export Supabase-managed Auth/Storage schemas or Storage object bytes. If SWEKSHA needs a full recovery point including Auth users/provider settings, Storage object bytes, secrets, Edge Function secrets, and project configuration, those components need their own supported exports or a higher-tier backup/restore plan. Verify them separately before declaring a complete disaster-recovery backup.

Official references:
- https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore
- https://supabase.com/docs/reference/cli/supabase-db-dump
- https://supabase.com/docs/guides/storage/management/download-objects
- https://supabase.com/docs/guides/platform/backups
