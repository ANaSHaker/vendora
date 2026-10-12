// Firebase Cloud Messaging service worker (web push).
// Fill in your own Firebase web config below (same values as in `.env`).
// These placeholders contain NO real project keys.
importScripts("https://www.gstatic.com/firebasejs/10.11.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.11.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "YOUR_FIREBASE_API_KEY",
  authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT_ID.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_WEB_APP_ID",
});
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[Vendora SW] Background message:", payload);
  const { title, body, imageUrl } = payload.notification ?? {};
  return self.registration.showNotification(title ?? "Vendora", {
    body: body ?? "",
    icon: imageUrl ?? "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png",
    data: payload.data,
  });
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const url = event.notification.data?.click_action ?? "/";
  event.waitUntil(clients.openWindow(url));
});

