import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
  ];

  /// No description provided for @navToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get navToday;

  /// No description provided for @navTimetable.
  ///
  /// In zh, this message translates to:
  /// **'課表'**
  String get navTimetable;

  /// No description provided for @navCourses.
  ///
  /// In zh, this message translates to:
  /// **'課程'**
  String get navCourses;

  /// No description provided for @navCalendar.
  ///
  /// In zh, this message translates to:
  /// **'日曆'**
  String get navCalendar;

  /// No description provided for @navMore.
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get navMore;

  /// No description provided for @signInPortal.
  ///
  /// In zh, this message translates to:
  /// **'登入單一入口'**
  String get signInPortal;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重試'**
  String get retry;

  /// No description provided for @updatedAt.
  ///
  /// In zh, this message translates to:
  /// **'更新於 {time}'**
  String updatedAt(String time);

  /// No description provided for @loadFailed.
  ///
  /// In zh, this message translates to:
  /// **'無法載入'**
  String get loadFailed;

  /// No description provided for @toDo.
  ///
  /// In zh, this message translates to:
  /// **'待辦'**
  String get toDo;

  /// No description provided for @nothingDueSoon.
  ///
  /// In zh, this message translates to:
  /// **'14 天內沒有到期項目'**
  String get nothingDueSoon;

  /// No description provided for @unitHours.
  ///
  /// In zh, this message translates to:
  /// **'小時'**
  String get unitHours;

  /// No description provided for @unitDays.
  ///
  /// In zh, this message translates to:
  /// **'天'**
  String get unitDays;

  /// No description provided for @unitMinutes.
  ///
  /// In zh, this message translates to:
  /// **'分鐘'**
  String get unitMinutes;

  /// No description provided for @unitMinutesLater.
  ///
  /// In zh, this message translates to:
  /// **'分鐘後'**
  String get unitMinutesLater;

  /// No description provided for @todayNoClasses.
  ///
  /// In zh, this message translates to:
  /// **'今天沒有課'**
  String get todayNoClasses;

  /// No description provided for @todayClassesOver.
  ///
  /// In zh, this message translates to:
  /// **'今天的課結束了'**
  String get todayClassesOver;

  /// No description provided for @todayClassesLeft.
  ///
  /// In zh, this message translates to:
  /// **'今天還有{count, select, 1{一} 2{兩} 3{三} 4{四} 5{五} 6{六} 7{七} 8{八} 9{九} 10{十} other{ {count} }}堂課'**
  String todayClassesLeft(String count);

  /// No description provided for @inClass.
  ///
  /// In zh, this message translates to:
  /// **'上課中'**
  String get inClass;

  /// No description provided for @untilTime.
  ///
  /// In zh, this message translates to:
  /// **'到 {time}'**
  String untilTime(String time);

  /// No description provided for @nextClass.
  ///
  /// In zh, this message translates to:
  /// **'下一堂'**
  String get nextClass;

  /// No description provided for @startsAt.
  ///
  /// In zh, this message translates to:
  /// **'{time} 開始'**
  String startsAt(String time);

  /// No description provided for @dueThisWeek.
  ///
  /// In zh, this message translates to:
  /// **'本週到期'**
  String get dueThisWeek;

  /// No description provided for @unread.
  ///
  /// In zh, this message translates to:
  /// **'未讀'**
  String get unread;

  /// No description provided for @unreadDetail.
  ///
  /// In zh, this message translates to:
  /// **'通知 {notices}・信件 {mail}'**
  String unreadDetail(int notices, int mail);

  /// No description provided for @notifications.
  ///
  /// In zh, this message translates to:
  /// **'通知'**
  String get notifications;

  /// No description provided for @notificationsUnread.
  ///
  /// In zh, this message translates to:
  /// **'通知，{count} 則未讀'**
  String notificationsUnread(int count);

  /// No description provided for @mail.
  ///
  /// In zh, this message translates to:
  /// **'信件'**
  String get mail;

  /// No description provided for @noNotifications.
  ///
  /// In zh, this message translates to:
  /// **'沒有通知'**
  String get noNotifications;

  /// No description provided for @noMail.
  ///
  /// In zh, this message translates to:
  /// **'沒有信件'**
  String get noMail;

  /// No description provided for @monthTitle.
  ///
  /// In zh, this message translates to:
  /// **'{month} 月'**
  String monthTitle(String month);

  /// No description provided for @yearMonthTitle.
  ///
  /// In zh, this message translates to:
  /// **'{year} 年 {month} 月'**
  String yearMonthTitle(int year, String month);

  /// No description provided for @goToToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get goToToday;

  /// No description provided for @itemCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 項'**
  String itemCount(int count);

  /// No description provided for @noEventsThisDay.
  ///
  /// In zh, this message translates to:
  /// **'這天沒有事件'**
  String get noEventsThisDay;

  /// No description provided for @academicSystem.
  ///
  /// In zh, this message translates to:
  /// **'學籍系統'**
  String get academicSystem;

  /// No description provided for @academicRecord.
  ///
  /// In zh, this message translates to:
  /// **'學籍資料'**
  String get academicRecord;

  /// No description provided for @studentNo.
  ///
  /// In zh, this message translates to:
  /// **'學號'**
  String get studentNo;

  /// No description provided for @englishName.
  ///
  /// In zh, this message translates to:
  /// **'英文姓名'**
  String get englishName;

  /// No description provided for @email.
  ///
  /// In zh, this message translates to:
  /// **'電子郵件'**
  String get email;

  /// No description provided for @mobile.
  ///
  /// In zh, this message translates to:
  /// **'行動電話'**
  String get mobile;

  /// No description provided for @onSchoolWebsite.
  ///
  /// In zh, this message translates to:
  /// **'在學校網站辦理'**
  String get onSchoolWebsite;

  /// No description provided for @editNameContact.
  ///
  /// In zh, this message translates to:
  /// **'修改英文姓名與聯絡資料'**
  String get editNameContact;

  /// No description provided for @studentPhoto.
  ///
  /// In zh, this message translates to:
  /// **'學生照片'**
  String get studentPhoto;

  /// No description provided for @enrollmentCertificate.
  ///
  /// In zh, this message translates to:
  /// **'在學證明書'**
  String get enrollmentCertificate;

  /// No description provided for @generating.
  ///
  /// In zh, this message translates to:
  /// **'產生中'**
  String get generating;

  /// No description provided for @generate.
  ///
  /// In zh, this message translates to:
  /// **'產生'**
  String get generate;

  /// No description provided for @regenerate.
  ///
  /// In zh, this message translates to:
  /// **'重新產生'**
  String get regenerate;

  /// No description provided for @open.
  ///
  /// In zh, this message translates to:
  /// **'開啟'**
  String get open;

  /// No description provided for @share.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get share;

  /// No description provided for @notYetThisSemester.
  ///
  /// In zh, this message translates to:
  /// **'本學期尚未產生'**
  String get notYetThisSemester;

  /// No description provided for @validPrinted.
  ///
  /// In zh, this message translates to:
  /// **'有效・列印日 {date}'**
  String validPrinted(String date);

  /// No description provided for @expiredPrinted.
  ///
  /// In zh, this message translates to:
  /// **'已過期・列印日 {date}'**
  String expiredPrinted(String date);

  /// No description provided for @savedToDevice.
  ///
  /// In zh, this message translates to:
  /// **'已存到裝置 {time}'**
  String savedToDevice(String time);

  /// No description provided for @notPdf.
  ///
  /// In zh, this message translates to:
  /// **'學校回傳的不是 PDF'**
  String get notPdf;

  /// No description provided for @courseSelection.
  ///
  /// In zh, this message translates to:
  /// **'選課系統'**
  String get courseSelection;

  /// No description provided for @viewInApp.
  ///
  /// In zh, this message translates to:
  /// **'在 App 查看'**
  String get viewInApp;

  /// No description provided for @courseCountShort.
  ///
  /// In zh, this message translates to:
  /// **'{count} 門'**
  String courseCountShort(int count);

  /// No description provided for @selectionQuery.
  ///
  /// In zh, this message translates to:
  /// **'選課查詢'**
  String get selectionQuery;

  /// No description provided for @thisSemesterCredits.
  ///
  /// In zh, this message translates to:
  /// **'本學期・{credits} 學分'**
  String thisSemesterCredits(String credits);

  /// No description provided for @typeCredits.
  ///
  /// In zh, this message translates to:
  /// **'{type} {credits} 學分'**
  String typeCredits(String type, String credits);

  /// No description provided for @courseChanges.
  ///
  /// In zh, this message translates to:
  /// **'開排課異動查詢'**
  String get courseChanges;

  /// No description provided for @schoolwideChanges.
  ///
  /// In zh, this message translates to:
  /// **'全校本學期異動'**
  String get schoolwideChanges;

  /// No description provided for @myApplications.
  ///
  /// In zh, this message translates to:
  /// **'我的申請'**
  String get myApplications;

  /// No description provided for @applicationsHint.
  ///
  /// In zh, this message translates to:
  /// **'加簽、超短修、校際、棄選、學程'**
  String get applicationsHint;

  /// No description provided for @kindCount.
  ///
  /// In zh, this message translates to:
  /// **'{kind} {count} 筆'**
  String kindCount(String kind, int count);

  /// No description provided for @programs.
  ///
  /// In zh, this message translates to:
  /// **'跨領域學程'**
  String get programs;

  /// No description provided for @programsDetail.
  ///
  /// In zh, this message translates to:
  /// **'學程與開設單位'**
  String get programsDetail;

  /// No description provided for @notOpen.
  ///
  /// In zh, this message translates to:
  /// **'未開放'**
  String get notOpen;

  /// No description provided for @noData.
  ///
  /// In zh, this message translates to:
  /// **'沒有資料'**
  String get noData;

  /// No description provided for @academics.
  ///
  /// In zh, this message translates to:
  /// **'學業'**
  String get academics;

  /// No description provided for @grades.
  ///
  /// In zh, this message translates to:
  /// **'成績'**
  String get grades;

  /// No description provided for @courseCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 門課'**
  String courseCount(int count);

  /// No description provided for @campus.
  ///
  /// In zh, this message translates to:
  /// **'校園'**
  String get campus;

  /// No description provided for @allCampusSystems.
  ///
  /// In zh, this message translates to:
  /// **'全部校務系統'**
  String get allCampusSystems;

  /// No description provided for @account.
  ///
  /// In zh, this message translates to:
  /// **'帳號'**
  String get account;

  /// No description provided for @ecourseSignedIn.
  ///
  /// In zh, this message translates to:
  /// **'eCourse2 已登入'**
  String get ecourseSignedIn;

  /// No description provided for @ecourseSignedOut.
  ///
  /// In zh, this message translates to:
  /// **'eCourse2 未登入'**
  String get ecourseSignedOut;

  /// No description provided for @portalShared.
  ///
  /// In zh, this message translates to:
  /// **'單一入口共用'**
  String get portalShared;

  /// No description provided for @campusSystems.
  ///
  /// In zh, this message translates to:
  /// **'校務系統'**
  String get campusSystems;

  /// No description provided for @searchSystems.
  ///
  /// In zh, this message translates to:
  /// **'搜尋系統'**
  String get searchSystems;

  /// No description provided for @favorites.
  ///
  /// In zh, this message translates to:
  /// **'常用'**
  String get favorites;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'編輯'**
  String get edit;

  /// No description provided for @recentlyOpened.
  ///
  /// In zh, this message translates to:
  /// **'最近開啟'**
  String get recentlyOpened;

  /// No description provided for @favoritesCount.
  ///
  /// In zh, this message translates to:
  /// **'常用（{count}/{max}）'**
  String favoritesCount(int count, int max);

  /// No description provided for @noGrades.
  ///
  /// In zh, this message translates to:
  /// **'還沒有成績'**
  String get noGrades;

  /// No description provided for @itemNotFound.
  ///
  /// In zh, this message translates to:
  /// **'找不到這個項目'**
  String get itemNotFound;

  /// No description provided for @stepOpens.
  ///
  /// In zh, this message translates to:
  /// **'開放'**
  String get stepOpens;

  /// No description provided for @stepSubmitted.
  ///
  /// In zh, this message translates to:
  /// **'繳交'**
  String get stepSubmitted;

  /// No description provided for @notSubmitted.
  ///
  /// In zh, this message translates to:
  /// **'未繳交'**
  String get notSubmitted;

  /// No description provided for @stepDue.
  ///
  /// In zh, this message translates to:
  /// **'截止'**
  String get stepDue;

  /// No description provided for @stepGrade.
  ///
  /// In zh, this message translates to:
  /// **'成績'**
  String get stepGrade;

  /// No description provided for @mySubmission.
  ///
  /// In zh, this message translates to:
  /// **'我的繳交'**
  String get mySubmission;

  /// No description provided for @description.
  ///
  /// In zh, this message translates to:
  /// **'說明'**
  String get description;

  /// No description provided for @attachments.
  ///
  /// In zh, this message translates to:
  /// **'附件'**
  String get attachments;

  /// No description provided for @stepAttempted.
  ///
  /// In zh, this message translates to:
  /// **'作答'**
  String get stepAttempted;

  /// No description provided for @notAttempted.
  ///
  /// In zh, this message translates to:
  /// **'未作答'**
  String get notAttempted;

  /// No description provided for @stepCloses.
  ///
  /// In zh, this message translates to:
  /// **'關閉'**
  String get stepCloses;

  /// No description provided for @quizSettings.
  ///
  /// In zh, this message translates to:
  /// **'設定'**
  String get quizSettings;

  /// No description provided for @quizStart.
  ///
  /// In zh, this message translates to:
  /// **'開始'**
  String get quizStart;

  /// No description provided for @quizEnd.
  ///
  /// In zh, this message translates to:
  /// **'結束'**
  String get quizEnd;

  /// No description provided for @attemptsAllowed.
  ///
  /// In zh, this message translates to:
  /// **'允許作答'**
  String get attemptsAllowed;

  /// No description provided for @unlimited.
  ///
  /// In zh, this message translates to:
  /// **'不限次數'**
  String get unlimited;

  /// No description provided for @attemptCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 次'**
  String attemptCount(int count);

  /// No description provided for @passGrade.
  ///
  /// In zh, this message translates to:
  /// **'及格分數'**
  String get passGrade;

  /// No description provided for @fullMarks.
  ///
  /// In zh, this message translates to:
  /// **'滿分 {max}'**
  String fullMarks(String max);

  /// No description provided for @noFiles.
  ///
  /// In zh, this message translates to:
  /// **'沒有檔案'**
  String get noFiles;

  /// No description provided for @filesLabel.
  ///
  /// In zh, this message translates to:
  /// **'個檔案'**
  String get filesLabel;

  /// No description provided for @total.
  ///
  /// In zh, this message translates to:
  /// **'合計'**
  String get total;

  /// No description provided for @lastUpdated.
  ///
  /// In zh, this message translates to:
  /// **'最後更新'**
  String get lastUpdated;

  /// No description provided for @fileUpdated.
  ///
  /// In zh, this message translates to:
  /// **'{size}・{date} 更新'**
  String fileUpdated(String size, String date);

  /// No description provided for @courseNotFound.
  ///
  /// In zh, this message translates to:
  /// **'找不到這門課'**
  String get courseNotFound;

  /// No description provided for @nothingDue.
  ///
  /// In zh, this message translates to:
  /// **'沒有待辦'**
  String get nothingDue;

  /// No description provided for @nameDue.
  ///
  /// In zh, this message translates to:
  /// **'{name} 到期'**
  String nameDue(String name);

  /// No description provided for @announcementsUnit.
  ///
  /// In zh, this message translates to:
  /// **'則公告'**
  String get announcementsUnit;

  /// No description provided for @currentGrade.
  ///
  /// In zh, this message translates to:
  /// **'目前成績'**
  String get currentGrade;

  /// No description provided for @courseSection.
  ///
  /// In zh, this message translates to:
  /// **'課程'**
  String get courseSection;

  /// No description provided for @allSections.
  ///
  /// In zh, this message translates to:
  /// **'全部章節'**
  String get allSections;

  /// No description provided for @sectionCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 個章節'**
  String sectionCount(int count);

  /// No description provided for @announcements.
  ///
  /// In zh, this message translates to:
  /// **'公告'**
  String get announcements;

  /// No description provided for @postCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 則'**
  String postCount(int count);

  /// No description provided for @hoursLeft.
  ///
  /// In zh, this message translates to:
  /// **'{count} 小時'**
  String hoursLeft(int count);

  /// No description provided for @daysLeft.
  ///
  /// In zh, this message translates to:
  /// **'{count} 天'**
  String daysLeft(int count);

  /// No description provided for @today.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In zh, this message translates to:
  /// **'明天'**
  String get tomorrow;

  /// No description provided for @nextClassAt.
  ///
  /// In zh, this message translates to:
  /// **'下次上課　{when}'**
  String nextClassAt(String when);

  /// No description provided for @noContents.
  ///
  /// In zh, this message translates to:
  /// **'還沒有課程內容'**
  String get noContents;

  /// No description provided for @dueOn.
  ///
  /// In zh, this message translates to:
  /// **'{date} 截止'**
  String dueOn(String date);

  /// No description provided for @fileCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 個檔案'**
  String fileCount(int count);

  /// No description provided for @noAnnouncements.
  ///
  /// In zh, this message translates to:
  /// **'沒有公告'**
  String get noAnnouncements;

  /// No description provided for @noGradeItems.
  ///
  /// In zh, this message translates to:
  /// **'還沒有成績項目'**
  String get noGradeItems;

  /// No description provided for @searchCourses.
  ///
  /// In zh, this message translates to:
  /// **'搜尋課程'**
  String get searchCourses;

  /// No description provided for @noMatchingCourses.
  ///
  /// In zh, this message translates to:
  /// **'沒有符合的課程'**
  String get noMatchingCourses;

  /// No description provided for @verifiedAt.
  ///
  /// In zh, this message translates to:
  /// **'{time} 驗證'**
  String verifiedAt(String time);

  /// No description provided for @signedOut.
  ///
  /// In zh, this message translates to:
  /// **'未登入'**
  String get signedOut;

  /// No description provided for @verifyFailed.
  ///
  /// In zh, this message translates to:
  /// **'驗證失敗'**
  String get verifyFailed;

  /// No description provided for @signedInAs.
  ///
  /// In zh, this message translates to:
  /// **'已登入：{name}'**
  String signedInAs(String name);

  /// No description provided for @signedInUnverified.
  ///
  /// In zh, this message translates to:
  /// **'已登入，未驗證'**
  String get signedInUnverified;

  /// No description provided for @verify.
  ///
  /// In zh, this message translates to:
  /// **'驗證'**
  String get verify;

  /// No description provided for @signOut.
  ///
  /// In zh, this message translates to:
  /// **'登出'**
  String get signOut;

  /// No description provided for @portalCas.
  ///
  /// In zh, this message translates to:
  /// **'單一入口（CAS）'**
  String get portalCas;

  /// No description provided for @sharedWithEcourse.
  ///
  /// In zh, this message translates to:
  /// **'與 eCourse2 共用登入'**
  String get sharedWithEcourse;

  /// No description provided for @portal.
  ///
  /// In zh, this message translates to:
  /// **'單一入口'**
  String get portal;

  /// No description provided for @openPortal.
  ///
  /// In zh, this message translates to:
  /// **'開啟單一入口'**
  String get openPortal;

  /// No description provided for @signInFailed.
  ///
  /// In zh, this message translates to:
  /// **'登入失敗：{error}'**
  String signInFailed(String error);

  /// No description provided for @signInWithPortal.
  ///
  /// In zh, this message translates to:
  /// **'以單一入口登入'**
  String get signInWithPortal;

  /// No description provided for @noClassesThisDay.
  ///
  /// In zh, this message translates to:
  /// **'這天沒有課'**
  String get noClassesThisDay;

  /// No description provided for @unscheduled.
  ///
  /// In zh, this message translates to:
  /// **'未排時間'**
  String get unscheduled;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'關閉'**
  String get close;

  /// No description provided for @switchSemester.
  ///
  /// In zh, this message translates to:
  /// **'切換學期'**
  String get switchSemester;

  /// No description provided for @semesterLabel.
  ///
  /// In zh, this message translates to:
  /// **'{year} 學年{term, select, 1{上學期} 2{下學期} other{暑期}}'**
  String semesterLabel(String year, String term);

  /// No description provided for @sectionGeneral.
  ///
  /// In zh, this message translates to:
  /// **'一般'**
  String get sectionGeneral;

  /// No description provided for @eventLabel.
  ///
  /// In zh, this message translates to:
  /// **'{kind, select, assign{作業} quiz{測驗} course{課程事件} user{個人事件} site{全校事件} other{活動}}{action, select, due{到期} close{關閉} open{開放} other{}}'**
  String eventLabel(String kind, String action);

  /// No description provided for @weekdayShort.
  ///
  /// In zh, this message translates to:
  /// **'{day, select, 1{一} 2{二} 3{三} 4{四} 5{五} 6{六} 7{日} other{}}'**
  String weekdayShort(String day);

  /// No description provided for @weekdayFull.
  ///
  /// In zh, this message translates to:
  /// **'{day, select, 1{週一} 2{週二} 3{週三} 4{週四} 5{週五} 6{週六} 7{週日} other{}}'**
  String weekdayFull(String day);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
