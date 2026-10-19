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
  String get unitHoursLater => '小時後';

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
  String get grades => '成績';

  @override
  String get gradesThisTerm => '本學期';

  @override
  String get gradesHistory => '歷年';

  @override
  String get gradesOnSchoolSite => '在學校網站查看';

  @override
  String courseCount(int count) {
    return '$count 門課';
  }

  @override
  String get account => '帳號';

  @override
  String get ecourseSignedIn => 'eCourse2 已登入';

  @override
  String get ecourseSignedOut => 'eCourse2 未登入';

  @override
  String get portalShared => '單一入口共用';

  @override
  String get searchSystems => '搜尋系統';

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
  String get noDiscussions => '沒有討論';

  @override
  String replyCount(int count) {
    return '$count 則回覆';
  }

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
  String get anyTime => '不限';

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
  String get allTime => '全部時間';

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

  @override
  String get ptTitle => '學習暨勞僱時數';

  @override
  String get ptSelect => '選取';

  @override
  String get ptDone => '完成';

  @override
  String ptMonth(int year, int month) {
    return '$year 年 $month 月';
  }

  @override
  String get ptAllUnits => '所有單位';

  @override
  String get ptUnconfirmed => '未確認';

  @override
  String get ptConfirmed => '已確認';

  @override
  String get ptPaid => '已報帳';

  @override
  String ptHours(String hours) {
    return '$hours 小時';
  }

  @override
  String ptWeek(String used, int limit) {
    return '本週 $used / $limit 小時';
  }

  @override
  String get ptOther => '其他';

  @override
  String get ptPayroll => '付款清冊';

  @override
  String get ptPrint => '列印簽到退表與批號';

  @override
  String get ptAdd => '新增時數';

  @override
  String get ptDate => '日期';

  @override
  String get ptUnit => '單位';

  @override
  String get ptTime => '時間';

  @override
  String get ptWork => '內容';

  @override
  String get ptStage => '加入待儲存';

  @override
  String ptStaged(int count, String hours) {
    return '待儲存 $count 筆・$hours 小時';
  }

  @override
  String ptSaveCount(int count) {
    return '儲存 $count 筆';
  }

  @override
  String ptSaveTitle(int count) {
    return '儲存 $count 筆時數？';
  }

  @override
  String get ptSave => '儲存';

  @override
  String get ptEndAfterStart => '結束時間要晚於開始時間';

  @override
  String ptOverlap(String slot) {
    return '與 $slot 重疊';
  }

  @override
  String ptWeekOver(String total, int limit) {
    return '本週會到 $total 小時，超過每週 $limit 小時';
  }

  @override
  String ptDeleteCount(int count) {
    return '刪除 $count 筆';
  }

  @override
  String ptDeleteTitle(int count) {
    return '刪除 $count 筆時數？';
  }

  @override
  String get ptDelete => '刪除';

  @override
  String ptSelected(int count) {
    return '已選 $count 筆';
  }

  @override
  String get ptNoRecords => '沒有時數紀錄';

  @override
  String get ptSearchUnits => '搜尋單位';

  @override
  String get ptMyUnits => '我的單位';

  @override
  String get ptBatch => '批號';

  @override
  String get ptSheet => '簽到退表';

  @override
  String get ptOpenSheet => '開啟簽到退表';

  @override
  String get ptNet => '實領';

  @override
  String get ptGross => '應支金額';

  @override
  String get ptWage => '應領金額';

  @override
  String get ptEmpLabor => '機關勞保';

  @override
  String get ptEmpPension => '機關勞退';

  @override
  String get ptEmpHealth => '機關健保';

  @override
  String get ptEmpSupp => '機關負擔補充保費';

  @override
  String get ptDeduct => '代扣款項';

  @override
  String get ptTax => '所得稅';

  @override
  String get ptLabor => '勞保';

  @override
  String get ptPension => '勞退';

  @override
  String get ptHealth => '健保';

  @override
  String get ptSupp => '個人補充保費';

  @override
  String get ptOtherDeduct => '其他代扣款';

  @override
  String get ptSubtotal => '小計';

  @override
  String get ptHoliday => '例假日';

  @override
  String ptEntries(int count) {
    return '$count 筆';
  }

  @override
  String get demoMode => 'Demo 模式';

  @override
  String get demoModeDetail => 'ALPHA 功能顯示模擬資料';

  @override
  String get drTitle => '宿舍維修';

  @override
  String get drRequest => '申請維修';

  @override
  String get drHistory => '歷次申請';

  @override
  String get drNone => '沒有申請紀錄';

  @override
  String get drRoom => '寢號及床位';

  @override
  String get drRoomHint => '例：3316A、1325、A301、5108-1';

  @override
  String get drRoomInvalid => '只接受 3316A、1325、A301、5108-1 這四種格式';

  @override
  String get drEmailHint => '修好後寄到這裡';

  @override
  String get drEmailInvalid => 'E-mail 格式不正確';

  @override
  String get drMemo => '維修項目及損壞情形';

  @override
  String get drMemoHint => '哪裡壞了、什麼情形';

  @override
  String get drPresence => '是否需要住宿生在場';

  @override
  String get drNoNeed => '不需要';

  @override
  String get drNeed => '需要在場';

  @override
  String get drNoNeedNote => '管理員直接前往維修，修好後寄 E-mail 通知；請告知室友，貴重物品自行保管';

  @override
  String get drNeedNote => '請到宿舍服務中心約維修時間';

  @override
  String get drRemember => '記住寢號與 E-mail';

  @override
  String get drSubmitTitle => '送出維修申請？';

  @override
  String drResultTo(String email) {
    return '結果寄到 $email';
  }

  @override
  String get payTitle => '付款及所得';

  @override
  String payYear(int year) {
    return '$year 年';
  }

  @override
  String payReceived(int year, int count) {
    return '$year 年已入帳・$count 筆';
  }

  @override
  String payMonth(int month) {
    return '$month 月';
  }

  @override
  String get payCase => '案號';

  @override
  String get payHandler => '經手人';

  @override
  String get payAccount => '入帳帳號';

  @override
  String get payInvoice => '發票';

  @override
  String get payNone => '沒有付款紀錄';

  @override
  String get incomeTitle => '年度所得';

  @override
  String incomeYear(int year) {
    return '$year 年度';
  }

  @override
  String get incomeNet => '給付淨額';

  @override
  String get incomeGross => '給付總額';

  @override
  String get incomeTax => '扣繳稅額';

  @override
  String get incomePension => '勞退自提';

  @override
  String get incomeDetail => '所得明細表';

  @override
  String get incomeWithholding => '扣繳憑單';

  @override
  String get incomeNone => '沒有所得資料';

  @override
  String get attendanceRate => '出席率';

  @override
  String attendancePoints(String points) {
    return '分數 $points';
  }

  @override
  String get attendanceTakenUnit => '次已記錄';

  @override
  String get attendanceSessions => '上課時段';

  @override
  String get attendanceNotTaken => '尚未點名';

  @override
  String get noAttendance => '還沒有點名紀錄';

  @override
  String get absenceHistory => '個人請假表';

  @override
  String get noAbsences => '沒有請假紀錄';

  @override
  String get absenceNew => '填寫請假單';

  @override
  String get absenceCourse => '課程';

  @override
  String get absenceDate => '請假日期';

  @override
  String get absenceType => '請假類型';

  @override
  String get absenceType0 => '事假';

  @override
  String get absenceType1 => '病假';

  @override
  String get absenceType2 => '公假';

  @override
  String get absenceType3 => '喪假';

  @override
  String get absenceType4 => '娩假';

  @override
  String get absenceMode => '課程類型';

  @override
  String get absenceInPerson => '面授';

  @override
  String get absenceOnline => '同步課程';

  @override
  String get absenceRemark => '備註';

  @override
  String get absenceWarning => '只通知授課教師，不能取代學校的正式請假流程。';

  @override
  String get absenceSubmitTitle => '送出請假單？';
}
