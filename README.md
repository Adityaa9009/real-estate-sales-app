# Real Estate Sales App

A role-based real-estate sales application for Admin, Executive, Inside Sales, and Outside Sales employees.

## Project status

The shared architecture is being set up. The first deliverable is secure login and role-based access; dashboards are built after that foundation is ready.

## Roles

- `admin` - manages employees, attendance, recordings, broadcasts, and all data.
- `executive` - creates employees/customers and assigns customers to Inside Sales.
- `inside_sales` - handles assigned customers, records call outcomes, and schedules Outside Sales visits.
- `outside_sales` - handles assigned visits, recordings, and customer selfies.

## Team workflow

1. Each person works in a separate Git branch.
2. No one pushes directly to `main`.
3. Open a pull request into `develop` when a feature is ready.
4. The team lead reviews database/API changes before merging.

See [docs/TEAM_WORKFLOW.md](docs/TEAM_WORKFLOW.md) and [docs/DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md) for the shared rules.
