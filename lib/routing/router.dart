import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/ecourse_auth_repository.dart';
import '../ui/account/account_screen.dart';
import '../ui/core/app_shell.dart';
import '../ui/core/theme.dart';
import '../ui/core/widgets.dart';
import '../ui/courses/absence_screen.dart';
import '../ui/courses/attendance_screen.dart';
import '../ui/courses/course_detail_screen.dart';
import '../ui/courses/courses_screen.dart';
import '../ui/courses/forum_screen.dart';
import '../ui/courses/module_screen.dart';
import '../ui/login/login_screen.dart';
import '../ui/more/about_screen.dart';
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
import '../ui/more/dorm_repair_screen.dart';
import '../ui/more/event_detail_screen.dart';
import '../data/services/events_data.dart';
import '../ui/more/events_screen.dart';
import '../ui/more/parttime_screen.dart';
import '../ui/more/payment_screen.dart';
import '../ui/more/saved_data_screen.dart';
import '../ui/more/settings_screen.dart';
import '../ui/more/space_screen.dart';
import '../ui/more/design_language_screen.dart';
import '../ui/more/more_screen.dart';
import '../ui/more/tools/bus_screen.dart';
import '../ui/more/tools/countdown_screen.dart';
import '../ui/more/tools/tools_screen.dart';
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
    if (!auth.canEnter) return atLogin ? null : '/login';
    return atLogin ? '/today' : null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    StatefulShellRoute(
      builder: (_, state, shell) =>
          AppShell(shell: shell, location: state.uri.path),
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
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/messages',
              builder: (_, _) => const MessagesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/timetable',
              builder: (_, _) => const TimetableScreen(),
            ),
            // Courses open from the timetable's search and from anywhere
            // else; pushing one shows the 課表 tab.
            GoRoute(
              path: '/courses',
              builder: (_, _) => const CoursesScreen(),
              routes: [
                // Desktop: the course page stays at the left and its lists
                // open beside it. Course 0 only carries discussions opened
                // from a notification, so it has no page to show.
                ShellRoute(
                  builder: (context, state, child) {
                    final id = int.parse(state.pathParameters['id']!);
                    if (id == 0) return child;
                    return _listBeside(
                      context,
                      list: CourseDetailScreen(
                        courseId: id,
                        open: state.uri.path,
                      ),
                      root: ':id',
                      atRoot: state.uri.path == '/courses/$id',
                      child: child,
                    );
                  },
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
                        GoRoute(
                          path: 'attendance/:cmid',
                          builder: (_, state) => AttendanceScreen(
                            cmid: int.parse(state.pathParameters['cmid']!),
                            title: state.extra as String?,
                          ),
                        ),
                        GoRoute(
                          path: 'absence/:cmid',
                          builder: (_, state) => AbsenceScreen(
                            cmid: int.parse(state.pathParameters['cmid']!),
                            title: state.extra as String?,
                          ),
                        ),
                        GoRoute(
                          path: 'discussions/:did',
                          builder: (_, state) => DiscussionScreen(
                            discussionId: int.parse(
                              state.pathParameters['did']!,
                            ),
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
            // Desktop direction A: the More list stays at the left and its
            // pages open beside it.
            ShellRoute(
              builder: (context, state, child) => _listBeside(
                context,
                list: MoreScreen(open: state.uri.path),
                root: '/more',
                atRoot: state.uri.path == '/more',
                child: child,
              ),
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
                      path: 'tools',
                      builder: (_, _) => const ToolsScreen(),
                      routes: [
                        GoRoute(
                          path: 'bus',
                          builder: (_, _) => const BusScreen(),
                        ),
                        GoRoute(
                          path: 'countdown',
                          builder: (_, _) => const CountdownScreen(),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'iccu',
                      builder: (_, _) => const IccuScreen(),
                    ),
                    GoRoute(
                      path: 'leave',
                      builder: (_, _) => const LeaveScreen(),
                    ),
                    GoRoute(
                      path: 'space',
                      builder: (_, _) => const SpaceScreen(),
                    ),
                    GoRoute(
                      path: 'events',
                      builder: (_, _) => const EventsScreen(),
                      routes: [
                        GoRoute(
                          path: 'detail',
                          builder: (_, state) {
                            final (:event, :onChanged) =
                                state.extra!
                                    as ({
                                      SchoolEvent event,
                                      VoidCallback? onChanged,
                                    });
                            return EventDetailScreen(
                              event: event,
                              onChanged: onChanged,
                            );
                          },
                        ),
                        GoRoute(
                          path: 'mine',
                          builder: (_, state) {
                            final (
                              :data,
                              :onChanged,
                            ) = state.extra!
                                as ({EventsData data, VoidCallback onChanged});
                            return MyEventsScreen(
                              data: data,
                              onChanged: onChanged,
                            );
                          },
                        ),
                        GoRoute(
                          path: 'poster',
                          builder: (_, state) =>
                              PosterScreen(url: state.extra! as String),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'payment',
                      builder: (_, _) => const PaymentScreen(),
                    ),
                    GoRoute(
                      path: 'dorm-repair',
                      builder: (_, _) => const DormRepairScreen(),
                      routes: [
                        GoRoute(
                          path: 'new',
                          builder: (_, _) => const DormRepairFormScreen(),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'parttime',
                      builder: (_, _) => const ParttimeScreen(),
                      routes: [
                        GoRoute(
                          path: 'add',
                          builder: (_, _) => const ParttimeAddScreen(),
                        ),
                        GoRoute(
                          path: 'pay',
                          builder: (_, _) => const ParttimePayScreen(),
                        ),
                        GoRoute(
                          path: 'print',
                          builder: (_, _) => const ParttimePrintScreen(),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'settings',
                      builder: (_, _) => const SettingsScreen(),
                      routes: [
                        GoRoute(
                          path: 'saved',
                          builder: (_, _) => const SavedDataScreen(),
                        ),
                      ],
                    ),
                    GoRoute(
                      path: 'about',
                      builder: (_, _) => const AboutScreen(),
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
                                state.extra!
                                    as ({LibraryRecord record, int index});
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
    ),
  ],
);

/// Desktop direction A: a list page at the left and the page opened from
/// it beside it, at [root]'s route; a narrow area shows only [child].
Widget _listBeside(
  BuildContext context, {
  required Widget list,
  required String root,
  required bool atRoot,
  required Widget child,
}) {
  if (MediaQuery.sizeOf(context).width < wideLayout) return child;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        width: paneWidth,
        child: PaneSize(child: list),
      ),
      VerticalDivider(
        width: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      Expanded(
        child: atRoot
            ? const SizedBox.shrink()
            : PaneSize(
                child: ListPaneScope(root: root, child: child),
              ),
      ),
    ],
  );
}
