import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PROJECT_ID = 'real-estate-sales-app-dev';
const RULES_PATH = path.resolve(__dirname, '../firestore.rules');
const rules = fs.readFileSync(RULES_PATH, 'utf8');

async function runRulesTests() {
  console.log('Initializing Firestore Rules Test Environment...');
  const testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules,
      host: '127.0.0.1',
      port: 8080,
    },
  });

  let passed = 0;
  let failed = 0;

  async function test(name, fn) {
    try {
      await fn();
      console.log(`  ✓ ${name}`);
      passed++;
    } catch (err) {
      console.error(`  ✗ ${name}:`, err.message || err);
      failed++;
    }
  }

  try {
    console.log('\n--- Seeding User Accounts & Directories ---');
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      const staff = [
        { id: 'admin-1', name: 'Admin User', role: 'admin', active: true, email: 'admin@estate.com' },
        { id: 'exec-1', name: 'Exec User', role: 'executive', active: true, email: 'exec@estate.com' },
        { id: 'inside-1', name: 'Inside Rep', role: 'inside_sales', active: true, email: 'inside@estate.com' },
        { id: 'outside-1', name: 'Outside Rep', role: 'outside_sales', active: true, email: 'outside1@estate.com' },
        { id: 'outside-2', name: 'Outside Rep 2', role: 'outside_sales', active: true, email: 'outside2@estate.com' },
      ];

      for (const s of staff) {
        await db.collection('employees').doc(s.id).set({
          id: s.id,
          name: s.name,
          role: s.role,
          active: s.active,
          email: s.email,
        });
      }
    });

    const adminDb = testEnv.authenticatedContext('admin-1').firestore();
    const execDb = testEnv.authenticatedContext('exec-1').firestore();
    const insideDb = testEnv.authenticatedContext('inside-1').firestore();
    const outsideDb = testEnv.authenticatedContext('outside-1').firestore();
    const unauthedDb = testEnv.unauthenticatedContext().firestore();

    console.log('\n--- 1. Employee Management & Global Role Validation ---');

    await test('Admin can create valid employee roles', async () => {
      await assertSucceeds(
        adminDb.collection('employees').doc('new-rep').set({
          id: 'new-rep',
          name: 'New Outside Rep',
          role: 'outside_sales',
          active: true,
          email: 'newrep@estate.com',
        })
      );
    });

    await test('Employee creation rejects invalid or unknown roles', async () => {
      await assertFails(
        adminDb.collection('employees').doc('bad-role-1').set({
          id: 'bad-role-1',
          name: 'Hacker',
          role: 'hacker',
          active: true,
          email: 'hacker@estate.com',
        })
      );
      await assertFails(
        adminDb.collection('employees').doc('bad-role-2').set({
          id: 'bad-role-2',
          name: 'Super User',
          role: 'super_admin',
          active: true,
          email: 'super@estate.com',
        })
      );
    });

    console.log('\n--- 2. Employee Access & Privilege Escalation Lockout ---');

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('employees').doc('emp-sensitive').set({
        id: 'emp-sensitive',
        name: 'Rohan Sharma',
        email: 'rohan@estate.com',
        phone: '9876543210',
        role: 'inside_sales',
        active: true,
        dob: '1995-05-12',
      });
    });

    await test('Admin CAN read any employee document in /employees', async () => {
      await assertSucceeds(adminDb.collection('employees').doc('emp-sensitive').get());
    });

    await test('Employee CAN read their own document in /employees', async () => {
      await assertSucceeds(insideDb.collection('employees').doc('inside-1').get());
    });

    await test('Active employee CAN read /employees for assignments', async () => {
      await assertSucceeds(insideDb.collection('employees').doc('emp-sensitive').get());
      await assertSucceeds(execDb.collection('employees').doc('emp-sensitive').get());
    });

    await test('Unauthenticated client CANNOT read employee directory', async () => {
      await assertFails(unauthedDb.collection('employees').doc('emp-sensitive').get());
    });

    await test('Executive CANNOT escalate role to admin or executive on create', async () => {
      await assertFails(
        execDb.collection('employees').doc('exec-escalate-1').set({
          id: 'exec-escalate-1',
          name: 'Escalated Exec',
          role: 'executive',
          active: true,
          email: 'escalate@estate.com',
        })
      );
      await assertFails(
        execDb.collection('employees').doc('exec-escalate-2').set({
          id: 'exec-escalate-2',
          name: 'Escalated Admin',
          role: 'admin',
          active: true,
          email: 'admin2@estate.com',
        })
      );
    });

    await test('Executive CANNOT update employee document (escalation prevention)', async () => {
      await assertFails(
        execDb.collection('employees').doc('emp-sensitive').update({
          role: 'executive',
        })
      );
    });

    console.log('\n--- 3. Universal Raw Phone Ban & Private Contact Subcollection ---');

    await test('Root customer document DENIES raw phone field on create', async () => {
      await assertFails(
        adminDb.collection('customers').doc('cust-leak').set({
          id: 'cust-leak',
          name: 'Jane Doe',
          phone: '9876543210', // BANNED
          maskedPhone: '******3210',
          status: 'assigned_to_inside_sales',
          createdAt: new Date().toISOString(),
        })
      );
    });

    await test('Root customer document ALLOWS maskedPhone and required fields', async () => {
      await assertSucceeds(
        adminDb.collection('customers').doc('cust-safe-1').set({
          id: 'cust-safe-1',
          name: 'Jane Doe',
          maskedPhone: '******3210',
          status: 'assigned_to_inside_sales',
          assignedInsideSalesId: 'inside-1',
          assignedInsideSalesName: 'Inside Rep',
          createdAt: new Date().toISOString(),
        })
      );
    });

    await test('Root customer document DENIES adding raw phone on update', async () => {
      await assertFails(
        adminDb.collection('customers').doc('cust-safe-1').update({
          phone: '9876543210',
        })
      );
    });

    await test('Raw phone permitted in /customers/{id}/private/contact subcollection', async () => {
      await assertSucceeds(
        adminDb.collection('customers').doc('cust-safe-1').collection('private').doc('contact').set({
          customerId: 'cust-safe-1',
          phone: '9876543210',
          updatedAt: new Date().toISOString(),
        })
      );
    });

    await test('Unassigned outside rep CANNOT read /customers/{id}/private/contact', async () => {
      await assertFails(
        outsideDb.collection('customers').doc('cust-safe-1').collection('private').doc('contact').get()
      );
    });

    console.log('\n--- 4. Atomic Bidirectional Visit Scheduling & State Transitions ---');

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.collection('customers').doc('cust-to-schedule').set({
        id: 'cust-to-schedule',
        name: 'Karan Mehra',
        maskedPhone: '******9999',
        status: 'interested',
        assignedInsideSalesId: 'inside-1',
        assignedInsideSalesName: 'Inside Rep',
        createdAt: new Date().toISOString(),
      });
    });

    await test('Scheduling: Customer update without paired visit creation is DENIED', async () => {
      await assertFails(
        insideDb.collection('customers').doc('cust-to-schedule').update({
          status: 'visit_scheduled',
          assignedOutsideSalesId: 'outside-1',
          assignedOutsideSalesName: 'Outside Rep',
          activeVisitId: 'visit-new-1',
        })
      );
    });

    await test('Scheduling: Visit creation without paired customer update is DENIED', async () => {
      await assertFails(
        insideDb.collection('visits').doc('visit-new-1').set({
          id: 'visit-new-1',
          customerId: 'cust-to-schedule',
          customerName: 'Karan Mehra',
          maskedPhone: '******9999',
          insideSalesId: 'inside-1',
          outsideSalesId: 'outside-1',
          status: 'visit_scheduled',
          scheduledAt: new Date().toISOString(),
        })
      );
    });

    await test('Scheduling: Atomic paired batch with matching IDs is ALLOWED', async () => {
      const batch = insideDb.batch();
      batch.update(insideDb.collection('customers').doc('cust-to-schedule'), {
        status: 'visit_scheduled',
        assignedOutsideSalesId: 'outside-1',
        assignedOutsideSalesName: 'Outside Rep',
        activeVisitId: 'visit-atomic-1',
      });
      batch.set(insideDb.collection('visits').doc('visit-atomic-1'), {
        id: 'visit-atomic-1',
        customerId: 'cust-to-schedule',
        customerName: 'Karan Mehra',
        maskedPhone: '******9999',
        insideSalesId: 'inside-1',
        outsideSalesId: 'outside-1',
        status: 'visit_scheduled',
        scheduledAt: new Date().toISOString(),
      });
      await assertSucceeds(batch.commit());
    });

    await test('Check-In ("Reached Location"): Unpaired visit update to visit_in_progress is DENIED', async () => {
      await assertFails(
        outsideDb.collection('visits').doc('visit-atomic-1').update({
          status: 'visit_in_progress',
          reachedAt: new Date().toISOString(),
        })
      );
    });

    await test('Check-In ("Reached Location"): Atomic paired batch is ALLOWED', async () => {
      const batch = outsideDb.batch();
      batch.update(outsideDb.collection('visits').doc('visit-atomic-1'), {
        status: 'visit_in_progress',
        reachedAt: new Date().toISOString(),
      });
      batch.update(outsideDb.collection('customers').doc('cust-to-schedule'), {
        status: 'visit_in_progress',
      });
      await assertSucceeds(batch.commit());
    });

    await test('Completion: Atomic paired batch to visit_completed is ALLOWED', async () => {
      const batch = outsideDb.batch();
      batch.update(outsideDb.collection('visits').doc('visit-atomic-1'), {
        status: 'visit_completed',
        completedAt: new Date().toISOString(),
        notes: 'Customer interested in 3BHK unit 402',
      });
      batch.update(outsideDb.collection('customers').doc('cust-to-schedule'), {
        status: 'visit_completed',
      });
      await assertSucceeds(batch.commit());
    });

    console.log('\n--- 4b. Isolated Visit Media Subcollection Security ---');

    await test('Assigned Outside Sales rep can write valid media metadata', async () => {
      await assertSucceeds(
        outsideDb.collection('visits').doc('visit-atomic-1').collection('private').doc('media').set({
          recordingPath: 'visits/visit-atomic-1/audio.m4a',
          selfiePath: 'visits/visit-atomic-1/selfie.jpg',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        })
      );
    });

    await test('Media write DENIED if docId is not "media"', async () => {
      await assertFails(
        outsideDb.collection('visits').doc('visit-atomic-1').collection('private').doc('photos').set({
          recordingPath: 'visits/visit-atomic-1/audio.m4a',
          selfiePath: 'visits/visit-atomic-1/selfie.jpg',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        })
      );
    });

    await test('Media write DENIED if raw URLs or forbidden keys are included', async () => {
      await assertFails(
        outsideDb.collection('visits').doc('visit-atomic-1').collection('private').doc('media').set({
          recordingPath: 'visits/visit-atomic-1/audio.m4a',
          recordingUrl: 'https://firebasestorage.googleapis.com/...', // BANNED
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        })
      );
      await assertFails(
        outsideDb.collection('visits').doc('visit-atomic-1').collection('private').doc('media').set({
          recordingPath: 'visits/visit-atomic-1/audio.m4a',
          phone: '9876543210', // BANNED
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        })
      );
    });

    await test('Admin can read visit media metadata', async () => {
      await assertSucceeds(
        adminDb.collection('visits').doc('visit-atomic-1').collection('private').doc('media').get()
      );
    });

    await test('Assigned Outside Sales rep can read visit media metadata', async () => {
      await assertSucceeds(
        outsideDb.collection('visits').doc('visit-atomic-1').collection('private').doc('media').get()
      );
    });

    await test('Unassigned Outside Sales rep CANNOT read visit media metadata', async () => {
      const outside2Db = testEnv.authenticatedContext('outside-2').firestore();
      await assertFails(
        outside2Db.collection('visits').doc('visit-atomic-1').collection('private').doc('media').get()
      );
    });

    console.log('\n--- 5. Legacy Document ID Backfill & Updateability ---');

    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      // Simulate migrated legacy document that now has id: docId backfilled
      await db.collection('customers').doc('cust-migrated-legacy').set({
        id: 'cust-migrated-legacy',
        name: 'Legacy Customer',
        maskedPhone: '******1111',
        status: 'interested',
        assignedInsideSalesId: 'inside-1',
        assignedInsideSalesName: 'Inside Rep',
        createdAt: new Date().toISOString(),
      });
    });

    await test('Migrated legacy customer with backfilled id can transition through lifecycle', async () => {
      const batch = insideDb.batch();
      batch.update(insideDb.collection('customers').doc('cust-migrated-legacy'), {
        status: 'visit_scheduled',
        assignedOutsideSalesId: 'outside-1',
        assignedOutsideSalesName: 'Outside Rep',
        activeVisitId: 'visit-legacy-1',
      });
      batch.set(insideDb.collection('visits').doc('visit-legacy-1'), {
        id: 'visit-legacy-1',
        customerId: 'cust-migrated-legacy',
        customerName: 'Legacy Customer',
        maskedPhone: '******1111',
        insideSalesId: 'inside-1',
        outsideSalesId: 'outside-1',
        status: 'visit_scheduled',
        scheduledAt: new Date().toISOString(),
      });
      await assertSucceeds(batch.commit());
    });
  } finally {
    await testEnv.cleanup();
  }

  console.log(`\n========================================`);
  console.log(`Rules Test Summary: ${passed} passed, ${failed} failed`);
  console.log(`========================================\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

runRulesTests().catch((err) => {
  console.error('Fatal Test Runner Error:', err);
  process.exit(1);
});
