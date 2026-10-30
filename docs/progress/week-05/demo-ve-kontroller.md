# Week 5 — gösterim ve doğrulama

30 Ekim 2026

## Hocaya kısa anlatım

“Geçen hafta kamera görüntüsünden dudak bölgesini ayırmıştım. Bu hafta dudak açıklığını zaman içinde ölçüp grafik olarak göstermeyi ve model girdisi olacak son kareleri ekranda incelemeyi ekledim. Türkçe dudak okuma modellerini de araştırdım; erişilebilir, Türkçe için eğitilmiş ağırlık doğrulanamadığından henüz kelime tahmini eklemedim.”

## Fiziksel iPhone üzerinde gösterim

Bu adımlar henüz fiziksel cihazda doğrulanmadı. Sunumdan önce deneyin.

1. Xcode'dan güncel uygulamayı iPhone'a çalıştırın. Lip Reading ekranını açın ve kamerayı başlatın.
2. Arka kamerayı iyi aydınlatılmış tek bir kişinin yüzüne yöneltin. Telefonu ve başı mümkün olduğunca sabit tutun.
3. Dudakları sabit tutup sonra yavaşça açıp kapatın. Grafiği ve deneysel hareket göstergesini gözlemleyin. Göstergenin konuşma tespiti olmadığını belirtin.
4. Son kareler şeridini ve en fazla 16 karelik tamponu gösterin. Süre ilk ve son kare arasındaki zaman farkıdır, her zaman iki saniye değildir.
5. Yüzü kadrajdan çıkarın. Karelerin ve grafiğin temizlendiğini kontrol edin. Durdur butonuyla tekrar kontrol edin.
6. Ekrandan çıkma ve uygulamayı arka plana alma sonrası kameranın durduğunu kontrol edin.

Işık, yüz açısı ve Vision ölçüm hatası hareket göstergesini etkileyebilir. Birden fazla yüz olduğunda en büyük yüz seçilir; kişi kimliği takip edilmez. Gerçek cihazda gecikme, RAM, ısınma ve doğruluk ölçülmedi.

## Yazılım kontrolleri

Proje kökünden:

```sh
xcrun swiftc ios/RealitySubtitles/LipMotion.swift tests/LipMotionChecks.swift -o /tmp/lip-motion-checks
/tmp/lip-motion-checks
xcrun swiftc ios/RealitySubtitles/LipFrameBuffer.swift tests/LipFrameBufferChecks.swift -o /tmp/lip-frame-checks
/tmp/lip-frame-checks
```

Hareket kontrolü: geometrik oran, ölçek/dönüş/öteleme, eksik noktalar, sabit ve değişken açıklık, kapasite, süre sınırı, uzun kesinti, zaman sıfırlanması, geçersiz değerler.

Kırpma/tampon kontrolü: koordinat yönü, kenarlar, 96×96 RGBA çıktı, sıra, süre, kapasite ve temizleme. Core Image kontrolü macOS grafik erişimi gerektirir.

## Ölçüm yöntemi ve sınırları

İç dudak noktalarının dış dudağın en uzun eksenine dik izdüşüm aralığı, dış dudak genişliğine bölünür. Son iki saniyenin en fazla 16 örneği tutulur. En az dört örnek ve 0,4 saniye gerekir. Aralık 0,04 veya üstündeyse “Hareket gözlendi” gösterilir. Eşik deneysel olup kişiye göre kalibre edilmemiştir. Ölçümler arasında 0,5 saniyeden uzun kesinti ya da geçersiz ölçüm geçmişi sıfırlar. Bu değerler fonem, kelime, konuşma olasılığı veya doğruluk puanı değildir.

Mevcut en fazla 8 analiz/saniye ve 96×96 ağız kırpması bir Türkçe modelin tüm giriş gereksinimlerini karşıladığı anlamına gelmez. Model seçildikten sonra kare hızı, hizalama ve renk dönüşümü yeniden uyarlanmalıdır.
