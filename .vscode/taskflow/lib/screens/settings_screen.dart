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
  String _selectedThemeName = 'Mor (Varsayılan)';
  ThemeMode _themeMode = ThemeMode.system;

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm Verileri Sil'),
        content: const Text('Tüm görev ve harcamalar silinecek. Emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Renk Teması Seç',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppThemes.themes.entries.map((entry) {
                final isSelected = _selectedThemeName == entry.key;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedThemeName = entry.key);
                    MyApp.of(context)?.setSeedColor(entry.value);
                    Navigator.pop(ctx);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: entry.value,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: Colors.black, width: 3)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: entry.value.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 24)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.key.split(' ').first,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Görünüm
          _sectionHeader('Görünüm'),

          // Renk teması
          ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  AppThemes.themes[_selectedThemeName] ?? Colors.indigo,
              radius: 16,
              child: const Icon(Icons.palette,
                  color: Colors.white, size: 16),
            ),
            title: const Text('Renk Teması'),
            subtitle: Text(_selectedThemeName),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: _showThemeColorPicker,
          ),

          // Karanlık mod
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Arayüz Modu'),
            subtitle: Text(_themeModeLabel(_themeMode)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Arayüz Modu',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _themeModeOption(
                          ctx, 'Sistem Varsayılanı',
                          Icons.phone_android, ThemeMode.system),
                      _themeModeOption(
                          ctx, 'Açık Mod',
                          Icons.light_mode, ThemeMode.light),
                      _themeModeOption(
                          ctx, 'Karanlık Mod',
                          Icons.dark_mode, ThemeMode.dark),
                    ],
                  ),
                ),
              );
            },
          ),

          const Divider(),

          // Bildirimler
          _sectionHeader('Tercihler'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Bildirimler'),
            subtitle: const Text('Görev hatırlatıcıları'),
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
          ),

          const Divider(),

          // Veri
          _sectionHeader('Veri'),
          ListTile(
            leading:
                const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Tüm Verileri Sil',
                style: TextStyle(color: Colors.red)),
            subtitle: const Text('Görev ve harcamaları temizle'),
            onTap: _clearAllData,
          ),

          const Divider(),

          // Hakkında
          _sectionHeader('Hakkında'),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('Proje Türü'),
            subtitle: const Text('Okul Projesi'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Teknoloji'),
            subtitle: const Text('Flutter + SQLite'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versiyon'),
            subtitle: const Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _themeModeOption(BuildContext ctx, String label,
      IconData icon, ThemeMode mode) {
    final isSelected = _themeMode == mode;
    return ListTile(
      leading: Icon(icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : null),
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check,
              color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        setState(() => _themeMode = mode);
        MyApp.of(context)?.setThemeMode(mode);
        Navigator.pop(ctx);
      },
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'Açık Mod';
      case ThemeMode.dark: return 'Karanlık Mod';
      default: return 'Sistem Varsayılanı';
    }
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}