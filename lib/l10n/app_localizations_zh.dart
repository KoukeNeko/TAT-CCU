// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get navToday => '今天';

  @override
  String get navTimetable => '課表';

  @override
  String get navCourses => '課程';

  @override
  String get navCalendar => '日曆';

  @override
  String get navMore => '更多';

  @override
  String get signInPortal => '登入單一入口';

  @override
  String get retry => '重試';

  @override
  String updatedAt(String time) {
    return '更新於 $time';
  }

  @override
  String get loadFailed => '無法載入';

  @override
  String get toDo => '待辦';

  @override
  String get nothingDueSoon => '14 天內沒有到期項目';

  @override
  String get unitHours => '小時';

  @override
  String get unitDays => '天';

  @override
  String get unitMinutes => '分鐘';

  @override
  String get unitMinutesLater => '分鐘後';

  @override
  String get todayNoClasses => '今天沒有課';

  @override
  String get todayClassesOver => '今天的課結束了';

  @override
  String todayClassesLeft(String count) {
    String _temp0 = intl.Intl.selectLogic(count, {
      '1': '一',
      '2': '兩',
      '3': '三',
      '4': '四',
      '5': '五',
      '6': '六',
      '7': '七',
      '8': '八',
      '9': '九',
      '10': '十',
      'other': ' $count ',
    });
    return '今天還有$_temp0堂課';
  }

  @override
  String get inClass => '上課中';

  @override
  String untilTime(String time) {
    return '到 $time';
  }

  @override
  String get nextClass => '下一堂';

  @override
  String startsAt(String time) {
    return '$time 開始';
  }

  @override
  String get dueThisWeek => '本週到期';

  @override
  String get unread => '未讀';

  @override
  String unreadDetail(int notices, int mail) {
    return '通知 $notices・信件 $mail';
  }

  @override
  String get notifications => '通知';

  @override
  String notificationsUnread(int count) {
    return '通知，$count 則未讀';
  }

  @override
  String get mail => '信件';

  @override
  String get noNotifications => '沒有通知';

  @override
  String get noMail => '沒有信件';

  @override
  String monthTitle(String month) {
    return '$month 月';
  }

  @override
  String yearMonthTitle(int year, String month) {
    return '$year 年 $month 月';
  }

  @override
  String get goToToday => '今天';

  @override
  String itemCount(int count) {
    return '$count 項';
  }

  @override
  String get noEventsThisDay => '這天沒有事件';

  @override
  String get academicSystem => '學籍系統';

  @override
  String get academicRecord => '學籍資料';

  @override
  String get studentNo => '學號';

  @override
  String get englishName => '英文姓名';

  @override
  String get email => '電子郵件';

  @override
  String get mobile => '行動電話';

  @override
  String get onSchoolWebsite => '在學校網站辦理';

  @override
  String get editNameContact => '修改英文姓名與聯絡資料';

  @override
  String get studentPhoto => '學生照片';

  @override
  String get enrollmentCertificate => '在學證明書';

  @override
  String get generating => '產生中';

  @override
  String get generate => '產生';

  @override
  String get regenerate => '重新產生';

  @override
  String get open => '開啟';

  @override
  String get share => '分享';

  @override
  String get notYetThisSemester => '本學期尚未產生';

  @override
  String validPrinted(String date) {
    return '有效・列印日 $date';
  }

  @override
  String expiredPrinted(String date) {
    return '已過期・列印日 $date';
  }

  @override
  String savedToDevice(String time) {
    return '已存到裝置 $time';
  }

  @override
  String get notPdf => '學校回傳的不是 PDF';

  @override
  String get courseSelection => '選課系統';

  @override
  String get viewInApp => '在 App 查看';

  @override
  String courseCountShort(int count) {
    return '$count 門';
  }

  @override
  String get selectionQuery => '選課查詢';

  @override
  String thisSemesterCredits(String credits) {
    return '本學期・$credits 學分';
  }

  @override
  String typeCredits(String type, String credits) {
    return '$type $credits 學分';
  }

  @override
  String get courseChanges => '開排課異動查詢';

  @override
  String get schoolwideChanges => '全校本學期異動';

  @override
  String get myApplications => '我的申請';

  @override
  String get applicationsHint => '加簽、超短修、校際、棄選、學程';

  @override
  String kindCount(String kind, int count) {
    return '$kind $count 筆';
  }

  @override
  String get programs => '跨領域學程';

  @override
  String get programsDetail => '學程與開設單位';

  @override
  String get notOpen => '未開放';

  @override
  String get noData => '沒有資料';

  @override
  String get academics => '學業';

  @override
  String get grades => '成績';

  @override
  String courseCount(int count) {
    return '$count 門課';
  }

  @override
  String get campus => '校園';

  @override
  String get allCampusSystems => '全部校務系統';

  @override
  String get account => '帳號';

  @override
  String get ecourseSignedIn => 'eCourse2 已登入';

  @override
  String get ecourseSignedOut => 'eCourse2 未登入';

  @override
  String get portalShared => '單一入口共用';

  @override
  String get campusSystems => '校務系統';

  @override
  String get searchSystems => '搜尋系統';

  @override
  String get favorites => '常用';

  @override
  String get edit => '編輯';

  @override
  String get replaceWith => '換成';

  @override
  String get settings => '設定';

  @override
  String get appearance => '外觀';

  @override
  String get language => '語言';

  @override
  String get followSystem => '跟隨系統';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get recentlyOpened => '最近開啟';

  @override
  String favoritesCount(int count, int max) {
    return '常用（$count/$max）';
  }

  @override
  String get noGrades => '還沒有成績';

  @override
  String get itemNotFound => '找不到這個項目';

  @override
  String get stepOpens => '開放';

  @override
  String get stepSubmitted => '繳交';

  @override
  String get notSubmitted => '未繳交';

  @override
  String get stepDue => '截止';

  @override
  String get stepGrade => '成績';

  @override
  String get mySubmission => '我的繳交';

  @override
  String get description => '說明';

  @override
  String get attachments => '附件';

  @override
  String get stepAttempted => '作答';

  @override
  String get notAttempted => '未作答';

  @override
  String get stepCloses => '關閉';

  @override
  String get quizSettings => '設定';

  @override
  String get quizStart => '開始';

  @override
  String get quizEnd => '結束';

  @override
  String get attemptsAllowed => '允許作答';

  @override
  String get unlimited => '不限次數';

  @override
  String attemptCount(int count) {
    return '$count 次';
  }

  @override
  String get passGrade => '及格分數';

  @override
  String fullMarks(String max) {
    return '滿分 $max';
  }

  @override
  String get noFiles => '沒有檔案';

  @override
  String get filesLabel => '個檔案';

  @override
  String get total => '合計';

  @override
  String get lastUpdated => '最後更新';

  @override
  String fileUpdated(String size, String date) {
    return '$size・$date 更新';
  }

  @override
  String get courseNotFound => '找不到這門課';

  @override
  String get nothingDue => '沒有待辦';

  @override
  String nameDue(String name) {
    return '$name 到期';
  }

  @override
  String get announcementsUnit => '則公告';

  @override
  String get currentGrade => '目前成績';

  @override
  String get courseSection => '課程';

  @override
  String get allSections => '全部章節';

  @override
  String sectionCount(int count) {
    return '$count 個章節';
  }

  @override
  String get announcements => '公告';

  @override
  String postCount(int count) {
    return '$count 則';
  }

  @override
  String hoursLeft(int count) {
    return '$count 小時';
  }

  @override
  String daysLeft(int count) {
    return '$count 天';
  }

  @override
  String get today => '今天';

  @override
  String get tomorrow => '明天';

  @override
  String nextClassAt(String when) {
    return '下次上課　$when';
  }

  @override
  String get noContents => '還沒有課程內容';

  @override
  String dueOn(String date) {
    return '$date 截止';
  }

  @override
  String fileCount(int count) {
    return '$count 個檔案';
  }

  @override
  String get noAnnouncements => '沒有公告';

  @override
  String get noGradeItems => '還沒有成績項目';

  @override
  String get searchCourses => '搜尋課程';

  @override
  String get noMatchingCourses => '沒有符合的課程';

  @override
  String verifiedAt(String time) {
    return '$time 驗證';
  }

  @override
  String get signedOut => '未登入';

  @override
  String get verifyFailed => '驗證失敗';

  @override
  String signedInAs(String name) {
    return '已登入：$name';
  }

  @override
  String get signedInUnverified => '已登入，未驗證';

  @override
  String get verify => '驗證';

  @override
  String get signOut => '登出';

  @override
  String get portalCas => '單一入口（CAS）';

  @override
  String get sharedWithEcourse => '與 eCourse2 共用登入';

  @override
  String get portal => '單一入口';

  @override
  String get openPortal => '開啟單一入口';

  @override
  String signInFailed(String error) {
    return '登入失敗：$error';
  }

  @override
  String get signInWithPortal => '以單一入口登入';

  @override
  String get noClassesThisDay => '這天沒有課';

  @override
  String get unscheduled => '未排時間';

  @override
  String get close => '關閉';

  @override
  String get switchSemester => '切換學期';

  @override
  String semesterLabel(String year, String term) {
    String _temp0 = intl.Intl.selectLogic(term, {
      '1': '上學期',
      '2': '下學期',
      'other': '暑期',
    });
    return '$year 學年$_temp0';
  }

  @override
  String get sectionGeneral => '一般';

  @override
  String eventLabel(String kind, String action) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'assign': '作業',
      'quiz': '測驗',
      'course': '課程事件',
      'user': '個人事件',
      'site': '全校事件',
      'other': '活動',
    });
    String _temp1 = intl.Intl.selectLogic(action, {
      'due': '到期',
      'close': '關閉',
      'open': '開放',
      'other': '',
    });
    return '$_temp0$_temp1';
  }

  @override
  String weekdayShort(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': '一',
      '2': '二',
      '3': '三',
      '4': '四',
      '5': '五',
      '6': '六',
      '7': '日',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String weekdayFull(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': '週一',
      '2': '週二',
      '3': '週三',
      '4': '週四',
      '5': '週五',
      '6': '週六',
      '7': '週日',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get leave => '請假';

  @override
  String get leaveApproved => '已核准';

  @override
  String get leavePending => '審核中';

  @override
  String get leaveCancelled => '已銷假';

  @override
  String get myLeaves => '假單';

  @override
  String get noLeaves => '沒有假單';

  @override
  String get applyLeave => '請假申請';

  @override
  String get cancelLeave => '銷假申請';

  @override
  String recordCount(int count) {
    return '$count 筆';
  }

  @override
  String get library => '我的圖書館';

  @override
  String get loansOverdue => '逾期';

  @override
  String get loansNextDue => '最近到期';

  @override
  String get onLoan => '借閱中';

  @override
  String get noLoans => '沒有借閱中的書';

  @override
  String bookCount(int count) {
    return '$count 本';
  }

  @override
  String get dueToday => '今天到期';

  @override
  String daysOverdue(int count) {
    return '逾期 $count 天';
  }

  @override
  String holdsReady(int count) {
    return '$count 本預約書可取';
  }

  @override
  String heldUntil(String date) {
    return '保留至 $date';
  }

  @override
  String get loansAndRenewals => '借閱與續借';

  @override
  String loanDue(String date) {
    return '$date 到期';
  }

  @override
  String loanDaysLeft(int count) {
    return '剩 $count 天';
  }

  @override
  String get rememberPasswordTitle => '記住密碼？';

  @override
  String get rememberPasswordBody => '下次需要登入單一入口時自動填入並送出。密碼加密存在這台裝置上。';

  @override
  String get notNow => '不要';

  @override
  String get remember => '記住';

  @override
  String get autoSignIn => '自動登入';

  @override
  String get deleteSavedPassword => '刪除儲存的密碼';

  @override
  String get campusConnecting => '連線中';

  @override
  String get campusFillingIn => '自動填入帳號密碼';

  @override
  String get campusVerifying => 'Cloudflare 驗證';

  @override
  String get campusReading => '讀取資料';

  @override
  String get showPage => '顯示網頁';

  @override
  String get librarySearchHint => '搜尋館藏、期刊、資料庫';

  @override
  String get kindCatalog => '館藏';

  @override
  String get kindJournal => '期刊';

  @override
  String get kindDatabase => '資料庫';

  @override
  String get onShelf => '在架';

  @override
  String get checkedOut => '借出';

  @override
  String get online => '線上全文';

  @override
  String get typeBooks => '圖書';

  @override
  String get typeDissertations => '學位論文';

  @override
  String get typeVideos => '影音';

  @override
  String get sortRelevance => '相關性';

  @override
  String get sortNewest => '新到舊';

  @override
  String get sortTitle => '題名';

  @override
  String get anyTime => '全部時間';

  @override
  String lastYears(int count) {
    return '近 $count 年';
  }

  @override
  String get filter => '篩選';

  @override
  String get filterAvailability => '取得方式';

  @override
  String get filterType => '資源類型';

  @override
  String get filterSort => '排序';

  @override
  String get filterYear => '出版年';

  @override
  String get showResults => '顯示結果';

  @override
  String resultCount(int count) {
    return '$count 筆';
  }

  @override
  String get holdings => '館藏';

  @override
  String get requestHold => '預約';

  @override
  String get readOnline => '線上閱讀';

  @override
  String get cite => '引用';

  @override
  String get citationCopied => '已複製引用';

  @override
  String get bibDetails => '詳細書目';

  @override
  String get publisher => '出版者';

  @override
  String get subjects => '主題';

  @override
  String get collections => '主題館藏';

  @override
  String get newBooks => '新進圖書';

  @override
  String get noBooks => '沒有書目';

  @override
  String get libraryCollections => '館藏';

  @override
  String get renewAll => '全部續借';

  @override
  String get renew => '續借';

  @override
  String get notRenewable => '不可續借';

  @override
  String get dueDate => '到期';

  @override
  String get renewPending => '續借申請已送出';

  @override
  String get renewFailed => '無法續借';

  @override
  String renewedCount(int renewed, int total) {
    return '已續借 $renewed / $total 本';
  }

  @override
  String get cancelHoldFailed => '無法取消預約';

  @override
  String get holds => '預約';

  @override
  String get holdReady => '可取';

  @override
  String get holdWaiting => '等待中';

  @override
  String get cancelHoldTitle => '取消預約？';

  @override
  String get cancelHold => '取消預約';

  @override
  String get keepHold => '保留';

  @override
  String get libraryDiscovery => '圖書館資源探索';

  @override
  String get viewAll => '全部';

  @override
  String get otherCollections => '其他主題館藏';

  @override
  String allCollections(int count) {
    return '全部 $count 個';
  }

  @override
  String get studySpace => '自學空間';

  @override
  String get scanToCheckIn => '掃描報到・開門';

  @override
  String get openHours => '開放';

  @override
  String get validFor => '有效';

  @override
  String get refreshing => '更新中';

  @override
  String get refresh => '重新整理';

  @override
  String get available => '可前往';

  @override
  String get bookSpace => '預約';

  @override
  String updatesIn(int count) {
    return '$count 秒後更新';
  }

  @override
  String get designLanguage => '設計語言';

  @override
  String get dlColors => '色彩';

  @override
  String get dlCorners => '圓角';

  @override
  String get dlSpacing => '間距';

  @override
  String get dlType => '字體';

  @override
  String get dlComponents => '元件';

  @override
  String get dlFunctional => '功能色';

  @override
  String get dlIdentity => '識別色';

  @override
  String get dlRoleNow => '目前・選取';

  @override
  String get dlRoleNext => '下一個・行程';

  @override
  String get dlRoleDue => '到期・注意';

  @override
  String get dlRoleUnread => '未讀';

  @override
  String get aboutApp => 'App';

  @override
  String get loadingCollections => '讀取館藏清單';

  @override
  String get loadingShelves => '讀取新書與暢銷榜';

  @override
  String get events => '活動報名';

  @override
  String get searchEvents => '搜尋活動';

  @override
  String searchFor(String query) {
    return '搜尋「$query」';
  }

  @override
  String get within3Days => '3 日內';

  @override
  String get withinWeek => '一週內';

  @override
  String get withinMonth => '一個月內';

  @override
  String get eventsOpen => '接受報名中';

  @override
  String get eventsOngoing => '活動進行中';

  @override
  String get eventsClosed => '已截止報名';

  @override
  String get anyStatus => '全部狀態';

  @override
  String get eventCategory => '類別';

  @override
  String get anyCategory => '全部類別';

  @override
  String get myEvents => '我的活動';

  @override
  String get nextSignedUp => '下一場・已報名';

  @override
  String inDays(int count) {
    return '$count 天後';
  }

  @override
  String waitlistSpots(int taken, int total) {
    return '備取 $taken/$total';
  }

  @override
  String waitlistOnly(int taken, int total) {
    return '正取已滿・備取 $taken / $total';
  }

  @override
  String get externalSignUp => '外部報名';

  @override
  String get signUpClosed => '已截止';

  @override
  String get signedUp => '已報名';

  @override
  String get eventFull => '額滿';

  @override
  String get happeningNow => '進行中';

  @override
  String get eventDate => '日期';

  @override
  String get eventPlace => '地點';

  @override
  String get eventOrganizer => '承辦';

  @override
  String get eventContact => '聯絡';

  @override
  String get eventIntro => '活動介紹';

  @override
  String get signUp => '報名';

  @override
  String get signUpWaitlist => '報名備取';

  @override
  String get goSignUp => '前往報名';

  @override
  String get cancelSignUp => '取消報名';

  @override
  String get cancelSignUpTitle => '取消報名？';

  @override
  String get keepSignUp => '保留';

  @override
  String get signUpName => '報名者姓名';

  @override
  String get signUpEmail => '報名信箱';

  @override
  String get submit => '送出';

  @override
  String get noMatchingEvents => '沒有符合的活動';

  @override
  String get searchAnyTimeStatus => '搜尋全部時間與狀態';

  @override
  String eventsAttended(String hours) {
    return '已參加・$hours 小時';
  }

  @override
  String get pastEvents => '歷史活動';

  @override
  String get noEventRecords => '沒有紀錄';

  @override
  String get signUpFailed => '無法報名';

  @override
  String get cancelSignUpFailed => '無法取消報名';
}
