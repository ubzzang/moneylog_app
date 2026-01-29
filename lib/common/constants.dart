class Constants {
   // static const String BASE_API_URL = 'http://10.0.2.2:8080';
  static const String BASE_API_URL = 'http://10.100.204.211:8080';

  // API 엔드포인트
  static const String AUTH_ENDPOINT = '/api/authentication';
  static const String MEMBER_ENDPOINT = '/api/members';
  static const String CHAT_ENDPOINT = '/api/chat';
  static const String TRANSACTION_ENDPOINT = '/api/transactions';

   // 추가: backend의 WS 엔드포인트
   static const String VOICE_WS_PATH = '/ws/voice-chat';

   static String voiceWsUrl() {
     final base = BASE_API_URL;
     if (base.startsWith('https://')) {
       return 'wss://${base.substring('https://'.length)}$VOICE_WS_PATH';
     }
     if (base.startsWith('http://')) {
       return 'ws://${base.substring('http://'.length)}$VOICE_WS_PATH';
     }
     return 'ws://$base$VOICE_WS_PATH';
   }
}