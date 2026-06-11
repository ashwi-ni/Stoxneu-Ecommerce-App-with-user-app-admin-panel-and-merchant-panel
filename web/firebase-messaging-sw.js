// web/firebase-messaging-sw.js

importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDeK3Sl5MXWzg_bBMFF-SlSUV9GOwKk44Q",
  authDomain: "stoxneu.firebaseapp.com",
  projectId: "stoxneu",
  storageBucket: "stoxneu.firebasestorage.app",
  messagingSenderId: "239389192310",
  appId: "1:239389192310:web:10f77720d16dfa39446f57",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("Received background message:", payload);

  const notificationTitle =
      payload.notification?.title || "Stoxneu Notification";

  const notificationOptions = {
    body: payload.notification?.body || "",
    icon: "/favicon.png",
  };

  self.registration.showNotification(
    notificationTitle,
    notificationOptions
  );
});