# Doğrulama kapsamı

## Gerçek donanım

14–15 Eylül 2026 geliştirme kontrolleri; FreeBuds SE 4 ANC (`BTFT0026`), `1.9.0.199` firmware, Apple Silicon ve macOS 26.3 ile yapıldı.

Pil/model okuma, ANC seviyesi, EQ, sol iki/üç dokunma ve basılı tutma hareketleri, gürültü modu döngüsü ve düşük gecikme ayarı gerçek kulaklıkta denendi. Her değişiklik geri okundu ve başlangıç değeri geri yüklendi; son ayar grupları başlangıçla eşleşti. Farkındalık/kapalı/ANC geçişleri ve arama hareketinin açılıp kapatılması arayüzden de kontrol edildi.

1.1 arayüzü açık/koyu görünümde, gerçek pil değerleriyle ve bağlantısız durumda incelendi. Herkese açık 1.2.0 sürümü çizimleri, azaltılmış şeffaflıktaki renk çözümlemesini, uygulama kimliğini ve dağıtım araçlarını değiştirir; Bluetooth taşıması ve ayar modeli bu donanım kontrollerinden geçen uygulamadan korunmuştur.

## Otomatik kontroller

CI, Apple Silicon ve Intel üzerinde uygulamayı derler; CRC referans vektörü, paketlerin tüm parçalanma sınırları, art arda paketler, bozuk veri sonrası toparlanma, hatalı TLV ve komuta özgü yanıt/ACK kabul kontrollerini çalıştırır. Paket imzası, Info.plist ve dağıtım arşivi de doğrulanır.

CI kulaklığa bağlanmaz. Bu kontroller, her macOS sürümünde gerçek donanım doğrulaması anlamına gelmez. İki dağıtım paketi de yayımlanan main commit’inin başarılı CI çalışmasından alınır.

## Sınırlar

- Diğer kulaklık modelleri, firmware sürümleri ve her hareket birleşimi denenmedi.
- Ses kalitesi, ANC etkinliği ve gecikme milisaniye cinsinden ölçülmedi.
- Gerçek telefon araması ve bütün hareketlerin fiziksel dokunma sonucu değerlendirilmedi.
- Bluetooth bağlantısı tamamen koptuktan sonra “Mac’e bağlan” işlemi tam olarak doğrulanmadı.
- Eski macOS malzeme yedeği ve erişilebilirlik tercihlerinin her birleşimi fiziksel Mac’lerde denenmedi.
- Çift cihaz bağlantısı, cihazlar arası geçiş ve firmware müdahalesi uygulanmadı.

README görselleri uygulamanın kendi bileşenlerinden, örnek değerler ve azaltılmış şeffaflık kullanılarak ekran dışında üretilir. Donanım testi kanıtı değildir.
