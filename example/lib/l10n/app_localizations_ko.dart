// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get navPlayground => '플레이그라운드';

  @override
  String get navExamples => '예제';

  @override
  String get navGettingStarted => '시작하기';

  @override
  String get menu => '메뉴';

  @override
  String get playgroundIntro => '옵션을 바꾸면 채팅에 바로 반영돼요. 메시지는 시뮬레이션이라 마음껏 보내 보세요.';

  @override
  String get preview => '미리보기';

  @override
  String get settings => '설정';

  @override
  String get receiveMessage => '메시지 받기';

  @override
  String get markAllRead => '모두 읽음';

  @override
  String get restart => '처음부터';

  @override
  String get online => '온라인';

  @override
  String get inputHint => '메시지를 입력해 주세요';

  @override
  String incomingMessage(int count) {
    return '새로 도착한 메시지예요 ($count)';
  }

  @override
  String autoReply(String text) {
    return '\"$text\" 잘 받았어.';
  }

  @override
  String newMessageFrom(String name) {
    return '$name님의 새 메시지';
  }

  @override
  String get readOnlyNotice => '읽기 전용 채팅방이에요';

  @override
  String get menuRetry => '다시 보내기';

  @override
  String get menuDelete => '삭제하기';

  @override
  String get menuCopy => '복사하기';

  @override
  String get sectionLayout => '레이아웃';

  @override
  String get startAtTopTitle => '메시지가 적으면 위에서부터';

  @override
  String get startAtTopDesc => '아래에 붙지 않고 위에서 시작해요';

  @override
  String get senderSideTitle => '내 메시지 위치';

  @override
  String get sideRight => '오른쪽';

  @override
  String get sideLeft => '왼쪽';

  @override
  String get sidePadding => '좌우 여백';

  @override
  String get sectionBubble => '말풍선';

  @override
  String get bubbleColor => '내 말풍선 색';

  @override
  String get cornerRadius => '모서리 둥글기';

  @override
  String get maxWidth => '최대 너비';

  @override
  String get noLimit => '제한 없음';

  @override
  String get appearAnimation => '등장 애니메이션';

  @override
  String get off => '끄기';

  @override
  String get sectionDisplay => '표시 요소';

  @override
  String get timeTitle => '보낸 시간';

  @override
  String get timeDesc => '끄면 기본 형식으로 보여요';

  @override
  String get profileTitle => '상대 프로필';

  @override
  String get unreadTitle => '안 읽음 표시';

  @override
  String get unreadDesc => '새로 보내는 메시지부터 보여요';

  @override
  String get longPressMenuTitle => '길게 눌러 메뉴 열기';

  @override
  String get notificationTitle => '새 메시지 알림';

  @override
  String get notificationDesc => '위로 올려 둔 채 메시지를 받으면 보여요';

  @override
  String get dateSeparatorTitle => '날짜 구분선 꾸미기';

  @override
  String get readOnlyTitle => '읽기 전용';

  @override
  String get readOnlyDesc => '입력창 대신 안내 문구를 보여요';

  @override
  String get sectionServer => '시뮬레이션';

  @override
  String get storedMessages => '저장된 메시지';

  @override
  String get none => '없음';

  @override
  String messageCount(int count) {
    return '$count건';
  }

  @override
  String get responseTime => '응답 시간';

  @override
  String seconds(String value) {
    return '$value초';
  }

  @override
  String get imagesTitle => '이미지 메시지 섞기';

  @override
  String get imagesDesc => '30%가 늦게 로드되는 이미지예요';

  @override
  String get sendResult => '보내기 결과';

  @override
  String get resultSuccess => '성공';

  @override
  String get resultFail => '실패';

  @override
  String get resultBlock => '차단';

  @override
  String get autoReplyTitle => '자동 답장';

  @override
  String get autoReplyDesc => '보내기에 성공하면 상대가 읽고 답해요';

  @override
  String get examplesIntro =>
      '서버에서 메시지를 받아 오는 채팅방들이에요. 방마다 메시지 수와 응답 속도가 달라서 스크롤 동작을 확인하기 좋아요.';

  @override
  String get roomShortTitle => '짧은 방';

  @override
  String get roomShortDesc => '메시지 5건. 화면을 다 채우지 못해요';

  @override
  String get roomNormalTitle => '보통 방';

  @override
  String get roomNormalDesc => '메시지 60건. 30건씩 2페이지예요';

  @override
  String get roomLongTitle => '긴 방';

  @override
  String get roomLongDesc => '메시지 500건. 위로 스크롤하면 30건씩 더 불러와요';

  @override
  String get roomImagesTitle => '이미지 많은 방';

  @override
  String get roomImagesDesc => '메시지 120건 중 40%가 늦게 로드되며 커지는 이미지예요';

  @override
  String get roomSlowTitle => '느린 서버 방';

  @override
  String get roomSlowDesc => '메시지 200건. 서버 응답이 2초 걸려요';

  @override
  String get loadingOlder => '이전 메시지 불러오는 중';

  @override
  String get gsIntro =>
      '메시지 묶기, 날짜 구분선, 전송 실패와 재전송, 이전 메시지 불러오기를 ChatController 하나로 다룰 수 있어요.';

  @override
  String get step1Title => '패키지를 설치해요';

  @override
  String get step2Title => '메시지 내용을 그릴 요소를 만들어요';

  @override
  String get step2Desc => '텍스트, 이미지 등 말풍선 안에 들어갈 내용을 MessageElement 로 정의해요.';

  @override
  String get step3Title => '채팅 화면을 붙여요';

  @override
  String get step3Desc =>
      '서버에서 받은 메시지는 setMessages, 위로 스크롤해서 받은 이전 메시지는 appendMessages 로 넣어요.';

  @override
  String get step4Title => '메시지를 보내요';

  @override
  String get step4Desc => 'null 을 돌려주면 실패로 표시되고, 길게 눌러 다시 보낼 수 있어요.';

  @override
  String get gsCtaTitle => '옵션을 직접 바꿔 보고 싶다면';

  @override
  String get gsCtaDesc => '플레이그라운드에서 설정마다 어떻게 달라지는지 바로 볼 수 있어요.';

  @override
  String get gsCtaButton => '열어 보기';

  @override
  String get copy => '복사';

  @override
  String get copied => '복사했어요';
}
