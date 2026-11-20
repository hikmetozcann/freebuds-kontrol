#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
"""Generate Resources/{en,de,tr}.lproj/Localizable.strings and verify coverage.

Keys are the Turkish source strings used in `L("...")` calls. Run without
arguments to regenerate the files; `--check` only verifies that every key used
in Sources/ has an English and German entry and that format specifiers match.
"""
from pathlib import Path
import re, sys

ROOT = Path(__file__).resolve().parent.parent
# key: (English, German)
T = {
"Ses": ("Sound", "Klang"),
"Dokunmalar": ("Gestures", "Gesten"),
"Cihaz": ("Device", "Gerät"),
"Görünüm": ("Appearance", "Darstellung"),
"Sistem": ("System", "System"),
"Açık": ("Light", "Hell"),
"Koyu": ("Dark", "Dunkel"),
"Bluetooth ayarlarını aç": ("Open Bluetooth Settings", "Bluetooth-Einstellungen öffnen"),
"Çıkış": ("Quit", "Beenden"),
"Uygulama seçenekleri": ("App options", "App-Optionen"),
"Mac’e bağlı": ("Connected to Mac", "Mit dem Mac verbunden"),
"Bağlanıyor": ("Connecting", "Verbindet"),
"Bağlantı yok": ("Not connected", "Nicht verbunden"),
"Sol kulaklık": ("Left earbud", "Linker Ohrhörer"),
"Sağ kulaklık": ("Right earbud", "Rechter Ohrhörer"),
"Şarj kutusu": ("Charging case", "Ladecase"),
"Seçili": ("Selected", "Ausgewählt"),
"Seçili değil": ("Not selected", "Nicht ausgewählt"),
"Gürültü kontrolü": ("Noise control", "Geräuschkontrolle"),
"Kapalı": ("Off", "Aus"),
"Engelleme": ("Noise cancellation", "Geräuschunterdrückung"),
"Farkındalık": ("Awareness", "Umgebungsmodus"),
"Seviye": ("Level", "Stufe"),
"Ses profili": ("Sound profile", "Klangprofil"),
"Düşük gecikme": ("Low latency", "Niedrige Latenz"),
"Kulaklığın gecikme tercihi.": ("The earbuds’ latency preference.", "Latenzeinstellung der Ohrhörer."),
"Hafif": ("Light", "Leicht"),
"Dengeli": ("Balanced", "Ausgewogen"),
"Güçlü": ("Strong", "Stark"),
"Otomatik": ("Automatic", "Automatisch"),
"Cihaz ayarı": ("Device setting", "Geräteeinstellung"),
"Cihaz ayarı (%ld)": ("Device setting (%ld)", "Geräteeinstellung (%ld)"),
"Engelleme seviyesi: %@": ("Noise cancellation level: %@", "Stufe der Geräuschunterdrückung: %@"),
"Doğal ve dengeli.": ("Natural and balanced.", "Natürlich und ausgewogen."),
"Bas frekansları öne çıkar.": ("Emphasizes bass frequencies.", "Betont die Bässe."),
"Tiz frekansları öne çıkar.": ("Emphasizes treble frequencies.", "Betont die Höhen."),
"Konuşma ve vokaller öne çıkar.": ("Emphasizes speech and vocals.", "Betont Sprache und Gesang."),
"Kulaklıktan okunamadı.": ("Could not be read from the earbuds.", "Konnte nicht von den Ohrhörern gelesen werden."),
"İki kez dokun": ("Double tap", "Doppeltippen"),
"Üç kez dokun": ("Triple tap", "Dreifach tippen"),
"Basılı tut": ("Press and hold", "Gedrückt halten"),
"Gürültü modu geçişi": ("Noise mode switching", "Wechsel des Geräuschmodus"),
"Basılı tutunca geçiş yapılacak modlar.": ("Modes to cycle through when you press and hold.", "Modi, zwischen denen beim Gedrückthalten gewechselt wird."),
"Sol": ("Left", "Links"),
"Sağ": ("Right", "Rechts"),
"Aramayı yanıtla / bitir": ("Answer / end call", "Anruf annehmen / beenden"),
"İki kez dokunarak.": ("With a double tap.", "Durch Doppeltippen."),
"İki dokunuşla aramayı yanıtla / bitir": ("Answer / end call with a double tap", "Anruf per Doppeltippen annehmen / beenden"),
"iki dokunma": ("double tap", "Doppeltippen"),
"üç dokunma": ("triple tap", "Dreifachtippen"),
"basılı tutma": ("press and hold", "Gedrückthalten"),
"gürültü geçişi": ("noise switching", "Geräuschmodus-Wechsel"),
"Kulaklık bilgileri": ("Earbud information", "Ohrhörer-Informationen"),
"Model": ("Model", "Modell"),
"Yazılım sürümü": ("Firmware version", "Firmware-Version"),
"Donanım sürümü": ("Hardware version", "Hardware-Version"),
"Model kodu": ("Model code", "Modellcode"),
"Bağlantı": ("Connection", "Verbindung"),
"Ayarları değiştirmek için kulaklığın Mac’e bağlı olması gerekir. Başka bir cihaza geçtiğinde panel bağlantıyı bekler.":
 ("The earbuds must be connected to this Mac to change settings. If they switch to another device, the panel waits for the connection.",
  "Zum Ändern der Einstellungen müssen die Ohrhörer mit diesem Mac verbunden sein. Wechseln sie zu einem anderen Gerät, wartet das Fenster auf die Verbindung."),
"SE 4 ANC için bağımsız Mac uygulaması. Kulaklık güncellemeleri için HUAWEI Audio Connect’i kullanın.":
 ("Independent Mac app for the SE 4 ANC. Use HUAWEI Audio Connect for earbud firmware updates.",
  "Unabhängige Mac-App für die SE 4 ANC. Für Firmware-Updates der Ohrhörer verwende HUAWEI Audio Connect."),
"Kaynak kodu · GPL-3.0": ("Source code · GPL-3.0", "Quellcode · GPL-3.0"),
"Kulaklık aranıyor…": ("Looking for earbuds…", "Suche nach Ohrhörern …"),
"Kulaklığını Mac’e bağla": ("Connect your earbuds to this Mac", "Verbinde deine Ohrhörer mit diesem Mac"),
"Başka bir cihaza bağlıysa önce o bağlantıyı kesmeniz gerekebilir.":
 ("If they are connected to another device, you may need to disconnect them there first.",
  "Sind sie mit einem anderen Gerät verbunden, musst du die Verbindung dort eventuell zuerst trennen."),
"Bluetooth ayarları": ("Bluetooth Settings", "Bluetooth-Einstellungen"),
"Mac’e bağlan": ("Connect to Mac", "Mit Mac verbinden"),
"Kulaklıkla iletişim kuruluyor…": ("Communicating with the earbuds…", "Kommuniziere mit den Ohrhörern …"),
"Ayarlar kulaklıktan okunuyor.": ("Reading settings from the earbuds.", "Einstellungen werden von den Ohrhörern gelesen."),
"Son okuma %@": ("Last read %@", "Zuletzt gelesen %@"),
"Ayarları yenile": ("Refresh settings", "Einstellungen aktualisieren"),
"Bu ayar okunamadı. Yenileyip tekrar deneyin.": ("This setting could not be read. Refresh and try again.", "Diese Einstellung konnte nicht gelesen werden. Aktualisiere und versuche es erneut."),
"FreeBuds Kontrol’den çık": ("Quit FreeBuds Kontrol", "FreeBuds Kontrol beenden"),
"FreeBuds SE 4 ANC — Mac’e bağlı": ("FreeBuds SE 4 ANC — connected to Mac", "FreeBuds SE 4 ANC — mit dem Mac verbunden"),
"FreeBuds Kontrol — bağlantı yok": ("FreeBuds Kontrol — not connected", "FreeBuds Kontrol — nicht verbunden"),
"FreeBuds’u aç": ("Open FreeBuds", "FreeBuds öffnen"),
"Kulaklık Mac’e bağlı değil. Bağlanıp devam edebilirsiniz.": ("The earbuds are not connected to this Mac. Connect them to continue.", "Die Ohrhörer sind nicht mit diesem Mac verbunden. Verbinde sie, um fortzufahren."),
"Ayarlar kulaklıktan okundu.": ("Settings read from the earbuds.", "Einstellungen von den Ohrhörern gelesen."),
"Kulaklıkta uygulanıyor…": ("Applying to the earbuds…", "Wird auf die Ohrhörer angewendet …"),
"Kulaklıkta uygulandı ve doğrulandı.": ("Applied and verified on the earbuds.", "Auf den Ohrhörern angewendet und bestätigt."),
"FreeBuds SE 4 ANC’yi önce Mac’in Bluetooth ayarlarından eşleştirin.": ("Pair the FreeBuds SE 4 ANC in this Mac’s Bluetooth settings first.", "Koppele die FreeBuds SE 4 ANC zuerst in den Bluetooth-Einstellungen dieses Macs."),
"Birden fazla SE 4 ANC bulundu. Kullanacağınız kulaklığı Bluetooth ayarlarından bağlayın.": ("Multiple SE 4 ANC devices found. Connect the one you want to use in Bluetooth settings.", "Mehrere SE 4 ANC gefunden. Verbinde die gewünschten Ohrhörer in den Bluetooth-Einstellungen."),
"Mac bağlantısı kurulamadı (%ld). iPhone’da kulaklığın bağlantısını kesip tekrar deneyin.": ("Could not connect to this Mac (%ld). Disconnect the earbuds on your iPhone and try again.", "Verbindung mit diesem Mac fehlgeschlagen (%ld). Trenne die Ohrhörer am iPhone und versuche es erneut."),
"Bağlantı zaman aşımına uğradı. Kulaklığı Mac’in Bluetooth ayarlarından bağlayın.": ("The connection timed out. Connect the earbuds in this Mac’s Bluetooth settings.", "Zeitüberschreitung bei der Verbindung. Verbinde die Ohrhörer in den Bluetooth-Einstellungen dieses Macs."),
"Mac bağlantısı kurulamadı (%ld).": ("Could not connect to this Mac (%ld).", "Verbindung mit diesem Mac fehlgeschlagen (%ld)."),
"Kulaklık Mac’e bağlı değil. Bağlan düğmesini kullanın veya Bluetooth ayarlarını açın.": ("The earbuds are not connected to this Mac. Use the Connect button or open Bluetooth Settings.", "Die Ohrhörer sind nicht mit diesem Mac verbunden. Nutze die Schaltfläche „Verbinden“ oder öffne die Bluetooth-Einstellungen."),
"Kulaklığın kontrol servisi bulunamadı. Bluetooth bağlantısını yenileyin.": ("The earbuds’ control service was not found. Refresh the Bluetooth connection.", "Der Steuerdienst der Ohrhörer wurde nicht gefunden. Aktualisiere die Bluetooth-Verbindung."),
"Bu kulaklığın kontrol servisi desteklenmiyor.": ("This earbud’s control service is not supported.", "Der Steuerdienst dieser Ohrhörer wird nicht unterstützt."),
"Kontrol bağlantısı açılamadı (%ld). Diğer kulaklık yönetim uygulamasını kapatıp yenileyin.": ("Could not open the control connection (%ld). Close any other earbud management app and refresh.", "Steuerverbindung konnte nicht geöffnet werden (%ld). Schließe andere Ohrhörer-Apps und aktualisiere."),
"Kulaklık kontrol bağlantısına yanıt vermedi.": ("The earbuds did not respond to the control connection.", "Die Ohrhörer haben auf die Steuerverbindung nicht geantwortet."),
"Bu uygulama yalnızca FreeBuds SE 4 ANC içindir.": ("This app only supports the FreeBuds SE 4 ANC.", "Diese App unterstützt nur die FreeBuds SE 4 ANC."),
"Kulaklığın bağlantısı kesildi.": ("The earbuds disconnected.", "Die Verbindung zu den Ohrhörern wurde getrennt."),
"Kontrol bağlantısı kurulamadı (%ld).": ("Could not establish the control connection (%ld).", "Steuerverbindung konnte nicht hergestellt werden (%ld)."),
"Kulaklık bağlantısı kesildi. Yeniden bağlanın.": ("The earbuds disconnected. Reconnect them.", "Die Ohrhörer wurden getrennt. Verbinde sie erneut."),
"Kulaklığa ulaşılamadı (%ld). Yenileyip tekrar deneyin.": ("Could not reach the earbuds (%ld). Refresh and try again.", "Ohrhörer nicht erreichbar (%ld). Aktualisiere und versuche es erneut."),
"Önceki kulaklık işlemi sürüyor.": ("The previous earbud operation is still in progress.", "Der vorherige Vorgang an den Ohrhörern läuft noch."),
"Kulaklık bu ayarı bildirmedi. Yenileyip tekrar deneyin.": ("The earbuds did not report this setting. Refresh and try again.", "Die Ohrhörer haben diese Einstellung nicht gemeldet. Aktualisiere und versuche es erneut."),
"Kulaklık modeli henüz doğrulanmadı.": ("The earbud model has not been verified yet.", "Das Ohrhörer-Modell wurde noch nicht bestätigt."),
"Kulaklık değişikliği doğrulamadı; ekranda cihazdan okunan ayar gösteriliyor.": ("The earbuds did not confirm the change; the screen shows the setting read from the device.", "Die Ohrhörer haben die Änderung nicht bestätigt; angezeigt wird die vom Gerät gelesene Einstellung."),
"Ayar doğrulanamadı.": ("The setting could not be verified.", "Die Einstellung konnte nicht bestätigt werden."),
"%%%ld": ("%ld%%", "%ld %%"),
", şarj oluyor": (", charging", ", lädt"),
"Pil bilgisi yok": ("No battery information", "Keine Akkuinformation"),
"Okunamadı": ("Could not be read", "Nicht lesbar"),
"Oynat / duraklat": ("Play / pause", "Wiedergabe / Pause"),
"Sonraki parça": ("Next track", "Nächster Titel"),
"Önceki parça": ("Previous track", "Vorheriger Titel"),
"Sesli asistan": ("Voice assistant", "Sprachassistent"),
"İşlem yapma": ("Do nothing", "Keine Aktion"),
"Gürültü modunu değiştir": ("Switch noise mode", "Geräuschmodus wechseln"),
"Sesi artır": ("Volume up", "Lauter"),
"Sesi azalt": ("Volume down", "Leiser"),
"Kapalı ↔ Engelleme": ("Off ↔ Noise cancellation", "Aus ↔ Geräuschunterdrückung"),
"Kapalı / Engelleme / Farkındalık": ("Off / Noise cancellation / Awareness", "Aus / Geräuschunterdrückung / Umgebungsmodus"),
"Engelleme ↔ Farkındalık": ("Noise cancellation ↔ Awareness", "Geräuschunterdrückung ↔ Umgebungsmodus"),
"Kapalı ↔ Farkındalık": ("Off ↔ Awareness", "Aus ↔ Umgebungsmodus"),
"Varsayılan": ("Default", "Standard"),
"Bas": ("Bass", "Bass"),
"Tiz": ("Treble", "Höhen"),
"Vokaller": ("Vocals", "Stimmen"),
}
def esc(s): return s.replace('\\', '\\\\').replace('"', '\\"')
def spec(s): return sorted(re.findall(r'%(?:ld|@|%)', s))
def used_keys():
    keys = set()
    for p in sorted((ROOT / 'Sources').glob('*.swift')):
        keys.update(re.findall(r'\bL\("((?:[^"\\]|\\.)*)"', p.read_text()))
    return keys
def main():
    used = used_keys()
    problems = [f'missing translation: {k}' for k in sorted(used - T.keys())]
    problems += [f'unused translation: {k}' for k in sorted(T.keys() - used)]
    for k, (en, de) in T.items():
        if spec(k.replace('%%', '%%')) != spec(en) and k != '%%%ld':
            problems.append(f'specifier mismatch (en): {k}')
        if k != '%%%ld' and spec(k) != spec(de): problems.append(f'specifier mismatch (de): {k}')
    if problems: raise SystemExit('\n'.join(problems))
    if '--check' not in sys.argv:
        for lang, idx in (('tr', None), ('en', 0), ('de', 1)):
            out = ROOT / 'Resources' / f'{lang}.lproj'; out.mkdir(parents=True, exist_ok=True)
            lines = ['/* Generated by Tools/translations.py; edit the table there. */']
            lines += [f'"{esc(k)}" = "{esc(k if idx is None else v[idx])}";' for k, v in T.items()]
            (out / 'Localizable.strings').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(f'PASS: {len(used)} localization keys have en/de/tr entries')
main()
