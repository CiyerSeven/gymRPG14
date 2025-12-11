# gymRPG
![logo](assets/logo.png)
LevelUp Gym Tracker

LevelUp Gym Tracker, geleneksel antrenman takibini oyunlaştırma (gamification) öğeleriyle birleştiren modern bir Flutter uygulamasıdır. Her set, her tekrar ve her kilogram; kas grubunuzun XP (Deneyim Puanı) kazanmasını ve Level atlamasını sağlar. Sadece ağırlık kaldırmayın, bir maceracı gibi seviye atlayın!

Temel Özellikler

Antrenman Takibi: Tarih ve nota dayalı detaylı antrenman kaydı.

XP ve Level Sistemi: Çalışılan kas gruplarına göre gerçek zamanlı deneyim puanı (XP) ve seviye (Level) ilerlemesi.

Kişisel Analiz: Maksimum 1RM (Tekrar Maksimum) hesaplama ve kas grubuna göre toplam hacim analizi.

Kilo ve Boy Takibi: Kilo geçmişini takip etme, BMI (Vücut Kitle İndeksi) hesaplama ve grafiksel ilerleme.

Haftalık Program: Haftalık antrenman programı oluşturma ve kaydetme.

Hareket Yönetimi: Kullanıcının kendi hareket tanımlarını kaydetme ve kategorize etme yeteneği.

Proje Görünümü

Dashboard ve İlerleme

Uygulamanın ana sayfasında genel seviyenizi, haftalık özetinizi ve kas grubuna göre seviye ilerlemenizi anında görün.

Kilo Takibi ve BMI

Kişisel verilerinizi girin, geçmişinizi grafikte takip edin ve BMI skorunuzu anlık olarak görün.

Kurulum ve Başlatma

Bu projeyi yerel ortamınızda çalıştırmak için aşağıdaki adımları takip edin:

Ön Gereksinimler

Flutter SDK (Stabil kanal önerilir)

Dart SDK

Hive: Bu proje, yerel veritabanı olarak Hive kullanmaktadır.

Adımlar

Projeyi Klonlayın:

git clone [REPO_URL]
cd gymrpg


Bağımlılıkları Yükleyin:

flutter pub get


Hive Model Kodlarını Oluşturun:
Hive modellerini kullanabilmek için build_runner çalıştırmanız gerekir:

flutter pub run build_runner build


Uygulamayı Başlatın:

flutter run


Dosya Yapısı

/lib
|-- /models
|   |-- workout.dart
|   |-- exercise.dart
|   |-- weight_entry.dart 
|   |-- ... (Diğer Hive modelleri)
|-- /providers
|   |-- gym_tracker_provider.dart  <-- Ana State Yönetimi ve İş Mantığı
|-- /screens
|   |-- dashboard_screen.dart 
|   |-- manage_exercises_screen.dart <-- Hareket Yönetimi
|   |-- personal_data_screen.dart   <-- Kilo & Boy Takibi
|   |-- ... (Diğer ekranlar)
|-- /services
|   |-- db_service.dart             <-- Hive Veritabanı Erişim Katmanı
|-- main.dart                       <-- Uygulama Başlangıcı ve Tema Tanımları


Katkıda Bulunma

Hata raporları, yeni özellik önerileri veya iyileştirmeler her zaman kabul edilir! Lütfen katkıda bulunmadan önce bir issue açmayı düşünün.

Lisans

Bu proje, MIT Lisansı altında yayımlanmıştır. (Detaylar için LICENSE dosyasına bakınız.)

Geliştiren: [Adınız/Kullanıcı Adınız]
