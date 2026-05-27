import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../services/comment_service.dart';

Future<int?> showCommentsSheet(
  BuildContext context,
  int mediaId,
  int currentCount,
  String authToken,
) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _CommentsSheet(
      mediaId: mediaId,
      currentCount: currentCount,
      authToken: authToken,
    ),
  );
}

class _CommentsSheet extends StatefulWidget {
  final int mediaId;
  final int currentCount;
  final String authToken;

  const _CommentsSheet({
    required this.mediaId,
    required this.currentCount,
    required this.authToken,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Comment> _comments = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _count = widget.currentCount;
    _fetch();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await CommentService.fetchComments(widget.mediaId, widget.authToken);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _comments = result.comments;
        if (_comments.length > _count) _count = _comments.length;
      } else {
        _error = result.message;
      }
    });
  }

  Future<void> _submit() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final comment = await CommentService.addComment(widget.mediaId, text, widget.authToken);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _textCtrl.clear();
      _count++;
      if (comment != null) {
        _comments.add(comment);
      } else {
        _comments.add(Comment(
          id: -_count,
          authorUsername: '',
          authorDisplayName: 'You',
          body: text,
        ));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Comments ($_count)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, _count),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              TextButton(onPressed: _fetch, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _comments.isEmpty
                          ? Center(
                              child: Text(
                                'No comments yet.\nBe the first!',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _comments.length,
                              itemBuilder: (_, i) => _CommentTile(
                                comment: _comments[i],
                                theme: theme,
                              ),
                            ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: 'Add a comment…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _sending
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton.filled(
                          icon: const Icon(Icons.send),
                          onPressed: _submit,
                          iconSize: 20,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final ThemeData theme;

  const _CommentTile({required this.comment, required this.theme});

  @override
  Widget build(BuildContext context) {
    final initials = comment.authorDisplayName.isNotEmpty
        ? comment.authorDisplayName[0].toUpperCase()
        : '?';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              initials,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorDisplayName.isNotEmpty
                          ? comment.authorDisplayName
                          : comment.authorUsername,
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (comment.createdAt != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        _relativeTime(comment.createdAt),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _relativeTime(String? iso) {
  if (iso == null) return '';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${dt.day}/${dt.month}/${dt.year}';
}
