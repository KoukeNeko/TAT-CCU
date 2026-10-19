import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/portal_prefs.dart';
import '../core/theme.dart';
import '../core/campus_web_screen.dart';
import '../core/widgets.dart';
import '../../l10n/l10n.dart';

/// Portal home; bounces to the portal login when its session has lapsed.
const portalHome = 'https://portal.ccu.edu.tw/sso_index.php';

/// Goes straight to the CAS form (or through it when already signed in).
const portalCasLogin = 'https://portal.ccu.edu.tw/login_check_cas.php';

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
final _groups = <(String, List<CampusSystem>)>[
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

/// Every system by `linkId`, for screens that show favorites elsewhere.
final campusSystems = {
  for (final (_, systems) in _groups)
    for (final s in systems) s.id: s,
};

/// Records the visit and opens [s] inside the app: systems with their own
/// page go there (the website is a tap further), the rest open the website.
void openCampusSystem(BuildContext context, PortalPrefs prefs, CampusSystem s) {
  prefs.opened(s.id);
  switch (inAppPages[s.id]) {
    case final path?:
      // Pushed, so back returns to wherever it was opened from.
      context.push(path);
    case null:
      openCampusPage(context, entryUrl(s), s.name);
  }
}

/// `linkId` → in-app page: 選課系統 (iCCU), 學籍系統, 學生請假系統 and My圖書館.
const inAppPages = {
  '0075': '/more/iccu',
  '0004': '/more/academic',
  '0064': '/more/leave',
  '0003': '/more/library',
};

String entryUrl(CampusSystem s) => s.service.startsWith('http')
    ? s.service
    : 'https://portal.ccu.edu.tw/ssoService.php?service=${s.service}&linkId=${s.id}&para=';

const _shapes = [spikyStar, clover, scallop];

/// Design A3 "寬列＋最近開啟" (design/round-07): favorites as tiles, recently
/// opened as chips, then every system as a wide row grouped by office.
class PortalScreen extends StatefulWidget {
  const PortalScreen({super.key});

  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PortalPrefs>();
    final t = context.tones;
    final scheme = Theme.of(context).colorScheme;
    // Groups use identity colors (靛、湖綠、珊瑚、橄欖、金黃), not the
    // functional ones, so they never read as "due" or "unread".
    final groupTones = [
      for (final i in [1, 3, 8, 5, 6]) t.identity[i],
    ];

    // Each system keeps its group's color and its slot's silhouette.
    final look = <String, (Tone, ShapeBorder)>{};
    final byId = <String, CampusSystem>{};
    for (final (gi, (_, systems)) in _groups.indexed) {
      for (final (i, s) in systems.indexed) {
        look[s.id] = (groupTones[gi], _shapes[i % _shapes.length]);
        byId[s.id] = s;
      }
    }

    void open(CampusSystem s) => openCampusSystem(context, prefs, s);

    final q = _query.toLowerCase();
    final searching = q.isNotEmpty;
    final favorites = [for (final id in prefs.favorites) ?byId[id]];
    final recent = [for (final id in prefs.recent) ?byId[id]];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, context.l10n.campusSystems),
      body: Builder(
        // Reads insets from inside this Scaffold, below the glass app bar.
        builder: (context) => ListView(
          padding: scrollPadding(context),
          children: [
            SearchBar(
              hintText: context.l10n.searchSystems,
              leading: const Icon(Icons.search),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
            if (!searching && favorites.isNotEmpty) ...[
              _Label(
                context.l10n.favorites,
                trailing: TextButton(
                  onPressed: () => _editFavorites(context, prefs),
                  child: Text(context.l10n.edit),
                ),
              ),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.82,
                children: [
                  for (final s in favorites)
                    _FavoriteTile(
                      system: s,
                      tone: look[s.id]!.$1,
                      shape: look[s.id]!.$2,
                      onTap: () => open(s),
                    ),
                ],
              ),
            ],
            if (!searching && recent.isNotEmpty) ...[
              _Label(context.l10n.recentlyOpened),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: recent.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => ActionChip(
                    label: Text(recent[i].name),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                    backgroundColor: scheme.surfaceContainerLow,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    onPressed: () => open(recent[i]),
                  ),
                ),
              ),
            ],
            for (final (group, systems) in _groups)
              if (systems
                      .where((s) => s.name.toLowerCase().contains(q))
                      .toList()
                  case final shown when shown.isNotEmpty) ...[
                _Label(group, count: shown.length),
                Card(
                  color: scheme.surfaceContainerLow,
                  clipBehavior: Clip.antiAlias,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      for (final (i, s) in shown.indexed) ...[
                        if (i > 0)
                          Divider(height: 1, color: scheme.outlineVariant),
                        _SystemRow(
                          system: s,
                          tone: look[s.id]!.$1,
                          shape: look[s.id]!.$2,
                          onTap: () => open(s),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Future<void> _editFavorites(BuildContext context, PortalPrefs prefs) async {
    final picked = [...prefs.favorites];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          builder: (context, controller) => ListView(
            controller: controller,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  context.l10n.favoritesCount(
                    picked.length,
                    PortalPrefs.maxFavorites,
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final (_, systems) in _groups)
                for (final s in systems)
                  CheckboxListTile(
                    value: picked.contains(s.id),
                    title: Text(s.name),
                    onChanged: (on) => setSheet(() {
                      if (on == true &&
                          picked.length < PortalPrefs.maxFavorites) {
                        picked.add(s.id);
                      } else if (on == false) {
                        picked.remove(s.id);
                      }
                    }),
                  ),
            ],
          ),
        ),
      ),
    );
    await prefs.setFavorites(picked);
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.count, this.trailing});

  final String text;
  final int? count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 0, 10),
      child: SizedBox(
        height: 28,
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (count != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: ShapeDecoration(
                  color: scheme.surfaceContainerHigh,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({
    required this.text,
    required this.tone,
    required this.shape,
    required this.size,
  });

  final String text;
  final Tone tone;
  final ShapeBorder shape;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(color: tone.strong, shape: shape),
      child: Text(
        text,
        style: TextStyle(
          color: tone.fill,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
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
    return ToneBlock(
      tone: tone,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      onTap: onTap,
      child: Column(
        children: [
          _Mark(text: system.mark, tone: tone, shape: shape, size: 48),
          const Spacer(),
          Text(
            system.name.replaceAll('系統', ''),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
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
            _Mark(text: system.mark, tone: tone, shape: shape, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    system.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
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
                Icons.north_east,
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
