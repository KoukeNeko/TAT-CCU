import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'floating_dock.dart';
import 'theme.dart';
import 'widgets.dart';

/// Opens [ComposeScreen] over the nav bar; true once [send] went through.
Future<bool> compose(
  BuildContext context, {
  required String title,
  required String hint,
  required Future<void> Function(String subject, String text) send,
  String? replyingTo,
  bool withSubject = false,
}) async =>
    await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ComposeScreen(
          title: title,
          hint: hint,
          send: send,
          replyingTo: replyingTo,
          withSubject: withSubject,
        ),
      ),
    ) ??
    false;

/// Writing a reply, discussion or comment: 取消 and 送出 in the bar, the
/// text below. A failed send keeps the text and says why.
class ComposeScreen extends StatefulWidget {
  const ComposeScreen({
    super.key,
    required this.title,
    required this.hint,
    required this.send,
    this.replyingTo,
    this.withSubject = false,
  });

  final String title, hint;
  final String? replyingTo;
  final bool withSubject;
  final Future<void> Function(String subject, String text) send;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _subject = TextEditingController();
  final _text = TextEditingController();
  var _sending = false;

  bool get _ready =>
      !_sending &&
      _text.text.trim().isNotEmpty &&
      (!widget.withSubject || _subject.text.trim().isNotEmpty);

  @override
  void dispose() {
    _subject.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await widget.send(_subject.text.trim(), _text.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      showSendError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 88,
        leading: TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        centerTitle: true,
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Space.m),
            child: FilledButton(
              onPressed: _ready ? _send : null,
              child: _sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(l10n.submit),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          pageMargin,
          Space.s,
          pageMargin,
          Space.xxl,
        ),
        children: [
          if (widget.replyingTo case final name?)
            Padding(
              padding: const EdgeInsets.only(left: Space.xs, bottom: Space.m),
              child: Text(
                l10n.replyingTo(name),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (widget.withSubject) ...[
            TextField(
              controller: _subject,
              autofocus: true,
              enabled: !_sending,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(hintText: l10n.subject),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _text,
            autofocus: !widget.withSubject,
            enabled: !_sending,
            onChanged: (_) => setState(() {}),
            minLines: 8,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(hintText: widget.hint),
            style: const TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// A field-looking bar that opens [ComposeScreen]: in a [FloatingDock] over
/// the page, or [inline] inside a list.
class ComposeBar extends StatelessWidget {
  const ComposeBar({
    super.key,
    required this.hint,
    required this.onTap,
    this.inline = false,
  });

  final String hint;
  final VoidCallback onTap;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final row = InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.l,
          vertical: Space.m,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hint,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.edit_outlined, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
    if (!inline) {
      return FloatingDock(child: row);
    }
    return Material(
      color: scheme.surfaceContainerHigh,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: row,
    );
  }
}
