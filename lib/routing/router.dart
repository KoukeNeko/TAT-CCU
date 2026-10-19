import 'package:go_router/go_router.dart';

import '../data/repositories/ecourse_auth_repository.dart';
import '../ui/account/account_screen.dart';
import '../ui/core/app_shell.dart';
import '../ui/courses/course_detail_screen.dart';
import '../ui/courses/courses_screen.dart';
import '../ui/courses/module_screen.dart';
import '../ui/login/login_screen.dart';
import '../ui/more/academic_screen.dart';
import '../ui/more/calendar_screen.dart';
import '../ui/more/grades_screen.dart';
import '../ui/more/iccu_screen.dart';
import '../ui/more/leave_screen.dart';
import '../data/services/primo_client.dart';
import '../ui/more/library_collections_screen.dart';
import '../ui/more/library_record_screen.dart';
import '../ui/more/library_screen.dart';
import '../ui/more/library_search_screen.dart';
import '../ui/more/settings_screen.dart';
import '../ui/more/space_screen.dart';
import '../ui/more/design_language_screen.dart';
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
    StatefulShellRoute(
      builder: (_, _, shell) => AppShell(shell: shell),
      navigatorContainerBuilder: (_, shell, children) =>
          AnimatedBranches(index: shell.currentIndex, children: children),
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
                    GoRoute(
                      path: 'modules/:cmid',
                      builder: (_, state) => ModuleScreen(
                        courseId: int.parse(state.pathParameters['id']!),
                        cmid: int.parse(state.pathParameters['cmid']!),
                        title: state.extra as String?,
                      ),
                    ),
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
                GoRoute(path: 'iccu', builder: (_, _) => const IccuScreen()),
                GoRoute(path: 'leave', builder: (_, _) => const LeaveScreen()),
                GoRoute(path: 'space', builder: (_, _) => const SpaceScreen()),
                GoRoute(
                  path: 'settings',
                  builder: (_, _) => const SettingsScreen(),
                ),
                GoRoute(
                  path: 'design',
                  builder: (_, _) => const DesignLanguageScreen(),
                  routes: [
                    GoRoute(
                      path: ':part',
                      builder: (_, state) => DesignPartScreen(
                        part: DesignPart.values.byName(
                          state.pathParameters['part']!,
                        ),
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'library',
                  builder: (_, _) => const LibraryScreen(),
                  routes: [
                    GoRoute(
                      path: 'search',
                      builder: (_, _) => const LibrarySearchScreen(),
                    ),
                    GoRoute(
                      path: 'record',
                      builder: (_, state) {
                        final (:record, :index) =
                            state.extra! as ({LibraryRecord record, int index});
                        return LibraryRecordScreen(
                          record: record,
                          index: index,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'collections',
                      builder: (_, _) => const LibraryCollectionsScreen(),
                    ),
                    GoRoute(
                      path: 'collection/:id',
                      builder: (_, state) => LibraryCollectionScreen(
                        id: state.pathParameters['id']!,
                        title: state.extra as String?,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'academic',
                  builder: (_, _) => const AcademicScreen(),
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
