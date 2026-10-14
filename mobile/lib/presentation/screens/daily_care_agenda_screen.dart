import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/services/widget_service.dart';
import '../../core/utils/calendar_export_helper.dart';
import '../../data/models/daily_agenda_model.dart';
import '../../data/models/patient_model.dart';
import 'daily_health_checkin_screen.dart';
import 'health_progress_screen.dart';
import 'smart_meal_detail_screen.dart';

class DailyCareAgendaScreen extends StatefulWidget {
  final PatientModel? patient;
  final String? initialDate;

  const DailyCareAgendaScreen({
    super.key,
    this.patient,
    this.initialDate,
  });

  @override
  State<DailyCareAgendaScreen> createState() => _DailyCareAgendaScreenState();
}

class _DailyCareAgendaScreenState extends State<DailyCareAgendaScreen> {
  late DateTime _selectedDate;
  bool _isLoading = true;
  DailyAgendaSummary? _agendaSummary;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate != null
        ? (DateTime.tryParse(widget.initialDate!) ?? DateTime.now())
        : DateTime.now();
    _loadAgendaData();
  }

  String get _dateStr => _selectedDate.toIso8601String().split('T').first;
  String get _patientId => widget.patient?.id ?? 'P-001';

  Future<void> _loadAgendaData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await ApiClient().getDailyAgenda(_patientId, date: _dateStr);
      if (mounted) {
        setState(() {
          _agendaSummary = summary;
          _isLoading = false;
        });
        // Keep Android native widget in sync!
        WidgetService.updateWidgetData(summary);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat agenda: $e';
        });
      }
    }
  }

  Future<void> _toggleItem(DailyAgendaItem item, bool newValue) async {
    setState(() {
      item.isCompleted = newValue;
      if (_agendaSummary != null) {
        final completed = _agendaSummary!.agenda.where((a) => a.isCompleted).length;
        final total = _agendaSummary!.agenda.length;
        _agendaSummary = DailyAgendaSummary(
          date: _agendaSummary!.date,
          agenda: _agendaSummary!.agenda,
          completedCount: completed,
          totalCount: total,
          completionPercentage: total > 0 ? (completed * 100 ~/ total) : 0,
          nextActivityTime: _agendaSummary!.nextActivityTime,
          nextActivityTitle: _agendaSummary!.nextActivityTitle,
          nextActivityCategory: _agendaSummary!.nextActivityCategory,
          contextualMascotMessage: completed == total
              ? 'Luar biasa! Semua agenda hari ini telah selesai 🌟'
              : 'Semangat! ${total - completed} aktivitas tersisa.',
        );
      }
    });

    // Update in backend
    await ApiClient().toggleAgendaItem(item.id, newValue, patientId: _patientId);

    // Sync directly to Android Home Screen Widget
    if (_agendaSummary != null) {
      WidgetService.updateWidgetData(_agendaSummary!);
    }
  }

  void _changeDate(int offsetDays) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offsetDays));
    });
    _loadAgendaData();
  }

  void _openGoogleCalendar(DailyAgendaItem item) {
    final url = CalendarExportHelper.buildGoogleCalendarUrl(
      title: item.title,
      description: item.subtitle,
      dateStr: _dateStr,
      timeStr: item.time,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tautan Google Calendar dibuat untuk ${item.title}'),
        backgroundColor: AppColors.primary,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _exportFullIcs() {
    if (_agendaSummary == null || _agendaSummary!.agenda.isEmpty) return;

    final ics = CalendarExportHelper.buildIcsString(
      items: _agendaSummary!.agenda,
      dateStr: _dateStr,
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Ekspor Kalender (.ics)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jadwal agenda harian Retiva siap diimpor ke Google Calendar, Apple Calendar, atau Microsoft Outlook.',
              style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_agendaSummary!.agenda.length} aktivitas terjadwal pada $_dateStr',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Jadwal .ics berhasil disiapkan untuk kalender HP!'),
                  backgroundColor: AppColors.statusGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Simpan & Sinkron'),
          ),
        ],
      ),
    );
  }

  void _showItemDetailModal(DailyAgendaItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(item.category).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.badgeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _getCategoryColor(item.category),
                    ),
                  ),
                ),
                Text(
                  '${item.time} ${item.endTime != null ? '- ${item.endTime}' : ''}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(item.subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const Divider(height: 24),
            if (item.instructions != null) ...[
              const Text('Panduan & Petunjuk:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text(item.instructions!, style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
            ],
            if (item.safetyNote != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFD54F)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, color: Color(0xFFF57C00), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.safetyNote!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFE65100), height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (item.category == 'MEAL') ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SmartMealDetailScreen(
                        initialCategory: item.id.contains('sarapan')
                            ? 'BREAKFAST'
                            : item.id.contains('siang')
                                ? 'LUNCH'
                                : 'DINNER',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                label: const Text('💡 Lihat Menu Cerdas & Dampak Glukosa'),
              ),
              const SizedBox(height: 12),
            ],
            Row(

              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openGoogleCalendar(item);
                    },
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: const Text('Google Calendar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _toggleItem(item, !item.isCompleted);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.isCompleted ? AppColors.textMuted : AppColors.statusGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(item.isCompleted ? 'Batal Selesai' : 'Tandai Selesai'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'GLUCOSE_CHECK':
        return const Color(0xFFF59E0B);
      case 'PHYSICAL_ACTIVITY':
        return const Color(0xFF8B5CF6);
      case 'MEAL':
        return const Color(0xFF00C566);
      case 'MEDICATION':
        return const Color(0xFF246BFD);
      case 'APPOINTMENT':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'GLUCOSE_CHECK':
        return Icons.water_drop_rounded;
      case 'PHYSICAL_ACTIVITY':
        return Icons.directions_walk_rounded;
      case 'MEAL':
        return Icons.restaurant_rounded;
      case 'MEDICATION':
        return Icons.medication_rounded;
      case 'APPOINTMENT':
        return Icons.local_hospital_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _dateStr == DateTime.now().toIso8601String().split('T').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Agenda Sehat Harian',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20, color: AppColors.primary),
            tooltip: 'Ekspor Kalender (.ics)',
            onPressed: _exportFullIcs,
          ),
          IconButton(
            icon: const Icon(Icons.insights_rounded, size: 20, color: AppColors.primary),
            tooltip: 'Tren & Progres',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HealthProgressScreen(patient: widget.patient),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadAgendaData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Navigation Row
                    _buildDateNavigator(isToday),
                    const SizedBox(height: 14),

                    // Mascot Progress Card
                    if (_agendaSummary != null) _buildMascotProgressCard(_agendaSummary!),
                    const SizedBox(height: 16),

                    // Google Calendar Sync Banner
                    _buildCalendarSyncBanner(),
                    const SizedBox(height: 16),

                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Jadwal Kegiatan Hari Ini',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '${_agendaSummary?.completedCount ?? 0} dari ${_agendaSummary?.totalCount ?? 0} Selesai',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Chronological Timeline Items
                    if (_agendaSummary != null && _agendaSummary!.agenda.isNotEmpty)
                      ..._agendaSummary!.agenda.map((item) => _buildTimelineCard(item))
                    else
                      _buildEmptyState(),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyHealthCheckinScreen(patient: widget.patient),
                      ),
                    );
                    if (res == true) _loadAgendaData();
                  },
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: const Text('Isi Check-in Harian (30 Detik)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateNavigator(bool isToday) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 24, color: Color(0xFF64748B)),
            onPressed: () => _changeDate(-1),
          ),
          Row(
            children: [
              const Icon(Icons.event_note_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                isToday ? 'Hari Ini, $_dateStr' : _dateStr,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 24, color: Color(0xFF64748B)),
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotProgressCard(DailyAgendaSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF246BFD), Color(0xFF1A56DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: const Color(0xFF246BFD).withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/mascot_app_icon.png',
                width: 44,
                height: 44,
                errorBuilder: (_, __, ___) => const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.favorite_rounded, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Retiva Care Companion',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFDFF1FB)),
                    ),
                    Text(
                      summary.contextualMascotMessage,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progres: ${summary.completedCount} dari ${summary.totalCount} agenda',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
              ),
              Text(
                '${summary.completionPercentage}%',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: summary.totalCount > 0 ? (summary.completedCount / summary.totalCount) : 0,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C566)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSyncBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8E5FF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Sinkron otomatis ke Google Calendar & Home Screen Widget Android.',
              style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), height: 1.3),
            ),
          ),
          TextButton(
            onPressed: _exportFullIcs,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('Sinkron', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(DailyAgendaItem item) {
    final catColor = _getCategoryColor(item.category);

    return InkWell(
      onTap: () => _showItemDetailModal(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isCompleted ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: item.isCompleted ? const Color(0xFFE2E8F0) : const Color(0xFFE2E8F0)),
          boxShadow: item.isCompleted
              ? []
              : [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Checkbox(
              value: item.isCompleted,
              activeColor: AppColors.statusGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (val) {
                if (val != null) _toggleItem(item, val);
              },
            ),
            const SizedBox(width: 8),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(_getCategoryIcon(item.category), size: 12, color: catColor),
                            const SizedBox(width: 4),
                            Text(
                              item.badgeLabel,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: catColor),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item.time,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: item.isCompleted ? AppColors.textMuted : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                      color: item.isCompleted ? AppColors.textMuted : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                  ),
                  if (item.category == 'MEAL') ...[
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SmartMealDetailScreen(
                              initialCategory: item.id.contains('sarapan')
                                  ? 'BREAKFAST'
                                  : item.id.contains('siang')
                                      ? 'LUNCH'
                                      : 'DINNER',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restaurant_menu_rounded, size: 12, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'Lihat Rekomendasi Menu & Gizi',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (item.safetyNote != null && !item.isCompleted) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.safetyNote!,
                            style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.event_available_rounded, size: 48, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          Text(
            'Tidak ada jadwal agenda pada tanggal ini.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
