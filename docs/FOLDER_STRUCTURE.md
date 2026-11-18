# Recommended Repository & Folder Structure

## 1. Monorepo Structure

```text
omr-platform/
│
├── README.md
├── LICENSE
├── .gitignore
├── .editorconfig
├── .env.example
├── docker-compose.yml
│
├── docs/
│   ├── PRD.md
│   ├── TRD.md
│   ├── DATABASE_SCHEMA.md
│   ├── SYSTEM_ARCHITECTURE.md
│   ├── SYSTEM_DESIGN.md
│   ├── FOLDER_STRUCTURE.md
│   ├── api/
│   ├── diagrams/
│   └── runbooks/
│
├── apps/
│   └── mobile/
│       ├── android/
│       ├── ios/
│       ├── assets/
│       │   ├── icons/
│       │   ├── images/
│       │   └── templates/
│       ├── lib/
│       │   ├── app/
│       │   │   ├── app.dart
│       │   │   ├── router.dart
│       │   │   ├── theme.dart
│       │   │   └── bootstrap.dart
│       │   │
│       │   ├── core/
│       │   │   ├── constants/
│       │   │   ├── errors/
│       │   │   ├── network/
│       │   │   ├── storage/
│       │   │   ├── utils/
│       │   │   └── validators/
│       │   │
│       │   ├── features/
│       │   │   ├── auth/
│       │   │   │   ├── data/
│       │   │   │   ├── domain/
│       │   │   │   └── presentation/
│       │   │   │
│       │   │   ├── organizations/
│       │   │   ├── students/
│       │   │   ├── exams/
│       │   │   ├── answer_keys/
│       │   │   ├── scan/
│       │   │   ├── review/
│       │   │   ├── results/
│       │   │   ├── reports/
│       │   │   ├── email_delivery/
│       │   │   └── settings/
│       │   │
│       │   ├── shared/
│       │   │   ├── widgets/
│       │   │   ├── dialogs/
│       │   │   └── models/
│       │   │
│       │   └── main.dart
│       │
│       ├── test/
│       ├── integration_test/
│       └── pubspec.yaml
│
├── services/
│   └── omr-engine/
│       ├── app/
│       │   ├── api/
│       │   ├── domain/
│       │   ├── services/
│       │   ├── processors/
│       │   ├── templates/
│       │   └── workers/
│       ├── tests/
│       │   ├── unit/
│       │   ├── integration/
│       │   └── fixtures/
│       ├── benchmark/
│       │   ├── clean/
│       │   ├── rotated/
│       │   ├── shadows/
│       │   ├── multiple_marks/
│       │   └── erased/
│       ├── Dockerfile
│       ├── pyproject.toml
│       └── README.md
│
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   │   ├── 0001_extensions.sql
│   │   ├── 0002_profiles.sql
│   │   ├── 0003_organizations.sql
│   │   ├── 0004_students.sql
│   │   ├── 0005_exams.sql
│   │   ├── 0006_scan_processing.sql
│   │   ├── 0007_results.sql
│   │   ├── 0008_reports_email.sql
│   │   ├── 0009_rls.sql
│   │   └── 0010_indexes.sql
│   │
│   ├── functions/
│   │   ├── send-report-email/
│   │   │   └── index.ts
│   │   ├── finalize-result/
│   │   │   └── index.ts
│   │   ├── create-report-link/
│   │   │   └── index.ts
│   │   └── email-webhook/
│   │       └── index.ts
│   │
│   └── seed.sql
│
├── packages/
│   ├── api-contracts/
│   ├── design-tokens/
│   └── shared-types/
│
├── scripts/
│   ├── setup_dev.sh
│   ├── run_tests.sh
│   ├── generate_types.sh
│   └── validate_rls.sh
│
└── .github/
    └── workflows/
        ├── mobile-ci.yml
        ├── omr-ci.yml
        ├── supabase-ci.yml
        └── release.yml
```

## 2. Flutter Feature Structure

Each feature follows:

```text
feature/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── controllers/
    ├── pages/
    └── widgets/
```

This keeps UI, business rules and backend implementation separate.

## 3. OMR Engine Structure

```text
omr-engine/
├── app/
│   ├── api/
│   ├── domain/
│   ├── processors/
│   │   ├── normalize.py
│   │   ├── detect_page.py
│   │   ├── align.py
│   │   ├── detect_bubbles.py
│   │   ├── detect_identity.py
│   │   └── confidence.py
│   ├── templates/
│   ├── services/
│   └── workers/
└── tests/
```

## 4. Database Migration Rules

- Never edit an already-applied migration in shared environments.
- Add a new migration for every schema change.
- Keep RLS policies in version-controlled SQL.
- Test migrations from an empty database.
- Test rollback procedures for high-risk changes.

## 5. Environment Files

Never commit real values.

Example:

```text
.env.example
.env.local            # ignored
services/omr-engine/.env.example
supabase/functions/.env.example
```

Variables should include placeholders such as:

```text
SUPABASE_URL=
SUPABASE_PUBLISHABLE_KEY=
SUPABASE_SERVICE_ROLE_KEY=
RESEND_API_KEY=
OMR_SERVICE_URL=
SENTRY_DSN=
```

`SUPABASE_SERVICE_ROLE_KEY` and all provider secrets belong only on trusted server environments.

## 6. Naming Conventions

### Dart

- files: `snake_case.dart`
- classes: `PascalCase`
- variables: `camelCase`

### TypeScript

- files: `kebab-case.ts`
- functions: `camelCase`
- types: `PascalCase`

### Python

- files: `snake_case.py`
- classes: `PascalCase`
- functions: `snake_case`

### SQL

- table/column names: `snake_case`
- primary keys: `id`
- foreign keys: `{table_singular}_id`

## 7. Documentation Structure

`docs/` should contain:

- product requirements.
- technical requirements.
- database schema.
- architecture.
- system design.
- API contracts.
- OMR template authoring guide.
- security runbook.
- incident response runbook.
- release checklist.
