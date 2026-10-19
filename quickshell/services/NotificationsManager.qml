pragma Singleton
import Quickshell.Services.Notifications
import Quickshell

Singleton {
    id: root

    property list<Notification> items: []
    readonly property var count: items.length

    NotificationServer {
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        persistenceSupported: true

        onNotification: function (newNotification) {
            newNotification.tracked = true;
            root.items.push(newNotification);
            newNotification.closed.connect(function () {
                items = items.filter(notification => notification !== newNotification);
            });
        }
    }

    function dismissAll() {
        items.forEach(notification => notification.dismiss());
        items = [];
    }

    function dismissOne(notification: Notification) {
        notification.dismiss();
        items = items.filter(item => item !== notification);
    }
}
