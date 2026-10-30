# Duy Beni — Dudak okuma modeli ön araştırması

Tarih: 29 Ekim 2026. Kapsam: resmi depolar, model listeleri, ön işleme kodu ve Türkçe veri kaynaklarının incelenmesi. Model indirme, çıkarım, Core ML dönüşümü veya cihaz performans testi yapılmadı. Hazır ağırlık bağlantıları listeleniyor; dosyaların indirilebilirliği ayrıca denenmedi.

## Güncel karar — doğrudan Türkçe şartı

İkinci tarama sonrası öneri: **MultiVSR'nin Türkçe için ince ayarlanmış sürümü**, araştırma temeli olarak en uygun aday. Aşağıdaki ilk tur Auto-AVSR önerisi, doğrudan Türkçe gereksinimi için geçerli değildir.

[MultiVSR makalesi](https://www.robots.ox.ac.uk/~vgg/publications/2025/Prajwal25/prajwal25.pdf), Türkçeyi yaklaşık 104 saatlik train/validation verisiyle ele alıyor. Temel ortak model 10 dilde eğitiliyor; Türkçe, Hollandaca ve Katalanca ayrı ince ayar deneyleri. Dolayısıyla “13 dilli veri seti” ifadesi, indirilen temel ağırlığın Türkçeyi doğrudan okuyabildiğini kanıtlamaz.

[Resmi depo](https://github.com/Sindhu-Hegde/multivsr) görsel özellik çıkarıcı ve lip-reading Transformer için indirme bağlantıları sağlıyor. Ancak incelenen README'de ayrıca Türkçe ince ayarlı ağırlık belirtilmiyor. Türkçe sürümün erişilebilirliği doğrulanmadan hazır entegrasyon sözü verilemez. Tokenizer'da `tr` bulunması veya `--lang_id tr` seçilmesi eğitim ihtiyacını ortadan kaldırmaz.

[Çıkarım kodu](https://github.com/Sindhu-Hegde/multivsr/blob/master/inference.py), ön işlenmiş yüz videolarından 96×96 RGB kareler ve 25 fps zaman varsayımı kullanıyor. Bizdeki 96×96 ağız kırpması aynı görsel alanı garanti etmiyor. iPhone/Core ML performansı test edilmedi.

İkinci aday [LipPY](https://github.com/CEOKT/LipPY): Türkçe, yalnızca video kullanan model ve ayrıca ses-görüntü modeli tanımlıyor. README video modeli için yaklaşık %48 PER bildiriyor; bu fonem hata oranıdır, kelime doğruluğu değildir ve bağımsız doğrulanmadı. Ağırlıklar git dışında; Kaggle Output'tan alınması isteniyor fakat README'de doğrudan ağırlık indirme bağlantısı doğrulanamadı. Bu nedenle ilk tercih olarak güvenle seçilemiyor.

Sonuç: Doğrudan Türkçe cümle okuma için en güçlü araştırma adayı MultiVSR Türkçe sürümü. Bugün indirip çalıştırılabilir, Türkçe başarısı doğrulanmış ve iPhone'a hazır bir paket bu taramada bulunamadı. Sonraki somut ihtiyaç Türkçe ince ayarlı checkpoint'i edinmek; bulunamazsa MultiVSR Türkçe verisiyle ince ayar yapmak. Bu, kullanıcının İngilizce demo yapmasını gerektirmez.

## İlk tarama notları (Türkçe şartından önce)

İlk masaüstü denemesi için Auto-AVSR; Türkçe uyarlama araştırması için AV-HuBERT ve LMD-VSR değerlendirilsin. İncelenen resmi model listelerinde hazır Türkçe ağırlık doğrulanamadı. Bu, Türkçe modelin hiçbir yerde bulunmadığı anlamına gelmez. İngilizce bir modelin çıktısını Türkçeye çevirmek, Türkçe konuşmanın dudaktan tanınmasını sağlamaz.

| Aday | Hazır ağırlık ve dil | Duy Beni açısından değerlendirme |
| --- | --- | --- |
| Auto-AVSR | Resmi depoda LRS3 için VSR ağırlıkları ve çıkarım öğreticisi var; Türkçe ağırlık listelenmiyor. VSR modelleri 250 milyon parametre. | İlk görüntüden metin denemesi için önerim. iPhone hız ve bellek uygunluğu kanıtlanmış değil. |
| AV-HuBERT | Ön eğitim ve ince ayar ağırlıkları, yalnızca görüntüyle çıkarım akışı var. İncelenen kaynaklarda Türkçe ağırlık doğrulanamadı. | Görsel temsil öğrenme ve ileride ses-görüntü birleşimi için araştırma temeli. Fairseq tabanlı kurulum ve mobil aktarım ayrıca çalışma gerektirir. |
| LMD-VSR | İngilizce, İspanyolca, Fransızca, İtalyanca ve Portekizce ağırlık bağlantıları var. Türkçe listelenmiyor. | Az kaynaklı dillere uyarlama yöntemi olarak ilgili; hazır Türkçe çözüm değil. AV-HuBERT tabanlı olduğundan bağımsız hafif mobil seçenek sayılmamalı. |

Kaynaklar: [Auto-AVSR](https://github.com/mpc001/auto_avsr), [AV-HuBERT](https://github.com/facebookresearch/av_hubert), [LMD-VSR](https://github.com/JeongHun0716/lmd-vsr).

## Mevcut görüntü akışıyla uyum

Yerel LipFrameBuffer.swift ve LipCamera.swift incelendi: 96×96 RGBA görüntüler, saniyede en fazla 8 analiz, en fazla 16 kare ve iki saniyeden kısa geçmiş tutuluyor.

- Auto-AVSR test dönüşümü 88×88 merkez kırpma, gri tonlama, 255'e bölme ve ortalama 0.421 / standart sapma 0.165 ile normalizasyon uyguluyor. Mevcut RGBA kareleri doğrudan model girdisi değil. [Resmi dönüşüm kodu](https://github.com/mpc001/auto_avsr/blob/main/datamodule/transforms.py)
- AV-HuBERT varsayılan görsel özellik hızı 25 Hz; yapılandırmada 88 piksel kırpma ve aynı normalizasyon değerleri var. LMD-VSR, AV-HuBERT ön işleme yolunu referans gösteriyor. Seçilen ağırlığın tam ayarları kurulum sırasında ayrıca sabitlenmeli. [AV-HuBERT açıklaması](https://github.com/facebookresearch/av_hubert), [yapılandırma](https://github.com/facebookresearch/av_hubert/blob/main/avhubert/hubert_pretraining.py)
- Mühendislik çıkarımı: 8 kare/saniyeden 25 kare/saniyeye kare tekrarlamak kayıp dudak hareketini geri getirmez. Daha yüksek ve düzenli örnekleme gerektiren model için yakalama/işleme akışı değişmeli. 25 kare/saniyede iki saniye yaklaşık 50 kare eder; 16 kare sınırı aynı süreyi korumaz.
- Yalnızca boyut eşleştirmek yetmez: yüz hizalama, ağız çevresindeki alan, zamanlama ve konuşmanın başlangıç/bitiş sınırları da eğitim akışıyla eşleşmeli. İki saniyelik kayan pencerenin cümle tanıma için yeterli olduğu varsayılmamalı.

## iPhone'a aktarım

İncelenen depolarda kullanıma hazır iOS/Core ML paketi doğrulanmadı. Apple'ın PyTorch → Core ML dönüşüm yolu mevcut; bu yolun varlığı bu üç modelin bütününün sorunsuz dönüşeceğini göstermiyor. Ön işleme, sinir ağı, metin çözümleme ve Swift entegrasyonu ayrı doğrulanmalı. [Apple dönüşüm belgesi](https://apple.github.io/coremltools/docs-guides/source/convert-pytorch-workflow.html)

Auto-AVSR'nin 250 milyon parametresi için yalnızca FP16 ağırlık hesabı yaklaşık 500 MB'dır (250 milyon × 2 bayt). Bu bir ölçüm değildir; çalışma belleği, ara tensörler ve uygulama giderleri dahil değildir. Cihazda gerçek zamanlı çalışacağı iddia edilemez.

## Türkçe için somut başlangıç kaynağı

Visual Lip Reading Dataset in Turkish, 10 kelime/ifade sınıfında toplam 2.335 örnek bildiriyor. “Merhaba”, “selam” ve “teşekkür ederim” gibi sınıflar var. Bu veri, sınırlı kelime/ifade sınıflandırma denemesi için adaydır; serbest Türkçe cümle altyazısı için yeterlilik göstermez. Veri sayfası CC BY 4.0 bildiriyor. [Veri seti](https://data.mendeley.com/datasets/4t8vs4dr4v/1), [veri makalesi](https://www.mdpi.com/2306-5729/8/1/15)

## Sonraki deney

1. Auto-AVSR'nin resmi çıkarım öğreticisini ayrı bir Python ortamında kur; kullanılan sürümü ve ağırlığı kaydet.
2. Model diline uygun kısa bir İngilizce örnekle, ses girdisi kullanmadan görüntüden metin üretimini doğrula; çıktıyı ve işlem süresini kaydet.
3. Türkçe örnek çıktısını yalnızca dil uyumsuzluğu incelemesi olarak değerlendir; başarılı Türkçe tanıma varsayma.
4. Türkçe önceliği için veri setinin gerçek dosya kapsamını, kare dizilerini ve konuşmacı/video ayrımlarını incele. Aynı kişinin veya aynı kaynak videonun eğitim ve testte bulunmasının sonuçları şişirmesini önle.
5. Çalışan masaüstü temelinden sonra mobil dönüşüm dene; iPhone'da gecikme ve bellek ölçümüyle devam kararını ver.

Bu sıralama araştırma önerisidir. Bu notta deney sonucu veya doğruluk iddiası yoktur.
