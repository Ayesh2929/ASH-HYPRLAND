// ╔═══════════════════════════════════════════════════════════════════════════════╗
// ║           ASH DOTFILES v3.0 — AGS NOTIFICATIONS MODULE                     ║
// ║           Beautiful notification overlay with animations                   ║
// ╚═══════════════════════════════════════════════════════════════════════════════╝

import Widget        from "resource:///com/github/Aylur/ags/widget.js";
import Notifications from "resource:///com/github/Aylur/ags/service/notifications.js";
import { execAsync } from "resource:///com/github/Aylur/ags/utils.js";
import Variable      from "resource:///com/github/Aylur/ags/variable.js";

// ═══════════════════════════════════════════════════════════════════════════════
// 🎨 URGENCY STYLES
// ═══════════════════════════════════════════════════════════════════════════════

const URGENCY_CLASSES = {
    low:      "notif-low",
    normal:   "notif-normal",
    critical: "notif-critical",
};

const URGENCY_ICONS = {
    low:      "dialog-information-symbolic",
    normal:   "dialog-information-symbolic",
    critical: "dialog-warning-symbolic",
};

// ═══════════════════════════════════════════════════════════════════════════════
// 🔔 NOTIFICATION WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

const NotificationWidget = (notification) => {
    const urgency_class = URGENCY_CLASSES[notification.urgency] || "notif-normal";

    // ── Dismiss button ────────────────────────────────────────────────────────
    const CloseButton = Widget.Button({
        class_name: "notif-close",
        child:       Widget.Label({ label: "✕" }),
        on_clicked:  () => notification.close(),
        tooltip_text: "Dismiss",
    });

    // ── App icon ──────────────────────────────────────────────────────────────
    const AppIcon = notification.image
        ? Widget.Box({
            class_name: "notif-image",
            css: `
                background-image: url("${notification.image}");
                background-size: cover;
                background-repeat: no-repeat;
                background-position: center;
                min-width: 48px;
                min-height: 48px;
                border-radius: 8px;
            `,
        })
        : Widget.Icon({
            class_name: "notif-icon",
            icon:        notification.app_icon ||
                         notification.app_entry ||
                         URGENCY_ICONS[notification.urgency] ||
                         "dialog-information-symbolic",
            size:        36,
        });

    // ── Header ────────────────────────────────────────────────────────────────
    const Header = Widget.Box({
        class_name: "notif-header",
        children: [
            Widget.Label({
                class_name:  "notif-app-name",
                label:        notification.app_name || "Notification",
                xalign:       0,
                truncate:     "end",
                max_width_chars: 20,
            }),
            Widget.Box({ hexpand: true }),
            Widget.Label({
                class_name: "notif-time",
                label:       _format_time(notification.time),
            }),
            CloseButton,
        ],
    });

    // ── Summary ───────────────────────────────────────────────────────────────
    const Summary = Widget.Label({
        class_name:  "notif-summary",
        label:        notification.summary || "",
        xalign:       0,
        lines:        2,
        wrap:         true,
        use_markup:   true,
        max_width_chars: 40,
    });

    // ── Body ──────────────────────────────────────────────────────────────────
    const Body = notification.body
        ? Widget.Label({
            class_name:  "notif-body",
            label:        notification.body,
            xalign:       0,
            lines:        3,
            wrap:         true,
            use_markup:   true,
            max_width_chars: 40,
        })
        : null;

    // ── Actions ───────────────────────────────────────────────────────────────
    const Actions = notification.actions.length > 0
        ? Widget.Box({
            class_name: "notif-actions",
            spacing:    6,
            children:   notification.actions.map(action =>
                Widget.Button({
                    class_name: "notif-action-btn",
                    child:       Widget.Label({ label: action.label }),
                    on_clicked: () => {
                        notification.invoke(action.id);
                        notification.close();
                    },
                })
            ),
        })
        : null;

    // ── Content ───────────────────────────────────────────────────────────────
    const content_children = [Summary];
    if (Body) content_children.push(Body);
    if (Actions) content_children.push(Actions);

    const Content = Widget.Box({
        class_name: "notif-content",
        vertical:   true,
        spacing:    4,
        children:   content_children,
    });

    // ── Main layout ───────────────────────────────────────────────────────────
    return Widget.EventBox({
        class_name: `notification ${urgency_class}`,
        on_secondary_click: () => notification.close(),
        child: Widget.Box({
            class_name: "notif-box",
            vertical:   true,
            children: [
                Header,
                Widget.Box({
                    spacing:  10,
                    children: [AppIcon, Content],
                }),
            ],
        }),
    });
};

// Helper: format timestamp
function _format_time(time) {
    if (!time) return "";
    const now  = Math.floor(Date.now() / 1000);
    const diff = now - time;

    if (diff < 60)    return "now";
    if (diff < 3600)  return `${Math.floor(diff / 60)}m ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
    return `${Math.floor(diff / 86400)}d ago`;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 📤 NOTIFICATION LIST
// ═══════════════════════════════════════════════════════════════════════════════

const NotificationList = () => {
    const notifications = Variable(Notifications.notifications);

    Notifications.connect("changed", () => {
        notifications.setValue([...Notifications.notifications]);
    });

    return Widget.Box({
        class_name: "notifications-list",
        vertical:   true,
        spacing:    6,
        children:   notifications.bind().as(notifs =>
            notifs.slice(-5).reverse().map(NotificationWidget)
        ),
    });
};

// ═══════════════════════════════════════════════════════════════════════════════
// 🪟 NOTIFICATION OVERLAY WINDOW
// ═══════════════════════════════════════════════════════════════════════════════

const NotificationsWindow = () => Widget.Window({
    name:    "notifications",
    class_name: "notifications-window",
    layer:   "overlay",
    anchor:  ["top", "right"],
    margins: [52, 12, 0, 0],
    visible: Notifications.bind("notifications").as(n => n.length > 0),
    child:   NotificationList(),
});

export default NotificationsWindow;