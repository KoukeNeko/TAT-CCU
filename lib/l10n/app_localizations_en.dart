// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navToday => 'Today';

  @override
  String get navTimetable => 'Timetable';

  @override
  String get navCourses => 'Courses';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navMore => 'More';

  @override
  String get signInPortal => 'Sign in to CCU Portal';

  @override
  String get retry => 'Retry';

  @override
  String updatedAt(String time) {
    return 'Updated $time';
  }

  @override
  String get loadFailed => 'Couldn\'t load';

  @override
  String get toDo => 'To do';

  @override
  String get nothingDueSoon => 'Nothing due in the next 14 days';

  @override
  String get unitHours => 'hrs';

  @override
  String get unitDays => 'days';

  @override
  String get unitMinutes => 'min';

  @override
  String get unitMinutesLater => 'min';

  @override
  String get todayNoClasses => 'No classes today';

  @override
  String get todayClassesOver => 'Today\'s classes are over';

  @override
  String todayClassesLeft(String count) {
    String _temp0 = intl.Intl.selectLogic(count, {
      '1': '1 class left today',
      'other': '$count classes left today',
    });
    return '$_temp0';
  }

  @override
  String get inClass => 'In class';

  @override
  String untilTime(String time) {
    return 'Until $time';
  }

  @override
  String get nextClass => 'Next';

  @override
  String startsAt(String time) {
    return 'Starts $time';
  }

  @override
  String get dueThisWeek => 'Due this week';

  @override
  String get unread => 'Unread';

  @override
  String unreadDetail(int notices, int mail) {
    return '$notices notifications · $mail mail';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String notificationsUnread(int count) {
    return 'Notifications, $count unread';
  }

  @override
  String get mail => 'Mail';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get noMail => 'No mail';

  @override
  String monthTitle(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      '1': 'January',
      '2': 'February',
      '3': 'March',
      '4': 'April',
      '5': 'May',
      '6': 'June',
      '7': 'July',
      '8': 'August',
      '9': 'September',
      '10': 'October',
      '11': 'November',
      '12': 'December',
      'other': '$month',
    });
    return '$_temp0';
  }

  @override
  String yearMonthTitle(int year, String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      '1': 'January',
      '2': 'February',
      '3': 'March',
      '4': 'April',
      '5': 'May',
      '6': 'June',
      '7': 'July',
      '8': 'August',
      '9': 'September',
      '10': 'October',
      '11': 'November',
      '12': 'December',
      'other': '$month',
    });
    return '$_temp0 $year';
  }

  @override
  String get goToToday => 'Today';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get noEventsThisDay => 'No events on this day';

  @override
  String get academicSystem => 'Student Records';

  @override
  String get academicRecord => 'Student record';

  @override
  String get studentNo => 'Student ID';

  @override
  String get englishName => 'English name';

  @override
  String get email => 'Email';

  @override
  String get mobile => 'Mobile';

  @override
  String get onSchoolWebsite => 'On the school website';

  @override
  String get editNameContact => 'Edit English name and contacts';

  @override
  String get studentPhoto => 'Student photo';

  @override
  String get enrollmentCertificate => 'Certificate of Enrollment';

  @override
  String get generating => 'Generating';

  @override
  String get generate => 'Generate';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get open => 'Open';

  @override
  String get share => 'Share';

  @override
  String get notYetThisSemester => 'Not generated this semester';

  @override
  String validPrinted(String date) {
    return 'Valid · printed $date';
  }

  @override
  String expiredPrinted(String date) {
    return 'Expired · printed $date';
  }

  @override
  String savedToDevice(String time) {
    return 'Saved $time';
  }

  @override
  String get notPdf => 'The school didn\'t return a PDF';

  @override
  String get courseSelection => 'Course Selection';

  @override
  String get viewInApp => 'In the app';

  @override
  String courseCountShort(int count) {
    return '$count';
  }

  @override
  String get selectionQuery => 'My courses';

  @override
  String thisSemesterCredits(String credits) {
    return 'This semester · $credits credits';
  }

  @override
  String typeCredits(String type, String credits) {
    return '$type · $credits credits';
  }

  @override
  String get courseChanges => 'Course changes';

  @override
  String get schoolwideChanges => 'All changes this semester';

  @override
  String get myApplications => 'My applications';

  @override
  String get applicationsHint =>
      'Add, underload, cross-school, withdrawal, programs';

  @override
  String kindCount(String kind, int count) {
    return '$kind $count';
  }

  @override
  String get programs => 'Interdisciplinary programs';

  @override
  String get programsDetail => 'Programs and offering units';

  @override
  String get notOpen => 'Not open';

  @override
  String get noData => 'No data';

  @override
  String get academics => 'Academics';

  @override
  String get grades => 'Grades';

  @override
  String courseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count courses',
      one: '1 course',
    );
    return '$_temp0';
  }

  @override
  String get campus => 'Campus';

  @override
  String get allCampusSystems => 'All campus systems';

  @override
  String get account => 'Account';

  @override
  String get ecourseSignedIn => 'eCourse2 signed in';

  @override
  String get ecourseSignedOut => 'eCourse2 signed out';

  @override
  String get portalShared => 'Portal shared';

  @override
  String get campusSystems => 'Campus systems';

  @override
  String get searchSystems => 'Search systems';

  @override
  String get favorites => 'Favorites';

  @override
  String get edit => 'Edit';

  @override
  String get replaceWith => 'Replace with';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get followSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get recentlyOpened => 'Recent';

  @override
  String favoritesCount(int count, int max) {
    return 'Favorites ($count/$max)';
  }

  @override
  String get noGrades => 'No grades yet';

  @override
  String get itemNotFound => 'Item not found';

  @override
  String get stepOpens => 'Opens';

  @override
  String get stepSubmitted => 'Submitted';

  @override
  String get notSubmitted => 'Not submitted';

  @override
  String get stepDue => 'Due';

  @override
  String get stepGrade => 'Grade';

  @override
  String get mySubmission => 'My submission';

  @override
  String get description => 'Description';

  @override
  String get attachments => 'Attachments';

  @override
  String get stepAttempted => 'Attempted';

  @override
  String get notAttempted => 'Not attempted';

  @override
  String get stepCloses => 'Closes';

  @override
  String get quizSettings => 'Settings';

  @override
  String get quizStart => 'Opens';

  @override
  String get quizEnd => 'Closes';

  @override
  String get attemptsAllowed => 'Attempts allowed';

  @override
  String get unlimited => 'Unlimited';

  @override
  String attemptCount(int count) {
    return '$count';
  }

  @override
  String get passGrade => 'Passing grade';

  @override
  String fullMarks(String max) {
    return 'Out of $max';
  }

  @override
  String get noFiles => 'No files';

  @override
  String get filesLabel => 'files';

  @override
  String get total => 'Total';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String fileUpdated(String size, String date) {
    return '$size · updated $date';
  }

  @override
  String get courseNotFound => 'Course not found';

  @override
  String get nothingDue => 'Nothing due';

  @override
  String nameDue(String name) {
    return '$name due';
  }

  @override
  String get announcementsUnit => 'announcements';

  @override
  String get currentGrade => 'Current grade';

  @override
  String get courseSection => 'Course';

  @override
  String get allSections => 'All sections';

  @override
  String sectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sections',
      one: '1 section',
    );
    return '$_temp0';
  }

  @override
  String get announcements => 'Announcements';

  @override
  String postCount(int count) {
    return '$count';
  }

  @override
  String hoursLeft(int count) {
    return '$count hrs';
  }

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String nextClassAt(String when) {
    return 'Next class $when';
  }

  @override
  String get noContents => 'No content yet';

  @override
  String dueOn(String date) {
    return 'Due $date';
  }

  @override
  String fileCount(int count) {
    return '$count files';
  }

  @override
  String get noAnnouncements => 'No announcements';

  @override
  String get noGradeItems => 'No grade items yet';

  @override
  String get searchCourses => 'Search courses';

  @override
  String get noMatchingCourses => 'No matching courses';

  @override
  String verifiedAt(String time) {
    return 'verified $time';
  }

  @override
  String get signedOut => 'Signed out';

  @override
  String get verifyFailed => 'Verification failed';

  @override
  String signedInAs(String name) {
    return 'Signed in: $name';
  }

  @override
  String get signedInUnverified => 'Signed in, not verified';

  @override
  String get verify => 'Verify';

  @override
  String get signOut => 'Sign out';

  @override
  String get portalCas => 'CCU Portal (CAS)';

  @override
  String get sharedWithEcourse => 'Shares the eCourse2 sign-in';

  @override
  String get portal => 'CCU Portal';

  @override
  String get openPortal => 'Open CCU Portal';

  @override
  String signInFailed(String error) {
    return 'Sign-in failed: $error';
  }

  @override
  String get signInWithPortal => 'Sign in with CCU Portal';

  @override
  String get noClassesThisDay => 'No classes this day';

  @override
  String get unscheduled => 'Unscheduled';

  @override
  String get close => 'Close';

  @override
  String get switchSemester => 'Switch semester';

  @override
  String semesterLabel(String year, String term) {
    String _temp0 = intl.Intl.selectLogic(term, {
      '1': 'Fall',
      '2': 'Spring',
      'other': 'Summer',
    });
    return '$_temp0 of year $year';
  }

  @override
  String get sectionGeneral => 'General';

  @override
  String eventLabel(String kind, String action) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'assign': 'Assignment',
      'quiz': 'Quiz',
      'course': 'Course event',
      'user': 'Personal event',
      'site': 'Campus event',
      'other': 'Activity',
    });
    String _temp1 = intl.Intl.selectLogic(action, {
      'due': ' due',
      'close': ' closes',
      'open': ' opens',
      'other': '',
    });
    return '$_temp0$_temp1';
  }

  @override
  String weekdayShort(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'Mon',
      '2': 'Tue',
      '3': 'Wed',
      '4': 'Thu',
      '5': 'Fri',
      '6': 'Sat',
      '7': 'Sun',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String weekdayFull(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'Mon',
      '2': 'Tue',
      '3': 'Wed',
      '4': 'Thu',
      '5': 'Fri',
      '6': 'Sat',
      '7': 'Sun',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get leave => 'Leave';

  @override
  String get leaveApproved => 'Approved';

  @override
  String get leavePending => 'Pending';

  @override
  String get leaveCancelled => 'Cancelled';

  @override
  String get myLeaves => 'Leave requests';

  @override
  String get noLeaves => 'No leave requests';

  @override
  String get applyLeave => 'Request leave';

  @override
  String get cancelLeave => 'Cancel leave';

  @override
  String recordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count requests',
      one: '1 request',
    );
    return '$_temp0';
  }

  @override
  String get library => 'My Library';

  @override
  String get loansOverdue => 'Overdue';

  @override
  String get loansNextDue => 'Next due';

  @override
  String get onLoan => 'On loan';

  @override
  String get noLoans => 'No books on loan';

  @override
  String bookCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0';
  }

  @override
  String get dueToday => 'Due today';

  @override
  String daysOverdue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String holdsReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count holds ready for pickup',
      one: '1 hold ready for pickup',
    );
    return '$_temp0';
  }

  @override
  String heldUntil(String date) {
    return 'Held until $date';
  }

  @override
  String get loansAndRenewals => 'Loans & renewals';

  @override
  String loanDue(String date) {
    return 'Due $date';
  }

  @override
  String loanDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String get rememberPasswordTitle => 'Remember password?';

  @override
  String get rememberPasswordBody =>
      'Next time CAS asks you to sign in, the app fills it in and sends it. The password is stored encrypted on this device.';

  @override
  String get notNow => 'Not now';

  @override
  String get remember => 'Remember';

  @override
  String get autoSignIn => 'Auto sign-in';

  @override
  String get deleteSavedPassword => 'Delete saved password';

  @override
  String get campusConnecting => 'Connecting';

  @override
  String get campusFillingIn => 'Filling in your saved password';

  @override
  String get campusVerifying => 'Cloudflare check';

  @override
  String get campusReading => 'Loading data';

  @override
  String get showPage => 'Show page';

  @override
  String get librarySearchHint => 'Search books, journals, databases';

  @override
  String get kindCatalog => 'Catalog';

  @override
  String get kindJournal => 'Journals';

  @override
  String get kindDatabase => 'Databases';

  @override
  String get onShelf => 'On shelf';

  @override
  String get checkedOut => 'Checked out';

  @override
  String get online => 'Online';

  @override
  String get typeBooks => 'Books';

  @override
  String get typeDissertations => 'Theses';

  @override
  String get typeVideos => 'Video';

  @override
  String get sortRelevance => 'Relevance';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortTitle => 'Title';

  @override
  String get anyTime => 'Any';

  @override
  String lastYears(int count) {
    return 'Last $count years';
  }

  @override
  String get filter => 'Filter';

  @override
  String get filterAvailability => 'Availability';

  @override
  String get filterType => 'Type';

  @override
  String get filterSort => 'Sort';

  @override
  String get filterYear => 'Published';

  @override
  String get showResults => 'Show results';

  @override
  String resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get holdings => 'Copies';

  @override
  String get requestHold => 'Request';

  @override
  String get readOnline => 'Read online';

  @override
  String get cite => 'Cite';

  @override
  String get citationCopied => 'Citation copied';

  @override
  String get bibDetails => 'Details';

  @override
  String get publisher => 'Publisher';

  @override
  String get subjects => 'Subjects';

  @override
  String get collections => 'Collections';

  @override
  String get newBooks => 'New books';

  @override
  String get noBooks => 'No books';

  @override
  String get libraryCollections => 'Browse';

  @override
  String get renewAll => 'Renew all';

  @override
  String get renew => 'Renew';

  @override
  String get notRenewable => 'Can\'t be renewed';

  @override
  String get dueDate => 'Due';

  @override
  String get renewPending => 'Renewal requested';

  @override
  String get renewFailed => 'Couldn\'t renew';

  @override
  String renewedCount(int renewed, int total) {
    return 'Renewed $renewed of $total';
  }

  @override
  String get cancelHoldFailed => 'Couldn\'t cancel the request';

  @override
  String get holds => 'Requests';

  @override
  String get holdReady => 'Ready';

  @override
  String get holdWaiting => 'Waiting';

  @override
  String get cancelHoldTitle => 'Cancel request?';

  @override
  String get cancelHold => 'Cancel request';

  @override
  String get keepHold => 'Keep';

  @override
  String get libraryDiscovery => 'Library Discovery';

  @override
  String get viewAll => 'All';

  @override
  String get otherCollections => 'More collections';

  @override
  String allCollections(int count) {
    return 'All $count';
  }

  @override
  String get studySpace => 'Study spaces';

  @override
  String get scanToCheckIn => 'Scan to check in';

  @override
  String get openHours => 'Open';

  @override
  String get validFor => 'Valid';

  @override
  String get refreshing => 'Updating';

  @override
  String get refresh => 'Refresh';

  @override
  String get available => 'Available';

  @override
  String get bookSpace => 'Book';

  @override
  String updatesIn(int count) {
    return 'Updates in ${count}s';
  }

  @override
  String get designLanguage => 'Design language';

  @override
  String get dlColors => 'Color';

  @override
  String get dlCorners => 'Corners';

  @override
  String get dlSpacing => 'Spacing';

  @override
  String get dlType => 'Type';

  @override
  String get dlComponents => 'Components';

  @override
  String get dlFunctional => 'Function colors';

  @override
  String get dlIdentity => 'Identity colors';

  @override
  String get dlRoleNow => 'Now・selected';

  @override
  String get dlRoleNext => 'Next・schedule';

  @override
  String get dlRoleDue => 'Due・attention';

  @override
  String get dlRoleUnread => 'Unread';

  @override
  String get aboutApp => 'App';

  @override
  String get loadingCollections => 'Loading collections';

  @override
  String get loadingShelves => 'Loading new books and best sellers';

  @override
  String get events => 'Event sign-up';

  @override
  String get searchEvents => 'Search events';

  @override
  String searchFor(String query) {
    return 'Search \"$query\"';
  }

  @override
  String get within3Days => 'Next 3 days';

  @override
  String get withinWeek => 'Next 7 days';

  @override
  String get withinMonth => 'Next 30 days';

  @override
  String get allTime => 'Any time';

  @override
  String get eventsOpen => 'Open';

  @override
  String get eventsOngoing => 'Happening now';

  @override
  String get eventsClosed => 'Closed';

  @override
  String get anyStatus => 'Any status';

  @override
  String get eventCategory => 'Category';

  @override
  String get anyCategory => 'All categories';

  @override
  String get myEvents => 'My events';

  @override
  String get nextSignedUp => 'Next・signed up';

  @override
  String inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count days',
      one: 'Tomorrow',
    );
    return '$_temp0';
  }

  @override
  String waitlistSpots(int taken, int total) {
    return 'Waitlist $taken/$total';
  }

  @override
  String waitlistOnly(int taken, int total) {
    return 'Full・waitlist $taken / $total';
  }

  @override
  String get externalSignUp => 'External';

  @override
  String get signUpClosed => 'Closed';

  @override
  String get signedUp => 'Signed up';

  @override
  String get eventFull => 'Full';

  @override
  String get happeningNow => 'Now';

  @override
  String get eventDate => 'Date';

  @override
  String get eventPlace => 'Place';

  @override
  String get eventOrganizer => 'Organizer';

  @override
  String get eventContact => 'Contact';

  @override
  String get eventIntro => 'About';

  @override
  String get signUp => 'Sign up';

  @override
  String get signUpWaitlist => 'Join waitlist';

  @override
  String get goSignUp => 'Sign up on website';

  @override
  String get cancelSignUp => 'Cancel sign-up';

  @override
  String get cancelSignUpTitle => 'Cancel sign-up?';

  @override
  String get keepSignUp => 'Keep';

  @override
  String get signUpName => 'Name';

  @override
  String get signUpEmail => 'Email';

  @override
  String get submit => 'Submit';

  @override
  String get noMatchingEvents => 'No matching events';

  @override
  String get searchAnyTimeStatus => 'Search any time and status';

  @override
  String eventsAttended(String hours) {
    return 'Attended・$hours h';
  }

  @override
  String get pastEvents => 'Past events';

  @override
  String get noEventRecords => 'None';

  @override
  String get signUpFailed => 'Couldn\'t sign up';

  @override
  String get cancelSignUpFailed => 'Couldn\'t cancel the sign-up';

  @override
  String get ptTitle => 'Study & work hours';

  @override
  String get ptSelect => 'Select';

  @override
  String get ptDone => 'Done';

  @override
  String ptMonth(int year, int month) {
    return '$month/$year';
  }

  @override
  String get ptAllUnits => 'All units';

  @override
  String get ptUnconfirmed => 'Unconfirmed';

  @override
  String get ptConfirmed => 'Confirmed';

  @override
  String get ptPaid => 'Paid';

  @override
  String ptHours(String hours) {
    return '$hours h';
  }

  @override
  String ptWeek(String used, int limit) {
    return 'This week $used / $limit h';
  }

  @override
  String get ptOther => 'More';

  @override
  String get ptPayroll => 'Payments';

  @override
  String get ptPrint => 'Sign-in sheets and batches';

  @override
  String get ptAdd => 'Log hours';

  @override
  String get ptDate => 'Date';

  @override
  String get ptUnit => 'Unit';

  @override
  String get ptTime => 'Time';

  @override
  String get ptWork => 'Work';

  @override
  String get ptStage => 'Add to list';

  @override
  String ptStaged(int count, String hours) {
    return '$count to save・$hours h';
  }

  @override
  String ptSaveCount(int count) {
    return 'Save $count';
  }

  @override
  String ptSaveTitle(int count) {
    return 'Save $count entries?';
  }

  @override
  String get ptSave => 'Save';

  @override
  String get ptEndAfterStart => 'End must be after start';

  @override
  String ptOverlap(String slot) {
    return 'Overlaps $slot';
  }

  @override
  String ptWeekOver(String total, int limit) {
    return 'This week would reach $total h, over the $limit h limit';
  }

  @override
  String ptDeleteCount(int count) {
    return 'Delete $count';
  }

  @override
  String ptDeleteTitle(int count) {
    return 'Delete $count entries?';
  }

  @override
  String get ptDelete => 'Delete';

  @override
  String ptSelected(int count) {
    return '$count selected';
  }

  @override
  String get ptNoRecords => 'No hours logged';

  @override
  String get ptSearchUnits => 'Search units';

  @override
  String get ptMyUnits => 'My units';

  @override
  String get ptBatch => 'Batch';

  @override
  String get ptSheet => 'Sign-in sheet';

  @override
  String get ptOpenSheet => 'Open sign-in sheet';

  @override
  String get ptNet => 'Net';

  @override
  String get ptGross => 'Gross';

  @override
  String get ptWage => 'Wage';

  @override
  String get ptEmpLabor => 'Employer labour insurance';

  @override
  String get ptEmpPension => 'Employer pension';

  @override
  String get ptEmpHealth => 'Employer health insurance';

  @override
  String get ptEmpSupp => 'Employer supplementary premium';

  @override
  String get ptDeduct => 'Deductions';

  @override
  String get ptTax => 'Income tax';

  @override
  String get ptLabor => 'Labour insurance';

  @override
  String get ptPension => 'Pension';

  @override
  String get ptHealth => 'Health insurance';

  @override
  String get ptSupp => 'Supplementary premium';

  @override
  String get ptOtherDeduct => 'Other deductions';

  @override
  String get ptSubtotal => 'Subtotal';

  @override
  String get ptHoliday => 'Holiday';

  @override
  String ptEntries(int count) {
    return '$count entries';
  }

  @override
  String get demoMode => 'Demo mode';

  @override
  String get demoModeDetail => 'Alpha features show sample data';
}
