import 'package:flutter/material.dart';
import 'package:cattle_tracer_app/constants/app_colors.dart';
import 'package:cattle_tracer_app/models/profile.dart';

// Info Card Widget
class InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> items;

  const InfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(204),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            ...items,
          ],
        ),
      ),
    );
  }
}

// Info Row Widget
class InfoRow extends StatelessWidget {
  final String label;
  final dynamic value; // Change from String? to dynamic

  const InfoRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    // Handle different value types
    final displayValue = value != null
        ? value.toString()
        : 'None';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              displayValue,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Education Item Widget
class EducationItem extends StatelessWidget {
  final EducationalBackground edu;

  const EducationItem({super.key, required this.edu});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: edu.level,
      icon: Icons.school_outlined,
      items: [
        InfoRow('School', edu.schoolName),
        InfoRow('Course', edu.course),
        InfoRow('Year Graduated', edu.yearGraduated),
        InfoRow('Honors', edu.honorsReceived),
      ],
    );
  }
}

// Training Item Widget
class TrainingItem extends StatelessWidget {
  final TrainingSeminar training;

  const TrainingItem({super.key, required this.training});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: training.title,
      icon: Icons.star_border_purple500_outlined,
      items: [
        InfoRow('Conducted By', training.conductedBy),
        InfoRow('Duration', '${training.dateFrom} to ${training.dateTo}'),
        InfoRow('Location', training.location),
        InfoRow(
          'Certificate',
          training.certificateIssued ? 'Issued' : 'Not Issued',
        ),
      ],
    );
  }
}

// Loading State Widget
class ProfileLoading extends StatelessWidget {
  const ProfileLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Loading Profile...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// Error State Widget
class ProfileError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ProfileError({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.redAccent, size: 50),
            const SizedBox(height: 16),
            const Text('Failed to Load Data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Please check your connection and try again.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Profile Header Widget
class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final String userEmail;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    final fullName =
    '${profile?['first_name'] ?? ''} ${profile?['last_name'] ?? ''}'.trim();
    final email = profile?['email'] ?? userEmail;
    final headerText = fullName.isNotEmpty ? fullName : 'Farmer Profile';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF303F9F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                headerText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black26)],
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (fullName.isNotEmpty)
              Text(email, style: TextStyle(color: Colors.white.withAlpha(204))),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}