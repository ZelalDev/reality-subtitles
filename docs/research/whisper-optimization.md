# B. Whisper optimizasyon yöntemleri

Araştırma tarihi: 14 Ekim 2026. Bu bölüm literatür ve kod incelemesidir; deney sonucu veya uygulanmış optimizasyon raporu değildir.

## Kaynak tespiti

Hocanın hatırladığı belgenin kimliği kesinleşmemiştir. “Whisper'ı daha iyi kullanmak için geliştiricilerinin yazdığı doküman” tarifine uyan iki doğrudan kaynak vardır:

- OpenAI, [Whisper prompting guide](https://developers.openai.com/cookbook/examples/whisper_prompting_guide): özel isimler, terimler ve yazım biçimi için örnek metinle yönlendirme.
- OpenAI, [Enhancing Whisper transcriptions: pre- & post-processing techniques](https://developers.openai.com/cookbook/examples/whisper_processing_guide): başlangıç sessizliğini kırpma, sesi bölme ve çıktı üzerinde düzeltmeler.

Bunlar Whisper API örnekleridir. Yöntemin fikri WhisperKit'e taşınabilir; Python/API kodu doğrudan Swift uygulamasında çalışmaz. Rehberdeki İngilizceye özgü ASCII dışı karakter temizliği Türkçeye uygulanmamalıdır: ç, ğ, ı, ö, ş, ü harflerini siler. GPT ile sonradan düzeltme de ayrı bir işlem aşamasıdır; modelin akustik tanıma başarısındaki iyileşme gibi raporlanmamalıdır.

Algoritmik “trick”ler için esas kaynak, [Whisper makalesi §4.5, s.12–13 ve Tablo 7](https://cdn.openai.com/papers/whisper.pdf). Burada beam search, temperature fallback, konuşma yokluğu değerlendirmesi, önceki metni bağlam olarak kullanma ve başlangıç zaman damgasını sınırlandırma açıklanır. Amaç özellikle uzun kayıtlardaki tekrarları, atlamaları ve hataları azaltmaktır; hepsi hızlandırma değildir.

Apple cihazlardaki hızlandırmanın kaynağı ise [WhisperKit makalesi §2](https://arxiv.org/html/2507.10860v1). Makaledeki araştırma sistemi ile uygulamamızın kullandığı açık kaynak paketinin özellikleri ayrı değerlendirilmelidir.

## 1. Modelin daha hızlı çalışmasını sağlayan yöntemler

| Yöntem | Nasıl yardımcı olur? | Sınır / karşılık |
| --- | --- | --- |
| Küçük veya daha az decoder katmanlı model | Hesap yükünü azaltır. Tiny/Base/Small ve Turbo bu açıdan karşılaştırılabilir. | Doğruluk, dil, bellek ve cihazla birlikte değerlendirilir; Turbo'nun Tiny'den hızlı olduğu varsayılmaz. |
| Donanıma uygun çalıştırma | Core ML üzerinden CPU/GPU/Apple Neural Engine kullanır. | En iyi seçenek gerçek cihazda ölçülür. |
| KV cache | Decoder'ın önceki token hesaplarını yeniden kullanır. | Kütüphane/model altyapısıdır; uygulama seviyesinde yeni icat edilen bir optimizasyon değildir. |
| Düşük hassasiyet / palettization | Model ağırlıklarının depolama ve bellek maliyetini azaltabilir. | Uyumlu dönüştürülmüş model gerekir; dosyanın küçülmesi otomatik hız garantisi değildir. |
| Daha az yeniden çözümleme | Hatalı çıktı için yapılan fallback denemelerini sınırlar. | Zor/gürültülü kayıtta doğruluk düşebilir. |
| Konuşma aralıklarını belirleme ve parçalama | Uzun kaydı uygun sınırlarla işler; ayrı bir konuşma kapısı gereksiz çağrıları azaltabilir. | VAD, gürültü temizleme veya hedef konuşmacıyı ayırma değildir. |
| Paralel işleme | Bağımsız kayıt veya parçaların toplam işlenme süresini azaltabilir. | Tek kısa cümlenin gecikmesini mutlaka azaltmaz; RAM/ısınma artabilir. |
| Speculative decoding | Küçük modelin önerdiği tokenları büyük modelle doğrular. | Donanım ve model maliyetine bağlıdır; her durumda kazanç sağlamaz. |

Model seçimi için [OpenAI model tablosu](https://github.com/openai/whisper#available-models-and-languages); batching/quantization için [faster-whisper](https://github.com/SYSTRAN/faster-whisper); speculative decoding için [Hugging Face teknik yazısı](https://huggingface.co/blog/whisper-speculative-decoding) kaynak alınmıştır. faster-whisper'ın CTranslate2 ayarları WhisperKit ayarları değildir.

WhisperKit makalesi ANE, stateful KV cache, ses encoder'ını akışa uyarlama ve OD-MBP ağırlık sıkıştırmasını inceler. Ayrıca speculative decoding'i Large v3 Turbo için nihai uygulamalarında kullanmadıklarını açıkça belirtir. Bu teknikleri mevcut Tiny modelinde tek bir seçenekle açabileceğimiz sonucunu çıkaramayız. Makalenin ölçümleri bizim iPhone/Türkçe ölçümümüz değildir. [WhisperKit makalesi](https://arxiv.org/html/2507.10860v1)

## 2. WhisperKit hangilerini destekliyor, uygulamamız hangilerini kullanıyor?

Kontrol edilen bağımlılık: `argmax-oss-swift 1.1.0`, revision `1e2a163736dfa5a198e637ae44c114e1c6d5cc2d`. Uygulama şu anda multilingual Tiny kullanıyor; kayıt bitince transkripsiyon yapıyor.

| Özellik | İncelenen sürümde durum | Uygulamamızdaki durum / karar |
| --- | --- | --- |
| Model seçimi | Var: `WhisperKitConfig(model:)` | `openai_whisper-tiny` seçili. Base/Small doğruluk–hız karşılaştırması yapılabilir. |
| Hesaplama birimi seçimi | Var: `ModelComputeOptions` | Özel seçim yok; paket varsayılanları kullanılıyor. Fiziksel cihaz için encoder/decoder varsayılanı CPU+ANE. GPU karşılaştırması yapılabilir. |
| Dili sabitleme | Var: `language`, `detectLanguage` | `tr` ve `false` zaten ayarlı; yeni optimizasyon diye sunulmaz. |
| Prompt bağlamı | Var: `promptTokens` | Özel terim bağlamı verilmemiş. `usePrefillPrompt: true`, tek başına alan sözlüğü verildiği anlamına gelmez. |
| Temperature fallback | Var | Varsayılan başlangıç 0, artış 0.2, fallback sayısı 5. Uygulama bunları değiştirmiyor. |
| Kalite / sessizlik eşikleri | Var | Varsayılan `compressionRatioThreshold=2.4`, `logProbThreshold=-1`, `noSpeechThreshold=0.6`. Yeni açılacak özellikler değildir. |
| VAD ile parçalama | Var: `chunkingStrategy: .vad` | Ayarlı değil. Bu çağrı yolunda yalnızca modelin ses penceresini aşan girdiler için devreye girer; Tiny için yaklaşık 30 saniye. Kısa kayıtta açmak otomatik kazanç sağlamaz. |
| Paralel parçalar | Var: `concurrentWorkerCount` | iOS varsayılanı 4; etkisi bağımsız parça/kayıt olduğunda araştırılır. |
| Kelime zaman damgaları | Var: `wordTimestamps` | Varsayılan false; kapatıp yeni hız kazancı iddia edemeyiz. |
| Beam search | Sınıf var, `update` ve `finalize` uygulanmamış | Hazır ve kullanılabilir destek olarak sayılmaz. `topK=5`, beş beam anlamına gelmez. |
| Prewarm | Var | Paket dokümanı, uzmanlaştırma sırasında bellek tepesini azaltmaya yönelik olduğunu ve yükleme süresini artırabileceğini söylüyor. Transkripsiyonu kesin hızlandırır denmez. |

Sürüm sabitli dayanaklar: [Configurations.swift](https://github.com/argmaxinc/argmax-oss-swift/blob/1e2a163736dfa5a198e637ae44c114e1c6d5cc2d/Sources/WhisperKit/Core/Configurations.swift), [Models.swift](https://github.com/argmaxinc/argmax-oss-swift/blob/1e2a163736dfa5a198e637ae44c114e1c6d5cc2d/Sources/WhisperKit/Core/Models.swift), [WhisperKit.swift](https://github.com/argmaxinc/argmax-oss-swift/blob/1e2a163736dfa5a198e637ae44c114e1c6d5cc2d/Sources/WhisperKit/Core/WhisperKit.swift), [TokenSampler.swift](https://github.com/argmaxinc/argmax-oss-swift/blob/1e2a163736dfa5a198e637ae44c114e1c6d5cc2d/Sources/WhisperKit/Core/Text/TokenSampler.swift). Bu dosyalar yerel Xcode bağımlılık kopyasından incelendi.

## 3. Uygulamada deneyebileceğimiz yöntemler

Aşağıdakiler kaynaklardan türetilen deney önerileridir; henüz ölçülmüş kazanımlar değildir.

1. **Prompt deneyi:** Aynı Tiny modeliyle bağlamsız çıktı ile kısa Türkçe terim bağlamını karşılaştırmak. Örnek bağlam: “Düzce Üniversitesi, bilgisayar mühendisliği, Whisper, WhisperKit.” Beklenen doğru test cümlesini prompt'a vermemek. Dayanak: OpenAI prompting rehberi.
2. **Fallback deneyi:** Mevcut 5 fallback ile 0 fallback'i karşılaştırmak; sıcaklık başlangıcı ve diğer ayarlar sabit kalmalı. Bu, güvenilirlik mekanizmasını kaldırmanın hız ve hata maliyetini ölçer. Dayanak: Whisper §4.5 ve paket seçenekleri.
3. **Donanım deneyi:** Aynı model ve kayıtlarla varsayılan CPU+ANE ile desteklenen CPU+GPU yapılandırmasını karşılaştırmak. Encoder ve decoder seçimlerini ayrı değiştirmek. Dayanak: `ModelComputeOptions`.
4. **Uzun kayıt deneyi:** 30 saniyeyi aşan kayıtlarda varsayılan işleme ile VAD parçalamayı karşılaştırmak; daha sonra worker sayısını ayrı deneyde değiştirmek. Dayanak: WhisperKit'in parçalama uygulaması.
5. **Model deneyi:** Tiny–Base–Small modellerini aynı Türkçe kayıtlarla karşılaştırmak. Bu özellikle doğruluk için bir adaydır; Base/Small'a geçiş hızlandırma diye adlandırılmaz. Dayanak: OpenAI model tablosu.

Her deneyde tek değişken değiştirilmelidir. Aynı cihaz, build ve ses dosyaları kullanılmalı; temiz ses, sabit gürültü eklenmiş sürümler ve yalnızca gürültü içeren örnekler ayrı raporlanmalıdır. SNR seviyeleri ve tekrar sayısı deney tasarımında önceden belirlenmelidir. Sonuçlar: WER, CER, işlem süresi, RTF = işlem süresi / ses süresi; mümkünse bellek ve termal durum. Sessizlikte yanlış metin üretimi ayrıca sayılmalıdır.

Mevcut uygulamanın işlem süresi ölçümü model yüklemeyi dışarıda bırakır. İlk kullanımdaki bekleme ayrıca ölçülmeli; canlı altyazı gecikmesiyle dosya işleme süresi birbirine karıştırılmamalıdır. Uygulama kayıtları siliyor ve CSV yalnızca son 10 sonucu tutuyor. Tekrarlanabilir deney için sabit test dosyaları ve ayrı sonuç arşivi gerekecek; mevcut canlı kayıt akışı tek başına kontrollü A/B karşılaştırması sağlamaz.

## 4. Gürültülü ortamlarda transkripsiyonu iyileştirme

- **Konuşma varlığını belirleme:** Sessizlikte/gürültüde gereksiz metin üretimini azaltmak için VAD ve no-speech kontrolü değerlendirilebilir. Enerji temelli VAD, güçlü arka plan gürültüsünde zorlanabilir; konuşma başlarını kesip kesmediği ölçülmelidir. [Whisper §4.5](https://cdn.openai.com/papers/whisper.pdf)
- **Gürültü bastırma:** ASR öncesine ayrı bir speech-enhancement bileşeni eklenebilir. [DeepFilterNet](https://github.com/Rikorose/DeepFilterNet) buna bir örnektir; WhisperKit'in hazır bir decoding ayarı değildir. Ön işleme konuşmayı da bozabileceğinden, ham ve temizlenmiş aynı sesin WER'i ve toplam gecikmesi karşılaştırılmalıdır.
- **Bağlam ve model seçimi:** Terim prompt'u özel isim hatalarını azaltma adayıdır; kaybolmuş ses bilgisini geri getirmez. Daha büyük multilingual modeller de denenebilir. [OpenAI prompting rehberi](https://developers.openai.com/cookbook/examples/whisper_prompting_guide), [OpenAI modelleri](https://github.com/openai/whisper#available-models-and-languages)
- **Konuşmacı ayrımı:** “Kim ne zaman konuştu?” diarization problemidir. “Sadece hedef kişinin sesini çıkar” ise speaker separation/extraction problemidir. Bunlar VAD'den farklıdır. [WhisperX](https://github.com/m-bain/whisperX) ayrı bir Whisper modeli değil; transkripsiyon, hizalama ve diarization bileşenlerini birleştiren bir sistemdir. Diarization etiketleri, üst üste konuşan seslerin otomatik temizlenmesi anlamına gelmez.

Önerilen ilk uygulama deneyi, Tiny sabitken kısa terim prompt'unun ve fallback sayısının ayrı ayrı değerlendirilmesidir. Hız kazancı ancak doğrulukla birlikte ölçüldükten sonra kabul edilmelidir. Hocanın kastettiği belgenin kesin kimliği hâlâ açık konudur; bulunan resmî rehberler doğrulanmış dayanak, belge eşleştirmesi ise adaydır.
