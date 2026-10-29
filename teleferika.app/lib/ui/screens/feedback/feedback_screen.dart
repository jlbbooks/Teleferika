import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Form screen for composing app feedback and opening it in the device mail app.
///
/// Builds a `mailto:` URI to [AppConfig.feedbackEmail]. Silent server-side
/// delivery is deferred until a license-server feedback endpoint exists.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final Logger _logger = Logger('FeedbackScreen');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isSending = false;
  String? _appVersionLabel;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _appVersionLabel = '${info.version}+${info.buildNumber}';
      });
    } catch (e, stackTrace) {
      _logger.warning('Failed to load app version', e, stackTrace);
    }
  }

  Uri _buildMailtoUri({
    required String message,
    required String? replyEmail,
  }) {
    final buffer = StringBuffer(message.trim());
    buffer.writeln();
    buffer.writeln();
    buffer.writeln('---');
    if (_appVersionLabel != null) {
      buffer.writeln('App version: $_appVersionLabel');
    }
    final reply = replyEmail?.trim();
    if (reply != null && reply.isNotEmpty) {
      buffer.writeln('Reply-to: $reply');
    }

    // Use encodeComponent (not queryParameters) so spaces are %20, not +,
    // which breaks some mail clients for mailto: URIs.
    final subject = Uri.encodeComponent('${AppConfig.appName} feedback');
    final body = Uri.encodeComponent(buffer.toString());
    return Uri.parse(
      'mailto:${AppConfig.feedbackEmail}?subject=$subject&body=$body',
    );
  }

  Future<void> _sendFeedback() async {
    if (_isSending) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isSending = true);
    final s = S.of(context);

    try {
      final uri = _buildMailtoUri(
        message: _messageController.text,
        replyEmail: _emailController.text,
      );

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!mounted) return;

      if (launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s?.feedback_mail_opened ??
                  'Email app opened. Send the message to finish.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s?.feedback_mail_open_failed ??
                  'Could not open an email app. Configure a mail account and try again.',
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.warning('Failed to open feedback mailto', e, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s?.feedback_mail_open_failed ??
                'Could not open an email app. Configure a mail account and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.feedback_outlined),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                s?.feedback_title ?? 'Feedback',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                s?.feedback_page_description(AppConfig.feedbackEmail) ??
                    'Describe your feedback. Your email app will open with a message ready to send to ${AppConfig.feedbackEmail}.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: s?.feedback_message_label ?? 'Message',
                  hintText:
                      s?.feedback_message_hint ??
                      'What would you like to tell us?',
                  alignLabelWithHint: true,
                ),
                minLines: 6,
                maxLines: 12,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return s?.feedback_message_required ??
                        'Please enter a message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: s?.feedback_reply_email_label ??
                      'Your email (optional)',
                  hintText:
                      s?.your_email_example ?? 'your.email@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) return null;
                  if (!trimmed.contains('@') || !trimmed.contains('.')) {
                    return s?.feedback_email_invalid ??
                        'Enter a valid email address';
                  }
                  return null;
                },
              ),
              if (_appVersionLabel != null) ...[
                const SizedBox(height: 12),
                Text(
                  s?.app_version_label(_appVersionLabel!) ??
                      'App Version: $_appVersionLabel',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendFeedback,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(s?.feedback_send ?? 'Send'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
