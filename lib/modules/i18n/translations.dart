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
  'compare_other_folder': {
    AppLanguage.en: 'Compare another folder',
    AppLanguage.vi: 'So sánh thư mục khác',
    AppLanguage.zh: '比较其他文件夹',
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
  'identical_result': {
    AppLanguage.en: 'Files are identical',
    AppLanguage.vi: 'Hai tệp giống hệt nhau',
    AppLanguage.zh: '两个文件完全相同',
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
        '1. Pick files individually, or drop two files / two folders anywhere '
        'in the app to fill both sides automatically.\n'
        '2. Press "Compare" to see the differences.\n'
        '3. If the files match exactly, the result bar shows "Files are identical".\n'
        '4. Added lines are green, removed lines are red, modified lines are amber.\n'
        '5. Both panes scroll together automatically.\n'
        '6. Select and copy text directly from either pane, or use the copy '
        'icon in a pane\'s header to copy that whole side.\n'
        '7. Use the share icon to export the result as Markdown (.md) or '
        'Excel (.xlsx) to save or share.\n'
        '8. Switch to Folders to compare complete directory trees; the result '
        'shows added, removed, modified, and similar-name files.\n'
        '9. The history icon (clock) keeps both file and folder comparisons '
        'so you can reopen a pair instantly.\n'
        '10. Press "Compare another file" to start over. For diagnostics, run '
        '`debug.bat`; logs are stored in the app\'s logs folder.\n\n'
        'Supported file formats: .txt .md .csv .json .log .xml .html .yaml '
        '.yml .ini .docx .xlsx .pdf',
    AppLanguage.vi:
        '1. Chọn từng file, hoặc kéo thả 2 file / 2 thư mục vào bất kỳ vị trí nào '
        'trong phần mềm để tự động điền hai phía.\n'
        '2. Bấm "So sánh" để xem điểm khác biệt.\n'
        '3. Nếu hai file giống nhau, thanh kết quả hiện "Hai tệp giống hệt nhau".\n'
        '4. Dòng thêm mới hiển thị màu xanh, xoá hiển thị màu đỏ, '
        'sửa đổi hiển thị màu vàng.\n'
        '5. Hai khung cuộn đồng bộ với nhau — cuộn một bên, bên kia tự cuộn theo.\n'
        '6. Có thể bôi đen và sao chép văn bản trực tiếp trong từng khung, '
        'hoặc bấm biểu tượng sao chép ở góc mỗi khung để sao chép toàn bộ.\n'
        '7. Bấm biểu tượng chia sẻ để xuất kết quả ra file Markdown (.md) '
        'hoặc Excel (.xlsx) nhằm lưu giữ hoặc chia sẻ.\n'
        '8. Chuyển sang chế độ Thư mục để so sánh toàn bộ cây thư mục; kết quả '
        'hiển thị file thêm, xoá, sửa đổi và có tên tương tự.\n'
        '9. Biểu tượng đồng hồ (Lịch sử) lưu cả lần so sánh file và thư mục để '
        'mở lại nhanh chóng.\n'
        '10. Bấm "So sánh file khác" để chọn lại tài liệu mới. Khi cần chẩn đoán, '
        'chạy `debug.bat`; log nằm trong thư mục logs cạnh app.\n\n'
        'Định dạng file hỗ trợ: .txt .md .csv .json .log .xml .html .yaml '
        '.yml .ini .docx .xlsx .pdf',
    AppLanguage.zh:
        '1. 逐个选择文件，或将两个文件 / 两个文件夹拖放到应用任意位置，自动填充两侧。\n'
        '2. 点击"比较"查看差异。\n'
        '3. 如果两个文件完全相同，结果栏会显示"两个文件完全相同"。\n'
        '4. 新增的行显示为绿色，删除的显示为红色，修改的显示为黄色。\n'
        '5. 两侧面板会自动同步滚动。\n'
        '6. 可直接在任一面板中选择并复制文本，或点击面板顶部的复制图标复制整侧内容。\n'
        '7. 点击分享图标，将结果导出为 Markdown (.md) 或 Excel (.xlsx) 以保存或分享。\n'
        '8. 切换到文件夹模式比较完整目录树；结果会显示新增、删除、修改和名称相似的文件。\n'
        '9. 历史图标（时钟）会保存文件和文件夹比较记录，方便快速重新打开。\n'
        '10. 点击"比较其他文件"重新开始。需要诊断时运行 `debug.bat`，日志位于应用旁的 logs 文件夹。\n\n'
        '支持的文件格式：.txt .md .csv .json .log .xml .html .yaml .yml .ini .docx .xlsx .pdf',
  },
  'version_label': {
    AppLanguage.en: 'Version',
    AppLanguage.vi: 'Phiên bản',
    AppLanguage.zh: '版本',
  },
  'about_description': {
    AppLanguage.en:
        'A Windows-first document and folder comparison tool with synchronized '
        'diff views, multi-format extraction, drag-and-drop pairing, identical-result '
        'feedback, and export.',
    AppLanguage.vi:
        'Công cụ Windows-first để so sánh tài liệu và thư mục, hiển thị khác '
        'biệt đồng bộ, trích xuất đa định dạng, kéo thả nhanh, báo kết quả giống nhau '
        'và xuất dữ liệu.',
    AppLanguage.zh: 'Windows 优先的文档和文件夹比较工具，提供同步差异视图、多格式提取、拖放配对、相同结果提示和导出功能。',
  },
  'developed_by': {
    AppLanguage.en: 'Developed by John Alaa / JA Tech',
    AppLanguage.vi: 'Phát triển bởi John Alaa / JA Tech',
    AppLanguage.zh: '由 John Alaa / JA Tech 开发',
  },
  'license_label': {
    AppLanguage.en: 'License: MIT',
    AppLanguage.vi: 'Giấy phép: MIT',
    AppLanguage.zh: '许可证：MIT',
  },
  'website_label': {
    AppLanguage.en: 'Website',
    AppLanguage.vi: 'Website',
    AppLanguage.zh: '网站',
  },
  'github_label': {
    AppLanguage.en: 'GitHub',
    AppLanguage.vi: 'GitHub',
    AppLanguage.zh: 'GitHub',
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
  'history_folder_missing': {
    AppLanguage.en: 'One of these folders can no longer be found',
    AppLanguage.vi: 'Một trong hai thư mục này không còn tồn tại',
    AppLanguage.zh: '其中一个文件夹已不存在',
  },
  'tab_files': {
    AppLanguage.en: 'Files',
    AppLanguage.vi: 'Tệp tin',
    AppLanguage.zh: '文件',
  },
  'tab_direct_text': {
    AppLanguage.en: 'Direct Text',
    AppLanguage.vi: 'Văn bản trực tiếp',
    AppLanguage.zh: '直接文本',
  },
  'swap_tooltip': {
    AppLanguage.en: 'Swap documents (Ctrl+Shift+S)',
    AppLanguage.vi: 'Hoán đổi 2 bên (Ctrl+Shift+S)',
    AppLanguage.zh: '交换左右 (Ctrl+Shift+S)',
  },
  'clear_all_tooltip': {
    AppLanguage.en: 'Clear both sides',
    AppLanguage.vi: 'Xoá cả 2 bên',
    AppLanguage.zh: '清空两侧',
  },
  'clear_side_tooltip': {
    AppLanguage.en: 'Clear',
    AppLanguage.vi: 'Xoá',
    AppLanguage.zh: '清空',
  },
  'paste_clipboard': {
    AppLanguage.en: 'Paste',
    AppLanguage.vi: 'Dán nhanh',
    AppLanguage.zh: '粘贴',
  },
  'paste_tooltip': {
    AppLanguage.en: 'Paste from clipboard',
    AppLanguage.vi: 'Dán từ bộ nhớ tạm (Clipboard)',
    AppLanguage.zh: '从剪贴板粘贴',
  },
  'opt_ignore_whitespace': {
    AppLanguage.en: 'Ignore whitespace',
    AppLanguage.vi: 'Bỏ qua khoảng trắng',
    AppLanguage.zh: '忽略空白',
  },
  'opt_ignore_case': {
    AppLanguage.en: 'Ignore case',
    AppLanguage.vi: 'Bỏ qua HOA/thường',
    AppLanguage.zh: '忽略大小写',
  },
  'opt_ignore_empty_lines': {
    AppLanguage.en: 'Ignore blank lines',
    AppLanguage.vi: 'Bỏ qua dòng trống',
    AppLanguage.zh: '忽略空行',
  },
  'sample_presets_label': {
    AppLanguage.en: 'Try samples:',
    AppLanguage.vi: 'Mẫu thử:',
    AppLanguage.zh: '试用样例：',
  },
  'ready_to_compare': {
    AppLanguage.en: 'Ready to compare',
    AppLanguage.vi: 'Sẵn sàng so sánh',
    AppLanguage.zh: '可开始对比',
  },
  'drop_here_prompt': {
    AppLanguage.en: 'Drop your file here!',
    AppLanguage.vi: 'Thả tệp vào đây ngay!',
    AppLanguage.zh: '将文件拖放到这里！',
  },
  'direct_text_hint_left': {
    AppLanguage.en: 'Paste or type original text here...',
    AppLanguage.vi: 'Dán hoặc gõ nội dung gốc vào đây...',
    AppLanguage.zh: '在此粘贴或输入原始内容...',
  },
  'direct_text_hint_right': {
    AppLanguage.en: 'Paste or type text to compare here...',
    AppLanguage.vi: 'Dán hoặc gõ nội dung so sánh vào đây...',
    AppLanguage.zh: '在此粘贴或输入对比内容...',
  },
  'chars_suffix': {
    AppLanguage.en: 'chars',
    AppLanguage.vi: 'ký tự',
    AppLanguage.zh: '字符',
  },
  'view_split': {
    AppLanguage.en: 'Split View',
    AppLanguage.vi: 'Song song',
    AppLanguage.zh: '分屏',
  },
  'view_unified': {
    AppLanguage.en: 'Unified View',
    AppLanguage.vi: 'Xem gộp',
    AppLanguage.zh: '统一',
  },
  'next_diff_tooltip': {
    AppLanguage.en: 'Next difference (F7)',
    AppLanguage.vi: 'Khác biệt kế tiếp (F7)',
    AppLanguage.zh: '下一处差异 (F7)',
  },
  'prev_diff_tooltip': {
    AppLanguage.en: 'Previous difference (Shift+F7)',
    AppLanguage.vi: 'Khác biệt trước (Shift+F7)',
    AppLanguage.zh: '上一处差异 (Shift+F7)',
  },
  'diff_done_hud': {
    AppLanguage.en: 'Compared in',
    AppLanguage.vi: 'Đã so sánh trong',
    AppLanguage.zh: '对比耗时',
  },
  'shortcuts_hint': {
    AppLanguage.en: 'Ctrl+Enter: Compare • Ctrl+O: Open • ⇄: Swap',
    AppLanguage.vi: 'Ctrl+Enter: So sánh • Ctrl+O: Mở • ⇄: Hoán đổi',
    AppLanguage.zh: 'Ctrl+Enter: 对比 • Ctrl+O: 打开 • ⇄: 交换',
  },
  'tab_folders': {
    AppLanguage.en: 'Folders',
    AppLanguage.vi: 'Thư mục',
    AppLanguage.zh: '文件夹',
  },
  'pane_left_folder_title': {
    AppLanguage.en: 'Original folder',
    AppLanguage.vi: 'Thư mục gốc',
    AppLanguage.zh: '原始文件夹',
  },
  'pane_right_folder_title': {
    AppLanguage.en: 'Folder to compare',
    AppLanguage.vi: 'Thư mục so sánh',
    AppLanguage.zh: '对比文件夹',
  },
  'pick_or_drop_folder': {
    AppLanguage.en: 'Choose a folder or drag & drop here',
    AppLanguage.vi: 'Chọn thư mục hoặc kéo-thả vào đây',
    AppLanguage.zh: '选择文件夹或拖放到此处',
  },
  'folder_total_files': {
    AppLanguage.en: 'files scanned',
    AppLanguage.vi: 'tệp đã quét',
    AppLanguage.zh: '个已扫描文件',
  },
  'opt_fuzzy_matching': {
    AppLanguage.en: 'Match similar file names (Fuzzy)',
    AppLanguage.vi: 'Ghép cặp file tên tương tự (Fuzzy)',
    AppLanguage.zh: '模糊匹配相似文件名',
  },
  'dir_summary_total': {
    AppLanguage.en: 'Total',
    AppLanguage.vi: 'Tổng cộng',
    AppLanguage.zh: '总计',
  },
  'dir_summary_modified': {
    AppLanguage.en: 'Modified',
    AppLanguage.vi: 'Đã sửa',
    AppLanguage.zh: '已修改',
  },
  'dir_summary_similar': {
    AppLanguage.en: 'Similar names',
    AppLanguage.vi: 'Tên tương tự',
    AppLanguage.zh: '相似文件名',
  },
  'dir_summary_added': {
    AppLanguage.en: 'Added',
    AppLanguage.vi: 'Mới thêm',
    AppLanguage.zh: '新增',
  },
  'dir_summary_removed': {
    AppLanguage.en: 'Removed',
    AppLanguage.vi: 'Đã xóa',
    AppLanguage.zh: '已删除',
  },
  'dir_summary_identical': {
    AppLanguage.en: 'Identical',
    AppLanguage.vi: 'Giống hệt',
    AppLanguage.zh: '完全相同',
  },
  'filter_all': {
    AppLanguage.en: 'All',
    AppLanguage.vi: 'Tất cả',
    AppLanguage.zh: '全部',
  },
  'filter_modified': {
    AppLanguage.en: 'Modified',
    AppLanguage.vi: 'Có khác biệt',
    AppLanguage.zh: '有修改',
  },
  'filter_similar': {
    AppLanguage.en: 'Similar names',
    AppLanguage.vi: 'Tên gần giống',
    AppLanguage.zh: '相似文件名',
  },
  'filter_left_only': {
    AppLanguage.en: 'Left only',
    AppLanguage.vi: 'Chỉ bên trái',
    AppLanguage.zh: '仅左侧',
  },
  'filter_right_only': {
    AppLanguage.en: 'Right only',
    AppLanguage.vi: 'Chỉ bên phải',
    AppLanguage.zh: '仅右侧',
  },
  'filter_identical': {
    AppLanguage.en: 'Identical',
    AppLanguage.vi: 'Trùng khớp',
    AppLanguage.zh: '完全相同',
  },
  'search_files_hint': {
    AppLanguage.en: 'Filter files by name or extension (.dart, .json)...',
    AppLanguage.vi: 'Tìm kiếm tệp theo tên hoặc định dạng (.dart, .json)...',
    AppLanguage.zh: '按文件名或扩展名搜索 (.dart, .json)...',
  },
  'status_identical': {
    AppLanguage.en: 'Identical',
    AppLanguage.vi: 'Giống hệt',
    AppLanguage.zh: '完全相同',
  },
  'status_modified': {
    AppLanguage.en: 'Modified',
    AppLanguage.vi: 'Đã sửa',
    AppLanguage.zh: '已修改',
  },
  'status_similar': {
    AppLanguage.en: 'Similar name',
    AppLanguage.vi: 'Tên tương tự',
    AppLanguage.zh: '相似文件名',
  },
  'status_left_only': {
    AppLanguage.en: 'Removed / Left only',
    AppLanguage.vi: 'Đã xóa / Chỉ có ở trái',
    AppLanguage.zh: '已删除 / 仅左侧',
  },
  'status_right_only': {
    AppLanguage.en: 'Added / Right only',
    AppLanguage.vi: 'Mới thêm / Chỉ có ở phải',
    AppLanguage.zh: '新增 / 仅右侧',
  },
  'view_diff_action': {
    AppLanguage.en: 'View Diff',
    AppLanguage.vi: 'Xem Diff',
    AppLanguage.zh: '查看差异',
  },
  'back_to_folder_list': {
    AppLanguage.en: 'Back to folder list',
    AppLanguage.vi: 'Quay lại danh sách thư mục',
    AppLanguage.zh: '返回文件夹列表',
  },
  'next_file_pair': {
    AppLanguage.en: 'Next file',
    AppLanguage.vi: 'File tiếp theo',
    AppLanguage.zh: '下一个文件',
  },
  'prev_file_pair': {
    AppLanguage.en: 'Previous file',
    AppLanguage.vi: 'File trước',
    AppLanguage.zh: '上一个文件',
  },
  'no_matching_files': {
    AppLanguage.en: 'No files match the current search or filter.',
    AppLanguage.vi: 'Không có tệp nào khớp với bộ lọc hoặc từ khóa tìm kiếm.',
    AppLanguage.zh: '没有匹配当前筛选或搜索条件的文件。',
  },
  'export_dir_report': {
    AppLanguage.en: 'Export Report',
    AppLanguage.vi: 'Xuất báo cáo',
    AppLanguage.zh: '导出报告',
  },
  'reveal_in_explorer': {
    AppLanguage.en: 'Open file location',
    AppLanguage.vi: 'Mở vị trí tệp trong Explorer',
    AppLanguage.zh: '在资源管理器中显示',
  },
  'copy_path': {
    AppLanguage.en: 'Copy file path',
    AppLanguage.vi: 'Sao chép đường dẫn tệp',
    AppLanguage.zh: '复制文件路径',
  },
  'path_copied': {
    AppLanguage.en: 'File path copied to clipboard',
    AppLanguage.vi: 'Đã sao chép đường dẫn tệp vào clipboard',
    AppLanguage.zh: '文件路径已复制到剪贴板',
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
