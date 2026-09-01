# Database Schema

This is the shared source of truth. Do not change field names or status values without agreement from the team lead.

## `employees`

| Field | Type | Notes |
|---|---|---|
| `id` | string | Firebase Auth user ID |
| `name` | string | Employee full name |
| `email` | string | Unique login email |
| `phone` | string | Employee phone number |
| `role` | string | `admin`, `executive`, `inside_sales`, or `outside_sales` |
| `profileImageUrl` | string? | Private storage URL/path |
| `active` | boolean | Disabled employees cannot use the app |
| `createdAt` | timestamp | Creation date |

## `customers`

| Field | Type | Notes |
|---|---|---|
| `id` | string | Customer ID |
| `name` | string | Customer name |
| `phone` | string | Never display the full value to sales staff |
| `email` | string? | Customer email |
| `status` | string | See status lifecycle below |
| `assignedInsideSalesId` | string? | Employee ID |
| `assignedOutsideSalesId` | string? | Employee ID |
| `createdAt` | timestamp | Creation date |

## `attendance`

| Field | Type |
|---|---|
| `employeeId` | string |
| `loginAt` | timestamp |
| `logoutAt` | timestamp? |
| `loginLatitude` | number? |
| `loginLongitude` | number? |
| `loginAllowed` | boolean |

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

| Field | Type |
|---|---|
| `customerId` | string |
| `outsideSalesId` | string |
| `scheduledAt` | timestamp |
| `reachedAt` | timestamp? |
| `completedAt` | timestamp? |
| `recordingPath` | string? |
| `selfiePath` | string? |
| `status` | string |

## `broadcast_messages`

| Field | Type |
|---|---|
| `title` | string |
| `message` | string |
| `createdBy` | string |
| `targetRoles` | string array |
| `createdAt` | timestamp |

## Customer status lifecycle

```text
unassigned
→ assigned_to_inside_sales
→ interested OR not_interested
→ visit_scheduled
→ visit_in_progress
→ visit_completed
```
