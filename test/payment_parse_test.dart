import 'package:flutter_test/flutter_test.dart';
import 'package:tat_ccu/ui/more/payment_screen.dart';

void main() {
  test('payments read ROC dates and money, newest first, once each', () {
    final row = {
      'expreg_no': 'A1',
      'expreg_seri_cd': '01',
      'reg_status_name': '已付款',
      'pay_date': '115/05/15',
      'pay_amt': r'$4,214',
      'bank_acc_no': '000123456781234',
      'invoice_no': '',
      'c_name': '',
      'unit_name': '圖書館',
      'purp_note': '學習型助學金',
    };
    final payments = paymentsOf({
      'rows': [
        row,
        {...row, 'expreg_no': 'A2', 'pay_date': '115/10/05'},
        row, // repeated by paging
        {...row, 'expreg_no': 'A3', 'pay_date': ''},
      ],
    });
    expect(payments.map((p) => p.id), ['A2', 'A1']);
    expect(payments.last.date, DateTime(2026, 5, 15));
    expect(payments.last.amount, 4214);
  });

  test('income is keyed by ROC year with plain amounts', () {
    final income = incomeOf({
      'income': {
        '114': [
          {
            'incoming_no': '50',
            'pro_cd': 'X',
            'in_amt_total': r'$1,234',
            'tax_amt_total': r'$0',
            'net_amt_total': r'$1,234',
            'labor_save_amt_total': r'$0',
          },
        ],
      },
    });
    expect(income[114]!.single.net, 1234);
  });
}
