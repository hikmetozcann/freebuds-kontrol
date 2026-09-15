# FreeBuds Kontrol

**FreeBuds SE 4 ANC için yerel Mac kontrol paneli.**

[İndir](https://github.com/hikmetozcann/freebuds-kontrol/releases/latest) · [English](README.md) · [Hata bildir](https://github.com/hikmetozcann/freebuds-kontrol/issues/new/choose)

<img src="docs/images/light.png" width="520" alt="FreeBuds Kontrol açık görünüm">

*Uygulamanın kendi bileşenlerinden örnek değerlerle ve azaltılmış şeffaflık görünümüyle üretilen arayüz önizlemesi.*

Menü çubuğundan sol/sağ/kutu pilini okuyun; ANC, farkındalık, ekolayzır, düşük gecikme ve dokunma hareketlerini ayarlayın. Değişiklikler kulaklıktan geri okunarak doğrulanır. Hesap, bulut hizmeti veya üçüncü taraf çalışma zamanı bağımlılığı yoktur.

## Destek

- **HUAWEI FreeBuds SE 4 ANC / BTFT0026** için geliştirilmiştir.
- Gerçek kulaklık doğrulaması: **1.9.0.199** firmware, **macOS 26.3**, Apple Silicon.
- macOS **14+** hedeflenir; Apple Silicon ve Intel paketleri CI üzerinde derlenip kontrol edilir. Her Mac/firmware birleşimi donanımla denenmiş değildir.
- Arayüz Türkçedir. macOS 26’da cam sekmeler, eski sürümlerde standart malzeme kullanılır.

**Çift cihaz bağlantısı, aynı anda iPhone/Mac sesi, otomatik cihazlar arası geçiş veya firmware müdahalesi sağlamaz.** Kutu pil yüzdesi kulaklığın en son bildiği değer olabilir. Düşük gecikme ayarı gerçek ses gecikmesinin milisaniye cinsinden ölçümü değildir.

## Kurulum ve kullanım

1. [Releases](https://github.com/hikmetozcann/freebuds-kontrol/releases/latest) bölümünden Mac’inize uygun ZIP’i indirin: Apple Silicon için `arm64`, Intel için `x86_64`.
2. Arşivi açıp **FreeBuds Kontrol.app** dosyasını **Uygulamalar** klasörüne taşıyın.
3. Kulaklığı macOS Bluetooth ayarlarından eşleştirin ve bağlayın. Uygulamayı açın; istenirse Bluetooth iznini verin.
4. Menü çubuğundaki kulaklık simgesi paneli açar. Yanındaki yüzde, pili daha düşük olan kulaklığa aittir.

Paketler **ad hoc imzalıdır; Apple noter onayı ve Developer ID imzası yoktur**. İlk açılış engellenirse kaynağı/indirmeyi değerlendirip güvendiğiniz takdirde [Apple’ın uygulamaya özel açma yönergelerini](https://support.apple.com/tr-tr/102445) izleyin veya kaynak koddan derleyin.

**Ses**, **Dokunmalar** ve **Cihaz** sekmelerinden ayarlara ulaşılır. **… → Görünüm** menüsünden Sistem / Açık / Koyu seçilir. Paneli kapatmak uygulamayı menü çubuğunda bırakır. Tamamen kapatmak için **… → Çıkış** veya **⌘Q** kullanın. Oturum açılışına otomatik eklenmez.

Kulaklık telefona geçtiğinde panel bağlantıyı bekler. Gerekirse telefondan bağlantıyı kesin, sonra **Mac’e bağlan** düğmesini veya macOS Bluetooth ayarlarını kullanın. Aynı anda iki kulaklık yönetim uygulaması çalıştırmayın.

## Kaynaktan derleme

macOS SDK’sını içeren Xcode/Command Line Tools ve Swift 6+ gerekir; bağımlılık kurulumu yoktur.

```sh
git clone https://github.com/hikmetozcann/freebuds-kontrol.git
cd freebuds-kontrol
./build.sh
"build/FreeBuds Kontrol.app/Contents/MacOS/FreeBudsKontrol" --self-test
```

Çıktı `build/FreeBuds Kontrol.app` olur. `--self-test` kulaklık gerektirmez. GUI kapalı ve kulaklık Mac’e bağlıyken `--snapshot` salt okuma tanısı verir. **`--smoke-test` ayarları kısa süreli değiştirir ve geri yüklemeyi dener**; önce [geliştirme notlarını](docs/DEVELOPMENT.md) okuyun.

## Gizlilik ve katkı

Telemetri, hesap, güncelleme denetleyicisi veya uygulama sunucusu yoktur. Seçilen Bluetooth adresi ve görünüm tercihi Mac’in yerel tercihlerinde saklanır. Seri numarası snapshot çıktısına dahil edilmez. Herkese açık hata bildirimlerine cihaz adresi, seri numarası veya incelenmemiş kayıtlar eklemeyin.

[Katkı rehberi](CONTRIBUTING.md) · [Test kapsamı](docs/VALIDATION.tr.md) · [Güvenlik bildirimi](SECURITY.md)

**GPL-3.0-only.** Protokol bilgileri için [OpenFreebuds](https://github.com/melianmiko/OpenFreebuds) katkıcılarına teşekkürler. Paketlenen çizimler bu projeye aittir; Huawei fotoğrafları veya firmware dosyaları içermez. Huawei veya Apple ile resmî bağlantısı yoktur. [Lisans](LICENSE) · [Atıflar](NOTICE.md)
