// Service worker that receives push messages while the tab is closed.
//
// It must live at the site root under exactly this name — the Firebase
// messaging SDK registers /firebase-messaging-sw.js by convention and does
// not look anywhere else.
//
// The config here is duplicated from lib/firebase/firebase_options.dart
// because a service worker cannot read the Dart bundle. These values are
// public in every Firebase web app; the data is guarded by the Firestore
// rules, not by hiding the project id.
importScripts(
  'https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js',
);

firebase.initializeApp({
  apiKey: 'AIzaSyD6QdoFu_DwOgoZ7Wf9kPM3oSrriGFGGjA',
  authDomain: 'child-health-tracker-7aad1.firebaseapp.com',
  projectId: 'child-health-tracker-7aad1',
  storageBucket: 'child-health-tracker-7aad1.firebasestorage.app',
  messagingSenderId: '261212268544',
  appId: '1:261212268544:web:ff57dccb00dd478285d0e5',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'Напоминание';
  self.registration.showNotification(title, {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    // Reminders for the same child collapse rather than stacking up: a
    // parent who left the tab closed for a day should not return to twenty
    // notifications.
    tag: payload.data?.reminder_id || 'reminder',
    data: payload.data || {},
  });
});

// Tapping the notification opens the app rather than a blank tab, and
// focuses an existing one if it is already open.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const target = '/reminders';
  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((windowClients) => {
        for (const client of windowClients) {
          if ('focus' in client) return client.focus();
        }
        return clients.openWindow(target);
      }),
  );
});
