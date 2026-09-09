// notification: NotificationProvider — the port for push delivery.
//
//   type NotificationProvider interface {
//       Send(ctx, PushMessage) (Receipt, error)
//       SendBatch(ctx, []PushMessage) ([]Receipt, error)
//   }
//
// PushMessage carries a LOCALIZATION KEY WITH PARAMETERS, not a rendered sentence, so the
// device renders in its own locale and a second UI language costs nothing.
//
// MVP implementation is FCM for both platforms (FCM delivers to iOS via APNs). A direct
// APNs adapter can be added behind this same interface later.
//
// See ARCHITECTURE.md 17.1, 17.3.

package notification
