import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/home_screen.dart';

class MenuDrawer extends StatelessWidget {
  final bool isLoggedIn;

  const MenuDrawer({
    super.key,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(),

            // 메뉴 항목들
            if (!isLoggedIn) ...[
              _buildMenuItem(
                context,
                icon: Icons.login,
                title: '로그인',
                color: Color(0xFF3498DB),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
              ),
              _buildMenuItem(
                context,
                icon: Icons.person_add,
                title: '회원가입',
                color: Color(0xFF3498DB),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignupScreen()),
                  );
                },
              ),
              Divider(),
            ],

            _buildMenuItem(
              context,
              icon: Icons.info_outline,
              title: '앱 정보',
              color: Colors.grey[700]!,
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),

            if (isLoggedIn) ...[
              Divider(),
              _buildMenuItem(
                context,
                icon: Icons.logout,
                title: '로그아웃',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _handleLogout(context);
                },
              ),
            ],

            Spacer(),

            // 하단 버전 정보
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'CashTalk v1.0.0',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 헤더
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF3498DB),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 48,
            color: Colors.white,
          ),
          SizedBox(height: 12),
          Text(
            isLoggedIn ? '환영합니다!' : 'CashTalk',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'GmarketSans',
            ),
          ),
          if (!isLoggedIn)
            Text(
              'AI 가계부 서비스',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
        ],
      ),
    );
  }

  // 메뉴 아이템
  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required Color color,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: title == '로그아웃' ? Colors.red : null,
        ),
      ),
      onTap: onTap,
    );
  }

  // 앱 정보 다이얼로그
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Color(0xFF3498DB)),
            SizedBox(width: 8),
            Text('CashTalk'),
          ],
        ),
        content: Text(
          'AI와 함께하는 스마트 가계부\n\n'
              '자연스러운 대화로 수입과 지출을 관리하세요.\n\n'
              'Version 1.0.0',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  // 로그아웃
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('로그아웃'),
        content: Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(isLoggedIn: false),
                ),
              );
            },
            child: Text(
              '로그아웃',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}