/// Sample data presets for instant comparison testing.
class SamplePreset {
  final String titleEn;
  final String titleVi;
  final String titleZh;
  final String leftName;
  final String rightName;
  final String leftContent;
  final String rightContent;

  const SamplePreset({
    required this.titleEn,
    required this.titleVi,
    required this.titleZh,
    required this.leftName,
    required this.rightName,
    required this.leftContent,
    required this.rightContent,
  });
}

class SamplePresets {
  static const jsonConfig = SamplePreset(
    titleEn: 'JSON Config',
    titleVi: 'Cấu hình JSON',
    titleZh: 'JSON 配置',
    leftName: 'appsettings.prod.json',
    rightName: 'appsettings.staging.json',
    leftContent: '''{
  "AppName": "JA Compare",
  "Environment": "Production",
  "Port": 8080,
  "EnableDebugLogs": false,
  "Database": {
    "Host": "db.production.internal",
    "Port": 5432,
    "PoolSize": 50,
    "TimeoutMs": 3000
  },
  "Features": {
    "DirectPaste": true,
    "AutoSave": true,
    "ExperimentalAI": false
  },
  "AllowedOrigins": [
    "https://jatechvn.github.io",
    "https://app.jaultra.com"
  ]
}''',
    rightContent: '''{
  "AppName": "JA Compare",
  "Environment": "Staging",
  "Port": 8090,
  "EnableDebugLogs": true,
  "Database": {
    "Host": "db.staging.internal",
    "Port": 5432,
    "PoolSize": 20,
    "TimeoutMs": 5000
  },
  "Features": {
    "DirectPaste": true,
    "AutoSave": true,
    "ExperimentalAI": true
  },
  "AllowedOrigins": [
    "https://jatechvn.github.io",
    "https://staging.jaultra.com",
    "http://localhost:3000"
  ]
}''',
  );

  static const dartSource = SamplePreset(
    titleEn: 'Dart Code',
    titleVi: 'Mã nguồn Dart',
    titleZh: 'Dart 代码',
    leftName: 'diff_service_v1.dart',
    rightName: 'diff_service_v2.dart',
    leftContent: '''class DiffService {
  final String engineVersion = '1.0.0';

  Future<DiffResult> process(List<String> a, List<String> b) async {
    print('Processing diff synchronously...');
    final result = computeDiff(a, b);
    return result;
  }

  void logStats(DiffResult result) {
    print('Lines changed: \${result.stats.totalChanges}');
  }
}''',
    rightContent: '''class DiffService {
  final String engineVersion = '2.0.0';
  final DiffOptions options;

  DiffService({this.options = const DiffOptions()});

  Future<DiffResult> process(List<String> a, List<String> b) async {
    // Run diff in background isolate for smooth 60fps UI
    return computeDiffInBackground(a, b, options: options);
  }

  void logStats(DiffResult result) {
    print('Lines changed: \${result.stats.totalChanges}');
    print('Intra-line highlights computed successfully.');
  }
}''',
  );

  static const vietnameseText = SamplePreset(
    titleEn: 'Document Text',
    titleVi: 'Văn bản Hợp đồng',
    titleZh: '合同文本',
    leftName: 'Dieu_khoan_v1.txt',
    rightName: 'Dieu_khoan_v2.txt',
    leftContent: '''ĐIỀU KHOẢN VÀ THOẢ THUẬN DỊCH VỤ (PHIÊN BẢN 1.0)

1. Phạm vi áp dụng:
Áp dụng cho toàn bộ người dùng sử dụng phần mềm JA Compare trên Windows 10 và 11.

2. Quyền hạn và trách nhiệm:
- Bên A cung cấp ứng dụng nguyên bản, không thu thập dữ liệu người dùng.
- Mọi dữ liệu so sánh được xử lý 100% Offline trên máy cục bộ.
- Thời gian hỗ trợ kỹ thuật: 30 ngày kể từ ngày kích hoạt bản quyền.

3. Bảo mật thông tin:
Cam kết bảo mật tuyệt đối các file văn bản so sánh.''',
    rightContent: '''ĐIỀU KHOẢN VÀ THOẢ THUẬN DỊCH VỤ (PHIÊN BẢN 2.0 - CẬP NHẬT)

1. Phạm vi áp dụng:
Áp dụng cho toàn bộ người dùng sử dụng phần mềm JA Compare trên Windows 10, 11 và các nền tảng tương lai.

2. Quyền hạn và trách nhiệm:
- Bên A cung cấp ứng dụng nguyên bản kèm chế độ So sánh Trực tiếp và Intra-line Diff.
- Mọi dữ liệu so sánh được xử lý 100% Offline trên máy cục bộ với tốc độ dưới 10ms.
- Thời gian hỗ trợ kỹ thuật: Trọn đời theo gói cập nhật phần mềm.

3. Bảo mật thông tin:
Cam kết bảo mật tuyệt đối các file văn bản và nội dung dán từ Clipboard.

4. Cập nhật mới:
Hỗ trợ xuất báo cáo định dạng Markdown và Microsoft Excel tự động.''',
  );

  static List<SamplePreset> get all => [jsonConfig, dartSource, vietnameseText];
}
