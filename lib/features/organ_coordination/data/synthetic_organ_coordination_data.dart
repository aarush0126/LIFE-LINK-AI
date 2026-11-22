enum DemoOrganCategory {
  heart('Heart'),
  lung('Lung'),
  liver('Liver'),
  kidney('Kidney'),
  pancreas('Pancreas'),
  cornea('Cornea'),
  tissue('Other tissue');

  const DemoOrganCategory(this.label);

  final String label;
}

enum DemoPathway {
  institutionReportedLiving('Institution-reported living donation pathway'),
  institutionReportedDeceased('Institution-reported deceased donation pathway'),
  tissueCoordination('Institution-reported tissue coordination pathway');

  const DemoPathway(this.label);

  final String label;
}

enum DemoVerificationStatus {
  awaitingConfirmation('Awaiting institutional confirmation'),
  sourceRecordReceived('Source record received (demo only)'),
  authorityResponseRecorded('Authority response recorded (demo only)');

  const DemoVerificationStatus(this.label);

  final String label;
}

enum DemoCaseStatus {
  pendingVerification('Pending verification'),
  awaitingInstitutionalResponse('Awaiting institutional response'),
  activeSimulation('Active simulation'),
  completedSimulation('Completed workflow (demo)');

  const DemoCaseStatus(this.label);

  final String label;
}

class DemoTransplantCentre {
  final String name;
  final String region;
  final Set<DemoOrganCategory> categories;
  final List<String> capabilities;
  final String directoryStatus;

  const DemoTransplantCentre({
    required this.name,
    required this.region,
    required this.categories,
    required this.capabilities,
    required this.directoryStatus,
  });
}

class DemoCaseEvent {
  final String title;
  final String detail;
  final DateTime occurredAt;
  final String actorLabel;

  const DemoCaseEvent({
    required this.title,
    required this.detail,
    required this.occurredAt,
    required this.actorLabel,
  });
}

class DemoVerificationCheck {
  final String label;
  final bool complete;

  const DemoVerificationCheck({required this.label, required this.complete});
}

class DemoParticipatingInstitution {
  final String name;
  final String role;
  final String responseStatus;

  const DemoParticipatingInstitution({
    required this.name,
    required this.role,
    required this.responseStatus,
  });
}

class DemoLogisticsStage {
  final String label;
  final String status;
  final DateTime lastUpdatedAt;

  const DemoLogisticsStage({
    required this.label,
    required this.status,
    required this.lastUpdatedAt,
  });
}

class DemoOrganCase {
  final String caseReference;
  final String hospital;
  final DemoPathway pathway;
  final DemoOrganCategory category;
  final DemoVerificationStatus verificationStatus;
  final DateTime lastUpdatedAt;
  final String authorizedCoordinator;
  final String relevantCentre;
  final String relevantCentreCapability;
  final DemoCaseStatus status;
  final bool humanReviewRecorded;
  final bool routeRecorded;
  final List<DemoCaseEvent> timeline;
  final List<DemoVerificationCheck> verificationChecklist;
  final List<DemoParticipatingInstitution> institutions;
  final List<DemoCaseEvent> notifications;
  final List<DemoCaseEvent> workflowHistory;
  final List<DemoCaseEvent> auditEvents;
  final List<DemoLogisticsStage> logistics;

  const DemoOrganCase({
    required this.caseReference,
    required this.hospital,
    required this.pathway,
    required this.category,
    required this.verificationStatus,
    required this.lastUpdatedAt,
    required this.authorizedCoordinator,
    required this.relevantCentre,
    required this.relevantCentreCapability,
    required this.status,
    required this.humanReviewRecorded,
    required this.routeRecorded,
    required this.timeline,
    required this.verificationChecklist,
    required this.institutions,
    required this.notifications,
    required this.workflowHistory,
    required this.auditEvents,
    required this.logistics,
  });

  DemoOrganCase copyWith({
    DemoVerificationStatus? verificationStatus,
    DateTime? lastUpdatedAt,
    DemoCaseStatus? status,
    bool? humanReviewRecorded,
    bool? routeRecorded,
    List<DemoCaseEvent>? timeline,
    List<DemoVerificationCheck>? verificationChecklist,
    List<DemoParticipatingInstitution>? institutions,
    List<DemoCaseEvent>? notifications,
    List<DemoCaseEvent>? workflowHistory,
    List<DemoCaseEvent>? auditEvents,
    List<DemoLogisticsStage>? logistics,
  }) {
    return DemoOrganCase(
      caseReference: caseReference,
      hospital: hospital,
      pathway: pathway,
      category: category,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      authorizedCoordinator: authorizedCoordinator,
      relevantCentre: relevantCentre,
      relevantCentreCapability: relevantCentreCapability,
      status: status ?? this.status,
      humanReviewRecorded: humanReviewRecorded ?? this.humanReviewRecorded,
      routeRecorded: routeRecorded ?? this.routeRecorded,
      timeline: timeline ?? this.timeline,
      verificationChecklist:
          verificationChecklist ?? this.verificationChecklist,
      institutions: institutions ?? this.institutions,
      notifications: notifications ?? this.notifications,
      workflowHistory: workflowHistory ?? this.workflowHistory,
      auditEvents: auditEvents ?? this.auditEvents,
      logistics: logistics ?? this.logistics,
    );
  }
}

class SyntheticOrganCoordinationData {
  SyntheticOrganCoordinationData._();

  static final _now = DateTime.now();

  static const hospitals = [
    'Northstar Teaching Hospital (Demo)',
    'Cedar Valley Medical Center (Demo)',
    'Riverside Regional Hospital (Demo)',
    'Meadowbrook Community Hospital (Demo)',
    'Summit Emergency Center (Demo)',
  ];

  static const coordinators = [
    'Duty Coordinator 01 (Synthetic)',
    'Duty Coordinator 02 (Synthetic)',
    'Duty Coordinator 03 (Synthetic)',
  ];

  static const centres = <DemoTransplantCentre>[
    DemoTransplantCentre(
      name: 'Northstar Retrieval Institute (Demo)',
      region: 'North District · Demo State',
      categories: {
        DemoOrganCategory.kidney,
        DemoOrganCategory.liver,
        DemoOrganCategory.cornea,
      },
      capabilities: [
        'Retrieval coordination workflow',
        'Corneal tissue handling pathway',
        'Institutional enquiry desk',
      ],
      directoryStatus: 'Synthetic directory record · verify independently',
    ),
    DemoTransplantCentre(
      name: 'Cedar Valley Transplant Centre (Demo)',
      region: 'Central District · Demo State',
      categories: {
        DemoOrganCategory.heart,
        DemoOrganCategory.lung,
        DemoOrganCategory.liver,
      },
      capabilities: [
        'Cardiothoracic coordination desk',
        'Liver transplant service listing',
        'Institutional enquiry desk',
      ],
      directoryStatus: 'Synthetic directory record · verify independently',
    ),
    DemoTransplantCentre(
      name: 'Riverside Tissue Coordination Unit (Demo)',
      region: 'East District · Demo State',
      categories: {
        DemoOrganCategory.cornea,
        DemoOrganCategory.tissue,
        DemoOrganCategory.kidney,
      },
      capabilities: [
        'Ocular tissue coordination listing',
        'Tissue preservation protocol reference',
        'Institutional enquiry desk',
      ],
      directoryStatus: 'Synthetic directory record · verify independently',
    ),
    DemoTransplantCentre(
      name: 'Meadowbrook Organ Retrieval Centre (Demo)',
      region: 'South District · Demo State',
      categories: {
        DemoOrganCategory.kidney,
        DemoOrganCategory.pancreas,
        DemoOrganCategory.liver,
      },
      capabilities: [
        'Abdominal organ retrieval coordination',
        'Preservation pathway reference',
        'Institutional enquiry desk',
      ],
      directoryStatus: 'Synthetic directory record · verify independently',
    ),
    DemoTransplantCentre(
      name: 'Summit Multispecialty Transplant Centre (Demo)',
      region: 'West District · Demo State',
      categories: {
        DemoOrganCategory.kidney,
        DemoOrganCategory.liver,
        DemoOrganCategory.heart,
        DemoOrganCategory.lung,
        DemoOrganCategory.pancreas,
        DemoOrganCategory.cornea,
        DemoOrganCategory.tissue,
      },
      capabilities: [
        'Multispecialty transplant service listing',
        'Retrieval coordination workflow',
        'Institutional enquiry desk',
      ],
      directoryStatus: 'Synthetic directory record · verify independently',
    ),
  ];

  static final cases = <DemoOrganCase>[
    _case(
      reference: 'DEMO-OT-2401',
      hospital: hospitals[0],
      pathway: DemoPathway.institutionReportedDeceased,
      category: DemoOrganCategory.kidney,
      centre: centres[0],
      status: DemoCaseStatus.pendingVerification,
      verification: DemoVerificationStatus.awaitingConfirmation,
      age: const Duration(minutes: 24),
      humanReview: false,
      routeRecorded: false,
    ),
    _case(
      reference: 'DEMO-OT-2402',
      hospital: hospitals[1],
      pathway: DemoPathway.institutionReportedLiving,
      category: DemoOrganCategory.liver,
      centre: centres[1],
      status: DemoCaseStatus.awaitingInstitutionalResponse,
      verification: DemoVerificationStatus.sourceRecordReceived,
      age: const Duration(hours: 2),
      humanReview: true,
      routeRecorded: true,
    ),
    _case(
      reference: 'DEMO-OT-2403',
      hospital: hospitals[2],
      pathway: DemoPathway.tissueCoordination,
      category: DemoOrganCategory.cornea,
      centre: centres[2],
      status: DemoCaseStatus.activeSimulation,
      verification: DemoVerificationStatus.sourceRecordReceived,
      age: const Duration(hours: 5),
      humanReview: true,
      routeRecorded: true,
    ),
    _case(
      reference: 'DEMO-OT-2404',
      hospital: hospitals[3],
      pathway: DemoPathway.institutionReportedDeceased,
      category: DemoOrganCategory.pancreas,
      centre: centres[3],
      status: DemoCaseStatus.completedSimulation,
      verification: DemoVerificationStatus.authorityResponseRecorded,
      age: const Duration(days: 1),
      humanReview: true,
      routeRecorded: true,
    ),
    _case(
      reference: 'DEMO-OT-2405',
      hospital: hospitals[4],
      pathway: DemoPathway.institutionReportedLiving,
      category: DemoOrganCategory.heart,
      centre: centres[4],
      status: DemoCaseStatus.pendingVerification,
      verification: DemoVerificationStatus.awaitingConfirmation,
      age: const Duration(days: 2),
      humanReview: false,
      routeRecorded: false,
    ),
  ];

  static DemoOrganCase createCase({
    required String reference,
    required String hospital,
    required DemoPathway pathway,
    required DemoOrganCategory category,
    required DemoVerificationStatus verification,
    required String coordinator,
    required DemoTransplantCentre centre,
  }) {
    return _case(
      reference: reference,
      hospital: hospital,
      pathway: pathway,
      category: category,
      centre: centre,
      status: DemoCaseStatus.pendingVerification,
      verification: verification,
      age: Duration.zero,
      humanReview: false,
      routeRecorded: false,
      coordinator: coordinator,
    );
  }

  static DemoOrganCase _case({
    required String reference,
    required String hospital,
    required DemoPathway pathway,
    required DemoOrganCategory category,
    required DemoTransplantCentre centre,
    required DemoCaseStatus status,
    required DemoVerificationStatus verification,
    required Duration age,
    required bool humanReview,
    required bool routeRecorded,
    String coordinator = 'Duty Coordinator 01 (Synthetic)',
  }) {
    final updatedAt = _now.subtract(age);
    final institutions = [
      DemoParticipatingInstitution(
        name: hospital,
        role: 'Submitting hospital · synthetic',
        responseStatus: 'Enquiry record only',
      ),
      DemoParticipatingInstitution(
        name: centre.name,
        role: 'Relevant capability directory entry · synthetic',
        responseStatus: 'No acceptance implied',
      ),
      const DemoParticipatingInstitution(
        name: 'Official pathway authority (as applicable)',
        role: 'Competent authority review',
        responseStatus: 'Not contacted by this prototype',
      ),
    ];
    final timeline = [
      DemoCaseEvent(
        title: 'Synthetic enquiry created',
        detail: 'A pseudonymized coordination case shell was created. No clinical determination was made.',
        occurredAt: updatedAt,
        actorLabel: coordinator,
      ),
      if (humanReview)
        DemoCaseEvent(
          title: 'Human review recorded (demo)',
          detail: 'A simulated coordinator review was recorded; this is not clinical approval or allocation.',
          occurredAt: updatedAt.add(const Duration(minutes: 4)),
          actorLabel: 'Authorized demo reviewer',
        ),
      if (routeRecorded)
        DemoCaseEvent(
          title: 'Simulated pathway recorded',
          detail: 'Illustrative NOTTO/ROTTO/SOTTO pathway reference recorded locally; no authority was contacted.',
          occurredAt: updatedAt.add(const Duration(minutes: 8)),
          actorLabel: 'Prototype workflow',
        ),
    ];
    final verificationChecklist = [
      DemoVerificationCheck(
        label: 'Submitting institution identified in demo directory',
        complete: true,
      ),
      DemoVerificationCheck(
        label: 'Institutional source record received',
        complete: verification != DemoVerificationStatus.awaitingConfirmation,
      ),
      DemoVerificationCheck(
        label: 'Official pathway reference supplied by institution',
        complete:
            verification == DemoVerificationStatus.authorityResponseRecorded,
      ),
      DemoVerificationCheck(
        label: 'Human coordinator reviewed administrative details',
        complete: humanReview,
      ),
    ];
    final workflowHistory = [
      DemoCaseEvent(
        title: 'Case shell opened',
        detail: 'Local prototype event; no external system action.',
        occurredAt: updatedAt,
        actorLabel: coordinator,
      ),
      if (humanReview)
        DemoCaseEvent(
          title: 'Human review step recorded',
          detail: 'Demo-only state transition.',
          occurredAt: updatedAt.add(const Duration(minutes: 4)),
          actorLabel: 'Authorized demo reviewer',
        ),
      if (routeRecorded)
        DemoCaseEvent(
          title: 'Simulated official-pathway routing step',
          detail: 'No external authority or institution was contacted.',
          occurredAt: updatedAt.add(const Duration(minutes: 8)),
          actorLabel: 'Prototype workflow',
        ),
    ];
    final auditEvents = [
      DemoCaseEvent(
        title: 'Demo audit event: case created',
        detail:
            'Pseudonymized reference $reference created in local demo state.',
        occurredAt: updatedAt,
        actorLabel: coordinator,
      ),
      if (humanReview)
        DemoCaseEvent(
          title: 'Demo audit event: review acknowledged',
          detail:
              'Simulation acknowledgement recorded; not a legal authorization.',
          occurredAt: updatedAt.add(const Duration(minutes: 4)),
          actorLabel: 'Authorized demo reviewer',
        ),
    ];
    final notifications = [
      DemoCaseEvent(
        title: 'Synthetic case activity',
        detail:
            'Administrative coordination status: ${status.label}. Confirm any real-world information through official channels.',
        occurredAt: updatedAt,
        actorLabel: 'Prototype notifications',
      ),
    ];

    return DemoOrganCase(
      caseReference: reference,
      hospital: hospital,
      pathway: pathway,
      category: category,
      verificationStatus: verification,
      lastUpdatedAt: updatedAt,
      authorizedCoordinator: coordinator,
      relevantCentre: centre.name,
      relevantCentreCapability: centre.capabilities.join(' · '),
      status: status,
      humanReviewRecorded: humanReview,
      routeRecorded: routeRecorded,
      timeline: timeline,
      verificationChecklist: verificationChecklist,
      institutions: institutions,
      notifications: notifications,
      workflowHistory: workflowHistory,
      auditEvents: auditEvents,
      logistics: [
        DemoLogisticsStage(
          label: 'Retrieval readiness',
          status: 'Not scheduled · demo only',
          lastUpdatedAt: updatedAt,
        ),
        DemoLogisticsStage(
          label: 'Preservation readiness',
          status: 'Institutional protocol confirmation pending',
          lastUpdatedAt: updatedAt,
        ),
        DemoLogisticsStage(
          label: 'Transportation',
          status: 'Not arranged · no dispatch initiated',
          lastUpdatedAt: updatedAt,
        ),
        DemoLogisticsStage(
          label: 'Receiving-centre readiness',
          status: 'Awaiting direct institutional confirmation',
          lastUpdatedAt: updatedAt,
        ),
      ],
    );
  }
}
