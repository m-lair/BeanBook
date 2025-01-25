/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

var serviceAccount = require("../config/serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});


interface BrewData {
  saveCount: number;
  title: string;
  creatorId: string;
}
export const notifyBrewOwnerOnFavorite = onDocumentUpdated(
    "coffeeBrews/{brewId}",
    async (event) => {
        // Check if event.data exists
    if (!event.data) {
        console.log("No data in event.");
        return null;
    }
        
    const beforeData = event.data.before?.data() as BrewData | undefined;
    const afterData = event.data.after?.data() as BrewData | undefined;
        
    if (!beforeData || !afterData) {
        console.log("Document data is missing or malformed.");
        return null;
    }

    // If saveCount is unchanged or invalid
    if (beforeData.saveCount === afterData.saveCount) {
      return null; // no change
    }

    // Determine the difference
    const increment = afterData.saveCount - beforeData.saveCount;
    if (increment <= 0) {
      return null; // no new favorite
    }

    // 1) Retrieve the brew's creator
    const creatorId = afterData.creatorId;

    // 2) Get the user's doc
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(creatorId)
      .get();

    if (!userDoc.exists) {
      console.log("User not found for creatorId:", creatorId);
      return null;
    }

    const userData = userDoc.data();
    if (!userData || !userData.fcmToken) {
      console.log("User does not have an fcmToken.");
      return null;
    }

    // 3) Build the notification message
    const payload = {
      notification: {
        title: "Someone favorited your brew!",
        body: `Your brew "${afterData.title}" got a new favorite.`,
      },
    };

    // 4) Send to the user's fcmToken
    try {
      await admin.messaging().sendToDevice(userData.fcmToken, payload);
      console.log("Notification sent to user:", creatorId);
    } catch (err) {
      console.error("Error sending FCM:", err);
    }

    return null;
  });
