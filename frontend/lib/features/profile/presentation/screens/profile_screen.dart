import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tracking/presentation/providers/step_provider.dart';
import '../../../tracking/presentation/providers/water_provider.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile data found'));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF6C63FF),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF6C63FF), Color(0xFF8B85FF)],
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          _buildProfileImage(context, ref, profile.profilePicture),
                          const SizedBox(height: 16),
                          Text(
                            profile.name ?? profile.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            profile.email,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () => context.push('/profile-setup'),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsRow(profile),
                      const SizedBox(height: 24),
                      const Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailCard(
                        items: [
                          _DetailItem(Icons.cake_outlined, 'Age', '${profile.age ?? "--"} years'),
                          _DetailItem(Icons.height, 'Height', '${profile.height ?? "--"} cm'),
                          _DetailItem(Icons.monitor_weight_outlined, 'Weight', '${profile.weight ?? "--"} kg'),
                          _DetailItem(Icons.wc_outlined, 'Gender', profile.gender ?? "--"),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Fitness Goal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildGoalCard(profile.fitnessGoal ?? "Not set"),
                      const SizedBox(height: 32),
                      _buildLogoutButton(context, ref),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context, WidgetRef ref, String? imageUrl) {
    return Stack(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.3),
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            child: imageUrl == null || imageUrl.isEmpty
                ? const Icon(Icons.person, size: 60, color: Colors.white)
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () async {
              final picker = ImagePicker();
              final image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null && context.mounted) {
                // Show loading indicator dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Color(0xFF6C63FF)),
                            SizedBox(height: 16),
                            Text('Uploading profile picture...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                final success = await ref.read(profileProvider.notifier).uploadImage(image);

                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pop(); // Close loading indicator
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile picture updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to update profile picture. Please check network/server logs.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFF8585),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(dynamic profile) {
    return Row(
      children: [
        Expanded(child: _buildStatItem('Steps', profile.totalSteps?.toString() ?? '0', Icons.directions_walk, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem('Burned', '${profile.caloriesBurned?.toInt() ?? 0}', Icons.local_fire_department, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem('Eaten', '${profile.caloriesConsumed?.toInt() ?? 0}', Icons.restaurant, Colors.green)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({required List<_DetailItem> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFFF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: const Color(0xFF6C63FF), size: 20),
            ),
            title: Text(
              item.label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            trailing: Text(
              item.value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalCard(String goal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B85FF)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Text(
            goal,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          await ref.read(authRepositoryProvider).logout();
          
          // Invalidate previous cached user data to force a fresh fetch on next login
          ref.invalidate(profileProvider);
          ref.invalidate(weeklyStepsProvider);
          ref.invalidate(liveStepProvider);
          ref.invalidate(waterIntakeProvider);

          if (context.mounted) {
            context.go('/login');
          }
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xFFFF8585)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Logout',
          style: TextStyle(
            color: Color(0xFFFF8585),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  _DetailItem(this.icon, this.label, this.value);
}
