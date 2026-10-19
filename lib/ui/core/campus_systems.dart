import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';
import 'campus_web_screen.dart';
import 'widgets.dart';
import '../../l10n/l10n.dart';

/// Portal home; bounces to the portal login when its session has lapsed.
const portalHome = 'https://portal.ccu.edu.tw/sso_index.php';

/// One portal tile: its `linkId`, the `ssoService.php` service it hands off
/// to, the character shown in its badge, and a note when it behaves
/// differently from the rest (campus-only, separate login, external site).
typedef CampusSystem = ({
  String id,
  String name,
  String service,
  String mark,
  String? note,
});

CampusSystem _s(
  String id,
  String name,
  String service,
  String mark, [
  String? note,
]) => (id: id, name: name, service: service, mark: mark, note: note);

/// Read from the logged-in portal on 2026-10-18 (CAS 校務系統清單.md).
final campusGroups = <(String, List<CampusSystem>)>[
  (
    '教務與學習',
    [
      _s('0075', '選課系統', '/test_0075_nidalap_CourseSelection.php', '選'),
      _s('0007', '成績查詢', '/test_0007_GradeQuery.php', '成'),
      _s('0004', '學籍系統', '/test_Academic.php', '籍'),
      _s('0053', '學分抵免申請', '/test_DeductApply.php', '抵'),
      _s('0054', '學位考試系統', '/test_Qualify.php', '考'),
      _s('0068', '微學分管理系統', '/test_0068_MicroCredit.php', '微'),
      _s('0006', '生涯定向系統', '/test_ePortfolio.php', '涯', '教育部 UCAN'),
      _s('0071', '課間增能星級行動平台', '/test_0071_Counseling.php', '增'),
    ],
  ),
  (
    '學務與學生事務',
    [
      _s('0064', '學生請假系統', '/test_0064_StuOff.php', '假'),
      _s('0067', '學生網路離校系統', '/test_0067_Leave.php', '離'),
      _s('0019', '初次晤談預約系統', '/test_Booking.php', '談'),
      _s('0012', '學雜費減免申請', '/test_Exemption.php', '減'),
      _s('0013', '不利處境助學申請', '/test_Support.php', '助'),
      _s('0055', '就學貸款申請系統', '/test_Loan.php', '貸'),
      _s('0014', '學習暨勞僱時數登錄', '/test_Parttime.php', '時'),
      _s('0015', '網路投票', '/test_0015_VoteTrans.php', '投'),
      _s('0056', '活動通報', '/test_Student_Off.php', '報'),
      _s('0040', '校務建言系統', '/test_CCUComment.php', '言'),
      _s('0033', '學生證掛失', 'https://card.ccu.edu.tw/', '卡', '另需登入'),
      _s('0035', '創新創業基地', 'https://startupland.ccu.edu.tw/', '創', '公開網站'),
    ],
  ),
  (
    '宿舍',
    [
      _s('0010', '大學部宿舍管理', '/test_DormApply.php', '宿'),
      _s('0009', '碩/博士宿舍系統', '/test_GradDormApply.php', '碩'),
      _s('0011', '宿舍維修系統', '/test_DormRepair.php', '修'),
      _s('0065', '宿網申請', '/test_0065_DormWifiApply.php', '網', '學生自治網站'),
    ],
  ),
  (
    '總務與財務',
    [
      _s('0042', '付款及所得查詢', '/test_payment.php', '付'),
      _s('0063', '車證申請', '/test_0063_CarApply.php', '車', '限校內網路'),
      _s('0008', '校園授權軟體下載', '/test_0008_Software.php', '軟'),
      _s('0023', '會計Web系統', '/test_Accounting.php', '會'),
      _s('0030', '物品管理系統', '/test_Consume.php', '物'),
      _s('0031', '計畫WEB系統', '/test_Project.php', '計'),
    ],
  ),
  (
    '圖書館',
    [
      _s('0003', 'My圖書館', '/test_0003_Lib.php', '書'),
      _s('0057', '圖書館資源探索', '/test_Lib_Explorer.php', '探'),
      _s('0059', '自學空間', '/test_Lib_Space_Reserves.php', '空'),
      _s('0060', '活動報名系統', '/test_Lib_iActivity_Apply.php', '活'),
    ],
  ),
];

/// Every system by `linkId`.
final campusSystems = {
  for (final (_, systems) in campusGroups)
    for (final s in systems) s.id: s,
};

/// Opens [s] inside the app: systems with their own page go there (the
/// website is a tap further), the rest open the website.
void openCampusSystem(BuildContext context, CampusSystem s) {
  switch (inAppPages[s.id]) {
    case final path?:
      // Pushed, so back returns to wherever it was opened from.
      context.push(path);
    case null:
      openSchoolSite(context, s.id);
  }
}

/// The school's own site for [systemId], signed in through the portal.
void openSchoolSite(BuildContext context, String systemId) {
  final s = campusSystems[systemId]!;
  openCampusPage(context, entryUrl(s), s.name);
}

/// `linkId` → in-app page: 選課系統 (iCCU), 成績查詢 (with eCourse2's running
/// grades), 學籍系統, 學生請假系統, My圖書館, 圖書館資源探索, 自學空間,
/// 活動報名系統, 學習暨勞僱時數登錄, 宿舍維修系統 and 付款及所得查詢.
const inAppPages = {
  '0075': '/more/iccu',
  '0007': '/more/grades',
  '0004': '/more/academic',
  '0064': '/more/leave',
  '0003': '/more/library',
  '0057': '/more/library/search',
  '0059': '/more/space',
  '0060': '/more/events',
  '0014': '/more/parttime',
  '0011': '/more/dorm-repair',
  '0042': '/more/payment',
};

/// In-app pages not yet finished, marked in the list: ALPHA still shows
/// made-up data, BETA reads the real site but is new.
const pageStages = {'0014': 'ALPHA', '0011': 'ALPHA', '0042': 'BETA'};

/// For an in-app page: opens the school's own site for [systemId], signed
/// in through the portal.
class SchoolSiteButton extends StatelessWidget {
  const SchoolSiteButton(this.systemId, {super.key});

  final String systemId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: context.l10n.onSchoolWebsite,
      style: IconButton.styleFrom(
        backgroundColor: scheme.surfaceContainerHigh,
        fixedSize: const Size(40, 40),
      ),
      icon: Icon(Icons.north_east, size: 18, color: scheme.onSurfaceVariant),
      onPressed: () => openSchoolSite(context, systemId),
    );
  }
}

String entryUrl(CampusSystem s) => s.service.startsWith('http')
    ? s.service
    : 'https://portal.ccu.edu.tw/ssoService.php?service=${s.service}&linkId=${s.id}&para=';

const _shapes = [spikyStar, clover, scallop];

/// Each office's systems as a list, the in-app pages first in the group's
/// color, then the school's websites in grey ([query] filters by name).
/// Design round-11 more-a-full.
List<Widget> campusSystemSections(BuildContext context, String query) {
  final t = context.tones;
  final scheme = Theme.of(context).colorScheme;
  // Groups use identity colors (靛、湖綠、珊瑚、橄欖、金黃), not the
  // functional ones, so they never read as "due" or "unread".
  final groupTones = [
    for (final i in [1, 3, 8, 5, 6]) t.identity[i],
  ];
  final q = query.toLowerCase();
  return [
    for (final (gi, (group, systems)) in campusGroups.indexed)
      if ([
            for (final s in systems)
              if (inAppPages.containsKey(s.id)) s,
            for (final s in systems)
              if (!inAppPages.containsKey(s.id)) s,
          ].where((s) => s.name.toLowerCase().contains(q)).toList()
          case final shown when shown.isNotEmpty) ...[
        SectionLabel(group, detail: '${shown.length}'),
        Card(
          color: scheme.surfaceContainerLow,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, s) in shown.indexed) ...[
                if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
                _SystemRow(
                  system: s,
                  tone: groupTones[gi],
                  shape: _shapes[systems.indexOf(s) % _shapes.length],
                  onTap: () => openCampusSystem(context, s),
                ),
              ],
            ],
          ),
        ),
      ],
  ];
}

class _Mark extends StatelessWidget {
  const _Mark({
    required this.text,
    required this.tone,
    required this.shape,
    required this.size,
  });

  final String text;

  /// Null draws the mark in grey, for a school website.
  final Tone? tone;
  final ShapeBorder shape;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: tone?.strong ?? scheme.surfaceContainerHigh,
        shape: shape,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tone?.fill ?? scheme.onSurfaceVariant,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SystemRow extends StatelessWidget {
  const _SystemRow({
    required this.system,
    required this.tone,
    required this.shape,
    required this.onTap,
  });

  final CampusSystem system;
  final Tone tone;
  final ShapeBorder shape;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _Mark(
              text: system.mark,
              tone: inAppPages.containsKey(system.id) ? tone : null,
              shape: shape,
              size: 40,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          system.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (pageStages[system.id] case final stage?) ...[
                        const SizedBox(width: 6),
                        StatusPill(
                          tone: stage == 'ALPHA'
                              ? context.tones.peach
                              : context.tones.lilac,
                          label: stage,
                        ),
                      ],
                    ],
                  ),
                  if (system.note case final note?)
                    Text(
                      note,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                // In-app pages open as pages; the rest go to the school.
                inAppPages.containsKey(system.id)
                    ? Icons.chevron_right
                    : Icons.north_east,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
