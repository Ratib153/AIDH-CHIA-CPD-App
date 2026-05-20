# CHIA CPD local database

SQLite file `chia_cpd.db` (via `sqflite`) stores recertification cycles, CPD activities, and app settings. Timestamps are ISO 8601 strings.

## Tables

- **recertification_cycles** — `cycle_name`, `start_date`, `end_date`, `target_points`, `is_active`, `created_at`
- **cpd_activities** — activity fields linked to `cycle_id`; `deleted_at` set for soft deletes
- **app_settings** — key/value (theme, profile display name, etc.)

## Lifecycle

`main.dart` calls `DatabaseService.instance.initDatabase()`. On first launch, a default 3-year active cycle is created if none exists.

## Cycles

- **archiveAndCreateNewCycle** — deactivates the current cycle and inserts a new active one (Profile → start new cycle).
- Category caps live in `lib/constants/cpd_categories.dart`; the DB stores totals only (`getPointsByCategory`).

## Activities

- Reads exclude soft-deleted rows (`deleted_at IS NULL`).
- **softDeleteActivity** — used from the activity list UI.
- Duplicate detection: `hasPotentialDuplicate` before insert/update.

## Export

`getExportData(cycleId)` returns cycle metadata and activity rows for `export_screen` / `export_service`.
