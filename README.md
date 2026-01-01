Multi-Tenant SaaS Backend — Django

A production-grade, multi-tenant backend built with Django, focused on system design, data isolation, and operational correctness — not feature count.

This project intentionally avoids frontend concerns and microservice overengineering.
The goal is to demonstrate how real backend systems are designed, enforced, and reasoned about.

🎯 Project Objectives

Build a clean Django monolith with strong internal boundaries

Implement true multi-tenancy with hard isolation guarantees

Demonstrate PostgreSQL depth, not ORM cargo-culting

Use Redis and Celery only where they provide real value

Make architectural decisions explicit and defensible

If it looks like a CRUD demo, the project has failed.

🧠 Why Django (Not Flask)

Django was chosen deliberately for this project because it enforces:

Explicit application boundaries (Django apps as domains)

A powerful middleware pipeline (critical for tenant context enforcement)

ORM + migrations discipline (required for multi-tenant schemas)

Mature ecosystem for auth, background jobs, and observability

Flask optimizes for flexibility and speed.
This project optimizes for correctness, structure, and long-term maintainability.

Architectural Style

Single monolith

Multiple domain apps

Clear dependency direction

No business logic in views

Layered Responsibility Model
HTTP (DRF Views / Controllers)
        ↓
Application Services (Orchestration)
        ↓
Domain Logic (Models + Domain Services)
        ↓
Infrastructure (DB, Cache, Messaging)


Views coordinate.
Services decide.
Models enforce invariants.

📦 Project Structure
backend/
├── config/                 # Infrastructure & framework config
│   └── settings/           # base / local / production
│
├── apps/                   # Domain-driven Django apps
│   ├── core/               # Shared domain primitives
│   ├── users/              # Identity (not auth)
│   ├── organizations/      # Tenant root
│   └── health/             # Infra validation endpoints
│
├── shared/                 # Cross-cutting technical concerns
│   ├── middleware/
│   ├── auth/
│   ├── db/
│   └── logging/
│
└── requirements/           # Environment-specific dependencies

Boundary Rules

apps/ must not depend on each other directly

shared/ must not contain business logic

Views must not contain domain rules

Settings must not contain conditional runtime logic

Violating these rules is considered architectural debt.

🧩 Multi-Tenancy Strategy
Chosen Approach

Shared Database, Shared Schema, Tenant Column

Every tenant-owned table includes:

tenant_id (organization_id)

Why This Strategy

Operational simplicity

Horizontal scalability

Easier cross-tenant analytics (with safeguards)

Proven pattern for SaaS at scale

Tenant Identification (Per Request)

Tenant is resolved via:

JWT claim or

Explicit request header (X-Tenant-ID)

(Optional) subdomain in future

Once resolved:

Tenant ID is stored in a request-scoped context

No tenant IDs are passed manually

All queries are tenant-filtered by default

If tenant context is missing → request fails.

Isolation Guarantees

Every tenant-owned model includes tenant_id

Composite indexes include (tenant_id, <primary_key>)

Foreign keys enforce tenant consistency

Query access without tenant context is forbidden

Accidental cross-tenant reads must be impossible, not unlikely.

🗄️ PostgreSQL Design Principles

PostgreSQL only (no SQLite)

Explicit indexes (including composite tenant indexes)

Foreign keys & constraints always enabled

Transactional boundaries clearly defined

Cursor-based pagination for large datasets

ORM usage is intentional — SQL trade-offs are documented.

⚡ Redis Usage (Purpose-Driven Only)

Redis is used for:

Caching expensive, tenant-scoped reads

Rate limiting

JWT / session token handling

Distributed locks (when required)

Cache Rules

All cache keys are tenant-aware

TTLs are explicit

Cache invalidation is a designed mechanism, not an afterthought

System must degrade gracefully if Redis is unavailable

🔐 Authentication & Authorization
Auth

JWT access + refresh tokens

Token rotation

Explicit expiration strategies

Authorization

Role-Based Access Control (RBAC)

Roles belong to tenant memberships, not users

Permissions are always tenant-scoped

Global roles are avoided unless strictly required.

🔄 Background Jobs

Celery + Redis

Idempotent tasks only

Retry strategies documented

Failure paths explicitly handled

No “fire-and-forget” logic.

📊 Observability

Structured logging (JSON)

Clear error classification

Health endpoints for infra validation

Metrics added only where actionable

Logs must explain what failed and why, not just that something failed.

🧭 Development Phases
Phase	Focus
0	Foundation
1	Tenant Context
2	Auth & Authorization
3	Domain Events
4	Background Jobs
5	Caching
6	Observability
7	API Design

No phase skipping.
No feature creep.

📄 Failure Scenarios (Explicitly Considered)

Redis down

Token replay attempts

Cross-tenant access attempts

Partial database outages

Long-running background tasks

Each scenario has a documented behavior.

🚀 Local Development
cp .env.example .env
docker-compose up -d postgres redis
python manage.py migrate
python manage.py runserver


Swagger is enabled only in local development.

🧠 Final Note

This repository is not meant to impress with features.
It is meant to prove architectural maturity.

If something feels slower to implement — that’s intentional.


📦 Dependency Management (pip-tools)

This project uses pip-tools to achieve deterministic, reproducible dependency management, similar to package.json + package-lock.json in Node.js — without hiding resolution behavior.

Why pip-tools (and not pipenv / poetry)

Explicit dependency intent vs resolved versions

Lock files are plain requirements.txt

No environment ownership (works with venv, Docker, CI)

Production-aligned and widely accepted in backend teams

This avoids dependency drift and “works on my machine” failures.

📁 Requirements Structure
requirements/
├── base.in
├── base.txt
├── local.in
├── local.txt
├── production.in
└── production.txt


There are two types of files:

.in → Intent (what we want)

.txt → Lock files (what we actually install)

🔹 base.in — Core Application Dependencies
Django>=4.2,<5.0
djangorestframework>=3.14
psycopg[binary]>=3.1
python-dotenv>=1.0

Purpose

Defines the minimum required dependencies for the application to run in any environment.

Rules

No environment-specific tools

No dev-only packages

Must be safe for production

Think of this as:

The backend cannot exist without these.

🔹 local.in — Development Dependencies
-r base.in
drf-spectacular>=0.27

Purpose

Extends base.in with local development tools.

Examples:

Swagger / OpenAPI tooling

Debug helpers

Developer productivity utilities

Rules

Must include -r base.in

Must never include production-only infra (e.g. gunicorn)

Can be freely changed by developers

Equivalent to:

devDependencies in Node.js

🔹 production.in — Production Runtime Dependencies
-r base.in
gunicorn>=21.2

Purpose

Defines only what is required to run the app in production.

Examples:

WSGI server

Monitoring agents (if required)

Rules

Must include -r base.in

Must not include dev tooling

Should be minimal and stable

This file is what Docker / servers consume.

🔒 Lock Files (*.txt) — The Source of Truth

Files like:

base.txt

local.txt

production.txt

are generated, never handwritten.

They contain:

Fully resolved dependency trees

Exact versions

Hashes (if enabled)

These files must be committed.

They are equivalent to:

package-lock.json

⚙️ Installation Workflow
1️⃣ Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

2️⃣ Install pip-tools
pip install pip-tools

3️⃣ Compile lock files (only when dependencies change)
pip-compile requirements/base.in
pip-compile requirements/local.in
pip-compile requirements/production.in


⚠️ Do not edit .txt files manually

4️⃣ Install dependencies (deterministic)
pip-sync requirements/local.txt


This:

Removes undeclared packages

Installs exact locked versions

Prevents dependency drift

Equivalent to:

npm ci

🚫 Hard Rules (Enforced by Discipline)

❌ No pip install package-name directly

❌ No editing requirements/*.txt by hand

❌ No global Python installs

✅ Always update .in → recompile → sync

Breaking these rules invalidates reproducibility.

🧠 Why This Matters Architecturally

This setup ensures:

Deterministic builds across dev, CI, and prod

Clear separation of concerns per environment

Easy auditing of dependency changes

Production realism (no hidden tooling)

This is boring on purpose — and that’s a compliment.
