# Database Schema

This is the shared source of truth. Do not change field names or status values without agreement from the team lead.

## `employees`
Full employee profile (Admin or Self read-only; Admin-only update).

| Field | Type | Notes |
|---|---|---|
| `id` | string | Firebase Auth user ID |
| `name` | string | Employee full name |
| `email` | string | Unique login email |
| `phone` | string | Employee phone number (PII) |
| `role` | string | `admin`, `executive`, `inside_sales`, or `outside_sales` |
| `profileImageUrl` | string? | Private storage URL/path |
| `active` | boolean | Disabled employees cannot use the app |
| `createdAt` | timestamp | Creation date |
| `dob` | string? | Date of birth |

## `staff_directory`
Public staff directory for assignment pickers (accessible by all active employees, Admin-only or Executive non-admin creation, Admin-only update). Contains zero sensitive employee PII.

| Field | Type | Notes |
|---|---|---|
| `id` | string | Firebase Auth user ID |
| `name` | string | Employee name |
| `role` | string | `admin`, `executive`, `inside_sales`, or `outside_sales` |
| `active` | boolean | Active status |

## `customers`
Root customer documents must NEVER contain raw phone numbers.

| Field | Type | Notes |
|---|---|---|
| `id` | string | Customer document ID (backfilled during migration) |
| `name` | string | Customer name |
| `maskedPhone` | string | Masked phone number (e.g., '******4285') |
| `email` | string? | Customer email |
| `status` | string | Lifecycle: `unassigned`, `assigned_to_inside_sales`, `interested`, `not_interested`, `visit_scheduled`, `visit_in_progress`, `visit_completed` |
| `budget` | string? | Budget range |
| `propertyNotes` | string? | Property preferences/notes |
| `assignedInsideSalesId` | string? | Employee ID |
| `assignedInsideSalesName` | string? | Employee Name |
| `assignedOutsideSalesId` | string? | Employee ID |
| `assignedOutsideSalesName` | string? | Employee Name |
| `activeVisitId` | string? | Paired active visit document ID |
| `createdAt` | timestamp | Creation date |

### `customers/{customerId}/private/contact`
Restricted subcollection storing actual raw phone numbers. Accessible only by Admin and currently assigned Inside/Outside Sales staff.

| Field | Type | Notes |
|---|---|---|
| `customerId` | string | Matches parent customer ID |
| `phone` | string | Raw phone number for on-demand calling/WhatsApp |
| `updatedAt` | timestamp | Last updated timestamp |

## `attendance`

| Field | Type |
|---|---|
| `employeeId` | string |
| `employeeName` | string? |
| `employeeEmail` | string? |
| `loginAt` | timestamp |
| `logoutAt` | timestamp? |
| `loginLatitude` | number? |
| `loginLongitude` | number? |
| `loginAllowed` | boolean |
| `failureReason` | string? |
| `distanceMeters` | number? |

## `customer_assignments`

| Field | Type |
|---|---|
| `customerId` | string |
| `insideSalesId` | string? |
| `outsideSalesId` | string? |
| `assignedBy` | string |
| `visitScheduledAt` | timestamp? |
| `status` | string |
| `createdAt` | timestamp |

## `call_updates`

| Field | Type |
|---|---|
| `customerId` | string |
| `insideSalesId` | string |
| `outcome` | string: `interested`, `not_interested`, or `follow_up` |
| `notes` | string? |
| `whatsappSentAt` | timestamp? |
| `createdAt` | timestamp |

## `visits`
Root visit documents contain only scheduling and status metadata. Media proofs are strictly prohibited from the root document.

| Field | Type | Notes |
|---|---|---|
| `id` | string | Visit document ID (backfilled during migration) |
| `customerId` | string | Associated Customer ID |
| `customerName` | string | Customer name |
| `maskedPhone` | string | Masked phone number (e.g., '******4285') |
| `insideSalesId` | string | Scheduling Inside Sales employee ID |
| `insideSalesName` | string? | Inside Sales employee name |
| `outsideSalesId` | string | Assigned Outside Sales employee ID |
| `outsideSalesName` | string? | Outside Sales employee name |
| `scheduledAt` | timestamp | Appointment scheduled time |
| `reachedAt` | timestamp? | Time outside sales arrived |
| `completedAt` | timestamp? | Time visit was completed |
| `status` | string | `visit_scheduled`, `visit_in_progress`, `visit_completed` |
| `notes` | string? | Visit outcome/notes |
| `createdAt` | timestamp? | Creation date |

### `visits/{visitId}/private/media`
Restricted subcollection storing media verification proofs. Accessible only by Admin and the assigned Outside Sales representative. Prohibited from root visit document.

| Field | Type | Notes |
|---|---|---|
| `recordingPath` | string? | Firebase Storage object path (e.g. `visits/{visitId}/audio/...`) |
| `selfiePath` | string? | Firebase Storage object path (e.g. `visits/{visitId}/selfies/...`) |
| `createdAt` | timestamp? | Created date |
| `updatedAt` | timestamp | Last updated timestamp |

## `broadcast_messages`

| Field | Type |
|---|---|
| `title` | string |
| `message` | string |
| `createdBy` | string |
| `targetRoles` | string array |
| `createdAt` | timestamp |

## Customer & Visit Status Lifecycle

```text
unassigned
→ assigned_to_inside_sales
→ interested OR not_interested
→ visit_scheduled (bidirectional atomic sync with visit creation)
→ visit_in_progress (bidirectional atomic sync with visit check-in)
→ visit_completed (bidirectional atomic sync with visit completion)
```

## Firebase Storage Object Structure & Rules

All customer site visit media is stored under restricted Cloud Storage object paths:

| Object Path Pattern | Purpose | Authorized Roles |
|---|---|---|
| `visits/{visitId}/audio/{timestamp}.m4a` | Audio recording proof of site visit | Admin, assigned active Outside Sales representative |
| `visits/{visitId}/selfies/{timestamp}.jpg` | Customer verification photo | Admin, assigned active Outside Sales representative |
| `_healthcheck/{allPaths=**}` | Harmless probe path with no customer data | Active employees |
| All other paths | Restricted / Denied | Denied to all |
