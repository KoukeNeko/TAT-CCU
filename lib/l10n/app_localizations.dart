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

  /// No description provided for @gradesThisTerm.
  ///
  /// In zh, this message translates to:
  /// **'本學期'**
  String get gradesThisTerm;

  /// No description provided for @gradesHistory.
  ///
  /// In zh, this message translates to:
  /// **'歷年'**
  String get gradesHistory;

  /// No description provided for @gradesOnSchoolSite.
  ///
  /// In zh, this message translates to:
  /// **'在學校網站查看'**
  String get gradesOnSchoolSite;

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

  /// No description provided for @replaceWith.
  ///
  /// In zh, this message translates to:
  /// **'換成'**
  String get replaceWith;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'設定'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In zh, this message translates to:
  /// **'外觀'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'語言'**
  String get language;

  /// No description provided for @followSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟隨系統'**
  String get followSystem;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'淺色'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get themeDark;

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

  /// No description provided for @leave.
  ///
  /// In zh, this message translates to:
  /// **'請假'**
  String get leave;

  /// No description provided for @leaveApproved.
  ///
  /// In zh, this message translates to:
  /// **'已核准'**
  String get leaveApproved;

  /// No description provided for @leavePending.
  ///
  /// In zh, this message translates to:
  /// **'審核中'**
  String get leavePending;

  /// No description provided for @leaveCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已銷假'**
  String get leaveCancelled;

  /// No description provided for @myLeaves.
  ///
  /// In zh, this message translates to:
  /// **'假單'**
  String get myLeaves;

  /// No description provided for @noLeaves.
  ///
  /// In zh, this message translates to:
  /// **'沒有假單'**
  String get noLeaves;

  /// No description provided for @applyLeave.
  ///
  /// In zh, this message translates to:
  /// **'請假申請'**
  String get applyLeave;

  /// No description provided for @cancelLeave.
  ///
  /// In zh, this message translates to:
  /// **'銷假申請'**
  String get cancelLeave;

  /// No description provided for @recordCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 筆'**
  String recordCount(int count);

  /// No description provided for @library.
  ///
  /// In zh, this message translates to:
  /// **'我的圖書館'**
  String get library;

  /// No description provided for @loansOverdue.
  ///
  /// In zh, this message translates to:
  /// **'逾期'**
  String get loansOverdue;

  /// No description provided for @loansNextDue.
  ///
  /// In zh, this message translates to:
  /// **'最近到期'**
  String get loansNextDue;

  /// No description provided for @onLoan.
  ///
  /// In zh, this message translates to:
  /// **'借閱中'**
  String get onLoan;

  /// No description provided for @noLoans.
  ///
  /// In zh, this message translates to:
  /// **'沒有借閱中的書'**
  String get noLoans;

  /// No description provided for @bookCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 本'**
  String bookCount(int count);

  /// No description provided for @dueToday.
  ///
  /// In zh, this message translates to:
  /// **'今天到期'**
  String get dueToday;

  /// No description provided for @daysOverdue.
  ///
  /// In zh, this message translates to:
  /// **'逾期 {count} 天'**
  String daysOverdue(int count);

  /// No description provided for @holdsReady.
  ///
  /// In zh, this message translates to:
  /// **'{count} 本預約書可取'**
  String holdsReady(int count);

  /// No description provided for @heldUntil.
  ///
  /// In zh, this message translates to:
  /// **'保留至 {date}'**
  String heldUntil(String date);

  /// No description provided for @loansAndRenewals.
  ///
  /// In zh, this message translates to:
  /// **'借閱與續借'**
  String get loansAndRenewals;

  /// No description provided for @loanDue.
  ///
  /// In zh, this message translates to:
  /// **'{date} 到期'**
  String loanDue(String date);

  /// No description provided for @loanDaysLeft.
  ///
  /// In zh, this message translates to:
  /// **'剩 {count} 天'**
  String loanDaysLeft(int count);

  /// No description provided for @rememberPasswordTitle.
  ///
  /// In zh, this message translates to:
  /// **'記住密碼？'**
  String get rememberPasswordTitle;

  /// No description provided for @rememberPasswordBody.
  ///
  /// In zh, this message translates to:
  /// **'下次需要登入單一入口時自動填入並送出。密碼加密存在這台裝置上。'**
  String get rememberPasswordBody;

  /// No description provided for @notNow.
  ///
  /// In zh, this message translates to:
  /// **'不要'**
  String get notNow;

  /// No description provided for @remember.
  ///
  /// In zh, this message translates to:
  /// **'記住'**
  String get remember;

  /// No description provided for @autoSignIn.
  ///
  /// In zh, this message translates to:
  /// **'自動登入'**
  String get autoSignIn;

  /// No description provided for @deleteSavedPassword.
  ///
  /// In zh, this message translates to:
  /// **'刪除儲存的密碼'**
  String get deleteSavedPassword;

  /// No description provided for @campusConnecting.
  ///
  /// In zh, this message translates to:
  /// **'連線中'**
  String get campusConnecting;

  /// No description provided for @campusFillingIn.
  ///
  /// In zh, this message translates to:
  /// **'自動填入帳號密碼'**
  String get campusFillingIn;

  /// No description provided for @campusVerifying.
  ///
  /// In zh, this message translates to:
  /// **'Cloudflare 驗證'**
  String get campusVerifying;

  /// No description provided for @campusReading.
  ///
  /// In zh, this message translates to:
  /// **'讀取資料'**
  String get campusReading;

  /// No description provided for @showPage.
  ///
  /// In zh, this message translates to:
  /// **'顯示網頁'**
  String get showPage;

  /// No description provided for @librarySearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜尋館藏、期刊、資料庫'**
  String get librarySearchHint;

  /// No description provided for @kindCatalog.
  ///
  /// In zh, this message translates to:
  /// **'館藏'**
  String get kindCatalog;

  /// No description provided for @kindJournal.
  ///
  /// In zh, this message translates to:
  /// **'期刊'**
  String get kindJournal;

  /// No description provided for @kindDatabase.
  ///
  /// In zh, this message translates to:
  /// **'資料庫'**
  String get kindDatabase;

  /// No description provided for @onShelf.
  ///
  /// In zh, this message translates to:
  /// **'在架'**
  String get onShelf;

  /// No description provided for @checkedOut.
  ///
  /// In zh, this message translates to:
  /// **'借出'**
  String get checkedOut;

  /// No description provided for @online.
  ///
  /// In zh, this message translates to:
  /// **'線上全文'**
  String get online;

  /// No description provided for @typeBooks.
  ///
  /// In zh, this message translates to:
  /// **'圖書'**
  String get typeBooks;

  /// No description provided for @typeDissertations.
  ///
  /// In zh, this message translates to:
  /// **'學位論文'**
  String get typeDissertations;

  /// No description provided for @typeVideos.
  ///
  /// In zh, this message translates to:
  /// **'影音'**
  String get typeVideos;

  /// No description provided for @sortRelevance.
  ///
  /// In zh, this message translates to:
  /// **'相關性'**
  String get sortRelevance;

  /// No description provided for @sortNewest.
  ///
  /// In zh, this message translates to:
  /// **'新到舊'**
  String get sortNewest;

  /// No description provided for @sortTitle.
  ///
  /// In zh, this message translates to:
  /// **'題名'**
  String get sortTitle;

  /// No description provided for @anyTime.
  ///
  /// In zh, this message translates to:
  /// **'不限'**
  String get anyTime;

  /// No description provided for @lastYears.
  ///
  /// In zh, this message translates to:
  /// **'近 {count} 年'**
  String lastYears(int count);

  /// No description provided for @filter.
  ///
  /// In zh, this message translates to:
  /// **'篩選'**
  String get filter;

  /// No description provided for @filterAvailability.
  ///
  /// In zh, this message translates to:
  /// **'取得方式'**
  String get filterAvailability;

  /// No description provided for @filterType.
  ///
  /// In zh, this message translates to:
  /// **'資源類型'**
  String get filterType;

  /// No description provided for @filterSort.
  ///
  /// In zh, this message translates to:
  /// **'排序'**
  String get filterSort;

  /// No description provided for @filterYear.
  ///
  /// In zh, this message translates to:
  /// **'出版年'**
  String get filterYear;

  /// No description provided for @showResults.
  ///
  /// In zh, this message translates to:
  /// **'顯示結果'**
  String get showResults;

  /// No description provided for @resultCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 筆'**
  String resultCount(int count);

  /// No description provided for @holdings.
  ///
  /// In zh, this message translates to:
  /// **'館藏'**
  String get holdings;

  /// No description provided for @requestHold.
  ///
  /// In zh, this message translates to:
  /// **'預約'**
  String get requestHold;

  /// No description provided for @readOnline.
  ///
  /// In zh, this message translates to:
  /// **'線上閱讀'**
  String get readOnline;

  /// No description provided for @cite.
  ///
  /// In zh, this message translates to:
  /// **'引用'**
  String get cite;

  /// No description provided for @citationCopied.
  ///
  /// In zh, this message translates to:
  /// **'已複製引用'**
  String get citationCopied;

  /// No description provided for @bibDetails.
  ///
  /// In zh, this message translates to:
  /// **'詳細書目'**
  String get bibDetails;

  /// No description provided for @publisher.
  ///
  /// In zh, this message translates to:
  /// **'出版者'**
  String get publisher;

  /// No description provided for @subjects.
  ///
  /// In zh, this message translates to:
  /// **'主題'**
  String get subjects;

  /// No description provided for @collections.
  ///
  /// In zh, this message translates to:
  /// **'主題館藏'**
  String get collections;

  /// No description provided for @newBooks.
  ///
  /// In zh, this message translates to:
  /// **'新進圖書'**
  String get newBooks;

  /// No description provided for @noBooks.
  ///
  /// In zh, this message translates to:
  /// **'沒有書目'**
  String get noBooks;

  /// No description provided for @libraryCollections.
  ///
  /// In zh, this message translates to:
  /// **'館藏'**
  String get libraryCollections;

  /// No description provided for @renewAll.
  ///
  /// In zh, this message translates to:
  /// **'全部續借'**
  String get renewAll;

  /// No description provided for @renew.
  ///
  /// In zh, this message translates to:
  /// **'續借'**
  String get renew;

  /// No description provided for @notRenewable.
  ///
  /// In zh, this message translates to:
  /// **'不可續借'**
  String get notRenewable;

  /// No description provided for @dueDate.
  ///
  /// In zh, this message translates to:
  /// **'到期'**
  String get dueDate;

  /// No description provided for @renewPending.
  ///
  /// In zh, this message translates to:
  /// **'續借申請已送出'**
  String get renewPending;

  /// No description provided for @renewFailed.
  ///
  /// In zh, this message translates to:
  /// **'無法續借'**
  String get renewFailed;

  /// No description provided for @renewedCount.
  ///
  /// In zh, this message translates to:
  /// **'已續借 {renewed} / {total} 本'**
  String renewedCount(int renewed, int total);

  /// No description provided for @cancelHoldFailed.
  ///
  /// In zh, this message translates to:
  /// **'無法取消預約'**
  String get cancelHoldFailed;

  /// No description provided for @holds.
  ///
  /// In zh, this message translates to:
  /// **'預約'**
  String get holds;

  /// No description provided for @holdReady.
  ///
  /// In zh, this message translates to:
  /// **'可取'**
  String get holdReady;

  /// No description provided for @holdWaiting.
  ///
  /// In zh, this message translates to:
  /// **'等待中'**
  String get holdWaiting;

  /// No description provided for @cancelHoldTitle.
  ///
  /// In zh, this message translates to:
  /// **'取消預約？'**
  String get cancelHoldTitle;

  /// No description provided for @cancelHold.
  ///
  /// In zh, this message translates to:
  /// **'取消預約'**
  String get cancelHold;

  /// No description provided for @keepHold.
  ///
  /// In zh, this message translates to:
  /// **'保留'**
  String get keepHold;

  /// No description provided for @libraryDiscovery.
  ///
  /// In zh, this message translates to:
  /// **'圖書館資源探索'**
  String get libraryDiscovery;

  /// No description provided for @viewAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get viewAll;

  /// No description provided for @otherCollections.
  ///
  /// In zh, this message translates to:
  /// **'其他主題館藏'**
  String get otherCollections;

  /// No description provided for @allCollections.
  ///
  /// In zh, this message translates to:
  /// **'全部 {count} 個'**
  String allCollections(int count);

  /// No description provided for @studySpace.
  ///
  /// In zh, this message translates to:
  /// **'自學空間'**
  String get studySpace;

  /// No description provided for @scanToCheckIn.
  ///
  /// In zh, this message translates to:
  /// **'掃描報到・開門'**
  String get scanToCheckIn;

  /// No description provided for @openHours.
  ///
  /// In zh, this message translates to:
  /// **'開放'**
  String get openHours;

  /// No description provided for @validFor.
  ///
  /// In zh, this message translates to:
  /// **'有效'**
  String get validFor;

  /// No description provided for @refreshing.
  ///
  /// In zh, this message translates to:
  /// **'更新中'**
  String get refreshing;

  /// No description provided for @refresh.
  ///
  /// In zh, this message translates to:
  /// **'重新整理'**
  String get refresh;

  /// No description provided for @available.
  ///
  /// In zh, this message translates to:
  /// **'可前往'**
  String get available;

  /// No description provided for @bookSpace.
  ///
  /// In zh, this message translates to:
  /// **'預約'**
  String get bookSpace;

  /// No description provided for @updatesIn.
  ///
  /// In zh, this message translates to:
  /// **'{count} 秒後更新'**
  String updatesIn(int count);

  /// No description provided for @designLanguage.
  ///
  /// In zh, this message translates to:
  /// **'設計語言'**
  String get designLanguage;

  /// No description provided for @dlColors.
  ///
  /// In zh, this message translates to:
  /// **'色彩'**
  String get dlColors;

  /// No description provided for @dlCorners.
  ///
  /// In zh, this message translates to:
  /// **'圓角'**
  String get dlCorners;

  /// No description provided for @dlSpacing.
  ///
  /// In zh, this message translates to:
  /// **'間距'**
  String get dlSpacing;

  /// No description provided for @dlType.
  ///
  /// In zh, this message translates to:
  /// **'字體'**
  String get dlType;

  /// No description provided for @dlComponents.
  ///
  /// In zh, this message translates to:
  /// **'元件'**
  String get dlComponents;

  /// No description provided for @dlFunctional.
  ///
  /// In zh, this message translates to:
  /// **'功能色'**
  String get dlFunctional;

  /// No description provided for @dlIdentity.
  ///
  /// In zh, this message translates to:
  /// **'識別色'**
  String get dlIdentity;

  /// No description provided for @dlRoleNow.
  ///
  /// In zh, this message translates to:
  /// **'目前・選取'**
  String get dlRoleNow;

  /// No description provided for @dlRoleNext.
  ///
  /// In zh, this message translates to:
  /// **'下一個・行程'**
  String get dlRoleNext;

  /// No description provided for @dlRoleDue.
  ///
  /// In zh, this message translates to:
  /// **'到期・注意'**
  String get dlRoleDue;

  /// No description provided for @dlRoleUnread.
  ///
  /// In zh, this message translates to:
  /// **'未讀'**
  String get dlRoleUnread;

  /// No description provided for @aboutApp.
  ///
  /// In zh, this message translates to:
  /// **'App'**
  String get aboutApp;

  /// No description provided for @loadingCollections.
  ///
  /// In zh, this message translates to:
  /// **'讀取館藏清單'**
  String get loadingCollections;

  /// No description provided for @loadingShelves.
  ///
  /// In zh, this message translates to:
  /// **'讀取新書與暢銷榜'**
  String get loadingShelves;

  /// No description provided for @events.
  ///
  /// In zh, this message translates to:
  /// **'活動報名'**
  String get events;

  /// No description provided for @searchEvents.
  ///
  /// In zh, this message translates to:
  /// **'搜尋活動'**
  String get searchEvents;

  /// No description provided for @searchFor.
  ///
  /// In zh, this message translates to:
  /// **'搜尋「{query}」'**
  String searchFor(String query);

  /// No description provided for @within3Days.
  ///
  /// In zh, this message translates to:
  /// **'3 日內'**
  String get within3Days;

  /// No description provided for @withinWeek.
  ///
  /// In zh, this message translates to:
  /// **'一週內'**
  String get withinWeek;

  /// No description provided for @withinMonth.
  ///
  /// In zh, this message translates to:
  /// **'一個月內'**
  String get withinMonth;

  /// No description provided for @allTime.
  ///
  /// In zh, this message translates to:
  /// **'全部時間'**
  String get allTime;

  /// No description provided for @eventsOpen.
  ///
  /// In zh, this message translates to:
  /// **'接受報名中'**
  String get eventsOpen;

  /// No description provided for @eventsOngoing.
  ///
  /// In zh, this message translates to:
  /// **'活動進行中'**
  String get eventsOngoing;

  /// No description provided for @eventsClosed.
  ///
  /// In zh, this message translates to:
  /// **'已截止報名'**
  String get eventsClosed;

  /// No description provided for @anyStatus.
  ///
  /// In zh, this message translates to:
  /// **'全部狀態'**
  String get anyStatus;

  /// No description provided for @eventCategory.
  ///
  /// In zh, this message translates to:
  /// **'類別'**
  String get eventCategory;

  /// No description provided for @anyCategory.
  ///
  /// In zh, this message translates to:
  /// **'全部類別'**
  String get anyCategory;

  /// No description provided for @myEvents.
  ///
  /// In zh, this message translates to:
  /// **'我的活動'**
  String get myEvents;

  /// No description provided for @nextSignedUp.
  ///
  /// In zh, this message translates to:
  /// **'下一場・已報名'**
  String get nextSignedUp;

  /// No description provided for @inDays.
  ///
  /// In zh, this message translates to:
  /// **'{count} 天後'**
  String inDays(int count);

  /// No description provided for @waitlistSpots.
  ///
  /// In zh, this message translates to:
  /// **'備取 {taken}/{total}'**
  String waitlistSpots(int taken, int total);

  /// No description provided for @waitlistOnly.
  ///
  /// In zh, this message translates to:
  /// **'正取已滿・備取 {taken} / {total}'**
  String waitlistOnly(int taken, int total);

  /// No description provided for @externalSignUp.
  ///
  /// In zh, this message translates to:
  /// **'外部報名'**
  String get externalSignUp;

  /// No description provided for @signUpClosed.
  ///
  /// In zh, this message translates to:
  /// **'已截止'**
  String get signUpClosed;

  /// No description provided for @signedUp.
  ///
  /// In zh, this message translates to:
  /// **'已報名'**
  String get signedUp;

  /// No description provided for @eventFull.
  ///
  /// In zh, this message translates to:
  /// **'額滿'**
  String get eventFull;

  /// No description provided for @happeningNow.
  ///
  /// In zh, this message translates to:
  /// **'進行中'**
  String get happeningNow;

  /// No description provided for @eventDate.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get eventDate;

  /// No description provided for @eventPlace.
  ///
  /// In zh, this message translates to:
  /// **'地點'**
  String get eventPlace;

  /// No description provided for @eventOrganizer.
  ///
  /// In zh, this message translates to:
  /// **'承辦'**
  String get eventOrganizer;

  /// No description provided for @eventContact.
  ///
  /// In zh, this message translates to:
  /// **'聯絡'**
  String get eventContact;

  /// No description provided for @eventIntro.
  ///
  /// In zh, this message translates to:
  /// **'活動介紹'**
  String get eventIntro;

  /// No description provided for @signUp.
  ///
  /// In zh, this message translates to:
  /// **'報名'**
  String get signUp;

  /// No description provided for @signUpWaitlist.
  ///
  /// In zh, this message translates to:
  /// **'報名備取'**
  String get signUpWaitlist;

  /// No description provided for @goSignUp.
  ///
  /// In zh, this message translates to:
  /// **'前往報名'**
  String get goSignUp;

  /// No description provided for @cancelSignUp.
  ///
  /// In zh, this message translates to:
  /// **'取消報名'**
  String get cancelSignUp;

  /// No description provided for @cancelSignUpTitle.
  ///
  /// In zh, this message translates to:
  /// **'取消報名？'**
  String get cancelSignUpTitle;

  /// No description provided for @keepSignUp.
  ///
  /// In zh, this message translates to:
  /// **'保留'**
  String get keepSignUp;

  /// No description provided for @signUpName.
  ///
  /// In zh, this message translates to:
  /// **'報名者姓名'**
  String get signUpName;

  /// No description provided for @signUpEmail.
  ///
  /// In zh, this message translates to:
  /// **'報名信箱'**
  String get signUpEmail;

  /// No description provided for @submit.
  ///
  /// In zh, this message translates to:
  /// **'送出'**
  String get submit;

  /// No description provided for @noMatchingEvents.
  ///
  /// In zh, this message translates to:
  /// **'沒有符合的活動'**
  String get noMatchingEvents;

  /// No description provided for @searchAnyTimeStatus.
  ///
  /// In zh, this message translates to:
  /// **'搜尋全部時間與狀態'**
  String get searchAnyTimeStatus;

  /// No description provided for @eventsAttended.
  ///
  /// In zh, this message translates to:
  /// **'已參加・{hours} 小時'**
  String eventsAttended(String hours);

  /// No description provided for @pastEvents.
  ///
  /// In zh, this message translates to:
  /// **'歷史活動'**
  String get pastEvents;

  /// No description provided for @noEventRecords.
  ///
  /// In zh, this message translates to:
  /// **'沒有紀錄'**
  String get noEventRecords;

  /// No description provided for @signUpFailed.
  ///
  /// In zh, this message translates to:
  /// **'無法報名'**
  String get signUpFailed;

  /// No description provided for @cancelSignUpFailed.
  ///
  /// In zh, this message translates to:
  /// **'無法取消報名'**
  String get cancelSignUpFailed;

  /// No description provided for @ptTitle.
  ///
  /// In zh, this message translates to:
  /// **'學習暨勞僱時數'**
  String get ptTitle;

  /// No description provided for @ptSelect.
  ///
  /// In zh, this message translates to:
  /// **'選取'**
  String get ptSelect;

  /// No description provided for @ptDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get ptDone;

  /// No description provided for @ptMonth.
  ///
  /// In zh, this message translates to:
  /// **'{year} 年 {month} 月'**
  String ptMonth(int year, int month);

  /// No description provided for @ptAllUnits.
  ///
  /// In zh, this message translates to:
  /// **'所有單位'**
  String get ptAllUnits;

  /// No description provided for @ptUnconfirmed.
  ///
  /// In zh, this message translates to:
  /// **'未確認'**
  String get ptUnconfirmed;

  /// No description provided for @ptConfirmed.
  ///
  /// In zh, this message translates to:
  /// **'已確認'**
  String get ptConfirmed;

  /// No description provided for @ptPaid.
  ///
  /// In zh, this message translates to:
  /// **'已報帳'**
  String get ptPaid;

  /// No description provided for @ptHours.
  ///
  /// In zh, this message translates to:
  /// **'{hours} 小時'**
  String ptHours(String hours);

  /// No description provided for @ptWeek.
  ///
  /// In zh, this message translates to:
  /// **'本週 {used} / {limit} 小時'**
  String ptWeek(String used, int limit);

  /// No description provided for @ptOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get ptOther;

  /// No description provided for @ptPayroll.
  ///
  /// In zh, this message translates to:
  /// **'付款清冊'**
  String get ptPayroll;

  /// No description provided for @ptPrint.
  ///
  /// In zh, this message translates to:
  /// **'列印簽到退表與批號'**
  String get ptPrint;

  /// No description provided for @ptAdd.
  ///
  /// In zh, this message translates to:
  /// **'新增時數'**
  String get ptAdd;

  /// No description provided for @ptDate.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get ptDate;

  /// No description provided for @ptUnit.
  ///
  /// In zh, this message translates to:
  /// **'單位'**
  String get ptUnit;

  /// No description provided for @ptTime.
  ///
  /// In zh, this message translates to:
  /// **'時間'**
  String get ptTime;

  /// No description provided for @ptWork.
  ///
  /// In zh, this message translates to:
  /// **'內容'**
  String get ptWork;

  /// No description provided for @ptStage.
  ///
  /// In zh, this message translates to:
  /// **'加入待儲存'**
  String get ptStage;

  /// No description provided for @ptStaged.
  ///
  /// In zh, this message translates to:
  /// **'待儲存 {count} 筆・{hours} 小時'**
  String ptStaged(int count, String hours);

  /// No description provided for @ptSaveCount.
  ///
  /// In zh, this message translates to:
  /// **'儲存 {count} 筆'**
  String ptSaveCount(int count);

  /// No description provided for @ptSaveTitle.
  ///
  /// In zh, this message translates to:
  /// **'儲存 {count} 筆時數？'**
  String ptSaveTitle(int count);

  /// No description provided for @ptSave.
  ///
  /// In zh, this message translates to:
  /// **'儲存'**
  String get ptSave;

  /// No description provided for @ptEndAfterStart.
  ///
  /// In zh, this message translates to:
  /// **'結束時間要晚於開始時間'**
  String get ptEndAfterStart;

  /// No description provided for @ptOverlap.
  ///
  /// In zh, this message translates to:
  /// **'與 {slot} 重疊'**
  String ptOverlap(String slot);

  /// No description provided for @ptWeekOver.
  ///
  /// In zh, this message translates to:
  /// **'本週會到 {total} 小時，超過每週 {limit} 小時'**
  String ptWeekOver(String total, int limit);

  /// No description provided for @ptDeleteCount.
  ///
  /// In zh, this message translates to:
  /// **'刪除 {count} 筆'**
  String ptDeleteCount(int count);

  /// No description provided for @ptDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'刪除 {count} 筆時數？'**
  String ptDeleteTitle(int count);

  /// No description provided for @ptDelete.
  ///
  /// In zh, this message translates to:
  /// **'刪除'**
  String get ptDelete;

  /// No description provided for @ptSelected.
  ///
  /// In zh, this message translates to:
  /// **'已選 {count} 筆'**
  String ptSelected(int count);

  /// No description provided for @ptNoRecords.
  ///
  /// In zh, this message translates to:
  /// **'沒有時數紀錄'**
  String get ptNoRecords;

  /// No description provided for @ptSearchUnits.
  ///
  /// In zh, this message translates to:
  /// **'搜尋單位'**
  String get ptSearchUnits;

  /// No description provided for @ptMyUnits.
  ///
  /// In zh, this message translates to:
  /// **'我的單位'**
  String get ptMyUnits;

  /// No description provided for @ptBatch.
  ///
  /// In zh, this message translates to:
  /// **'批號'**
  String get ptBatch;

  /// No description provided for @ptSheet.
  ///
  /// In zh, this message translates to:
  /// **'簽到退表'**
  String get ptSheet;

  /// No description provided for @ptOpenSheet.
  ///
  /// In zh, this message translates to:
  /// **'開啟簽到退表'**
  String get ptOpenSheet;

  /// No description provided for @ptNet.
  ///
  /// In zh, this message translates to:
  /// **'實領'**
  String get ptNet;

  /// No description provided for @ptGross.
  ///
  /// In zh, this message translates to:
  /// **'應支金額'**
  String get ptGross;

  /// No description provided for @ptWage.
  ///
  /// In zh, this message translates to:
  /// **'應領金額'**
  String get ptWage;

  /// No description provided for @ptEmpLabor.
  ///
  /// In zh, this message translates to:
  /// **'機關勞保'**
  String get ptEmpLabor;

  /// No description provided for @ptEmpPension.
  ///
  /// In zh, this message translates to:
  /// **'機關勞退'**
  String get ptEmpPension;

  /// No description provided for @ptEmpHealth.
  ///
  /// In zh, this message translates to:
  /// **'機關健保'**
  String get ptEmpHealth;

  /// No description provided for @ptEmpSupp.
  ///
  /// In zh, this message translates to:
  /// **'機關負擔補充保費'**
  String get ptEmpSupp;

  /// No description provided for @ptDeduct.
  ///
  /// In zh, this message translates to:
  /// **'代扣款項'**
  String get ptDeduct;

  /// No description provided for @ptTax.
  ///
  /// In zh, this message translates to:
  /// **'所得稅'**
  String get ptTax;

  /// No description provided for @ptLabor.
  ///
  /// In zh, this message translates to:
  /// **'勞保'**
  String get ptLabor;

  /// No description provided for @ptPension.
  ///
  /// In zh, this message translates to:
  /// **'勞退'**
  String get ptPension;

  /// No description provided for @ptHealth.
  ///
  /// In zh, this message translates to:
  /// **'健保'**
  String get ptHealth;

  /// No description provided for @ptSupp.
  ///
  /// In zh, this message translates to:
  /// **'個人補充保費'**
  String get ptSupp;

  /// No description provided for @ptOtherDeduct.
  ///
  /// In zh, this message translates to:
  /// **'其他代扣款'**
  String get ptOtherDeduct;

  /// No description provided for @ptSubtotal.
  ///
  /// In zh, this message translates to:
  /// **'小計'**
  String get ptSubtotal;

  /// No description provided for @ptHoliday.
  ///
  /// In zh, this message translates to:
  /// **'例假日'**
  String get ptHoliday;

  /// No description provided for @ptEntries.
  ///
  /// In zh, this message translates to:
  /// **'{count} 筆'**
  String ptEntries(int count);

  /// No description provided for @demoMode.
  ///
  /// In zh, this message translates to:
  /// **'Demo 模式'**
  String get demoMode;

  /// No description provided for @demoModeDetail.
  ///
  /// In zh, this message translates to:
  /// **'ALPHA 功能顯示模擬資料'**
  String get demoModeDetail;

  /// No description provided for @drTitle.
  ///
  /// In zh, this message translates to:
  /// **'宿舍維修'**
  String get drTitle;

  /// No description provided for @drRequest.
  ///
  /// In zh, this message translates to:
  /// **'申請維修'**
  String get drRequest;

  /// No description provided for @drHistory.
  ///
  /// In zh, this message translates to:
  /// **'歷次申請'**
  String get drHistory;

  /// No description provided for @drNone.
  ///
  /// In zh, this message translates to:
  /// **'沒有申請紀錄'**
  String get drNone;

  /// No description provided for @drRoom.
  ///
  /// In zh, this message translates to:
  /// **'寢號及床位'**
  String get drRoom;

  /// No description provided for @drRoomHint.
  ///
  /// In zh, this message translates to:
  /// **'例：3316A、1325、A301、5108-1'**
  String get drRoomHint;

  /// No description provided for @drRoomInvalid.
  ///
  /// In zh, this message translates to:
  /// **'只接受 3316A、1325、A301、5108-1 這四種格式'**
  String get drRoomInvalid;

  /// No description provided for @drEmailHint.
  ///
  /// In zh, this message translates to:
  /// **'修好後寄到這裡'**
  String get drEmailHint;

  /// No description provided for @drEmailInvalid.
  ///
  /// In zh, this message translates to:
  /// **'E-mail 格式不正確'**
  String get drEmailInvalid;

  /// No description provided for @drMemo.
  ///
  /// In zh, this message translates to:
  /// **'維修項目及損壞情形'**
  String get drMemo;

  /// No description provided for @drMemoHint.
  ///
  /// In zh, this message translates to:
  /// **'哪裡壞了、什麼情形'**
  String get drMemoHint;

  /// No description provided for @drPresence.
  ///
  /// In zh, this message translates to:
  /// **'是否需要住宿生在場'**
  String get drPresence;

  /// No description provided for @drNoNeed.
  ///
  /// In zh, this message translates to:
  /// **'不需要'**
  String get drNoNeed;

  /// No description provided for @drNeed.
  ///
  /// In zh, this message translates to:
  /// **'需要在場'**
  String get drNeed;

  /// No description provided for @drNoNeedNote.
  ///
  /// In zh, this message translates to:
  /// **'管理員直接前往維修，修好後寄 E-mail 通知；請告知室友，貴重物品自行保管'**
  String get drNoNeedNote;

  /// No description provided for @drNeedNote.
  ///
  /// In zh, this message translates to:
  /// **'請到宿舍服務中心約維修時間'**
  String get drNeedNote;

  /// No description provided for @drRemember.
  ///
  /// In zh, this message translates to:
  /// **'記住寢號與 E-mail'**
  String get drRemember;

  /// No description provided for @drSubmitTitle.
  ///
  /// In zh, this message translates to:
  /// **'送出維修申請？'**
  String get drSubmitTitle;

  /// No description provided for @drResultTo.
  ///
  /// In zh, this message translates to:
  /// **'結果寄到 {email}'**
  String drResultTo(String email);

  /// No description provided for @payTitle.
  ///
  /// In zh, this message translates to:
  /// **'付款及所得'**
  String get payTitle;

  /// No description provided for @payYear.
  ///
  /// In zh, this message translates to:
  /// **'{year} 年'**
  String payYear(int year);

  /// No description provided for @payReceived.
  ///
  /// In zh, this message translates to:
  /// **'{year} 年已入帳・{count} 筆'**
  String payReceived(int year, int count);

  /// No description provided for @payMonth.
  ///
  /// In zh, this message translates to:
  /// **'{month} 月'**
  String payMonth(int month);

  /// No description provided for @payCase.
  ///
  /// In zh, this message translates to:
  /// **'案號'**
  String get payCase;

  /// No description provided for @payHandler.
  ///
  /// In zh, this message translates to:
  /// **'經手人'**
  String get payHandler;

  /// No description provided for @payAccount.
  ///
  /// In zh, this message translates to:
  /// **'入帳帳號'**
  String get payAccount;

  /// No description provided for @payInvoice.
  ///
  /// In zh, this message translates to:
  /// **'發票'**
  String get payInvoice;

  /// No description provided for @payNone.
  ///
  /// In zh, this message translates to:
  /// **'沒有付款紀錄'**
  String get payNone;

  /// No description provided for @incomeTitle.
  ///
  /// In zh, this message translates to:
  /// **'年度所得'**
  String get incomeTitle;

  /// No description provided for @incomeYear.
  ///
  /// In zh, this message translates to:
  /// **'{year} 年度'**
  String incomeYear(int year);

  /// No description provided for @incomeNet.
  ///
  /// In zh, this message translates to:
  /// **'給付淨額'**
  String get incomeNet;

  /// No description provided for @incomeGross.
  ///
  /// In zh, this message translates to:
  /// **'給付總額'**
  String get incomeGross;

  /// No description provided for @incomeTax.
  ///
  /// In zh, this message translates to:
  /// **'扣繳稅額'**
  String get incomeTax;

  /// No description provided for @incomePension.
  ///
  /// In zh, this message translates to:
  /// **'勞退自提'**
  String get incomePension;

  /// No description provided for @incomeDetail.
  ///
  /// In zh, this message translates to:
  /// **'所得明細表'**
  String get incomeDetail;

  /// No description provided for @incomeWithholding.
  ///
  /// In zh, this message translates to:
  /// **'扣繳憑單'**
  String get incomeWithholding;

  /// No description provided for @incomeNone.
  ///
  /// In zh, this message translates to:
  /// **'沒有所得資料'**
  String get incomeNone;
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
