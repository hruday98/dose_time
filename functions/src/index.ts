import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();

// Types
interface UserData {
  id: string;
  email: string;
  displayName: string;
  role: 'patient' | 'doctor' | 'caretaker';
  phoneNumber?: string;
  fcmToken?: string;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

interface PrescriptionData {
  id: string;
  patientId: string;
  doctorId?: string;
  medicationName: string;
  dosage: string;
  type: string;
  frequency: string;
  reminderTimes: string[];
  startDate: admin.firestore.Timestamp;
  endDate?: admin.firestore.Timestamp;
  instructions?: string;
  notes?: string;
  isActive: boolean;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

interface MedicationLogData {
  id: string;
  prescriptionId: string;
  patientId: string;
  scheduledTime: admin.firestore.Timestamp;
  takenTime?: admin.firestore.Timestamp;
  status: 'upcoming' | 'taken' | 'missed' | 'skipped' | 'overdue';
  notes?: string;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

/**
 * Cloud Function: createPrescription
 * Triggered when a new prescription is created
 * - Generates medication logs for the prescription schedule
 * - Sends notification to patient
 */
export const createPrescription = functions.firestore
  .document('prescriptions/{prescriptionId}')
  .onCreate(async (snap, context) => {
    const prescriptionData = snap.data() as PrescriptionData;
    const prescriptionId = context.params.prescriptionId;
    
    try {
      console.log(`Creating prescription: ${prescriptionId}`);
      
      // Generate medication logs for the next 30 days
      await generateMedicationLogs(prescriptionData);
      
      // Send notification to patient
      await sendPrescriptionNotification(prescriptionData, 'created');
      
      console.log(`Successfully processed prescription creation: ${prescriptionId}`);
    } catch (error) {
      console.error(`Error processing prescription creation: ${error}`);
      throw error;
    }
  });

/**
 * Cloud Function: updatePrescription
 * Triggered when a prescription is updated
 * - Regenerates medication logs if schedule changed
 * - Sends notification to patient if needed
 */
export const updatePrescription = functions.firestore
  .document('prescriptions/{prescriptionId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data() as PrescriptionData;
    const afterData = change.after.data() as PrescriptionData;
    const prescriptionId = context.params.prescriptionId;
    
    try {
      console.log(`Updating prescription: ${prescriptionId}`);
      
      // Check if schedule changed
      const scheduleChanged = 
        JSON.stringify(beforeData.reminderTimes) !== JSON.stringify(afterData.reminderTimes) ||
        beforeData.frequency !== afterData.frequency ||
        beforeData.startDate !== afterData.startDate ||
        beforeData.endDate !== afterData.endDate;
      
      if (scheduleChanged && afterData.isActive) {
        // Delete existing future logs and regenerate
        await deleteFutureLogs(prescriptionId);
        await generateMedicationLogs(afterData);
      }
      
      // Send notification for significant changes
      if (scheduleChanged || beforeData.dosage !== afterData.dosage) {
        await sendPrescriptionNotification(afterData, 'updated');
      }
      
      console.log(`Successfully processed prescription update: ${prescriptionId}`);
    } catch (error) {
      console.error(`Error processing prescription update: ${error}`);
      throw error;
    }
  });

/**
 * Cloud Function: checkOverdueReminders
 * Scheduled function to check for overdue medication reminders
 * Runs every 30 minutes
 */
export const checkOverdueReminders = functions.pubsub
  .schedule('every 30 minutes')
  .onRun(async (context) => {
    try {
      console.log('Checking for overdue medication reminders');
      
      const now = admin.firestore.Timestamp.now();
      const fifteenMinutesAgo = admin.firestore.Timestamp.fromMillis(
        now.toMillis() - (15 * 60 * 1000)
      );
      
      // Find upcoming medications that are now overdue
      const overdueQuery = db.collection('medication_logs')
        .where('status', '==', 'upcoming')
        .where('scheduledTime', '<=', fifteenMinutesAgo);
      
      const overdueDocs = await overdueQuery.get();
      
      if (overdueDocs.empty) {
        console.log('No overdue medications found');
        return;
      }
      
      const batch = db.batch();
      const overdueNotifications: Promise<void>[] = [];
      
      overdueDocs.forEach(doc => {
        const logData = doc.data() as MedicationLogData;
        
        // Update status to overdue
        batch.update(doc.ref, {
          status: 'overdue',
          updatedAt: now
        });
        
        // Send overdue notification
        overdueNotifications.push(sendOverdueNotification(logData));
      });
      
      await batch.commit();
      await Promise.all(overdueNotifications);
      
      console.log(`Processed ${overdueDocs.size} overdue medications`);
    } catch (error) {
      console.error('Error checking overdue reminders:', error);
      throw error;
    }
  });

/**
 * Cloud Function: onMedicationTaken
 * Triggered when a medication log is updated to 'taken' status
 * - Sends confirmation notification
 * - Updates adherence statistics
 */
export const onMedicationTaken = functions.firestore
  .document('medication_logs/{logId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data() as MedicationLogData;
    const afterData = change.after.data() as MedicationLogData;
    
    // Check if status changed to 'taken'
    if (beforeData.status !== 'taken' && afterData.status === 'taken') {
      try {
        console.log(`Medication taken: ${context.params.logId}`);
        
        // Send confirmation notification (optional)
        // await sendMedicationTakenNotification(afterData);
        
        // Update adherence statistics (implement as needed)
        // await updateAdherenceStats(afterData.patientId);
        
      } catch (error) {
        console.error('Error processing medication taken:', error);
      }
    }
  });

/**
 * Helper function to generate medication logs for a prescription
 */
async function generateMedicationLogs(prescription: PrescriptionData): Promise<void> {
  const logs: MedicationLogData[] = [];
  const now = new Date();
  const startDate = prescription.startDate.toDate();
  const endDate = prescription.endDate?.toDate() || new Date(now.getTime() + (30 * 24 * 60 * 60 * 1000)); // 30 days default
  
  // Generate logs for each day
  for (let date = new Date(Math.max(startDate.getTime(), now.getTime())); 
       date <= endDate; 
       date.setDate(date.getDate() + 1)) {
    
    // Skip days based on frequency
    if (!shouldTakeMedicationOnDate(date, startDate, prescription.frequency)) {
      continue;
    }
    
    // Create logs for each reminder time
    for (const timeStr of prescription.reminderTimes) {
      const [hours, minutes] = timeStr.split(':').map(Number);
      const scheduledTime = new Date(date);
      scheduledTime.setHours(hours, minutes, 0, 0);
      
      // Only create logs for future times
      if (scheduledTime > now) {
        const logId = `${prescription.id}_${scheduledTime.getTime()}`;
        
        logs.push({
          id: logId,
          prescriptionId: prescription.id,
          patientId: prescription.patientId,
          scheduledTime: admin.firestore.Timestamp.fromDate(scheduledTime),
          status: 'upcoming',
          createdAt: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now()
        });
      }
    }
  }
  
  // Batch write logs
  const batch = db.batch();
  logs.forEach(log => {
    const logRef = db.collection('medication_logs').doc(log.id);
    batch.set(logRef, log);
  });
  
  await batch.commit();
  console.log(`Generated ${logs.length} medication logs for prescription ${prescription.id}`);
}

/**
 * Helper function to check if medication should be taken on a specific date
 */
function shouldTakeMedicationOnDate(date: Date, startDate: Date, frequency: string): boolean {
  const daysDiff = Math.floor((date.getTime() - startDate.getTime()) / (24 * 60 * 60 * 1000));
  
  switch (frequency) {
    case 'onceDaily':
    case 'twiceDaily':
    case 'threeTimesDaily':
    case 'fourTimesDaily':
    case 'asNeeded':
      return true;
    case 'everyOtherDay':
      return daysDiff % 2 === 0;
    case 'weekly':
      return daysDiff % 7 === 0;
    default:
      return true;
  }
}

/**
 * Helper function to delete future medication logs
 */
async function deleteFutureLogs(prescriptionId: string): Promise<void> {
  const now = admin.firestore.Timestamp.now();
  const futureLogsQuery = db.collection('medication_logs')
    .where('prescriptionId', '==', prescriptionId)
    .where('scheduledTime', '>', now)
    .where('status', '==', 'upcoming');
  
  const futureLogs = await futureLogsQuery.get();
  
  if (!futureLogs.empty) {
    const batch = db.batch();
    futureLogs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    console.log(`Deleted ${futureLogs.size} future logs for prescription ${prescriptionId}`);
  }
}

/**
 * Helper function to send prescription notifications
 */
async function sendPrescriptionNotification(prescription: PrescriptionData, action: 'created' | 'updated'): Promise<void> {
  try {
    // Get patient's FCM token
    const patientDoc = await db.collection('users').doc(prescription.patientId).get();
    if (!patientDoc.exists) return;
    
    const patientData = patientDoc.data() as UserData;
    if (!patientData.fcmToken) return;
    
    const title = action === 'created' ? 'New Prescription Added' : 'Prescription Updated';
    const body = `Your prescription for ${prescription.medicationName} has been ${action}.`;
    
    const message = {
      token: patientData.fcmToken,
      notification: {
        title,
        body
      },
      data: {
        type: 'prescription',
        action,
        prescriptionId: prescription.id
      }
    };
    
    await admin.messaging().send(message);
    console.log(`Sent ${action} notification for prescription ${prescription.id}`);
  } catch (error) {
    console.error(`Error sending prescription notification: ${error}`);
  }
}

/**
 * Helper function to send overdue medication notifications
 */
async function sendOverdueNotification(log: MedicationLogData): Promise<void> {
  try {
    // Get patient's FCM token
    const patientDoc = await db.collection('users').doc(log.patientId).get();
    if (!patientDoc.exists) return;
    
    const patientData = patientDoc.data() as UserData;
    if (!patientData.fcmToken) return;
    
    // Get prescription details
    const prescriptionDoc = await db.collection('prescriptions').doc(log.prescriptionId).get();
    if (!prescriptionDoc.exists) return;
    
    const prescriptionData = prescriptionDoc.data() as PrescriptionData;
    
    const message = {
      token: patientData.fcmToken,
      notification: {
        title: 'Missed Medication',
        body: `You missed your ${prescriptionData.medicationName} dose. Please take it when possible.`
      },
      data: {
        type: 'overdue',
        logId: log.id,
        prescriptionId: log.prescriptionId
      }
    };
    
    await admin.messaging().send(message);
    console.log(`Sent overdue notification for log ${log.id}`);
  } catch (error) {
    console.error(`Error sending overdue notification: ${error}`);
  }
}
