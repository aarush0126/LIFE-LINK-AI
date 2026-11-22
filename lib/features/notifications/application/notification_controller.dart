import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/user_model.dart';

enum DemoNotificationCategory {
  newEnquiry('New coordination enquiry'),
  resourceUpdate('Resource status update'),
  hospitalResponse('Hospital response'),
  pendingVerification('Pending verification'),
  workflowChange('Workflow status change');

  const DemoNotificationCategory(this.label);

  final String label;
}

enum DemoNotificationScope { general, blood, icu, equipment, organ }

class DemoNotification {
  const DemoNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    required this.occurredAt,
    required this.scope,
    this.isUnread = true,
  });

  final String id;
  final DemoNotificationCategory category;
  final String title;
  final String message;
  final DateTime occurredAt;
  final DemoNotificationScope scope;
  final bool isUnread;

  DemoNotification copyWith({bool? isUnread}) => DemoNotification(
    id: id,
    category: category,
    title: title,
    message: message,
    occurredAt: occurredAt,
    scope: scope,
    isUnread: isUnread ?? this.isUnread,
  );
}

class DemoNotificationsController extends ChangeNotifier {
  final List<DemoNotification> _notifications = _initialNotifications();

  List<DemoNotification> forRole(UserRole role) {
    final scopes = switch (role) {
      UserRole.networkAdministrator => DemoNotificationScope.values.toSet(),
      UserRole.transplantCoordinator => {
        DemoNotificationScope.organ,
        DemoNotificationScope.general,
      },
      UserRole.bloodBankOfficer => {
        DemoNotificationScope.blood,
        DemoNotificationScope.general,
      },
      UserRole.emergencyIcuCoordinator => {
        DemoNotificationScope.blood,
        DemoNotificationScope.icu,
        DemoNotificationScope.equipment,
        DemoNotificationScope.general,
      },
      UserRole.equipmentCoordinator => {
        DemoNotificationScope.equipment,
        DemoNotificationScope.general,
      },
      UserRole.hospitalAdministrator => {
        DemoNotificationScope.blood,
        DemoNotificationScope.icu,
        DemoNotificationScope.equipment,
        DemoNotificationScope.general,
      },
      UserRole.auditorComplianceOfficer => {DemoNotificationScope.general},
    };
    return List.unmodifiable(
      _notifications.where(
        (notification) => scopes.contains(notification.scope),
      ),
    );
  }

  void setRead(String id, {required bool isRead}) {
    final index = _notifications.indexWhere(
      (notification) => notification.id == id,
    );
    if (index == -1) return;
    _notifications[index] = _notifications[index].copyWith(isUnread: !isRead);
    notifyListeners();
  }

  void markAllRead(UserRole role) {
    final visibleIds = forRole(role)
        .map((notification) => notification.id)
        .toSet();
    for (var index = 0; index < _notifications.length; index++) {
      final notification = _notifications[index];
      if (visibleIds.contains(notification.id) && notification.isUnread) {
        _notifications[index] = notification.copyWith(isUnread: false);
      }
    }
    notifyListeners();
  }
}

List<DemoNotification> _initialNotifications() {
  final now = DateTime.now();
  return [
    DemoNotification(
      id: 'DEMO-NOTIF-01',
      category: DemoNotificationCategory.newEnquiry,
      title: 'New resource enquiry',
      message: 'A synthetic blood-component enquiry was logged for institutional review. No reservation or availability is implied.',
      occurredAt: now.subtract(const Duration(minutes: 8)),
      scope: DemoNotificationScope.blood,
    ),
    DemoNotification(
      id: 'DEMO-NOTIF-02',
      category: DemoNotificationCategory.resourceUpdate,
      title: 'Equipment listing updated',
      message: 'A synthetic equipment listing changed. Confirm status directly with the institution before relying on it.',
      occurredAt: now.subtract(const Duration(minutes: 24)),
      scope: DemoNotificationScope.equipment,
    ),
    DemoNotification(
      id: 'DEMO-NOTIF-03',
      category: DemoNotificationCategory.hospitalResponse,
      title: 'Institution response recorded',
      message: 'A fictional hospital response was recorded in the demonstration workflow.',
      occurredAt: now.subtract(const Duration(hours: 1)),
      scope: DemoNotificationScope.icu,
    ),
    DemoNotification(
      id: 'DEMO-NOTIF-04',
      category: DemoNotificationCategory.pendingVerification,
      title: 'Institution verification pending',
      message:
          'A synthetic resource report is awaiting institutional confirmation.',
      occurredAt: now.subtract(const Duration(hours: 2)),
      scope: DemoNotificationScope.general,
    ),
    DemoNotification(
      id: 'DEMO-NOTIF-05',
      category: DemoNotificationCategory.workflowChange,
      title: 'Coordination workflow updated',
      message: 'A simulated transplant coordination workflow changed. No donor or recipient information is included.',
      occurredAt: now.subtract(const Duration(hours: 4)),
      scope: DemoNotificationScope.organ,
    ),
    DemoNotification(
      id: 'DEMO-NOTIF-06',
      category: DemoNotificationCategory.resourceUpdate,
      title: 'ICU capacity indicator updated',
      message: 'A synthetic bed indicator changed. It is an enquiry signal, not a confirmed admission or transfer.',
      occurredAt: now.subtract(const Duration(hours: 6)),
      scope: DemoNotificationScope.icu,
    ),
    DemoNotification(
      id: 'DEMO-NOTIF-07',
      category: DemoNotificationCategory.hospitalResponse,
      title: 'Demo response received',
      message: 'A fictional blood-bank response was added to the local demonstration activity.',
      occurredAt: now.subtract(const Duration(hours: 9)),
      scope: DemoNotificationScope.blood,
    ),
  ];
}

final demoNotificationsControllerProvider =
    Provider<DemoNotificationsController>((ref) {
      final controller = DemoNotificationsController();
      ref.onDispose(controller.dispose);
      return controller;
    });
