import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/ecourse_auth_repository.dart';
import '../ui/account/account_screen.dart';
import '../ui/core/app_shell.dart';
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
import '../ui/more/dorm_net_screen.dart';
import '../ui/more/payment_screen.dart';
import '../ui/more/saved_data_screen.dart';
import '../ui/more/settings_screen.dart';
import '../ui/more/software_screen.dart';
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
      navigatorContainerBuilder: (context, shell, children) => AnimatedBranches(
        index: shell.currentIndex,
        children: [
          for (final (i, child) in children.indexed)
            i == _moreBranch
                ? _MoreBeside(
                    open: GoRouter.of(context).state.uri.path,
                    child: child,
                  )
                : child,
        ],
      ),
      branches: [
        StatefulShellBranch(
          observers: [PagesObserver()],
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
          observers: [PagesObserver()],
          routes: [
            GoRoute(
              path: '/messages',
              builder: (_, _) => const MessagesScreen(),
              routes: [
                // A post opened from a notification, which does not say its
                // course; back returns to the messages.
                GoRoute(
                  path: 'discussions/:did',
                  builder: (_, state) => DiscussionScreen(
                    discussionId: int.parse(state.pathParameters['did']!),
                    title: state.extra as String?,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          observers: [PagesObserver()],
          routes: [
            GoRoute(
              path: '/timetable',
              builder: (_, _) => const TimetableScreen(),
            ),
            // Courses open from the timetable's search and from anywhere
            // else; pushing one shows the 課表 tab.
            GoRoute(path: '/courses', builder: (_, _) => const CoursesScreen()),
            // A course, apart from the list above so opening one does not
            // build the list under it. Desktop: the course page stays at the
            // left and its lists open beside it.
            ..._besideList(
              [
                GoRoute(
                  path: '/courses/:id',
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
                        discussionId: int.parse(state.pathParameters['did']!),
                        title: state.extra as String?,
                      ),
                    ),
                    for (final part in CoursePart.values)
                      GoRoute(
                        path: part.name,
                        // Keyed like the course page beside it.
                        builder: (_, state) => CoursePartScreen(
                          key: ValueKey(state.uri.path),
                          courseId: int.parse(state.pathParameters['id']!),
                          part: part,
                        ),
                      ),
                  ],
                ),
              ],
              // Keyed: its data loads once, so another course needs a page
              // of its own.
              list: (state) => CourseDetailScreen(
                key: ValueKey(state.pathParameters['id']),
                courseId: int.parse(state.pathParameters['id']!),
                open: _atCourse(state)
                    ? '${state.uri.path}/contents'
                    : state.uri.path,
              ),
              root: '/courses/:id',
              atRoot: _atCourse,
              // Beside the course, its sections open at once.
              first: (state) => CoursePartScreen(
                key: ValueKey('${state.uri.path}/contents'),
                courseId: int.parse(state.pathParameters['id']!),
                part: CoursePart.contents,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          observers: [PagesObserver()],
          routes: [
            GoRoute(
              path: '/calendar',
              builder: (_, _) => const CalendarScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          observers: [PagesObserver()],
          routes: [
            // Desktop direction A: the More list stays at the left and its
            // pages open beside it ([_MoreBeside]), so beside it the first
            // page is empty.
            GoRoute(
              path: '/more',
              // The pane beside the list measures itself, not the window.
              builder: (context, _) =>
                  context.getInheritedWidgetOfExactType<ListPaneScope>() == null
                  ? const MoreScreen()
                  : const SizedBox.shrink(),
              routes: [
                GoRoute(
                  path: 'grades',
                  builder: (_, _) => const GradesScreen(),
                ),
                GoRoute(
                  path: 'tools',
                  builder: (_, _) => const ToolsScreen(),
                  routes: [
                    GoRoute(path: 'bus', builder: (_, _) => const BusScreen()),
                    GoRoute(
                      path: 'countdown',
                      builder: (_, _) => const CountdownScreen(),
                    ),
                  ],
                ),
                GoRoute(path: 'iccu', builder: (_, _) => const IccuScreen()),
                GoRoute(path: 'leave', builder: (_, _) => const LeaveScreen()),
                GoRoute(path: 'space', builder: (_, _) => const SpaceScreen()),
                GoRoute(
                  path: 'events',
                  builder: (_, _) => const EventsScreen(),
                  routes: [
                    GoRoute(
                      path: 'detail',
                      builder: (_, state) {
                        final (
                          :event,
                          :onChanged,
                        ) = state.extra!
                            as ({SchoolEvent event, VoidCallback? onChanged});
                        return EventDetailScreen(
                          event: event,
                          onChanged: onChanged,
                        );
                      },
                    ),
                    GoRoute(
                      path: 'mine',
                      builder: (_, state) {
                        final (:data, :onChanged) =
                            state.extra!
                                as ({
                                  ValueListenable<EventsData?> data,
                                  VoidCallback onChanged,
                                });
                        return MyEventsScreen(data: data, onChanged: onChanged);
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
                  path: 'software',
                  builder: (_, _) => const SoftwareScreen(),
                ),
                GoRoute(
                  path: 'dorm-net',
                  builder: (_, _) => const DormNetScreen(),
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
                GoRoute(path: 'about', builder: (_, _) => const AboutScreen()),
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

/// Desktop direction A: a list page at the left and the page opened from
/// it beside it, at [root]'s route; a narrow area shows only [child].
/// [routes] with every page set beside [list] on a wide screen. Each page
/// draws its own list instead of sharing a ShellRoute: a ShellRoute's
/// navigator has one key, so its pages could not also be pushed onto
/// another tab, which would build it twice and leave its own tab blank.
List<RouteBase> _besideList(
  List<RouteBase> routes, {
  required Widget Function(GoRouterState state) list,
  required String root,
  required bool Function(GoRouterState state) atRoot,
  Widget Function(GoRouterState state)? first,
}) => [
  for (final route in routes)
    if (route is GoRoute)
      GoRoute(
        path: route.path,
        pageBuilder: (context, state) {
          final page = _listBeside(
            context,
            list: list(state),
            root: root,
            atRoot: atRoot(state),
            first: first?.call(state),
            child: route.builder!(context, state),
          );
          // Beside the list a page changes in place: a transition would
          // move the list with it, since each page draws its own.
          // Named as go_router names its own pages: the back button finds
          // the list's root page by it (ListPaneScope).
          final name = state.name ?? state.path;
          return listBeside(context)
              ? NoTransitionPage(key: state.pageKey, name: name, child: page)
              : MaterialPage(key: state.pageKey, name: name, child: page);
        },
        routes: _besideList(
          route.routes,
          list: list,
          root: root,
          atRoot: atRoot,
          first: first,
        ),
      )
    else
      route,
];

/// The list beside each navigator's pages, by the list's own key.
final _listKeys = Expando<Map<Key?, GlobalKey>>();

Widget _listBeside(
  BuildContext context, {
  required Widget list,
  required String root,
  required bool atRoot,
  required Widget child,

  /// Beside the list at its first page; empty when null.
  Widget? first,
}) {
  if (!listBeside(context)) return child;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        width: listWidthOf(context),
        child: Builder(
          builder: (context) {
            // Only the top page draws the list, under one key per navigator,
            // so the next page takes it over with its data and scroll.
            if (!(ModalRoute.isCurrentOf(context) ?? true)) {
              return const SizedBox.shrink();
            }
            final keys = _listKeys[Navigator.of(context)] ??= {};
            return PaneSize(key: keys[list.key] ??= GlobalKey(), child: list);
          },
        ),
      ),
      VerticalDivider(
        width: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      Expanded(
        child: atRoot && first == null
            ? const SizedBox.shrink()
            : PaneSize(
                child: ListPaneScope(
                  root: root,
                  child: atRoot ? first! : child,
                ),
              ),
      ),
    ],
  );
}

bool _atCourse(GoRouterState state) =>
    state.uri.path == '/courses/${state.pathParameters['id']}';

/// The More tab's place among the branches.
const _moreBranch = 4;

/// The More tab beside its list in a wide window: one list for every page,
/// so it keeps its scroll and its tiles while pages change beside it.
class _MoreBeside extends StatelessWidget {
  const _MoreBeside({required this.open, required this.child});

  /// The page open beside the list; its row is lit.
  final String open;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!listBeside(context)) return child;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: listWidthOf(context),
          child: PaneSize(child: MoreScreen(open: open)),
        ),
        VerticalDivider(
          width: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        Expanded(
          child: PaneSize(
            child: ListPaneScope(root: '/more', child: child),
          ),
        ),
      ],
    );
  }
}
