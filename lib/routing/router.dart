import 'package:go_router/go_router.dart';

import '../data/repositories/ecourse_auth_repository.dart';
import '../ui/account/account_screen.dart';
import '../ui/core/app_shell.dart';
import '../ui/courses/course_detail_screen.dart';
import '../ui/courses/courses_screen.dart';
import '../ui/login/login_screen.dart';
import '../ui/more/calendar_screen.dart';
import '../ui/more/grades_screen.dart';
import '../ui/more/more_screen.dart';
import '../ui/more/portal_screen.dart';
import '../ui/notifications/notifications_screen.dart';
import '../ui/timetable/timetable_screen.dart';
import '../ui/today/due_screen.dart';
import '../ui/today/today_screen.dart';

/// Only the eCourse2 token gates the app; the CAS session is optional.
GoRouter buildRouter(EcourseAuthRepository auth) => GoRouter(
  initialLocation: '/today',
  refreshListenable: auth,
  redirect: (context, state) {
    final atLogin = state.matchedLocation == '/login';
    if (!auth.isSignedIn) return atLogin ? null : '/login';
    return atLogin ? '/today' : null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/today',
              builder: (_, _) => const TodayScreen(),
              routes: [
                GoRoute(path: 'due', builder: (_, _) => const DueScreen()),
                GoRoute(
                  path: 'notifications',
                  builder: (_, _) => const NotificationsScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/timetable',
              builder: (_, _) => const TimetableScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/courses',
              builder: (_, _) => const CoursesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => CourseDetailScreen(
                    courseId: int.parse(state.pathParameters['id']!),
                  ),
                  routes: [
                    for (final part in CoursePart.values)
                      GoRoute(
                        path: part.name,
                        builder: (_, state) => CoursePartScreen(
                          courseId: int.parse(state.pathParameters['id']!),
                          part: part,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calendar',
              builder: (_, _) => const CalendarScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/more',
              builder: (_, _) => const MoreScreen(),
              routes: [
                GoRoute(
                  path: 'grades',
                  builder: (_, _) => const GradesScreen(),
                ),
                GoRoute(
                  path: 'portal',
                  builder: (_, _) => const PortalScreen(),
                ),
                GoRoute(
                  path: 'account',
                  builder: (_, _) => const AccountScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
