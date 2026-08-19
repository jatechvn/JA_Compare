import 'language_provider.dart';

/// All user-facing strings, keyed by a short identifier. Add a new row here
/// (not a hardcoded string in a widget) whenever the UI needs new text.
const Map<String, Map<AppLanguage, String>> _translations = {
  'settings_tooltip': {
    AppLanguage.en: 'Settings',
    AppLanguage.vi: 'Cài đặt',
    AppLanguage.zh: '设置',
  },
  'theme_toggle_tooltip': {
    AppLanguage.en: 'Toggle light/dark',
    AppLanguage.vi: 'Đổi giao diện sáng/tối',
    AppLanguage.zh: '切换明暗主题',
  },
  'language_tooltip': {
    AppLanguage.en: 'Language',
    AppLanguage.vi: 'Ngôn ngữ',
    AppLanguage.zh: '语言',
  },
  'pane_left_title': {
    AppLanguage.en: 'Original document',
    AppLanguage.vi: 'Tài liệu gốc',
    AppLanguage.zh: '原始文档',
  },
  'pane_right_title': {
    AppLanguage.en: 'Document to compare',
    AppLanguage.vi: 'Tài liệu so sánh',
    AppLanguage.zh: '对比文档',
  },
  'compare_button': {
    AppLanguage.en: 'Compare',
    AppLanguage.vi: 'So sánh',
    AppLanguage.zh: '比较',
  },
  'pick_or_drop': {
    AppLanguage.en: 'Choose a file or drag & drop here',
    AppLanguage.vi: 'Chọn file hoặc kéo-thả vào đây',
    AppLanguage.zh: '选择文件或拖放到此处',
  },
  'change_file': {
    AppLanguage.en: 'Change file',
    AppLanguage.vi: 'Đổi file',
    AppLanguage.zh: '更换文件',
  },
  'lines_suffix': {
    AppLanguage.en: 'lines',
    AppLanguage.vi: 'dòng',
    AppLanguage.zh: '行',
  },
  'compare_other_file': {
    AppLanguage.en: 'Compare another file',
    AppLanguage.vi: 'So sánh file khác',
    AppLanguage.zh: '比较其他文件',
  },
  'no_content': {
    AppLanguage.en: 'No content',
    AppLanguage.vi: 'Không có nội dung',
    AppLanguage.zh: '无内容',
  },
  'added_suffix': {
    AppLanguage.en: 'added',
    AppLanguage.vi: 'thêm',
    AppLanguage.zh: '新增',
  },
  'removed_suffix': {
    AppLanguage.en: 'removed',
    AppLanguage.vi: 'xoá',
    AppLanguage.zh: '删除',
  },
  'modified_suffix': {
    AppLanguage.en: 'modified',
    AppLanguage.vi: 'sửa',
    AppLanguage.zh: '修改',
  },
  'differences_suffix': {
    AppLanguage.en: 'differences',
    AppLanguage.vi: 'khác biệt',
    AppLanguage.zh: '处差异',
  },
  'identical_label': {
    AppLanguage.en: 'Identical',
    AppLanguage.vi: 'Giống hệt nhau',
    AppLanguage.zh: '完全相同',
  },
  'settings_title': {
    AppLanguage.en: 'Settings',
    AppLanguage.vi: 'Cài đặt',
    AppLanguage.zh: '设置',
  },
  'tab_advanced': {
    AppLanguage.en: '⚙️ Advanced',
    AppLanguage.vi: '⚙️ Nâng cao',
    AppLanguage.zh: '⚙️ 高级',
  },
  'tab_guide': {
    AppLanguage.en: '📖 Guide',
    AppLanguage.vi: '📖 Hướng dẫn',
    AppLanguage.zh: '📖 指南',
  },
  'tab_about': {
    AppLanguage.en: 'ℹ️ About',
    AppLanguage.vi: 'ℹ️ Giới thiệu',
    AppLanguage.zh: 'ℹ️ 关于',
  },
  'glass_section_title': {
    AppLanguage.en: 'Glassmorphism',
    AppLanguage.vi: 'Giao diện kính mờ (Glassmorphism)',
    AppLanguage.zh: '玻璃拟态效果',
  },
  'glass_customize': {
    AppLanguage.en: 'Customize blur & transparency',
    AppLanguage.vi: 'Tuỳ chỉnh độ mờ & độ trong suốt',
    AppLanguage.zh: '自定义模糊与透明度',
  },
  'bg_blur_label': {
    AppLanguage.en: 'Main background blur',
    AppLanguage.vi: 'Độ mờ nền chính (Blur)',
    AppLanguage.zh: '主背景模糊度',
  },
  'bg_opacity_label': {
    AppLanguage.en: 'Main background opacity',
    AppLanguage.vi: 'Độ trong suốt nền chính',
    AppLanguage.zh: '主背景不透明度',
  },
  'dialog_blur_label': {
    AppLanguage.en: 'Dialog blur',
    AppLanguage.vi: 'Độ mờ hộp thoại (Blur)',
    AppLanguage.zh: '对话框模糊度',
  },
  'dialog_opacity_label': {
    AppLanguage.en: 'Dialog opacity',
    AppLanguage.vi: 'Độ trong suốt hộp thoại',
    AppLanguage.zh: '对话框不透明度',
  },
  'reset_defaults': {
    AppLanguage.en: 'RESET TO DEFAULTS',
    AppLanguage.vi: 'KHÔI PHỤC MẶC ĐỊNH',
    AppLanguage.zh: '恢复默认',
  },
  'save_settings': {
    AppLanguage.en: 'SAVE SETTINGS',
    AppLanguage.vi: 'LƯU CÀI ĐẶT',
    AppLanguage.zh: '保存设置',
  },
  'guide_body': {
    AppLanguage.en:
        '1. Pick or drag-and-drop a document into the left and right panes.\n'
        '2. Press "Compare" to see the differences.\n'
        '3. Added lines are green, removed lines are red, modified lines are amber.\n'
        '4. Both panes scroll together automatically.\n'
        '5. Select and copy text directly from either pane, or use the copy '
        'icon in a pane\'s header to copy that whole side.\n'
        '6. Use the share icon to export the result as Markdown (.md) or '
        'Excel (.xlsx) to save or share.\n'
        '7. The history icon (clock) keeps past comparisons so you can '
        'reopen a pair instantly.\n'
        '8. Press "Compare another file" to start over.\n\n'
        'Supported formats: .txt .md .csv .json .log .xml .html .docx .xlsx .pdf',
    AppLanguage.vi:
        '1. Chọn hoặc kéo-thả tài liệu bên trái và bên phải.\n'
        '2. Bấm "So sánh" để xem điểm khác biệt.\n'
        '3. Dòng thêm mới hiển thị màu xanh, xoá hiển thị màu đỏ, '
        'sửa đổi hiển thị màu vàng.\n'
        '4. Hai khung cuộn đồng bộ với nhau — cuộn một bên, bên kia tự cuộn theo.\n'
        '5. Có thể bôi đen và sao chép văn bản trực tiếp trong từng khung, '
        'hoặc bấm biểu tượng sao chép ở góc mỗi khung để sao chép toàn bộ.\n'
        '6. Bấm biểu tượng chia sẻ để xuất kết quả ra file Markdown (.md) '
        'hoặc Excel (.xlsx) nhằm lưu giữ hoặc chia sẻ.\n'
        '7. Biểu tượng đồng hồ (Lịch sử) lưu lại các cặp file đã so sánh để '
        'mở lại nhanh chóng.\n'
        '8. Bấm "So sánh file khác" để chọn lại tài liệu mới.\n\n'
        'Định dạng hỗ trợ: .txt .md .csv .json .log .xml .html .docx .xlsx .pdf',
    AppLanguage.zh:
        '1. 选择或拖放文档到左右两侧面板。\n'
        '2. 点击"比较"查看差异。\n'
        '3. 新增的行显示为绿色，删除的显示为红色，修改的显示为黄色。\n'
        '4. 两侧面板会自动同步滚动。\n'
        '5. 可直接在任一面板中选择并复制文本，或点击面板顶部的复制图标复制整侧内容。\n'
        '6. 点击分享图标，将结果导出为 Markdown (.md) 或 Excel (.xlsx) 以保存或分享。\n'
        '7. 历史图标（时钟）会保存过往的比较记录，方便快速重新打开。\n'
        '8. 点击"比较其他文件"重新开始。\n\n'
        '支持的格式：.txt .md .csv .json .log .xml .html .docx .xlsx .pdf',
  },
  'version_label': {
    AppLanguage.en: 'Version',
    AppLanguage.vi: 'Phiên bản',
    AppLanguage.zh: '版本',
  },
  'about_description': {
    AppLanguage.en:
        'A multi-format document comparison tool — side-by-side diff view, '
        'supporting Text/Markdown/CSV/JSON, Word, Excel and PDF.',
    AppLanguage.vi:
        'Công cụ so sánh tài liệu đa định dạng — hiển thị khác biệt '
        'song song, hỗ trợ Text/Markdown/CSV/JSON, Word, Excel và PDF.',
    AppLanguage.zh:
        '多格式文档比较工具 — 并排差异视图，支持 Text/Markdown/CSV/JSON、Word、Excel 和 PDF。',
  },
  'developed_by': {
    AppLanguage.en: 'Developed by John Alaa / JA Tech',
    AppLanguage.vi: 'Phát triển bởi John Alaa / JA Tech',
    AppLanguage.zh: '由 John Alaa / JA Tech 开发',
  },
  'website_label': {
    AppLanguage.en: 'Website',
    AppLanguage.vi: 'Website',
    AppLanguage.zh: '网站',
  },
  'copy_all_tooltip': {
    AppLanguage.en: 'Copy all text',
    AppLanguage.vi: 'Sao chép toàn bộ',
    AppLanguage.zh: '复制全部文本',
  },
  'copied_toast': {
    AppLanguage.en: 'Copied to clipboard',
    AppLanguage.vi: 'Đã sao chép vào clipboard',
    AppLanguage.zh: '已复制到剪贴板',
  },
  'export_tooltip': {
    AppLanguage.en: 'Export result',
    AppLanguage.vi: 'Xuất kết quả',
    AppLanguage.zh: '导出结果',
  },
  'export_markdown_option': {
    AppLanguage.en: 'Export as Markdown (.md)',
    AppLanguage.vi: 'Xuất Markdown (.md)',
    AppLanguage.zh: '导出为 Markdown (.md)',
  },
  'export_excel_option': {
    AppLanguage.en: 'Export as Excel (.xlsx)',
    AppLanguage.vi: 'Xuất Excel (.xlsx)',
    AppLanguage.zh: '导出为 Excel (.xlsx)',
  },
  'export_save_dialog_title': {
    AppLanguage.en: 'Save comparison result',
    AppLanguage.vi: 'Lưu kết quả so sánh',
    AppLanguage.zh: '保存比较结果',
  },
  'export_title': {
    AppLanguage.en: 'Comparison',
    AppLanguage.vi: 'So sánh',
    AppLanguage.zh: '比较',
  },
  'export_status_column': {
    AppLanguage.en: 'Status',
    AppLanguage.vi: 'Trạng thái',
    AppLanguage.zh: '状态',
  },
  'export_success': {
    AppLanguage.en: 'Exported successfully',
    AppLanguage.vi: 'Xuất file thành công',
    AppLanguage.zh: '导出成功',
  },
  'export_failed': {
    AppLanguage.en: 'Export failed',
    AppLanguage.vi: 'Xuất file thất bại',
    AppLanguage.zh: '导出失败',
  },
  'history_tooltip': {
    AppLanguage.en: 'Comparison history',
    AppLanguage.vi: 'Lịch sử so sánh',
    AppLanguage.zh: '比较历史',
  },
  'history_title': {
    AppLanguage.en: 'Comparison history',
    AppLanguage.vi: 'Lịch sử so sánh',
    AppLanguage.zh: '比较历史',
  },
  'history_empty': {
    AppLanguage.en: 'No comparisons yet',
    AppLanguage.vi: 'Chưa có lịch sử so sánh nào',
    AppLanguage.zh: '暂无比较记录',
  },
  'history_clear': {
    AppLanguage.en: 'Clear history',
    AppLanguage.vi: 'Xoá toàn bộ lịch sử',
    AppLanguage.zh: '清空历史记录',
  },
  'history_open_tooltip': {
    AppLanguage.en: 'Open this comparison again',
    AppLanguage.vi: 'Mở lại cặp so sánh này',
    AppLanguage.zh: '重新打开此比较',
  },
  'history_delete_tooltip': {
    AppLanguage.en: 'Remove from history',
    AppLanguage.vi: 'Xoá khỏi lịch sử',
    AppLanguage.zh: '从历史记录中删除',
  },
  'history_file_missing': {
    AppLanguage.en: 'One of these files can no longer be found',
    AppLanguage.vi: 'Một trong hai file này không còn tồn tại',
    AppLanguage.zh: '其中一个文件已不存在',
  },
};

/// Looks up [key] for [language], falling back to English then the raw key
/// if a translation is missing — so a missing row degrades gracefully
/// instead of crashing.
String translate(AppLanguage language, String key) {
  final entry = _translations[key];
  if (entry == null) return key;
  return entry[language] ?? entry[AppLanguage.en] ?? key;
}
