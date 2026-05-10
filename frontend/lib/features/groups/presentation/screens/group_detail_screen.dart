import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/group_provider.dart';
import '../../domain/group_models.dart';
import 'chat_tab.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final int groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final groups = ref.watch(myGroupsProvider).value ?? [];
    final group = groups.where((g) => g.id == widget.groupId).firstOrNull;
    final sortBy = ref.watch(leaderboardSortProvider);
    final leaderboard = ref.watch(leaderboardProvider(widget.groupId));
    final challenges = ref.watch(challengesProvider(widget.groupId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(group?.name ?? 'Group', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6C63FF),
          tabs: const [
            Tab(text: 'Chat', icon: Icon(Icons.chat, size: 18)),
            Tab(text: 'Leaderboard', icon: Icon(Icons.leaderboard, size: 18)),
            Tab(text: 'Challenges', icon: Icon(Icons.flag, size: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart),
            tooltip: 'Create Challenge',
            onPressed: () => context.push('/groups/${widget.groupId}/challenge'),
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // CHAT TAB
          ChatTab(groupId: widget.groupId),

          // LEADERBOARD TAB
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'total', label: Text('All-Time'), icon: Icon(Icons.star)),
                    ButtonSegment(value: 'today', label: Text("Today"), icon: Icon(Icons.today)),
                  ],
                  selected: {sortBy},
                  onSelectionChanged: (val) {
                    ref.read(leaderboardSortProvider.notifier).set(val.first);
                    ref.invalidate(leaderboardProvider(widget.groupId));
                  },
                ),
              ),
              Expanded(
                child: leaderboard.when(
                  data: (entries) => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: entries.length,
                    itemBuilder: (_, i) => _LeaderboardTile(entry: entries[i], sortBy: sortBy),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),

          // CHALLENGES TAB
          challenges.when(
            data: (list) => list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flag_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No challenges yet', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => context.push('/groups/${widget.groupId}/challenge'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                          child: const Text('Create First Challenge', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _ChallengeTile(challenge: list[i], groupId: widget.groupId),
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final String sortBy;
  const _LeaderboardTile({required this.entry, required this.sortBy});

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.rank <= 3;
    final medals = ['🥇', '🥈', '🥉'];
    final steps = sortBy == 'today' ? entry.todaySteps : entry.totalSteps;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTop3 ? const Color(0xFF6C63FF).withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isTop3
            ? Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2))
            : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              isTop3 ? medals[entry.rank - 1] : '#${entry.rank}',
              style: TextStyle(fontSize: isTop3 ? 22 : 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF6C63FF).withOpacity(0.15),
            child: Text(
              entry.name[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('@${entry.username}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$steps',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF))),
              Text('steps', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChallengeTile extends ConsumerWidget {
  final Challenge challenge;
  final int groupId;
  const _ChallengeTile({required this.challenge, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = challenge.status == 'ACTIVE';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/challenges/${challenge.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    challenge.type == 'STEPS' ? Icons.directions_walk : Icons.local_fire_department,
                    color: challenge.type == 'STEPS' ? const Color(0xFF6C63FF) : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(challenge.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      challenge.status,
                      style: TextStyle(
                          fontSize: 11,
                          color: isActive ? Colors.green.shade700 : Colors.grey,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              if (challenge.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(challenge.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.flag, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    'Goal: ${challenge.targetValue} ${challenge.type == 'STEPS' ? 'steps' : 'kcal'}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Icon(Icons.people, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text('${challenge.participantCount} joined',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text('${challenge.startDate} → ${challenge.endDate}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(challengesMutationProvider.notifier)
                            .joinChallenge(challenge.id, groupId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Joined challenge!'), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                        }
                      }
                    },
                    child: const Text('Join', style: TextStyle(color: Color(0xFF6C63FF))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
