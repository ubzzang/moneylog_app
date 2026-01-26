import 'package:flutter/material.dart';
import '../screens/login_screen.dart';

class LoginBanner extends StatelessWidget {
  const LoginBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF4C7BED).withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF4C7BED).withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF4C7BED)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '로그인하고 거래내역을 관리해보세요!',
              style: TextStyle(
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: Text(
              '로그인',
              style: TextStyle(
                color: Color(0xFF4C7BED),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}