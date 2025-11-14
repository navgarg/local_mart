import functions from "firebase-functions";
import admin from "firebase-admin";
import Razorpay from "razorpay";
import * as dotenv from "dotenv";

// Load .env
dotenv.config();

// Initialize Firebase Admin once
admin.initializeApp();

// Razorpay instance
const instance = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_SECRET,
});

// Cloud Function to create Razorpay Order
export const createOrder = functions.https.onCall(async (data, context) => {
  try {
    const options = {
      amount: data.amount, // amount in paise
      currency: "INR",
      receipt: `receipt_${Date.now()}`,
    };

    const order = await instance.orders.create(options);
    return order;
  } catch (err) {
    console.error("Razorpay Error:", err);
    throw new functions.https.HttpsError("internal", "Unable to create order");
  }
});

