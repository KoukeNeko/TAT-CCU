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
  String get portalShared => 'ポータル共通';

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
  String searchFor(String query) {
    return '「$query」を検索';
  }

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
  String get happeningNow => '開催中';

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
  String get ptSubtotal => '小計';

  @override
  String get ptHoliday => '休日';

  @override
  String ptEntries(int count) {
    return '$count 件';
  }

  @override
  String get demoMode => 'デモモード';

  @override
  String get demoModeDetail => 'ALPHA 機能でサンプルデータを表示';

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
}
