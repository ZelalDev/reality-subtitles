# MultiVSR Türkçe model erişim talebi

Durum: Taslak; gönderilmedi. 29 Ekim 2026.

Hedef: https://github.com/Sindhu-Hegde/multivsr/issues

## Title

Availability of Turkish fine-tuned checkpoint from Section V-D

## Body

Hello,

I am developing Duy Beni, an iOS accessibility research prototype, and would like to evaluate visual-only recognition of Turkish speech using MultiVSR.

Section V-D of your paper describes separate fine-tuning experiments for Turkish, Dutch and Catalan. The repository README links a lip-reading Transformer checkpoint and a VTP feature extractor, but I could not identify a separately labelled Turkish fine-tuned checkpoint.

Could you clarify:

1. Does the published model.pth include Turkish fine-tuning, or is it the joint model trained on the ten main languages?
2. Is the Turkish checkpoint used for the approximately 100-hour experiment available, together with its inference configuration and tokenizer?
3. Which Turkish test results and preprocessing settings correspond to that checkpoint?
4. What license and redistribution terms apply to the model weights and code for an iOS research prototype?

If the Turkish checkpoint cannot be shared, are the fine-tuning code and training configuration available to reproduce the Turkish experiment?

Thank you for making this research available.

## Entegrasyon için doğrulama sırası

- Türkçe eğitim kapsamı doğrulanmış ağırlık, kaynak sürümü ve dosya özeti kaydedilecek.
- Ön işleme resmi modelle eşleştirilecek. Mevcut 96×96 ağız kırpması, MultiVSR'nin yüz videosundan ürettiği 96×96 RGB girdisiyle otomatik olarak eşdeğer kabul edilmeyecek.
- 25 fps zaman varsayımı mevcut en fazla 8 fps analiz akışıyla uzlaştırılacak; kare tekrarlama eksik hareket bilgisini geri getirmez.
- Ağırlık önce bilgisayarda, ses girdisi olmadan, metni bilinen Türkçe videolarla sınanacak. WER ve gecikme ölçülecek.
- Başarılı temel sonuçtan sonra Core ML dönüşümü ve fiziksel iPhone ölçümü yapılacak. Sunucuya görüntü gönderme ayrıca ürün/mimari kararı gerektirir; mevcut uygulama bunu yapmıyor.

Bu belge model entegrasyonu değildir. Swift uygulama kodu bu aşamada değiştirilmedi; model yüklenmedi veya test edilmedi.
