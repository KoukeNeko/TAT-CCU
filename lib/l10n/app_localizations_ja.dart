// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get navToday => 'ホーム';

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
  String get unitHoursLater => '時間後';

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
  String get noSubject => '（件名なし）';

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
  String get grades => '成績';

  @override
  String get gradesThisTerm => '今学期';

  @override
  String get gradesHistory => 'これまで';

  @override
  String get gradesOnSchoolSite => '大学のサイトで見る';

  @override
  String courseCount(int count) {
    return '$count 科目';
  }

  @override
  String get account => 'アカウント';

  @override
  String get ecourseSignedIn => 'eCourse2 ログイン中';

  @override
  String get ecourseSignedOut => 'eCourse2 未ログイン';

  @override
  String get searchSystems => 'システムを検索';

  @override
  String get replaceWith => '入れ替え';

  @override
  String get settings => '設定';

  @override
  String get appearance => '外観';

  @override
  String get language => '言語';

  @override
  String get followSystem => 'システム';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

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
  String get noDiscussions => 'ディスカッションはありません';

  @override
  String replyCount(int count) {
    return '返信 $count 件';
  }

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
  String get timetableDay => '日';

  @override
  String get timetableWeek => '週';

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

  @override
  String get studySpace => '自習スペース';

  @override
  String get scanToCheckIn => 'スキャンしてチェックイン';

  @override
  String get openHours => '開館';

  @override
  String get validFor => '有効';

  @override
  String get refreshing => '更新中';

  @override
  String get refresh => '更新';

  @override
  String get available => '空き';

  @override
  String get bookSpace => '予約';

  @override
  String updatesIn(int count) {
    return '$count 秒後に更新';
  }

  @override
  String get designLanguage => 'デザイン言語';

  @override
  String get dlColors => 'カラー';

  @override
  String get dlCorners => '角丸';

  @override
  String get dlSpacing => '余白';

  @override
  String get dlType => '書体';

  @override
  String get dlComponents => 'コンポーネント';

  @override
  String get dlFunctional => '機能色';

  @override
  String get dlIdentity => '識別色';

  @override
  String get dlRoleNow => '現在・選択';

  @override
  String get dlRoleNext => '次・予定';

  @override
  String get dlRoleDue => '期限・注意';

  @override
  String get dlRoleUnread => '未読';

  @override
  String get aboutApp => 'アプリ';

  @override
  String get loadingCollections => 'コレクションを読み込み中';

  @override
  String get loadingShelves => '新着とベストセラーを読み込み中';

  @override
  String get events => 'イベント申込';

  @override
  String get searchEvents => 'イベントを検索';

  @override
  String get within3Days => '3日以内';

  @override
  String get withinWeek => '1週間以内';

  @override
  String get withinMonth => '1か月以内';

  @override
  String get allTime => 'すべての期間';

  @override
  String get eventsOpen => '受付中';

  @override
  String get eventsOngoing => '開催中';

  @override
  String get eventsClosed => '受付終了';

  @override
  String get anyStatus => 'すべての状態';

  @override
  String get eventCategory => 'カテゴリ';

  @override
  String get anyCategory => 'すべてのカテゴリ';

  @override
  String get myEvents => 'マイイベント';

  @override
  String get nextSignedUp => '次回・申込済み';

  @override
  String inDays(int count) {
    return '$count日後';
  }

  @override
  String waitlistSpots(int taken, int total) {
    return '補欠 $taken/$total';
  }

  @override
  String waitlistOnly(int taken, int total) {
    return '満員・補欠 $taken / $total';
  }

  @override
  String get externalSignUp => '外部申込';

  @override
  String get signUpClosed => '締切';

  @override
  String get signedUp => '申込済み';

  @override
  String get eventFull => '満員';

  @override
  String get eventDate => '日時';

  @override
  String get eventPlace => '場所';

  @override
  String get eventOrganizer => '主催';

  @override
  String get eventContact => '連絡先';

  @override
  String get eventIntro => '概要';

  @override
  String get signUp => '申し込む';

  @override
  String get signUpWaitlist => '補欠で申し込む';

  @override
  String get goSignUp => '申込ページへ';

  @override
  String get cancelSignUp => '申込を取り消す';

  @override
  String get cancelSignUpTitle => '申込を取り消しますか？';

  @override
  String get keepSignUp => '取り消さない';

  @override
  String get signUpName => '氏名';

  @override
  String get signUpEmail => 'メール';

  @override
  String get submit => '送信';

  @override
  String get noMatchingEvents => '該当するイベントはありません';

  @override
  String get searchAnyTimeStatus => 'すべての期間と状態で検索';

  @override
  String eventsAttended(String hours) {
    return '参加済み・$hours 時間';
  }

  @override
  String get pastEvents => '過去のイベント';

  @override
  String get noEventRecords => 'なし';

  @override
  String get signUpFailed => '申し込めませんでした';

  @override
  String get cancelSignUpFailed => '取り消せませんでした';

  @override
  String get ptTitle => '学習・雇用時間';

  @override
  String get ptSelect => '選択';

  @override
  String get ptDone => '完了';

  @override
  String ptMonth(int year, int month) {
    return '$year年$month月';
  }

  @override
  String get ptAllUnits => 'すべての部署';

  @override
  String get ptUnconfirmed => '未確認';

  @override
  String get ptConfirmed => '確認済み';

  @override
  String get ptPaid => '精算済み';

  @override
  String ptHours(String hours) {
    return '$hours 時間';
  }

  @override
  String ptWeek(String used, int limit) {
    return '今週 $used / $limit 時間';
  }

  @override
  String get ptOther => 'その他';

  @override
  String get ptPayroll => '支払明細';

  @override
  String get ptPrint => '出勤表と番号';

  @override
  String get ptAdd => '時間を登録';

  @override
  String get ptDate => '日付';

  @override
  String get ptUnit => '部署';

  @override
  String get ptTime => '時間';

  @override
  String get ptWork => '内容';

  @override
  String get ptStage => 'リストに追加';

  @override
  String ptStaged(int count, String hours) {
    return '保存待ち $count 件・$hours 時間';
  }

  @override
  String ptSaveCount(int count) {
    return '$count 件を保存';
  }

  @override
  String ptSaveTitle(int count) {
    return '$count 件を保存しますか？';
  }

  @override
  String get ptSave => '保存';

  @override
  String get ptEndAfterStart => '終了は開始より後にしてください';

  @override
  String ptOverlap(String slot) {
    return '$slot と重複';
  }

  @override
  String ptWeekOver(String total, int limit) {
    return '今週 $total 時間になり、上限 $limit 時間を超えます';
  }

  @override
  String ptDeleteCount(int count) {
    return '$count 件を削除';
  }

  @override
  String ptDeleteTitle(int count) {
    return '$count 件を削除しますか？';
  }

  @override
  String get ptDelete => '削除';

  @override
  String ptSelected(int count) {
    return '$count 件選択';
  }

  @override
  String get ptNoRecords => '記録なし';

  @override
  String get ptSearchUnits => '部署を検索';

  @override
  String get ptMyUnits => '自分の部署';

  @override
  String get ptBatch => '番号';

  @override
  String get ptSheet => '出勤表';

  @override
  String get ptOpenSheet => '出勤表を開く';

  @override
  String get ptNet => '手取り';

  @override
  String get ptGross => '支給額';

  @override
  String get ptWage => '給与';

  @override
  String get ptEmpLabor => '事業主労災保険';

  @override
  String get ptEmpPension => '事業主退職金';

  @override
  String get ptEmpHealth => '事業主健康保険';

  @override
  String get ptEmpSupp => '事業主補充保険料';

  @override
  String get ptDeduct => '控除';

  @override
  String get ptTax => '所得税';

  @override
  String get ptLabor => '労災保険';

  @override
  String get ptPension => '退職金';

  @override
  String get ptHealth => '健康保険';

  @override
  String get ptSupp => '補充保険料';

  @override
  String get ptOtherDeduct => 'その他の控除';

  @override
  String get ptHoliday => '休日';

  @override
  String ptEntries(int count) {
    return '$count 件';
  }

  @override
  String get demoMode => 'デモアカウント';

  @override
  String get demoModeDetail => 'すべてサンプルデータで、自分のアカウントとは別です';

  @override
  String get drTitle => '寮の修理';

  @override
  String get drRequest => '修理を申請';

  @override
  String get drHistory => '申請履歴';

  @override
  String get drNone => '申請履歴なし';

  @override
  String get drRoom => '部屋とベッド';

  @override
  String get drRoomHint => '例：3316A、1325、A301、5108-1';

  @override
  String get drRoomInvalid => '3316A、1325、A301、5108-1 のいずれかの形式で入力してください';

  @override
  String get drEmailHint => '修理結果の送信先';

  @override
  String get drEmailInvalid => 'メールアドレスの形式が正しくありません';

  @override
  String get drMemo => '修理内容';

  @override
  String get drMemoHint => 'どこがどう壊れたか';

  @override
  String get drPresence => '立ち会いが必要か';

  @override
  String get drNoNeed => '不要';

  @override
  String get drNeed => '必要';

  @override
  String get drNoNeedNote =>
      '管理員が直接修理し、終了後にメールで通知します。ルームメイトに伝え、貴重品は各自で保管してください。';

  @override
  String get drNeedNote => '寮サービスセンターで修理日時を予約してください';

  @override
  String get drRemember => '部屋とメールを記憶';

  @override
  String get drSubmitTitle => '修理を申請しますか？';

  @override
  String drResultTo(String email) {
    return '結果の送信先：$email';
  }

  @override
  String get payTitle => '支払と所得';

  @override
  String payYear(int year) {
    return '$year年';
  }

  @override
  String payReceived(int year, int count) {
    return '$year年の入金・$count 件';
  }

  @override
  String payMonth(int month) {
    return '$month月';
  }

  @override
  String get payCase => '案件番号';

  @override
  String get payHandler => '担当';

  @override
  String get payAccount => '振込口座';

  @override
  String get payInvoice => '請求書';

  @override
  String get payNone => '支払記録なし';

  @override
  String get incomeTitle => '年間所得';

  @override
  String incomeYear(int year) {
    return '$year年度';
  }

  @override
  String get incomeNet => '支給純額';

  @override
  String get incomeGross => '支給総額';

  @override
  String get incomeTax => '源泉徴収額';

  @override
  String get incomePension => '年金自己拠出';

  @override
  String get incomeDetail => '所得明細書';

  @override
  String get incomeWithholding => '源泉徴収票';

  @override
  String get incomeNone => '所得データなし';

  @override
  String get attendanceRate => '出席率';

  @override
  String attendancePoints(String points) {
    return '点数 $points';
  }

  @override
  String get attendanceTakenUnit => '回記録済み';

  @override
  String get attendanceSessions => '授業回';

  @override
  String get attendanceNotTaken => '未記録';

  @override
  String get noAttendance => '出席記録はありません';

  @override
  String get absenceHistory => '自分の欠席届';

  @override
  String get noAbsences => '欠席届はありません';

  @override
  String get absenceNew => '欠席届を書く';

  @override
  String get absenceCourse => '科目';

  @override
  String get absenceDate => '日付';

  @override
  String get absenceType => '種類';

  @override
  String get absenceType0 => '私用';

  @override
  String get absenceType1 => '病気';

  @override
  String get absenceType2 => '公欠';

  @override
  String get absenceType3 => '忌引';

  @override
  String get absenceType4 => '出産';

  @override
  String get absenceMode => '授業形態';

  @override
  String get absenceInPerson => '対面';

  @override
  String get absenceOnline => '同期オンライン';

  @override
  String get absenceRemark => '備考';

  @override
  String get absenceWarning => '担当教員への連絡のみで、正式な欠席手続きの代わりにはなりません。';

  @override
  String get absenceSubmitTitle => 'この欠席届を送信しますか？';

  @override
  String get notifyDue => '締切リマインダー';

  @override
  String get notifyDueDetail => '24 時間前と 1 時間前';

  @override
  String get notifyClass => '授業リマインダー';

  @override
  String get notifyClassDetail => '授業の 10 分前';

  @override
  String get notifyNews => '新しい通知とメール';

  @override
  String get notifyNewsDetail => 'システムが許可したときにバックグラウンドで確認';

  @override
  String get notifyDenied => '通知がオフです。システム設定でオンにしてください';

  @override
  String get notifyTest => 'テスト通知を送信';

  @override
  String get notifyTestShown => '通知は正常に届いています';

  @override
  String get reminderDue24 => '24 時間後に締切';

  @override
  String get reminderDue1 => '1 時間後に締切';

  @override
  String get reminderClass => '10 分後に授業';

  @override
  String newMailFrom(String sender) {
    return '$sender から新しいメール';
  }

  @override
  String get latestDue => '次の締切';

  @override
  String get latestPost => '最新のお知らせ';

  @override
  String classesEndAt(String time) {
    return '授業は $time まで';
  }

  @override
  String get demoUnavailable => 'デモアカウントでは使えません';

  @override
  String get demoEnter => 'デモアカウントで試す';

  @override
  String get appTagline => '中正大学の時間割、eCourse2 と学務システム';

  @override
  String get tools => 'ツール';

  @override
  String get toolBus => 'バス';

  @override
  String get toolCountdown => '学期カウントダウン';

  @override
  String get busLive => '運行状況';

  @override
  String get daysUnit => '日';

  @override
  String termWeek(int week, int weeks) {
    return '第 $week 週・全 $weeks 週';
  }

  @override
  String get countdownUpcoming => 'この先';

  @override
  String get countdownToday => '今日';

  @override
  String get countdownEnded => '今年度の行事予定は終了しました';

  @override
  String get ecourseMaintenance => 'eCourse2 はメンテナンス中です。後でもう一度お試しください';

  @override
  String get useCampusSystems => '校務システムを使う';

  @override
  String get signIn => 'ログイン';

  @override
  String firstClassOn(String day) {
    return '$dayの最初の授業';
  }

  @override
  String get nothingDueThisWeek => '今週の期限なし';

  @override
  String termWeekShort(int week, int weeks) {
    return '第 $week 週・全 $weeks 週';
  }

  @override
  String get classesUnit => 'コマ';

  @override
  String get itemsUnit => '件';

  @override
  String get ecourseInMaintenance => 'eCourse2 メンテナンス中';

  @override
  String get maintenanceChecking => '確認中';

  @override
  String get ecourseBack => 'eCourse2 が復旧しました';

  @override
  String get savedData => '保存データ';

  @override
  String get campusSystems => '学内システム';

  @override
  String savedItems(int count) {
    return '$count 件';
  }

  @override
  String get onThisDevice => 'この端末';

  @override
  String get savedCourses => '授業と時間割';

  @override
  String get savedContents => '授業内容';

  @override
  String get savedWork => '課題と小テスト';

  @override
  String get savedForums => 'お知らせと掲示板';

  @override
  String get savedMessages => '通知とメール';

  @override
  String get savedCalendar => 'ToDo とカレンダー';

  @override
  String get savedOther => 'その他';

  @override
  String get signedIn => 'ログイン中';

  @override
  String get signInExpired => 'ログイン期限切れ';

  @override
  String get maintenance => 'メンテナンス中';

  @override
  String get schoolCalendar => '学年暦';

  @override
  String get dlShapes => '形と動き';

  @override
  String busDeparts(String stop, String time) {
    return '$stop $time 発';
  }

  @override
  String get busRoutes => '路線';

  @override
  String get busFares => '運賃';

  @override
  String get busFareKinds => '大人／小人';

  @override
  String busDirectionFrom(String direction, String stop) {
    return '$direction・$stop発';
  }

  @override
  String busStartsOn(String date) {
    return '$date から運行';
  }

  @override
  String get busNoTrips => '今週の運行なし';

  @override
  String get busDepartsShort => '発';

  @override
  String get busUpNext => '次の便';

  @override
  String get takeAttendance => '出席登録';

  @override
  String get notAttendanceCode => '出席用の QR コードではありません';

  @override
  String get cameraUnavailable => 'カメラを使用できません。設定でカメラへのアクセスを許可してください。';

  @override
  String get flashlight => 'ライト';

  @override
  String get about => 'このアプリについて';

  @override
  String get contributors => 'コントリビューター';

  @override
  String get project => 'プロジェクト';

  @override
  String get openSourceLicenses => 'オープンソースライセンス';

  @override
  String get sendFailed => '送信できませんでした。もう一度お試しください。';

  @override
  String get reply => '返信';

  @override
  String get replyToThread => 'このディスカッションに返信';

  @override
  String replyingTo(String name) {
    return '$name に返信';
  }

  @override
  String get newDiscussion => '新しいディスカッション';

  @override
  String get subject => '件名';

  @override
  String get messageBody => '本文';

  @override
  String get cancel => 'キャンセル';

  @override
  String get submissionComments => '提出物へのコメント';

  @override
  String get commentHint => '教員・TA へのコメント';

  @override
  String get deleteComment => 'このコメントを削除しますか？';

  @override
  String get delete => '削除';

  @override
  String get markUnread => '未読にする';

  @override
  String get compose => '作成';

  @override
  String get navMessages => 'メッセージ';

  @override
  String get earlier => '以前';

  @override
  String get msgForum => 'ディスカッション';

  @override
  String get msgAssignment => '課題';

  @override
  String get recipients => '宛先';

  @override
  String get searchPeople => '他の人を検索';

  @override
  String get sendTo => '宛先';

  @override
  String get addRecipient => '宛先を追加';

  @override
  String get done => '完了';

  @override
  String get mailSent => '送信しました';

  @override
  String get staff => '教員と TA';

  @override
  String get others => 'その他';

  @override
  String commitCount(int count) {
    return '$count 件のコミット';
  }

  @override
  String get dormNetTitle => '寮ネット';

  @override
  String get dormNetToday => '今日の通信量 · 0:00 にリセット';

  @override
  String get dormNetOk => '接続中';

  @override
  String get dormNetNotApplied => '未申請';

  @override
  String get dormNetApply => '申し込む';

  @override
  String get dormNetSuspended => '停止中';

  @override
  String get dormNetUnsuspend => '復旧を申請';

  @override
  String get dormNetAllStopped => 'アカウントのすべての端末が停止中';

  @override
  String get dormNetUnsuspendHint =>
      'ウイルスを駆除するか再インストール・更新してから復旧を申請してください。罰則終了の翌日 0:00 に戻ります。';

  @override
  String get dormNetWifi => 'Wi-Fi 端末';

  @override
  String get dormNetCards => '有線 MAC';

  @override
  String get dormNetBreaks => '切断記録';

  @override
  String get dormNetNone => 'なし';

  @override
  String get dormNetRestored => '復旧済み';

  @override
  String get dormNetStillOff => '停止中';

  @override
  String get dormNetEditDevices => '端末を編集';

  @override
  String get dormNetOffices => '寮ネット窓口';

  @override
  String get dormNetOpenNow => '対応中';

  @override
  String get dormNetClosed => '終了';

  @override
  String get dormNetMeet => 'オンライン相談';

  @override
  String get dormNetMeetHours => 'Google Meet · 毎晩 19:00–22:00';

  @override
  String get dormNetDevices => '端末';

  @override
  String get dormNetDevicesNote => '最大 3 枚・Wi-Fi 同時 2 台';

  @override
  String get dormNetWired => '有線';

  @override
  String get dormNetPrivateMac => 'スマホは「プライベート Wi-Fi アドレス」をオフに';

  @override
  String get dormNetEditCards => 'カードを追加・変更';

  @override
  String get dormNetFee => '今学期の料金';

  @override
  String get dormNetFeeWhen => '申込時期';

  @override
  String get dormNetFeePay => '料金';

  @override
  String get dormNetFeeRefund => '返金';

  @override
  String get dormNetSlip => '払込票をダウンロード';

  @override
  String get dormNetSlipHint => '台湾 Pay・ATM・ネットバンク・コンビニ。現金は情報処 219';

  @override
  String get dormNetReceipt => '領収書をアップロード';

  @override
  String get dormNetReceiptHint => '電子決済の反映は 1–14 日。アップロードで先に処理';

  @override
  String get dormNetRules => '利用規約';

  @override
  String get dormNetRuleTraffic => '100 GiB / 日';

  @override
  String get dormNetRuleTrafficHint => '有線と Wi-Fi の合計。超過すると翌日 0:10 に自動復旧';

  @override
  String get dormNetRuleVirus => '感染で全停止';

  @override
  String get dormNetRuleVirusHint => '1 台が感染すると全端末が停止。駆除後に復旧を申請';

  @override
  String get dormNetRuleShare => '共有禁止';

  @override
  String get dormNetRuleShareHint => 'ルーター・アクセスポイント・サーバーは禁止';

  @override
  String get dormNetRuleMove => 'ベッド変更';

  @override
  String get dormNetRuleMoveHint => '変更証明と学生証を寮ネット窓口へ';

  @override
  String get dormNetNews => 'お知らせ';

  @override
  String get dormNetHelp => 'ヘルプ';

  @override
  String get dormNetTutorial => '使い方';

  @override
  String get dormNetTutorialHint => 'MAC の確認・設定・動画';

  @override
  String get dormNetFaq => 'よくある質問';

  @override
  String get dormNetReport => '問題を報告';

  @override
  String get dormNetReportHint => '寮ネットの問い合わせ窓口';

  @override
  String dormNetLeft(String left) {
    return '残り $left GiB';
  }

  @override
  String dormNetLastBed(String bed) {
    return '前回のベッド $bed';
  }

  @override
  String dormNetTimes(int count) {
    return '$count 回';
  }

  @override
  String dormNetWifiOf(int count, int limit) {
    return 'Wi-Fi $count / $limit 台';
  }

  @override
  String dormNetBreakTime(String from, String until) {
    return '$from 切断 · $until 復旧';
  }

  @override
  String dormNetBreakSince(String from) {
    return '$from から';
  }

  @override
  String dormNetFeePeriod(String period) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'fall0': '開学–10/31',
      'fall1': '11 月',
      'fall2': '12 月',
      'fall3': '1 月–冬休み',
      'spring0': '開学–3/31',
      'spring1': '4 月',
      'spring2': '5 月',
      'other': '6 月–夏休み',
    });
    return '$_temp0';
  }

  @override
  String get dormNetTraffic => '今日の通信量';

  @override
  String get dormNetAfterApply => '申請後に計測';

  @override
  String get dormNetOnApply => '申請時に入力';

  @override
  String dormNetNth(int count) {
    return '$count 回目';
  }

  @override
  String dormNetPenalty(int days) {
    return '停止 $days 日';
  }

  @override
  String dormNetFeeUntil(String period, int fee) {
    String _temp0 = intl.Intl.selectLogic(period, {
      'fall0': '10/31 まで',
      'fall1': '11/30 まで',
      'fall2': '12/31 まで',
      'fall3': '冬休み終了まで',
      'spring0': '3/31 まで',
      'spring1': '4/30 まで',
      'spring2': '5/31 まで',
      'other': '夏休み終了まで',
    });
    return '$_temp0 $fee 元';
  }

  @override
  String get pageStages => 'ページの段階';

  @override
  String get stageAlpha => '未テスト';

  @override
  String get stageBeta => '一部テスト済み';

  @override
  String get stagesHelp => 'ALPHA・BETA のページは十分にテストされていません。問題があればお知らせください。';

  @override
  String get reportIssue => '問題を報告';

  @override
  String issueTemplate(String version, String platform) {
    return 'ページ：\n状況：\n\nApp $version・$platform';
  }

  @override
  String get stageAlphaDetail => 'データや操作に誤りがある可能性';

  @override
  String get stageBetaDetail => 'すべてのアカウント状態は未確認';

  @override
  String get noMatchingPeople => '一致する人はいません';

  @override
  String get sendUnconfirmed => '送信できたか確認できませんでした';

  @override
  String get viewSentMail => '送信済みを見る';

  @override
  String get sentMail => '送信済み';

  @override
  String mailTo(String names) {
    return '宛先 $names';
  }

  @override
  String get noSentMail => '送信したメールはありません';

  @override
  String get folderInbox => '受信';

  @override
  String get folderStarred => 'スター';

  @override
  String get folderDrafts => '下書き';

  @override
  String get folderSent => '送信';

  @override
  String get folderTrash => 'ゴミ箱';

  @override
  String get starMail => 'スターを付ける';

  @override
  String get unstarMail => 'スターを外す';

  @override
  String get restoreMail => '元に戻す';

  @override
  String get discardDraft => '破棄';

  @override
  String get discardDraftTitle => 'この下書きを破棄しますか？';

  @override
  String get editDraft => '編集を続ける';

  @override
  String get emptyTrash => 'ゴミ箱を空にする';

  @override
  String get emptyTrashTitle => 'ゴミ箱を空にしますか？';

  @override
  String get emptyTrashBody => 'ゴミ箱のメールは完全に削除されます。';

  @override
  String get emptyTrashAction => '空にする';

  @override
  String get themeColors => 'テーマ';

  @override
  String get themeDefault => 'デフォルト';

  @override
  String get themeWallpaper => '壁紙の色';

  @override
  String get androidOnly => 'Android 12 以降のみ';

  @override
  String get version => 'バージョン';

  @override
  String get versionLatest => '最新バージョン';

  @override
  String versionCurrent(String version) {
    return '現在 $version';
  }

  @override
  String get versionUpdatable => 'アップデートできます';

  @override
  String get versionChecked => '確認しました';

  @override
  String get versionChecking => '確認中';

  @override
  String get versionCheckFailed => '確認できませんでした';

  @override
  String get checkUpdate => 'アップデートを確認';

  @override
  String get update => 'アップデート';

  @override
  String whatsNewIn(String version) {
    return '$version の新機能';
  }

  @override
  String get openInEcourse => 'eCourse2 で開く';

  @override
  String get campusSoftware => '学内ライセンスソフト';

  @override
  String swDownloads(int count) {
    return '↓ $count 回';
  }

  @override
  String get swOnSite => 'サイトでダウンロード';

  @override
  String get swLink => 'リンク';

  @override
  String get swHere => '認証と説明';

  @override
  String get swHereHint => 'アプリで開く';

  @override
  String get swInstallers => 'インストーラー';

  @override
  String get calUpcoming => 'これから';

  @override
  String get calThisMonth => '今月';

  @override
  String get calNothingAhead => '予定はありません';

  @override
  String get search => '検索';

  @override
  String get paletteHint => 'コース、課題、ページへ移動';

  @override
  String get palettePages => 'ページ';

  @override
  String get paletteSelect => '選択';

  @override
  String get openCourse => 'コースを開く';
}
