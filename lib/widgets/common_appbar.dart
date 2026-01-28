import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onStatisticsPressed;
  final VoidCallback? onChatPressed;
  final VoidCallback? onAddPressed; //영랑 추가
  final bool showBackButton;

  const CommonAppBar({
    super.key,
    required this.title,
    this.onStatisticsPressed,
    this.onChatPressed,
    this.onAddPressed, // 영랑 추가
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF157AFF), Color(0xFF1557FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: showBackButton
          ? const BackButton()
          : IconButton(
        icon: const Icon(Icons.bar_chart),
        onPressed: onStatisticsPressed,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'GmarketSans',
            ),
          ),
        ],
      ),
        // + 버튼
      actionsPadding: const EdgeInsets.only(right: 4), // ✅ 여기 값을 0~4로 조절
      actions: [
        IconButton(
          onPressed: onAddPressed,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
        ),
        // chat 버튼
        IconButton(
          icon: const Icon(Icons.chat, color: Colors.white),
          onPressed: onChatPressed,
        ),

        // ✅ 이게 “오른쪽 끝 여백”을 컨트롤하는 핵심
        const SizedBox(width: 0), // 0~8 사이로 조절해봐
      ],

    );
  }


  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}