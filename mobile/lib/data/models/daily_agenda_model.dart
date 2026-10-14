class DailyAgendaItem {
  final String id;
  final String time;
  final String? endTime;
  final String title;
  final String subtitle;
  final String category; // GLUCOSE_CHECK, PHYSICAL_ACTIVITY, MEAL, MEDICATION, APPOINTMENT, LIFESTYLE_CHECK
  bool isCompleted;
  final DateTime? completedAt;
  final String? instructions;
  final String? safetyNote;
  final String badgeLabel;
  final String patientId;

  DailyAgendaItem({
    required this.id,
    required this.time,
    this.endTime,
    required this.title,
    required this.subtitle,
    required this.category,
    this.isCompleted = false,
    this.completedAt,
    this.instructions,
    this.safetyNote,
    required this.badgeLabel,
    required this.patientId,
  });

  factory DailyAgendaItem.fromJson(Map<String, dynamic> json) {
    return DailyAgendaItem(
      id: json['id']?.toString() ?? '',
      time: json['time']?.toString() ?? '08:00',
      endTime: json['endTime']?.toString(),
      title: json['title']?.toString() ?? 'Aktivitas Sehat',
      subtitle: json['subtitle']?.toString() ?? '',
      category: json['category']?.toString() ?? 'LIFESTYLE_CHECK',
      isCompleted: json['isCompleted'] == true,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'].toString()) : null,
      instructions: json['instructions']?.toString(),
      safetyNote: json['safetyNote']?.toString(),
      badgeLabel: json['badgeLabel']?.toString() ?? 'Agenda',
      patientId: json['patientId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'endTime': endTime,
      'title': title,
      'subtitle': subtitle,
      'category': category,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'instructions': instructions,
      'safetyNote': safetyNote,
      'badgeLabel': badgeLabel,
      'patientId': patientId,
    };
  }
}

class DailyAgendaSummary {
  final String date;
  final List<DailyAgendaItem> agenda;
  final int completedCount;
  final int totalCount;
  final int completionPercentage;
  final String nextActivityTime;
  final String nextActivityTitle;
  final String nextActivityCategory;
  final String contextualMascotMessage;

  DailyAgendaSummary({
    required this.date,
    required this.agenda,
    required this.completedCount,
    required this.totalCount,
    required this.completionPercentage,
    required this.nextActivityTime,
    required this.nextActivityTitle,
    required this.nextActivityCategory,
    required this.contextualMascotMessage,
  });

  factory DailyAgendaSummary.fromJson(Map<String, dynamic> json) {
    final list = json['agenda'];
    final agendaItems = list is List
        ? list.map((e) => DailyAgendaItem.fromJson(Map<String, dynamic>.from(e))).toList()
        : <DailyAgendaItem>[];

    final next = json['nextActivity'] as Map<String, dynamic>?;

    return DailyAgendaSummary(
      date: json['date']?.toString() ?? '',
      agenda: agendaItems,
      completedCount: int.tryParse(json['completedCount']?.toString() ?? '0') ?? 0,
      totalCount: int.tryParse(json['totalCount']?.toString() ?? '0') ?? 0,
      completionPercentage: int.tryParse(json['completionPercentage']?.toString() ?? '0') ?? 0,
      nextActivityTime: next?['time']?.toString() ?? '07:15',
      nextActivityTitle: next?['title']?.toString() ?? 'Sarapan Sehat',
      nextActivityCategory: next?['category']?.toString() ?? 'MEAL',
      contextualMascotMessage: json['contextualMascotMessage']?.toString() ?? 'Halo! Semangat hari ini 💙',
    );
  }
}
