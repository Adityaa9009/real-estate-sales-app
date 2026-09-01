# Team Workflow

## Branches

Use these branches:

| Branch | Owner | Purpose |
|---|---|---|
| `main` | Team lead | Stable demo-ready version only |
| `develop` | Whole team | Combined development work |
| `feature/backend-auth` | Team lead | Authentication, roles, database, shared services |
| `feature/admin-dashboard` | Admin developer | Admin dashboard |
| `feature/executive-dashboard` | Executive developer | Executive dashboard |
| `feature/inside-sales` | Inside Sales developer | Inside Sales module |
| `feature/outside-sales` | Outside Sales developer | Outside Sales module |
| `feature/qa-devops` | QA developer | Tests, deployment configuration |

## Rules

1. Before work: pull the latest `develop` branch.
2. Work only on your own feature branch.
3. Do not rename database fields, roles, or statuses without team-lead approval.
4. Test your screen with real data from the shared development Firebase project.
5. Push your branch and create a Pull Request to `develop`.
6. Only merge after review and a successful build.

## Shared development accounts

Create and use one test account per role after Firebase setup:

| Email | Role |
|---|---|
| `admin@demo.com` | `admin` |
| `executive@demo.com` | `executive` |
| `inside@demo.com` | `inside_sales` |
| `outside@demo.com` | `outside_sales` |
