import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_status_badge.dart';
import '../../../core/widgets/glass_card.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _messageController = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Welcome to the LIFE-LINK AI synthetic demo assistant. This prototype can help navigate fictional resource listings. It is not connected to external systems and cannot provide clinical advice, assess eligibility or consent, rank recipients, allocate resources, or arrange transport.',
      isUser: false,
    ),
  ];

  void _sendMessage([String? quickText]) {
    final text = quickText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      if (quickText == null) _messageController.clear();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Synthetic demo only: no external database or authority was contacted. Resource listings are unconfirmed enquiry indicators, not guarantees. Clinical and allocation decisions remain with authorized authorities and medical professionals.',
              isUser: false,
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 960 : double.infinity,
          ),
          child: Column(
            children: [
              // Header Sub-bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.auto_awesome,
                      color: AppColors.aiPurple,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'AI Coordination Assistant • Synthetic demo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Spacer(),
                    AppStatusBadge(
                      label: 'DEMO ONLY',
                      variant: StatusBadgeVariant.ai,
                      isPulsing: true,
                    ),
                  ],
                ),
              ),

              // Chat Messages
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return Align(
                      alignment: msg.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        constraints: BoxConstraints(
                          maxWidth: isDesktop ? 680 : double.infinity,
                        ),
                        child: GlassCard(
                          glowAccent: msg.isUser
                              ? GlowAccent.blue
                              : GlowAccent.cyan,
                          backgroundColor: msg.isUser
                              ? AppColors.bgCardHover
                              : AppColors.bgCard,
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      (msg.isUser
                                              ? AppColors.accentSecondary
                                              : AppColors.accentPrimary)
                                          .withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  msg.isUser
                                      ? Icons.person_rounded
                                      : Icons.auto_awesome_rounded,
                                  size: 16,
                                  color: msg.isUser
                                      ? AppColors.accentSecondary
                                      : AppColors.accentPrimary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.isUser
                                          ? 'Officer Sengupta'
                                          : 'LIFE-LINK AI Clinical Engine',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: msg.isUser
                                            ? AppColors.accentSecondary
                                            : AppColors.accentPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      msg.text,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Quick Suggestions Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children:
                      [
                        'Find demo hospitals reporting ventilators',
                        'Show synthetic blood component listings',
                        'Summarize resource status freshness',
                      ].map((suggestion) {
                        return InkWell(
                          onTap: () => _sendMessage(suggestion),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Text(
                              suggestion,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.accentPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),

              // Input Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.bgSecondary,
                  border: Border(
                    top: BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.bgInput,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter clinical triage query or organ logistics question...',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: 'Send',
                      icon: Icons.send_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: () => _sendMessage(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
