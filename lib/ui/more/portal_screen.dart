import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';

/// Portal home; bounces to the portal login when its session has lapsed.
const portalHome = 'https://portal.ccu.edu.tw/sso_index.php';

/// Goes straight to the CAS form (or through it when already signed in).
const portalCasLogin = 'https://portal.ccu.edu.tw/login_check_cas.php';

typedef _System = (String linkId, String name, String service);

/// Portal tiles and the `ssoService.php` service each one hands off to,
/// read from the logged-in portal on 2026-10-18 (CAS 校務系統清單.md).
const _groups = <(String, List<_System>)>[
  (
    '教務與學習',
    [
      ('0075', '選課系統', '/test_0075_nidalap_CourseSelection.php'),
      ('0007', '成績查詢', '/test_0007_GradeQuery.php'),
      ('0004', '學籍系統', '/test_Academic.php'),
      ('0053', '學分抵免申請', '/test_DeductApply.php'),
      ('0054', '學位考試系統', '/test_Qualify.php'),
      ('0068', '微學分管理系統', '/test_0068_MicroCredit.php'),
      ('0006', '生涯定向系統', '/test_ePortfolio.php'),
      ('0071', '課間增能星級行動平台', '/test_0071_Counseling.php'),
    ],
  ),
  (
    '學務與學生事務',
    [
      ('0064', '學生請假系統', '/test_0064_StuOff.php'),
      ('0067', '學生網路離校系統', '/test_0067_Leave.php'),
      ('0019', '初次晤談預約系統', '/test_Booking.php'),
      ('0012', '學雜費減免申請', '/test_Exemption.php'),
      ('0013', '不利處境助學申請', '/test_Support.php'),
      ('0055', '就學貸款申請系統', '/test_Loan.php'),
      ('0014', '學習暨勞僱時數登錄', '/test_Parttime.php'),
      ('0015', '網路投票', '/test_0015_VoteTrans.php'),
      ('0056', '活動通報', '/test_Student_Off.php'),
      ('0040', '校務建言系統', '/test_CCUComment.php'),
      ('0033', '學生證掛失', 'https://card.ccu.edu.tw/'),
      ('0035', '創新創業基地', 'https://startupland.ccu.edu.tw/'),
    ],
  ),
  (
    '宿舍',
    [
      ('0010', '大學部宿舍管理', '/test_DormApply.php'),
      ('0009', '碩/博士宿舍系統', '/test_GradDormApply.php'),
      ('0011', '宿舍維修系統', '/test_DormRepair.php'),
      ('0065', '宿網申請', '/test_0065_DormWifiApply.php'),
    ],
  ),
  (
    '總務與財務',
    [
      ('0042', '付款及所得查詢', '/test_payment.php'),
      ('0063', '車證申請（限校內IP）', '/test_0063_CarApply.php'),
      ('0008', '校園授權軟體下載', '/test_0008_Software.php'),
      ('0023', '會計Web系統', '/test_Accounting.php'),
      ('0030', '物品管理系統', '/test_Consume.php'),
      ('0031', '計畫WEB系統', '/test_Project.php'),
    ],
  ),
  (
    '圖書館',
    [
      ('0003', 'My圖書館', '/test_0003_Lib.php'),
      ('0057', '圖書館資源探索', '/test_Lib_Explorer.php'),
      ('0059', '自學空間', '/test_Lib_Space_Reserves.php'),
      ('0060', '活動報名系統', '/test_Lib_iActivity_Apply.php'),
    ],
  ),
];

String _entryUrl(_System s) => s.$3.startsWith('http')
    ? s.$3
    : 'https://portal.ccu.edu.tw/ssoService.php?service=${s.$3}&linkId=${s.$1}&para=';

class PortalScreen extends StatelessWidget {
  const PortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tones = context.tones.cycle;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: subBar(context, '校務系統'),
      body: // Builder: the list must read insets from inside this Scaffold,
          // where the glass app bar's height is part of the padding.
          Builder(
            builder: (context) => ListView(
              padding: scrollPadding(context, top: 0),
              children: [
                for (final (i, (group, systems)) in _groups.indexed) ...[
                  SectionLabel(group),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in systems)
                        ActionChip(
                          label: Text(s.$2),
                          labelStyle: TextStyle(
                            color: tones[i % tones.length].ink,
                            fontWeight: FontWeight.w800,
                          ),
                          backgroundColor: tones[i % tones.length].fill,
                          side: BorderSide.none,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          // Same sign-in sheet as the eCourse2 login, so the CAS
                          // sign-in made there opens systems without a password.
                          onPressed: () => openSignInSheet(_entryUrl(s)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
    );
  }
}
