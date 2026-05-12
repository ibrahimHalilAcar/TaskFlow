import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  String _selectedThemeName = 'Okyanus';
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = MyApp.of(context);
      if (app != null) {
        setState(() {
          _selectedThemeName = app.themeName;
          _themeMode = app.themeMode;
        });
      }
    });
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm Verileri Sil'),
        content: const Text(
            'Tüm görev ve harcamalar silinecek. Emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DBHelper.instance.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tüm veriler silindi.')),
        );
      }
    }
  }

  void _showThemeColorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Renk Teması Seç',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Uygulamanın genel renk temasını seç',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 20),
            ...AppThemes.themes.entries.map((entry) {
              final isSelected =
                  _selectedThemeName == entry.key;
              final color = entry.value;
              final scheme = ColorScheme.fromSeed(
                  seedColor: color,
                  brightness: Brightness.light);

              return GestureDetector(
                onTap: () {
                  setState(
                      () => _selectedThemeName = entry.key);
                  MyApp.of(context)
                      ?.setSeedColor(color, entry.key);
                  Navigator.pop(ctx);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? color
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius:
                              BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(entry.key,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isSelected
                                      ? color
                                      : null,
                                )),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _colorDot(scheme.primary),
                                _colorDot(scheme.secondary),
                                _colorDot(scheme.tertiary),
                                _colorDot(
                                    scheme.primaryContainer),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle,
                            color: color, size: 24),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _colorDot(Color color) {
    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  void _showModePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Arayüz Modu',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _themeModeOption(
                ctx,
                'Sistem Varsayılanı',
                Icons.phone_android,
                ThemeMode.system,
                'Cihazın ayarını takip eder'),
            _themeModeOption(
                ctx,
                'Açık Mod',
                Icons.light_mode,
                ThemeMode.light,
                'Her zaman açık tema'),
            _themeModeOption(
                ctx,
                'Karanlık Mod',
                Icons.dark_mode,
                ThemeMode.dark,
                'Her zaman koyu tema'),
          ],
        ),
      ),
    );
  }

  Widget _themeModeOption(BuildContext ctx, String label,
      IconData icon, ThemeMode mode, String subtitle) {
    final isSelected = _themeMode == mode;
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.08) : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading:
            Icon(icon, color: isSelected ? color : null),
        title: Text(label,
            style: TextStyle(
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12)),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: color)
            : null,
        onTap: () {
          setState(() => _themeMode = mode);
          MyApp.of(context)?.setThemeMode(mode);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final selectedColor =
        AppThemes.themes[_selectedThemeName] ?? Colors.indigo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor:
            Theme.of(context).colorScheme.primaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _sectionHeader('Görünüm'),

          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
            child: InkWell(
              onTap: _showThemeColorPicker,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selectedColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: selectedColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.palette,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text('Renk Teması',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text(_selectedThemeName,
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
            child: InkWell(
              onTap: _showModePicker,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _themeMode == ThemeMode.dark
                            ? Icons.dark_mode
                            : _themeMode == ThemeMode.light
                                ? Icons.light_mode
                                : Icons.phone_android,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text('Arayüz Modu',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text(_themeModeLabel(_themeMode),
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(indent: 16, endIndent: 16),

          _sectionHeader('Tercihler'),
          SwitchListTile(
            secondary:
                const Icon(Icons.notifications_outlined),
            title: const Text('Bildirimler'),
            subtitle: const Text('Görev hatırlatıcıları'),
            value: _notifications,
            onChanged: (v) =>
                setState(() => _notifications = v),
          ),

          const Divider(indent: 16, endIndent: 16),

          _sectionHeader('Veri'),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
            child: InkWell(
              onTap: _clearAllData,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_forever,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('Tüm Verileri Sil',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                          Text(
                              'Görev ve harcamaları temizle',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(indent: 16, endIndent: 16),

          _sectionHeader('Hakkında'),
          _infoTile(Icons.school_outlined, 'Proje Türü',
              'Okul Projesi'),
          _infoTile(
              Icons.code, 'Teknoloji', 'Flutter + SQLite'),
          _infoTile(
              Icons.info_outline, 'Versiyon', '1.0.0'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _infoTile(
      IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon,
          color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Açık Mod';
      case ThemeMode.dark:
        return 'Karanlık Mod';
      default:
        return 'Sistem Varsayılanı';
    }
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}