import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/profile/presentation/screens/profile_form_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/groups/presentation/screens/groups_screen.dart';
import '../../features/groups/presentation/screens/create_group_screen.dart';
import '../../features/groups/presentation/screens/group_detail_screen.dart';
import '../../features/groups/presentation/screens/create_challenge_screen.dart';
import '../../features/groups/presentation/screens/challenge_detail_screen.dart';
import '../shell/main_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      // Auth routes (no bottom nav)
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

      // Main shell routes (with bottom nav)
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/profile-setup', builder: (context, state) => const ProfileFormScreen()),
          GoRoute(path: '/groups', builder: (context, state) => const GroupsScreen()),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(path: '/groups/create', builder: (context, state) => const CreateGroupScreen()),
      GoRoute(
        path: '/groups/:id',
        builder: (context, state) => GroupDetailScreen(
          groupId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/groups/:id/challenge',
        builder: (context, state) => CreateChallengeScreen(
          groupId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/challenges/:id',
        builder: (context, state) => ChallengeDetailScreen(
          challengeId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ],
  );
}
