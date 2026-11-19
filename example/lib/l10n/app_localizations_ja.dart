// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get navPlayground => 'プレイグラウンド';

  @override
  String get navExamples => '例';

  @override
  String get navGettingStarted => 'はじめに';

  @override
  String get menu => 'メニュー';

  @override
  String get playgroundIntro =>
      'オプションを変更すると、チャットにすぐ反映されます。メッセージはシミュレーションなので、自由に送信してみてください。';

  @override
  String get preview => 'プレビュー';

  @override
  String get settings => '設定';

  @override
  String get receiveMessage => '受信';

  @override
  String get markAllRead => 'すべて既読にする';

  @override
  String get restart => '最初から';

  @override
  String get online => 'オンライン';

  @override
  String get inputHint => 'メッセージを入力';

  @override
  String incomingMessage(int count) {
    return '新しいメッセージ（$count）';
  }

  @override
  String autoReply(String text) {
    return '「$text」を受け取りました';
  }

  @override
  String newMessageFrom(String name) {
    return '$nameさんからの新しいメッセージ';
  }

  @override
  String get readOnlyNotice => 'このチャットは読み取り専用です';

  @override
  String get menuRetry => '再送信';

  @override
  String get menuDelete => '削除';

  @override
  String get menuCopy => 'コピー';

  @override
  String get sectionLayout => 'レイアウト';

  @override
  String get startAtTopTitle => 'メッセージが少ないときは上から表示';

  @override
  String get startAtTopDesc => '下部に寄せず、上から始めます';

  @override
  String get senderSideTitle => '自分のメッセージの位置';

  @override
  String get sideRight => '右';

  @override
  String get sideLeft => '左';

  @override
  String get sidePadding => '左右の余白';

  @override
  String get bubbleColor => '自分の吹き出しの色';

  @override
  String get maxWidth => '最大幅';

  @override
  String get noLimit => '制限なし';

  @override
  String get appearAnimation => '表示アニメーション';

  @override
  String get off => 'オフ';

  @override
  String get readOnlyTitle => '読み取り専用';

  @override
  String get readOnlyDesc => '入力欄の代わりに案内を表示します';

  @override
  String get sectionServer => 'シミュレーション';

  @override
  String get storedMessages => '保存済みメッセージ';

  @override
  String get none => 'なし';

  @override
  String messageCount(int count) {
    return '$count件';
  }

  @override
  String get responseTime => '応答時間';

  @override
  String seconds(String value) {
    return '$value秒';
  }

  @override
  String get imagesTitle => '画像メッセージを混ぜる';

  @override
  String get imagesDesc => '30%は読み込みが遅れる画像です';

  @override
  String get sendResult => '送信結果';

  @override
  String get resultSuccess => '成功';

  @override
  String get resultFail => '失敗';

  @override
  String get resultBlock => 'ブロック';

  @override
  String get autoReplyTitle => '自動返信';

  @override
  String get autoReplyDesc => '送信に成功すると、相手が読んで返信します';

  @override
  String get examplesIntro =>
      'サーバーからメッセージを読み込むチャットルームです。ルームごとにメッセージ数と応答速度が異なるため、スクロールの動作を確認できます。';

  @override
  String get roomShortTitle => '短いルーム';

  @override
  String get roomShortDesc => 'メッセージ5件。画面を埋めきれない量です';

  @override
  String get roomNormalTitle => '標準的なルーム';

  @override
  String get roomNormalDesc => 'メッセージ60件。30件ずつ2ページに分かれています';

  @override
  String get roomLongTitle => '長いルーム';

  @override
  String get roomLongDesc => 'メッセージ500件。上端に達するたびに30件ずつ追加で読み込みます';

  @override
  String get roomImagesTitle => '画像の多いルーム';

  @override
  String get roomImagesDesc => 'メッセージ120件。40%は読み込みが遅く、読み込み後に大きくなる画像です';

  @override
  String get roomSlowTitle => '低速サーバー';

  @override
  String get roomSlowDesc => 'メッセージ200件。応答に2秒かかります';

  @override
  String get loadingOlder => '過去のメッセージを読み込み中';

  @override
  String get gsIntro =>
      'メッセージのグループ化、日付の区切り線、送信失敗と再送信、過去のメッセージの読み込みを、ひとつの ChatController で扱えます。';

  @override
  String get step1Title => 'パッケージをインストールする';

  @override
  String get step2Title => 'メッセージの内容の描画方法を定義する';

  @override
  String get step2Desc => 'テキストや画像など吹き出しに入る内容を MessageElement として定義します。';

  @override
  String get step3Title => 'チャットを追加する';

  @override
  String get step3Desc =>
      'サーバーからのメッセージは setMessages で、スクロールして読み込む過去のメッセージは appendMessages で追加します。';

  @override
  String get step4Title => 'メッセージを送信する';

  @override
  String get step4Desc => 'null を返すと送信失敗として表示され、長押しで再送信できます。';

  @override
  String get gsCtaTitle => 'オプションを試してみますか？';

  @override
  String get gsCtaDesc => 'プレイグラウンドで各設定がチャットをどう変えるかを確認できます。';

  @override
  String get gsCtaButton => 'プレイグラウンドを開く';

  @override
  String get copy => 'コピー';

  @override
  String get copied => 'コピーしました';

  @override
  String get search => '検索';

  @override
  String get searchHint => 'メッセージを検索';

  @override
  String get searchNoResults => '結果がありません';

  @override
  String get searchOlder => '前の結果';

  @override
  String get searchNewer => '次の結果';

  @override
  String get closeSearch => '検索を閉じる';

  @override
  String get jumpToLatest => '最新のメッセージへ';

  @override
  String get receiverBubbleColor => '相手の吹き出しの色';

  @override
  String get groupingTitle => 'メッセージをグループ化';

  @override
  String get groupingDesc => '同じ分に同じ人が送ったメッセージは、ひとつのプロフィールにまとめられます';

  @override
  String get sendingIndicatorTitle => '送信中表示のカスタマイズ';

  @override
  String get sendingIndicatorDesc => 'サーバーから応答があるまで吹き出しに表示します';

  @override
  String get sending => '送信中…';

  @override
  String searchResultCount(int current, int total) {
    return '$current/$total';
  }

  @override
  String get searchShortcutsTitle => 'キーボードショートカット';

  @override
  String get close => '閉じる';

  @override
  String get cancel => 'キャンセル';

  @override
  String get send => '送信';

  @override
  String get verticalPadding => '上下の余白';

  @override
  String get backgroundTitle => 'チャットの背景';

  @override
  String get lookCustom => 'カスタム';

  @override
  String get lookLibrary => '既定';

  @override
  String get fontSize => '文字サイズ';

  @override
  String get bubblePaddingH => '内側の余白（左右）';

  @override
  String get bubblePaddingV => '内側の余白（上下）';

  @override
  String get hide => '非表示';

  @override
  String get myProfileTitle => '自分のプロフィール';

  @override
  String get myProfileDesc => '自分のメッセージにもプロフィールを表示';

  @override
  String get scrollThresholdTitle => '自動スクロールの範囲';

  @override
  String get menuPopup => 'ポップアップ';

  @override
  String get menuSheet => 'ボトムシート';

  @override
  String get longPressTitle => '長押しで開く';

  @override
  String get longPressDesc => 'オフにすると右クリックのみ';

  @override
  String get hapticTitle => '触覚フィードバック';

  @override
  String get confirmDeleteTitle => '送信失敗メッセージの削除確認';

  @override
  String get confirmDeleteDesc => '送信結果を失敗にして削除してみてください';

  @override
  String get deleteFailedTitle => 'このメッセージを削除しますか？';

  @override
  String get deleteFailedBody => '送信されていないため、相手には表示されていません。';

  @override
  String get kind => '種類';

  @override
  String get designBackground => '背景色';

  @override
  String get designTextColor => '文字色';

  @override
  String get designRadius => '角の丸み';

  @override
  String get designHeight => '高さ';

  @override
  String get designSize => 'サイズ';

  @override
  String get designShape => '形';

  @override
  String get roundness => '丸み';

  @override
  String get roundFull => '完全な丸';

  @override
  String get weekdayTitle => '曜日を表示';

  @override
  String get use24hTitle => '24時間表示';

  @override
  String get searchShortcutsDesc => 'Ctrl/⌘ + F で開く、Enter で次の結果、Esc で閉じる';

  @override
  String get sectionBehavior => '動作';

  @override
  String get partBubble => '吹き出し';

  @override
  String get partBubbleDesc =>
      'senderBubbleBuilder と receiverBubbleBuilder はメッセージの中身を child で受け取ります。好きなコンテナで包むだけです。';

  @override
  String get partSearch => '検索バー';

  @override
  String get partSearchDesc =>
      'チャット上の検索ボタンで開いてください。ツールキットの ChatSearchBar を装飾するか、ChatSearchController の search()、showOlder()、showNewer()、close() で自作のバーをつなげます。';

  @override
  String get partInput => '入力欄';

  @override
  String get partInputDesc =>
      'チャットは customInputField を下に置くだけです。入力欄と送信（controller.dispatchMessage）は自分で作ります。';

  @override
  String get partNotice => '新着メッセージのお知らせ';

  @override
  String get partNoticeDesc =>
      '上にスクロールしている間にメッセージが届くと表示されます。上にスクロールしてからチャット上の受信ボタンを押してください。';

  @override
  String get partSeparator => '日付の区切り';

  @override
  String get partSeparatorDesc => '日付が変わる所に表示されます。ビルダーはその日の timestamp を受け取ります。';

  @override
  String get partTime => '時刻';

  @override
  String get partTimeDesc =>
      'まとまりの最後の吹き出しの横に表示されます。ビルダーはメッセージの timestamp を受け取ります。';

  @override
  String get partProfile => 'プロフィール';

  @override
  String get partProfileDesc => 'メッセージのまとまりごとに一度表示されます。ビルダーは送信者名を受け取ります。';

  @override
  String get partRead => '既読表示';

  @override
  String get partReadDesc =>
      'SenderMessage(isRead: false/true) に表示されます。メッセージを送ってから「すべて既読」を押してください。';

  @override
  String get partMenu => '吹き出しメニュー';

  @override
  String get partMenuDesc =>
      '吹き出しを長押しまたは右クリックしてください。ツールキットのポップアップに項目を入れるか、ハンドラーで好きな UI を表示できます。';

  @override
  String get partReadOnly => '読み取り専用のお知らせ';

  @override
  String get partReadOnlyDesc =>
      'Chat(readOnly: true) のとき、入力欄の代わりに readOnlyWidget が表示されます。';

  @override
  String get studioEdit => '編集';

  @override
  String get studioReset => '最初に戻す';

  @override
  String get tabStructure => '構成';

  @override
  String get tabStyle => 'ボックス';

  @override
  String get tabCode => 'コード';

  @override
  String get layoutAxis => '並べる方向';

  @override
  String get axisRow => '横';

  @override
  String get axisColumn => '縦';

  @override
  String get layoutMain => '並び方向の揃え';

  @override
  String get layoutCross => '交差方向の揃え';

  @override
  String get layoutGap => '要素の間隔';

  @override
  String get alignStart => '先頭';

  @override
  String get alignCenter => '中央';

  @override
  String get alignEnd => '末尾';

  @override
  String get alignBetween => '両端';

  @override
  String get elements => '要素';

  @override
  String get elementsHint => '⋮⋮ をドラッグで並べ替え、要素をタップしてスタイルを変更';

  @override
  String get addElement => '追加';

  @override
  String get elementVisible => '表示/非表示';

  @override
  String get elContent => 'メッセージ内容';

  @override
  String get elText => 'テキスト';

  @override
  String get elIcon => 'アイコン';

  @override
  String get elField => '入力欄';

  @override
  String get elButton => 'ボタン';

  @override
  String get elBadge => 'バッジ';

  @override
  String get elAvatar => 'プロフィール画像';

  @override
  String get elSpacer => 'スペース';

  @override
  String get elDivider => '線';

  @override
  String get propSource => '表示内容';

  @override
  String get propText => '文言';

  @override
  String get propTextUnread => '既読前の文言';

  @override
  String get propTextRead => '既読後の文言';

  @override
  String get propIconUnread => '既読前のアイコン';

  @override
  String get propIconRead => '既読後のアイコン';

  @override
  String get propHint => 'ヒント';

  @override
  String get propAction => '動作';

  @override
  String get propBold => '太字';

  @override
  String get propColor => '色';

  @override
  String get propExpand => '残りの幅を埋める';

  @override
  String get propWidth => '幅';

  @override
  String get propThickness => '太さ';

  @override
  String get lookFilled => '塗り';

  @override
  String get srcLiteral => '入力した文字';

  @override
  String get srcName => '名前';

  @override
  String get srcTime => '時刻';

  @override
  String get srcDate => '日付';

  @override
  String get srcCount => '件数';

  @override
  String get srcRead => '既読状態';

  @override
  String get srcNotice => 'お知らせ文';

  @override
  String get srcReadOnly => '案内文';

  @override
  String get actNone => 'なし';

  @override
  String get actAttach => '添付';

  @override
  String get boxGradient => 'グラデーション';

  @override
  String get boxGradientTo => 'グラデーションの終わり';

  @override
  String get boxBorder => '枠線の太さ';

  @override
  String get boxBorderColor => '枠線の色';

  @override
  String get boxShadow => '影';

  @override
  String get boxMarginH => '外側の余白（左右）';

  @override
  String get boxMarginV => '外側の余白（上下）';

  @override
  String get boxAuto => '自動';

  @override
  String get boxFill => '横幅いっぱい';

  @override
  String get boxAlign => '位置';

  @override
  String get colorHue => '色相';

  @override
  String get colorSaturation => '彩度';

  @override
  String get colorBrightness => '明るさ';

  @override
  String get colorOpacity => '不透明度';

  @override
  String get colorHexHint => 'RRGGBB または AARRGGBB を入力して Enter';

  @override
  String get sectionParts => 'パーツのデザイン';

  @override
  String get sectionPartsDesc =>
      'カスタムを選ぶとチャットの横に編集パネルが開きます。要素の追加・削除・並べ替え、要素とボックスのスタイルを自由に変更でき、すぐにチャットに反映されます。';

  @override
  String studioTitle(String part) {
    return '$partのデザイン';
  }

  @override
  String get previewNotice => '表示してみる: 上にスクロールして受信';

  @override
  String get boxMinHeight => '最小の高さ';
}
