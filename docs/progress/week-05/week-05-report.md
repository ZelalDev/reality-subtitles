Week 5

Duy Beni • 30 Ekim 2026

Bu hafta yapılanlar

Bu hafta geçen hafta oluşturduğum Lip Reading ekranını geliştirdim. Dudak bölgesini tespit edip kırpmanın yanında, ağız açıklığının zaman içindeki değişimini ölçen bir analiz ekledim. Son görüntü karelerini de ekranda göstererek hazırlanmış görüntü dizisini inceleyebileceğim bir alan oluşturdum.

Türkçe dudak okuma için kullanılabilecek açık kaynak projeleri araştırdım. Ancak uygulamada çalıştırabileceğim, Türkçe için eğitildiği ve erişilebilir olduğu doğrulanmış bir model ağırlığına henüz ulaşamadım. Bu nedenle bu haftanın çıktısı hareket analizi ve model öncesi görüntü hazırlama altyapısının geliştirilmesi oldu; uygulama henüz dudaktan kelime veya cümle üretmiyor.

Dudak hareketini nasıl ölçüyorum?

Apple Vision ile elde edilen iç ve dış dudak noktalarını kullanıyorum. İç dudak açıklığını dış dudak genişliğine bölerek bir oran hesaplıyorum. Böylece yüzün görüntüde büyüyüp küçülmesinin ölçüme etkisini azaltmayı amaçlıyorum. Hesaplamada ağız eksenini de dikkate alıyorum; ancak bu, her yüz açısında güvenilir sonuç elde edildiği anlamına gelmiyor.

Son iki saniyedeki açıklık değerlerini bir çizgi grafikte gösteriyorum. Yeterli örnek toplandıktan sonra değerlerin değişim aralığına göre “Hareket gözlendi” veya “Hareket düşük” bilgisi veriyorum. Ölçüm bulunmadığında ya da yeni başladığında ayrı durum mesajları gösteriliyor.

Bu gösterge deneysel bir eşik kullanıyor. Dudak hareketi; konuşma, gülümseme veya başka bir yüz hareketinden kaynaklanabilir. Bu yüzden göstergenin konuşma tespiti ya da kelime tahmini olmadığını arayüzde açıkça belirttim.

Görüntü tamponunda ne değişti?

• Bellekte tutulan son dudak karelerini en eskiden en yeniye bir şerit halinde gösterdim.

• Tampondaki kare sayısını ve ilk kare ile son kare arasındaki süreyi ekledim.

• Mevcut 96×96 piksel kırpma, en fazla 16 kare ve iki saniyeden kısa geçmiş sınırlarını korudum.

• Dudak tespiti kaybolduğunda geçmiş görüntüler temizleniyor. Kamera durduğunda grafik ve kareler de kaldırılıyor.

Görüntüler dosyaya kaydedilmiyor ve sunucuya gönderilmiyor. Ölçüm geçmişi de yalnızca bellekte tutuluyor. Model seçildiğinde kare hızı, renk biçimi ve hizalama gereksinimlerini ayrıca uyarlamam gerekecek.

Türkçe model araştırmasında ne buldum?

<b>MultiVSR:</b> Makalede Türkçe için ayrı ince ayar deneyleri bulunuyor. Ancak yayımlanan temel model bağlantısının Türkçe ince ayarlı sürüm olduğunu doğrulayamadım. Türkçe ağırlık ve ona ait çalıştırma ayarları netleşmeden bu modeli uygulamaya eklemek doğru olmayacak.

<b>LipPY:</b> Türkçe ve yalnızca görüntü kullanan bir model tanımlıyor. Eğitim ve çıkarım kodlarını inceledim; ancak eğitilmiş ağırlığı indirip çalıştıramadım. Depoda bildirilen fonem hata oranını uygulamamın sonucu olarak değerlendirmiyorum.

<b>Diğer projeler:</b> TrLipNetProject ve Çankaya Üniversitesi Türkçe dudak okuma projesinde eğitim not defterleri ve kaynak kodlar buldum. İncelenen dosyalarda doğrudan kullanabileceğim eğitilmiş ağırlıkları doğrulayamadım. GitHub’da kod bulunmasının tek başına hazır model anlamına gelmediğini gördüm.

Bu hafta neleri kontrol ettim?

Yeni ölçüm hesabını örnek noktalarla kontrol ettim. Ölçek, düzlem içi dönüş ve konum değişikliğinde oranın korunması; eksik noktaların, geçersiz değerlerin ve veri kesintilerinin ele alınması kontrolleri geçti. Sabit açıklık ve değişen açıklık örnekleriyle hareket göstergesinin davranışını da kontrol ettim.

Mevcut kırpma ve tampon kontrollerini tekrar çalıştırdım. Koordinat yönü, kenar sınırları, 96×96 çıktı, kare sırası, kapasite ve temizleme kontrolleri geçti. Uygulamanın genel iOS hedefi için kod imzalama kapalı Xcode derlemesi başarıyla tamamlandı.

Bu kontroller gerçek kamera doğruluğunu kanıtlamıyor. Yeni ekranın fiziksel iPhone üzerinde farklı ışık, mesafe ve açılardaki davranışını henüz doğrulamadım. RAM, ısınma, gecikme veya kelime hata oranı için bu hafta yeni bir cihaz ölçümü yapmadım.

Şu anki durum ve sonraki adım

Uygulamada artık dudak kırpmasına ek olarak ölçüm grafiği, deneysel hareket durumu ve son karelerin incelenebildiği bir alan var. Türkçe görsel konuşma tanıma için eksik kalan temel parça, erişilebilir ve doğrulanmış eğitilmiş model ağırlığı.

• Yeni ekranı fiziksel iPhone üzerinde denemek; tespit kaybı ve kamera kapanışında temizlemeyi kontrol etmek.

• Türkçe ağırlık erişimini netleştirip önce küçük bir video üzerinde gerçek model çıktısı almak.

• Modelin giriş biçimini mevcut görüntü akışına uyarlamak; ardından cihaz uygunluğunu ve hata oranını ölçmek.

İncelenen kaynaklar

<link href="https://github.com/Sindhu-Hegde/multivsr" color="#333333">MultiVSR</link>

<link href="https://github.com/CEOKT/LipPY" color="#333333">LipPY</link>

<link href="https://github.com/Brbln/TrLipNetProject" color="#333333">TrLipNetProject</link>

<link href="https://github.com/CankayaUniversity/ceng-407-408-2025-2026-Turkish-Lip-Reading-System" color="#333333">Çankaya Üniversitesi Türkçe dudak okuma projesi</link>