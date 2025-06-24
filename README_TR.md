## Dil / Language

[English](README.md)

# MPV Altyazı Birleştirici

Bu MPV oynatıcı için yazılmış Lua betiği, o anda etkin olan iki altyazıyı (dahili veya harici) tek bir `.ass` altyazı dosyasına birleştirerek, birini ekranın altında, diğerini üstünde görüntüler. Bu, özellikle dil öğrenenler veya iki farklı çeviriyi ya da bir çeviri ile orijinal metni aynı anda görmek isteyen herkes için kullanışlıdır.

![Ekran görüntüsü 2025-06-24 113218](https://github.com/user-attachments/assets/54f465ed-7e8b-4ae0-95aa-f554ba3e1c21)
![Ekran görüntüsü 2025-06-24 113306](https://github.com/user-attachments/assets/5b4a64c0-aa45-4cd9-b33f-6abb52f0a1ec)


## Özellikler

* **Altyazıları Birleştirme**: İki etkin altyazı parçasını (dahili veya harici) tek bir `.ass` dosyasına birleştirir.
* **Çift Görüntüleme**: Bir altyazı parçasını videonun altında, diğerini üstünde görüntüler.
* **Zaman Senkronizasyonu**: Başlangıç zamanına en yakın olana göre altyazıları senkronize etmeye çalışır.
* **Otomatik Temizleme**: Birleştirme işlemi sırasında oluşturulan geçici dosyaları kaldırır.

## Kurulum

1.  **MPV Betikleri Dizinini Bulun**:
    * **Windows**: `C:\Users\KullanıcıAdınız\AppData\Roaming\mpv\scripts\`
    * **Linux/macOS**: `~/.config/mpv/scripts/` veya `~/.mpv/scripts/`

2.  **Betiği İndirin**:
    `merge-subs.lua` dosyasını indirin ve MPV `scripts` dizinine yerleştirin.

3.  **FFmpeg'in Yüklü Olduğundan Emin Olun**:
    Bu betik, dahili altyazı parçalarını çıkarmak için `ffmpeg` kullanır. `ffmpeg`'in sisteminizde yüklü olduğundan ve PATH'inizden erişilebilir olduğundan emin olun. Yoksa, [ffmpeg.org](https://ffmpeg.org/download.html) adresinden indirebilirsiniz.

## Kullanım

1.  **MPV ile Bir Video Açın**:
    MPV'de en az iki altyazı parçasına (dahili veya harici) sahip herhangi bir video dosyasını açın.

2.  **İki Altyazı Parçasını Etkinleştirin**:
    * **Birincil Altyazı**: MPV'nin altyazı seçim seçeneklerini kullanarak (örn. parçalar arasında geçiş yapmak için `j` veya `J` tuşlarına basarak veya OSD menüsünü kullanarak) ilk altyazı parçanızı seçin. Bu, birleştirilmiş çıktıda "Altta" yer alacak altyazı olacaktır.
    * **İkincil Altyazı**: İkinci altyazı parçanızı seçin. Bu, MPV'nin `secondary-sid` seçeneği aracılığıyla yapılabilir. Örneğin, OSD menüsünü kullanarak ikincil bir altyazı seçebilir veya `input.conf` dosyanızda bir tuş ataması kullanabilirsiniz (örn. `s cycle secondary-sid`). Bu, birleştirilmiş çıktıda "Üstte" yer alacak altyazı olacaktır.

3.  **Altyazıları Birleştirin**:
    Birleştirme işlemini başlatmak için `Ctrl+B` (varsayılan tuş ataması) tuşlarına basın.

4.  **Onay**:
    Başarılı olursa OSD'de "✅ Seçili altyazılar birleştirildi 🎬" mesajı görünecektir. Bir sorun olursa, bir hata mesajı görüntülenecektir.

## Nasıl Çalışır?

Betik aşağıdaki adımları gerçekleştirir:

1.  **Etkin Altyazıları Tanımlar**: İki etkin altyazı parçasını (`sid` ve `secondary-sid`) kontrol eder.
2.  **Altyazı Dosyalarını Çıkarır**:
    * Altyazı harici bir dosyaysa, doğrudan yolunu kullanır.
    * Altyazı video dosyasına gömülüyse, geçici bir `.srt` dosyasına çıkarmak için `ffmpeg` kullanır.
3.  **SRT Dosyalarını Ayrıştırır**: Her iki altyazı dosyası da Lua tablolarına ayrıştırılır.
4.  **Altyazıları ASS Biçimine Birleştirir**:
    * Birincil altyazı parçası üzerinde döner.
    * Birincil parçadaki her altyazı girişi için, başlangıç zamanına göre ikincil parçadaki "en yakın" karşılık gelen altyazı girişini bulur.
    * Daha sonra bu çiftleri önceden tanımlanmış stilleri (`Bottom` ve `Top`) uygulayarak Gelişmiş SubStation Alpha (`.ass`) biçimine dönüştürür.
5.  **Birleştirilmiş Altyazıyı Yükler**: Yeni oluşturulan `.ass` dosyası MPV'ye yüklenir ve çakışmaları önlemek için `secondary-sid` "no" olarak ayarlanır.
6.  **Temizler**: Dahili altyazıları çıkarmak için oluşturulan tüm geçici dosyalar ve dizinler kaldırılır.

## Yapılandırma

Birleştirilmiş altyazıların görünümünü `merge-subs.lua` dosyasındaki `ass_template_top` değişkenini düzenleyerek özelleştirebilirsiniz. Özellikle, `Style: Bottom` ve `Style: Top` satırlarını aşağıdaki gibi değiştirebilirsiniz:

* **Fontname**: `Arial`
* **Fontsize**: `50`
* **PrimaryColour**: Altta için `&H00FFFFFF` (beyaz için ARGB hex kodu), Üstte için `&H00FFFF00` (sarı için ARGB hex kodu).
* **OutlineColour**: `&H00000000` (siyah)
* **BackColour**: `&H64000000` (yarı saydam siyah)
* **Alignment**: Altta için `2` (alt orta), Üstte için `8` (üst orta).
* **MarginV**: Altta için `50` (alttan uzaklık), Üstte için `950` (üstten uzaklık).

Stil seçenekleri hakkında daha fazla bilgi için [ASS (Gelişmiş SubStation Alpha) biçimi belgelerine](http://docs.aegisub.org/3.2/ASS_Tags/) bakınız.

## Sorun Giderme

* **"❌ İki altyazı aynı anda aktif değil."**: MPV'de hem birincil (`sid`) hem de ikincil (`secondary-sid`) altyazı parçasının etkin olduğundan emin olun.
* **"❌ FFmpeg ile altyazı çıkarılamadı."**:
    * FFmpeg'in yüklü olduğundan ve sisteminizin PATH'inde olduğundan emin olun.
    * Video dosyasının bozuk olmadığından veya dahili altyazı parçalarının düzgün bir şekilde çoğaltıldığından emin olun.
* **"❌ Altyazılar parse edilemedi."**:
    * `.srt` dosyalarınızın doğru biçimlendirilmiş olduğunu doğrulayın.
    * Çıkarılan geçici dosyalar boş veya bozuksa, FFmpeg çıkarma işleminde bir sorun olabilir.
* **Altyazılar doğru senkronize olmuyor**: Betik "en yakın başlangıç zamanı" yaklaşımını kullanır. Yüksek derecede senkronize olmayan altyazılar için bu mükemmel sonuçlar vermeyebilir. Birleştirmeden önce MPV'de altyazı parçalarından birini manuel olarak ayarlamanız gerekebilir (örn. `Alt+j` veya `Alt+k` kullanarak).

## Katkıda Bulunma

İyileştirmeler veya hata düzeltmeleri için önerileriniz varsa çekinmeyin, sorunlar açın veya çekme istekleri gönderin.
---
**Not**: `username`, `repo-name` ve `path/to/your/screenshot.png` kısımlarını kendi GitHub bilgileriniz ve betiği çalışırken gösteren bir ekran görüntüsü/GIF'in yolu ile değiştirin.
