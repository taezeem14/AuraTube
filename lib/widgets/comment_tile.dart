import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/youtube_comment.dart';
import '../theme/aura_theme.dart';

class CommentTile extends StatelessWidget {
  final YouTubeComment comment;

  const CommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuraColors.surfaceHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuraColors.outline.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Avatar Circle
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AuraColors.primaryBlue.withValues(alpha: 0.2),
              border: Border.all(color: AuraColors.primaryBlueLight.withValues(alpha: 0.4), width: 1),
            ),
            child: Center(
              child: Text(
                comment.author.isNotEmpty ? comment.author[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: AuraColors.primaryBlueLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AuraColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      comment.publishedTime,
                      style: const TextStyle(
                        color: AuraColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    if (comment.isPinned) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AuraColors.primaryBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            FaIcon(FontAwesomeIcons.thumbtack, size: 8, color: AuraColors.accentCyan),
                            SizedBox(width: 3),
                            Text('PINNED', style: TextStyle(color: AuraColors.accentCyan, fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: const TextStyle(
                    color: AuraColors.textPrimary,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.thumbsUp, color: AuraColors.textMuted, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      comment.likeCountFormatted,
                      style: const TextStyle(color: AuraColors.textMuted, fontSize: 11),
                    ),
                    if (comment.replyCount > 0) ...[
                      const SizedBox(width: 14),
                      const FaIcon(FontAwesomeIcons.comments, color: AuraColors.textMuted, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.replyCount} replies',
                        style: const TextStyle(color: AuraColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
