import 'package:easy_comment/easy_comment.dart';
import 'package:easy_helpers/easy_helpers.dart';
import 'package:easy_post_v2/easy_post_v2.dart';
import 'package:flutter/material.dart';

class PostCommentTextButton extends StatelessWidget {
  const PostCommentTextButton({
    super.key,
    required this.post,
    required this.child,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior,
    this.statesController,
    this.isSemanticButton,
    this.isCreated,
  });

  final Post post;
  final Widget child;
  final ButtonStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip? clipBehavior;
  final WidgetStatesController? statesController;
  final bool? isSemanticButton;
  final Function(bool?)? isCreated;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: style,
      focusNode: focusNode,
      autofocus: autofocus,
      clipBehavior: clipBehavior,
      statesController: statesController,
      isSemanticButton: isSemanticButton,
      onPressed: () async {
        try {
          final re = await CommentService.instance.showCommentEditDialog(
            context: context,
            documentReference: post.ref,
            focusOnContent: false,
          );

          isCreated?.call(re);
        } catch (e) {
          if (context.mounted) {
            error(context: context, message: Text('$e'));
          }
          rethrow;
        }
      },
      child: child,
    );
  }
}
