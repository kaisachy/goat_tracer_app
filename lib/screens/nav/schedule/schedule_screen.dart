import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/app_colors.dart';

class ScheduleScreen extends StatefulWidget {
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String _selectedView = 'Week';

  // Sample schedule data - replace with actual data from your service
  final List<Map<String, dynamic>> _sampleSchedule = [
    {
      'id': 1,
      'title': 'Vaccination - Bella',
      'cattleId': 'COW001',
      'cattleName': 'Bella',
      'type': 'Vaccination',
      'date': DateTime.now().add(Duration(hours: 2)),
      'duration': 30,
      'priority': 'High',
      'status': 'Scheduled',
      'veterinarian': 'Dr. Smith',
      'notes': 'Annual FMD vaccination',
    },
    {
      'id': 2,
      'title': 'Breeding Check - Luna',
      'cattleId': 'COW002',
      'cattleName': 'Luna',
      'type': 'Breeding',
      'date': DateTime.now().add(Duration(days: 1, hours: 10)),
      'duration': 45,
      'priority': 'Medium',
      'status': 'Scheduled',
      'veterinarian': 'Dr. Johnson',
      'notes': 'Pregnancy confirmation',
    },
    {
      'id': 3,
      'title': 'Feed Delivery',
      'type': 'Feed',
      'date': DateTime.now().add(Duration(days: 2)),
      'duration': 60,
      'priority': 'Low',
      'status': 'Scheduled',
      'notes': 'Monthly feed supply delivery',
    },
    {
      'id': 4,
      'title': 'Weight Check - All Cattle',
      'type': 'Weigh',
      'date': DateTime.now().add(Duration(days: 7)),
      'duration': 120,
      'priority': 'Medium',
      'status': 'Scheduled',
      'notes': 'Monthly weight monitoring for all cattle',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          _buildDateHeader(),
          _buildViewSelector(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildUpcomingTab(),
                _buildCalendarTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddScheduleDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateHeader(_selectedDate),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_getTodayTasksCount()} tasks scheduled',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showDatePicker(),
            icon: const Icon(Icons.calendar_today),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    final views = ['Day', 'Week', 'Month'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: views.map((view) {
          final isSelected = _selectedView == view;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: () => setState(() => _selectedView = view),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? AppColors.primary : Colors.grey.shade200,
                  foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
                  elevation: isSelected ? 2 : 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(view),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(text: 'Today'),
          Tab(text: 'Upcoming'),
          Tab(text: 'Calendar'),
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    final todayTasks = _sampleSchedule
        .where((task) => _isToday(task['date']))
        .toList();

    if (todayTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.calendarCheck,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks scheduled for today',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enjoy your free day!',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: todayTasks.length,
      itemBuilder: (context, index) {
        final task = todayTasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildUpcomingTab() {
    final upcomingTasks = _sampleSchedule
        .where((task) => task['date'].isAfter(DateTime.now().add(Duration(days: 1))))
        .toList();

    upcomingTasks.sort((a, b) => a['date'].compareTo(b['date']));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: upcomingTasks.length,
      itemBuilder: (context, index) {
        final task = upcomingTasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildCalendarTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Calendar View',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('Calendar widget will be displayed here'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Stats',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickStat('Today', _getTodayTasksCount().toString()),
                      _buildQuickStat('This Week', _getWeekTasksCount().toString()),
                      _buildQuickStat('Overdue', '0'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTaskDetails(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTaskTypeIcon(task['type']),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (task['cattleName'] != null)
                          Text(
                            '${task['cattleName']} (${task['cattleId']})',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildPriorityChip(task['priority']),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatTaskTime(task['date']),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${task['duration']} min',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  if (task['veterinarian'] != null)
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          task['veterinarian'],
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                ],
              ),
              if (task['notes'] != null && task['notes'].isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task['notes'],
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _markAsComplete(task),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Complete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rescheduleTask(task),
                      icon: const Icon(Icons.schedule, size: 16),
                      label: const Text('Reschedule'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'Vaccination':
        icon = FontAwesomeIcons.syringe;
        color = Colors.green;
        break;
      case 'Breeding':
        icon = FontAwesomeIcons.heart;
        color = Colors.red;
        break;
      case 'Feed':
        icon = FontAwesomeIcons.seedling;
        color = Colors.brown;
        break;
      case 'Weigh':
        icon = FontAwesomeIcons.weight;
        color = Colors.blue;
        break;
      case 'Treatment':
        icon = FontAwesomeIcons.kitMedical;
        color = Colors.orange;
        break;
      default:
        icon = FontAwesomeIcons.calendar;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FaIcon(icon, color: color, size: 20),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    switch (priority) {
      case 'High':
        color = Colors.red;
        break;
      case 'Medium':
        color = Colors.orange;
        break;
      case 'Low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _formatDateHeader(DateTime date) {
    final weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return '${weekdays[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatTaskTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  int _getTodayTasksCount() {
    return _sampleSchedule.where((task) => _isToday(task['date'])).length;
  }

  int _getWeekTasksCount() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final weekEnd = weekStart.add(Duration(days: 6));

    return _sampleSchedule.where((task) {
      final taskDate = task['date'] as DateTime;
      return taskDate.isAfter(weekStart) && taskDate.isBefore(weekEnd.add(Duration(days: 1)));
    }).length;
  }

  void _showDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  void _showTaskDetails(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task['cattleName'] != null)
              Text('Cattle: ${task['cattleName']} (${task['cattleId']})'),
            const SizedBox(height: 8),
            Text('Type: ${task['type']}'),
            const SizedBox(height: 8),
            Text('Date: ${_formatTaskTime(task['date'])}'),
            const SizedBox(height: 8),
            Text('Duration: ${task['duration']} minutes'),
            const SizedBox(height: 8),
            Text('Priority: ${task['priority']}'),
            const SizedBox(height: 8),
            Text('Status: ${task['status']}'),
            if (task['veterinarian'] != null) ...[
              const SizedBox(height: 8),
              Text('Veterinarian: ${task['veterinarian']}'),
            ],
            if (task['notes'] != null && task['notes'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: ${task['notes']}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to edit task
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to Add Schedule Task Screen'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _markAsComplete(Map<String, dynamic> task) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "${task['title']}" marked as complete'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rescheduleTask(Map<String, dynamic> task) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rescheduling "${task['title']}"'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}