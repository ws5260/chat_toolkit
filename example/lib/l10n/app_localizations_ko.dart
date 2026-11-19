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
  String get bubbleColor => '내 말풍선 색';

  @override
  String get maxWidth => '최대 너비';

  @override
  String get noLimit => '제한 없음';

  @override
  String get appearAnimation => '등장 애니메이션';

  @override
  String get off => '끄기';

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

  @override
  String get search => '검색';

  @override
  String get searchHint => '메시지 검색';

  @override
  String get searchNoResults => '결과 없음';

  @override
  String get searchOlder => '이전 결과';

  @override
  String get searchNewer => '다음 결과';

  @override
  String get closeSearch => '검색 닫기';

  @override
  String get jumpToLatest => '최신 메시지로';

  @override
  String get receiverBubbleColor => '상대 말풍선 색';

  @override
  String get groupingTitle => '메시지 묶기';

  @override
  String get groupingDesc => '같은 사람이 같은 분에 보낸 메시지를 하나로 묶어요';

  @override
  String get sendingIndicatorTitle => '전송 중 표시 커스텀';

  @override
  String get sendingIndicatorDesc => '서버가 응답할 때까지 말풍선에 보여요';

  @override
  String get sending => '보내는 중…';

  @override
  String searchResultCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String get searchShortcutsTitle => '단축키';

  @override
  String get close => '닫기';

  @override
  String get cancel => '취소';

  @override
  String get send => '전송';

  @override
  String get verticalPadding => '위아래 여백';

  @override
  String get backgroundTitle => '채팅 배경';

  @override
  String get lookCustom => '커스텀';

  @override
  String get lookLibrary => '기본';

  @override
  String get fontSize => '글자 크기';

  @override
  String get bubblePaddingH => '안쪽 여백 (좌우)';

  @override
  String get bubblePaddingV => '안쪽 여백 (위아래)';

  @override
  String get hide => '숨김';

  @override
  String get myProfileTitle => '내 프로필';

  @override
  String get myProfileDesc => '내 메시지 옆에도 프로필 표시';

  @override
  String get scrollThresholdTitle => '자동 스크롤 범위';

  @override
  String get menuPopup => '팝업';

  @override
  String get menuSheet => '바텀시트';

  @override
  String get longPressTitle => '길게 눌러 열기';

  @override
  String get longPressDesc => '끄면 우클릭으로만 열려요';

  @override
  String get hapticTitle => '햅틱 피드백';

  @override
  String get confirmDeleteTitle => '실패한 메시지 삭제 확인';

  @override
  String get confirmDeleteDesc => '전송 결과를 실패로 두고 삭제해 보세요';

  @override
  String get deleteFailedTitle => '이 메시지를 삭제할까요?';

  @override
  String get deleteFailedBody => '전송되지 않아 상대방은 보지 못했어요.';

  @override
  String get kind => '종류';

  @override
  String get designBackground => '배경색';

  @override
  String get designTextColor => '글자색';

  @override
  String get designRadius => '모서리';

  @override
  String get designHeight => '높이';

  @override
  String get designSize => '크기';

  @override
  String get designShape => '모양';

  @override
  String get roundness => '둥글기';

  @override
  String get roundFull => '완전 둥글게';

  @override
  String get weekdayTitle => '요일 표시';

  @override
  String get use24hTitle => '24시간제';

  @override
  String get searchShortcutsDesc => 'Ctrl/⌘ + F로 열기, Enter로 다음 결과, Esc로 닫기';

  @override
  String get sectionBehavior => '동작';

  @override
  String get partBubble => '말풍선';

  @override
  String get partBubbleDesc =>
      'senderBubbleBuilder와 receiverBubbleBuilder는 메시지 내용을 child로 받아요. 원하는 컨테이너로 감싸기만 하면 됩니다.';

  @override
  String get partSearch => '검색창';

  @override
  String get partSearchDesc =>
      '채팅 위 검색 버튼으로 열어 보세요. 툴킷의 ChatSearchBar를 꾸미거나, ChatSearchController의 search(), showOlder(), showNewer(), close()로 직접 만든 바를 연결할 수 있어요.';

  @override
  String get partInput => '입력창';

  @override
  String get partInputDesc =>
      '채팅은 customInputField를 아래에 배치만 해요. 입력창과 전송(controller.dispatchMessage)은 직접 만듭니다.';

  @override
  String get partNotice => '새 메시지 알림';

  @override
  String get partNoticeDesc =>
      '위로 스크롤한 상태에서 메시지가 오면 보여요. 위로 스크롤한 뒤 채팅 위의 받기 버튼을 눌러 보세요.';

  @override
  String get partSeparator => '날짜 구분선';

  @override
  String get partSeparatorDesc => '날짜가 바뀌는 곳에 보여요. 빌더는 그날의 timestamp를 받습니다.';

  @override
  String get partTime => '시간';

  @override
  String get partTimeDesc => '묶음의 마지막 말풍선 옆에 보여요. 빌더는 메시지 timestamp를 받습니다.';

  @override
  String get partProfile => '프로필';

  @override
  String get partProfileDesc => '메시지 묶음마다 한 번 보여요. 빌더는 보낸 사람 이름을 받습니다.';

  @override
  String get partRead => '읽음 표시';

  @override
  String get partReadDesc =>
      'SenderMessage(isRead: false/true)에 보여요. 메시지를 보낸 뒤 모두 읽음을 눌러 보세요.';

  @override
  String get partMenu => '말풍선 메뉴';

  @override
  String get partMenuDesc =>
      '말풍선을 길게 누르거나 우클릭하세요. 툴킷 팝업에 항목만 넣거나, 핸들러로 원하는 UI를 띄울 수 있어요.';

  @override
  String get partReadOnly => '읽기 전용 안내';

  @override
  String get partReadOnlyDesc =>
      'Chat(readOnly: true)일 때 입력창 대신 readOnlyWidget이 보여요.';

  @override
  String get studioEdit => '편집';

  @override
  String get studioReset => '처음 상태로';

  @override
  String get tabStructure => '구성';

  @override
  String get tabStyle => '박스';

  @override
  String get tabCode => '코드';

  @override
  String get layoutAxis => '배치 방향';

  @override
  String get axisRow => '가로';

  @override
  String get axisColumn => '세로';

  @override
  String get layoutMain => '방향 정렬';

  @override
  String get layoutCross => '교차 정렬';

  @override
  String get layoutGap => '요소 간격';

  @override
  String get alignStart => '시작';

  @override
  String get alignCenter => '가운데';

  @override
  String get alignEnd => '끝';

  @override
  String get alignBetween => '양끝';

  @override
  String get elements => '요소';

  @override
  String get elementsHint => '⋮⋮를 끌어 순서를 바꾸고, 요소를 눌러 스타일을 바꾸세요';

  @override
  String get addElement => '추가';

  @override
  String get elementVisible => '보이기/숨기기';

  @override
  String get elContent => '메시지 내용';

  @override
  String get elText => '텍스트';

  @override
  String get elIcon => '아이콘';

  @override
  String get elField => '입력칸';

  @override
  String get elButton => '버튼';

  @override
  String get elBadge => '배지';

  @override
  String get elAvatar => '프로필 사진';

  @override
  String get elSpacer => '빈 공간';

  @override
  String get elDivider => '선';

  @override
  String get propSource => '표시 내용';

  @override
  String get propText => '문구';

  @override
  String get propTextUnread => '읽기 전 문구';

  @override
  String get propTextRead => '읽은 후 문구';

  @override
  String get propIconUnread => '읽기 전 아이콘';

  @override
  String get propIconRead => '읽은 후 아이콘';

  @override
  String get propHint => '힌트 문구';

  @override
  String get propAction => '동작';

  @override
  String get propBold => '굵게';

  @override
  String get propColor => '색';

  @override
  String get propExpand => '남은 공간 채우기';

  @override
  String get propWidth => '너비';

  @override
  String get propThickness => '두께';

  @override
  String get lookFilled => '채움';

  @override
  String get srcLiteral => '직접 입력';

  @override
  String get srcName => '이름';

  @override
  String get srcTime => '시간';

  @override
  String get srcDate => '날짜';

  @override
  String get srcCount => '결과 개수';

  @override
  String get srcRead => '읽음 상태';

  @override
  String get srcNotice => '알림 문구';

  @override
  String get srcReadOnly => '안내 문구';

  @override
  String get actNone => '없음';

  @override
  String get actAttach => '첨부';

  @override
  String get boxGradient => '그라데이션';

  @override
  String get boxGradientTo => '그라데이션 끝 색';

  @override
  String get boxBorder => '테두리 두께';

  @override
  String get boxBorderColor => '테두리 색';

  @override
  String get boxShadow => '그림자';

  @override
  String get boxMarginH => '바깥 여백 (좌우)';

  @override
  String get boxMarginV => '바깥 여백 (위아래)';

  @override
  String get boxAuto => '자동';

  @override
  String get boxFill => '가로로 꽉 채우기';

  @override
  String get boxAlign => '위치';

  @override
  String get colorHue => '색상';

  @override
  String get colorSaturation => '채도';

  @override
  String get colorBrightness => '밝기';

  @override
  String get colorOpacity => '불투명도';

  @override
  String get colorHexHint => 'RRGGBB 또는 AARRGGBB 입력 후 Enter';

  @override
  String get sectionParts => '컴포넌트 디자인';

  @override
  String get sectionPartsDesc =>
      '커스텀을 고르면 채팅 옆에 편집 패널이 열려요. 요소를 추가·삭제·순서 변경하고, 요소와 박스의 스타일을 자유롭게 바꿀 수 있어요. 바꾸는 즉시 채팅에 반영됩니다.';

  @override
  String studioTitle(String part) {
    return '$part 디자인';
  }

  @override
  String get previewNotice => '미리보기: 위로 스크롤 후 메시지 받기';

  @override
  String get boxMinHeight => '최소 높이';

  @override
  String get srcPreview => '메시지 요약';

  @override
  String get newMessageArrived => '새 메시지';
}
