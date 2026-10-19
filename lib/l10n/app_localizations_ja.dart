// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get navToday => '今日';

  @override
  String get navTimetable => '時間割';

  @override
  String get navCourses => 'コース';

  @override
  String get navCalendar => 'カレンダー';

  @override
  String get navMore => 'その他';

  @override
  String get signInPortal => 'ポータルにログイン';

  @override
  String get retry => '再試行';

  @override
  String updatedAt(String time) {
    return '$time 更新';
  }

  @override
  String get loadFailed => '読み込めません';

  @override
  String get toDo => 'やること';

  @override
  String get nothingDueSoon => '14 日以内の締切はありません';

  @override
  String get unitHours => '時間';

  @override
  String get unitDays => '日';

  @override
  String get unitMinutes => '分';

  @override
  String get unitMinutesLater => '分後';

  @override
  String get todayNoClasses => '今日は授業がありません';

  @override
  String get todayClassesOver => '今日の授業は終わりました';

  @override
  String todayClassesLeft(String count) {
    return '今日はあと $count コマ';
  }

  @override
  String get inClass => '授業中';

  @override
  String untilTime(String time) {
    return '$time まで';
  }

  @override
  String get nextClass => '次の授業';

  @override
  String startsAt(String time) {
    return '$time 開始';
  }

  @override
  String get dueThisWeek => '今週締切';

  @override
  String get unread => '未読';

  @override
  String unreadDetail(int notices, int mail) {
    return '通知 $notices・メール $mail';
  }

  @override
  String get notifications => '通知';

  @override
  String notificationsUnread(int count) {
    return '通知、未読 $count 件';
  }

  @override
  String get mail => 'メール';

  @override
  String get noNotifications => '通知はありません';

  @override
  String get noMail => 'メールはありません';

  @override
  String monthTitle(String month) {
    return '$month月';
  }

  @override
  String yearMonthTitle(int year, String month) {
    return '$year年$month月';
  }

  @override
  String get goToToday => '今日';

  @override
  String itemCount(int count) {
    return '$count 件';
  }

  @override
  String get noEventsThisDay => 'この日の予定はありません';

  @override
  String get academicSystem => '学籍';

  @override
  String get academicRecord => '学籍情報';

  @override
  String get studentNo => '学籍番号';

  @override
  String get englishName => '英語氏名';

  @override
  String get email => 'メール';

  @override
  String get mobile => '携帯電話';

  @override
  String get onSchoolWebsite => '学校のサイトで';

  @override
  String get editNameContact => '英語氏名と連絡先の変更';

  @override
  String get studentPhoto => '学生写真';

  @override
  String get enrollmentCertificate => '在学証明書';

  @override
  String get generating => '作成中';

  @override
  String get generate => '作成';

  @override
  String get regenerate => '再作成';

  @override
  String get open => '開く';

  @override
  String get share => '共有';

  @override
  String get notYetThisSemester => '今学期は未作成';

  @override
  String validPrinted(String date) {
    return '有効・発行日 $date';
  }

  @override
  String expiredPrinted(String date) {
    return '期限切れ・発行日 $date';
  }

  @override
  String savedToDevice(String time) {
    return '端末に保存 $time';
  }

  @override
  String get notPdf => '学校から PDF が返されませんでした';

  @override
  String get courseSelection => '履修登録';

  @override
  String get viewInApp => 'アプリで見る';

  @override
  String courseCountShort(int count) {
    return '$count 科目';
  }

  @override
  String get selectionQuery => '履修照会';

  @override
  String thisSemesterCredits(String credits) {
    return '今学期・$credits 単位';
  }

  @override
  String typeCredits(String type, String credits) {
    return '$type $credits 単位';
  }

  @override
  String get courseChanges => '開講変更';

  @override
  String get schoolwideChanges => '全学の今学期の変更';

  @override
  String get myApplications => '申請';

  @override
  String get applicationsHint => '追加・単位不足・他大学・放棄・プログラム';

  @override
  String kindCount(String kind, int count) {
    return '$kind $count 件';
  }

  @override
  String get programs => '分野横断プログラム';

  @override
  String get programsDetail => 'プログラムと開設部局';

  @override
  String get notOpen => '受付期間外';

  @override
  String get noData => 'データがありません';

  @override
  String get academics => '学業';

  @override
  String get grades => '成績';

  @override
  String courseCount(int count) {
    return '$count 科目';
  }

  @override
  String get campus => 'キャンパス';

  @override
  String get allCampusSystems => 'すべての学内システム';

  @override
  String get account => 'アカウント';

  @override
  String get ecourseSignedIn => 'eCourse2 ログイン中';

  @override
  String get ecourseSignedOut => 'eCourse2 未ログイン';

  @override
  String get portalShared => 'ポータル共通';

  @override
  String get campusSystems => '学内システム';

  @override
  String get searchSystems => 'システムを検索';

  @override
  String get favorites => 'よく使う';

  @override
  String get edit => '編集';

  @override
  String get recentlyOpened => '最近使ったもの';

  @override
  String favoritesCount(int count, int max) {
    return 'よく使う（$count/$max）';
  }

  @override
  String get noGrades => '成績はまだありません';

  @override
  String get itemNotFound => '項目が見つかりません';

  @override
  String get stepOpens => '開始';

  @override
  String get stepSubmitted => '提出';

  @override
  String get notSubmitted => '未提出';

  @override
  String get stepDue => '締切';

  @override
  String get stepGrade => '成績';

  @override
  String get mySubmission => '提出物';

  @override
  String get description => '説明';

  @override
  String get attachments => '添付ファイル';

  @override
  String get stepAttempted => '受験';

  @override
  String get notAttempted => '未受験';

  @override
  String get stepCloses => '終了';

  @override
  String get quizSettings => '設定';

  @override
  String get quizStart => '開始';

  @override
  String get quizEnd => '終了';

  @override
  String get attemptsAllowed => '受験回数';

  @override
  String get unlimited => '無制限';

  @override
  String attemptCount(int count) {
    return '$count 回';
  }

  @override
  String get passGrade => '合格点';

  @override
  String fullMarks(String max) {
    return '満点 $max';
  }

  @override
  String get noFiles => 'ファイルはありません';

  @override
  String get filesLabel => 'ファイル';

  @override
  String get total => '合計';

  @override
  String get lastUpdated => '最終更新';

  @override
  String fileUpdated(String size, String date) {
    return '$size・$date 更新';
  }

  @override
  String get courseNotFound => 'コースが見つかりません';

  @override
  String get nothingDue => 'やることはありません';

  @override
  String nameDue(String name) {
    return '$name 締切';
  }

  @override
  String get announcementsUnit => '件のお知らせ';

  @override
  String get currentGrade => '現在の成績';

  @override
  String get courseSection => 'コース';

  @override
  String get allSections => 'すべてのセクション';

  @override
  String sectionCount(int count) {
    return '$count セクション';
  }

  @override
  String get announcements => 'お知らせ';

  @override
  String postCount(int count) {
    return '$count 件';
  }

  @override
  String hoursLeft(int count) {
    return '$count 時間';
  }

  @override
  String daysLeft(int count) {
    return '$count 日';
  }

  @override
  String get today => '今日';

  @override
  String get tomorrow => '明日';

  @override
  String nextClassAt(String when) {
    return '次の授業 $when';
  }

  @override
  String get noContents => 'コンテンツはまだありません';

  @override
  String dueOn(String date) {
    return '$date 締切';
  }

  @override
  String fileCount(int count) {
    return '$count ファイル';
  }

  @override
  String get noAnnouncements => 'お知らせはありません';

  @override
  String get noGradeItems => '成績項目はまだありません';

  @override
  String get searchCourses => 'コースを検索';

  @override
  String get noMatchingCourses => '該当するコースはありません';

  @override
  String verifiedAt(String time) {
    return '$time 確認';
  }

  @override
  String get signedOut => '未ログイン';

  @override
  String get verifyFailed => '確認に失敗しました';

  @override
  String signedInAs(String name) {
    return 'ログイン中：$name';
  }

  @override
  String get signedInUnverified => 'ログイン中（未確認）';

  @override
  String get verify => '確認';

  @override
  String get signOut => 'ログアウト';

  @override
  String get portalCas => 'ポータル（CAS）';

  @override
  String get sharedWithEcourse => 'eCourse2 とログインを共有';

  @override
  String get portal => 'ポータル';

  @override
  String get openPortal => 'ポータルを開く';

  @override
  String signInFailed(String error) {
    return 'ログインに失敗しました：$error';
  }

  @override
  String get signInWithPortal => 'ポータルでログイン';

  @override
  String get noClassesThisDay => 'この日は授業がありません';

  @override
  String get unscheduled => '時間未定';

  @override
  String get close => '閉じる';

  @override
  String get switchSemester => '学期を切り替え';

  @override
  String semesterLabel(String year, String term) {
    String _temp0 = intl.Intl.selectLogic(term, {
      '1': '前期',
      '2': '後期',
      'other': '夏期',
    });
    return '$year学年度 $_temp0';
  }

  @override
  String get sectionGeneral => '一般';

  @override
  String eventLabel(String kind, String action) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'assign': '課題',
      'quiz': '小テスト',
      'course': 'コースの予定',
      'user': '個人の予定',
      'site': '全学の予定',
      'other': '活動',
    });
    String _temp1 = intl.Intl.selectLogic(action, {
      'due': '締切',
      'close': '終了',
      'open': '開始',
      'other': '',
    });
    return '$_temp0$_temp1';
  }

  @override
  String weekdayShort(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': '月',
      '2': '火',
      '3': '水',
      '4': '木',
      '5': '金',
      '6': '土',
      '7': '日',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String weekdayFull(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': '月曜',
      '2': '火曜',
      '3': '水曜',
      '4': '木曜',
      '5': '金曜',
      '6': '土曜',
      '7': '日曜',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get leave => '休暇';

  @override
  String get leaveApproved => '承認済み';

  @override
  String get leavePending => '審査中';

  @override
  String get leaveCancelled => '取り消し済み';

  @override
  String get myLeaves => '休暇申請';

  @override
  String get noLeaves => '休暇申請はありません';

  @override
  String get applyLeave => '休暇を申請';

  @override
  String get cancelLeave => '休暇を取り消す';

  @override
  String recordCount(int count) {
    return '$count 件';
  }

  @override
  String get library => 'マイライブラリ';

  @override
  String get loansOverdue => '延滞';

  @override
  String get loansNextDue => '次の返却';

  @override
  String get onLoan => '貸出中';

  @override
  String get noLoans => '貸出中の本はありません';

  @override
  String bookCount(int count) {
    return '$count 冊';
  }

  @override
  String get dueToday => '今日返却';

  @override
  String daysOverdue(int count) {
    return '$count 日延滞';
  }

  @override
  String holdsReady(int count) {
    return '取り置き $count 冊';
  }

  @override
  String heldUntil(String date) {
    return '$date まで取り置き';
  }

  @override
  String get loansAndRenewals => '貸出と延長';

  @override
  String loanDue(String date) {
    return '$date 返却';
  }

  @override
  String loanDaysLeft(int count) {
    return '残り $count 日';
  }

  @override
  String get rememberPasswordTitle => 'パスワードを保存しますか？';

  @override
  String get rememberPasswordBody =>
      '次回 CAS のログインで自動入力して送信します。パスワードはこの端末に暗号化して保存されます。';

  @override
  String get notNow => '保存しない';

  @override
  String get remember => '保存';

  @override
  String get autoSignIn => '自動ログイン';

  @override
  String get deleteSavedPassword => '保存したパスワードを削除';

  @override
  String get campusConnecting => '接続中';

  @override
  String get campusFillingIn => '保存したパスワードを入力中';

  @override
  String get campusVerifying => 'Cloudflare 認証';

  @override
  String get campusReading => 'データを読み込み中';

  @override
  String get showPage => 'ページを表示';

  @override
  String get librarySearchHint => '蔵書・雑誌・データベースを検索';

  @override
  String get kindCatalog => '蔵書';

  @override
  String get kindJournal => '雑誌';

  @override
  String get kindDatabase => 'データベース';

  @override
  String get onShelf => '貸出可';

  @override
  String get checkedOut => '貸出中';

  @override
  String get online => 'オンライン';

  @override
  String get typeBooks => '図書';

  @override
  String get typeDissertations => '学位論文';

  @override
  String get typeVideos => '映像';

  @override
  String get sortRelevance => '関連度';

  @override
  String get sortNewest => '新しい順';

  @override
  String get sortTitle => 'タイトル';

  @override
  String get anyTime => '指定なし';

  @override
  String lastYears(int count) {
    return '過去 $count 年';
  }

  @override
  String get filter => '絞り込み';

  @override
  String get filterAvailability => '入手方法';

  @override
  String get filterType => '資料種別';

  @override
  String get filterSort => '並べ替え';

  @override
  String get filterYear => '出版年';

  @override
  String get showResults => '結果を表示';

  @override
  String resultCount(int count) {
    return '$count 件';
  }

  @override
  String get holdings => '所蔵';

  @override
  String get requestHold => '予約';

  @override
  String get readOnline => 'オンラインで読む';

  @override
  String get cite => '引用';

  @override
  String get citationCopied => '引用をコピーしました';

  @override
  String get bibDetails => '書誌情報';

  @override
  String get publisher => '出版者';

  @override
  String get subjects => '件名';

  @override
  String get collections => 'テーマコレクション';

  @override
  String get newBooks => '新着図書';

  @override
  String get noBooks => '資料がありません';

  @override
  String get libraryCollections => '蔵書';

  @override
  String get renewAll => 'すべて延長';

  @override
  String get renew => '延長';

  @override
  String get notRenewable => '延長不可';

  @override
  String get dueDate => '返却期限';

  @override
  String get renewPending => '延長を申請しました';

  @override
  String get renewFailed => '延長できませんでした';

  @override
  String renewedCount(int renewed, int total) {
    return '$total 冊中 $renewed 冊を延長';
  }

  @override
  String get cancelHoldFailed => '予約を取り消せませんでした';

  @override
  String get holds => '予約';

  @override
  String get holdReady => '受取可';

  @override
  String get holdWaiting => '待機中';

  @override
  String get cancelHoldTitle => '予約を取り消しますか？';

  @override
  String get cancelHold => '予約を取り消す';

  @override
  String get keepHold => '取り消さない';

  @override
  String get libraryDiscovery => '図書館資料検索';

  @override
  String get viewAll => 'すべて';

  @override
  String get otherCollections => 'その他のコレクション';

  @override
  String allCollections(int count) {
    return 'すべて（$count）';
  }
}
