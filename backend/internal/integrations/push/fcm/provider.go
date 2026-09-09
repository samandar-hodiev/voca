// integrations/push/fcm: implements notification.NotificationProvider using Firebase Cloud
// Messaging.
//
// FCM delivers to Android directly and to iOS via APNs, so one integration covers both
// platforms at MVP. Credentials come from FCM_SERVICE_ACCOUNT_JSON.
//
// Reports unregistered tokens so notification.Service can prune them (ARCHITECTURE.md 17.3).

package fcm
