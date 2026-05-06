# CHIA CPD Database Guide

## Overview

This app uses a local SQLite database (`chia_cpd.db`) via `sqflite` to store:

- `recertification_cycles` (active + archived cycles)
- `cpd_activities` (CPD logs linked to a cycle)

All timestamps are stored as ISO 8601 strings.

## Schema Summary

### `recertification_cycles`

- `id` (PK)
- `cycle_name`
- `start_date`
- `end_date`
- `target_points` (default `60`)
- `is_active` (`1` active, `0` inactive)
- `created_at`

### `cpd_activities`

- `id` (PK)
- `cycle_id` (FK to `recertification_cycles.id`)
- `date_logged`
- `category_id`
- `category_name`
- `subcategory`
- `activity_description`
- `provider_name`
- `duration_hours`
- `points_claimed`
- `competency_domain`
- `evidence_note`
- `deleted_at` (nullable soft-delete marker)
- `created_at`
- `updated_at`

## Cycle Behavior

- The DB is initialized from `main.dart` using `DatabaseService.instance.initDatabase()`.
- On first launch, if no cycle exists, a default active cycle is created:
  - name: `Cycle 1`
  - start date: today
  - end date: today + 1095 days (~3 years)
  - target points: `60`

## Resetting/Starting a New Cycle

Use:

- `archiveAndCreateNewCycle(newCycle)`

This runs in one transaction:

1. Deactivate current active cycles.
2. Insert the new cycle as active.

Use `setActiveCycle(id)` when switching to an existing cycle.

## Soft Delete and Audit Trail

- `softDeleteActivity(id)` sets `deleted_at` (record preserved for audit/evidence trail).
- `hardDeleteActivity(id)` permanently removes a record (use only after explicit user confirmation).
- Standard read methods exclude soft-deleted rows (`deleted_at IS NULL`).

## Category Caps and Validation

Category metadata and caps are stored in `lib/constants/cpd_categories.dart` (not in DB).

The DB layer does **not** reject rows for cap overflow. Instead:

- `getPointsByCategory(cycleId)` returns totals per category (1-10)
- UI uses that output to show warning states (approaching/exceeding cap)

## Export Integration

`DatabaseService.getExportData(cycleId)` returns:

- cycle metadata (`name`, `startDate`, `endDate`, `totalPoints`, `targetPoints`)
- flat `activities` rows with export field names

The export screen reads this payload and maps rows into the existing export pipeline input, so export logic/signature remains unchanged.
