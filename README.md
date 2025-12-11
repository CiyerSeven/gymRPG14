
#GYM RPG

GymRPG, geleneksel antrenman takibini oyunlaştırma (gamification) öğeleriyle birleştiren modern bir andorid uygulamasıdır. Her set, her tekrar ve her kilogram; kas grubunuzun XP (Deneyim Puanı) kazanmasını ve Level atlamasını sağlar. Sadece ağırlık kaldırmayın, bir maceracı gibi seviye atlayın!

Temel Özellikler


Antrenman Takibi: Tarih ve nota dayalı detaylı antrenman kaydı.


XP ve Level Sistemi: Çalışılan kas gruplarına göre gerçek zamanlı deneyim puanı (XP) ve seviye (Level) ilerlemesi.


Kişisel Analiz: Maksimum 1RM (Tekrar Maksimum) hesaplama ve kas grubuna göre toplam hacim analizi.


Kilo ve Boy Takibi: Kilo geçmişini takip etme, BMI (Vücut Kitle İndeksi) hesaplama ve grafiksel ilerleme.


Haftalık Program: Haftalık antrenman programı oluşturma ve kaydetme.


Hareket Yönetimi: Kullanıcının kendi hareket tanımlarını kaydetme ve kategorize etme yeteneği.


Ekran Görüntüleri:

Dashboard:
<img width="1440" height="3040" alt="image" src="https://github.com/user-attachments/assets/05554ddd-1eff-4965-80b8-20d9e43a297c" />


Antreman Kayıt Ekran:
<img width="1440" height="3040" alt="image" src="https://github.com/user-attachments/assets/70586075-6072-4e71-bf16-cd63c01e6cd7" />


Geçmiş Ekranı:
<img width="1440" height="3040" alt="image" src="https://github.com/user-attachments/assets/3ed33390-3735-4110-aaa8-489954e25615" />


Geçmiş Ekranı Detay:
<img width="1440" height="3040" alt="image" src="https://github.com/user-attachments/assets/630298c8-b6d0-41cc-95ae-1718b3392fcf" />


Analiz Ekranı:
<img width="1440" height="3040" alt="image" src="https://github.com/user-attachments/assets/b22aba32-52ca-46c5-b53c-ba81dd3f0215" />


Analiz Ekranı Detay:
<img width="1440" height="3040" alt="image" src="https://github.com/user-attachments/assets/82776f32-a763-42e4-8ccc-10c50774fd8a" />


Hareket Ekranı:
<img width="1440" height="3040" alt="image" src="https://github.com/user-attachments/assets/f0f58e37-491f-4f7a-8a00-d18d5718bf29" />


Antreman Programı Ekranı:
<img width="1440" height="3040" alt="image" src="https://github.com/user-attachments/assets/731cc1cf-d420-410f-bc79-00464daabffd" />


Profil Ekranı:
<img width="1440" height="3040" alt="image" src="https://github.com/user-attachments/assets/21f6aa1d-1dad-4334-aa0e-3c80bbfbedf3" />


Kilo Boy Takip Ekranı:
<img width="1440" height="3040" alt="image" src="https://github.com/user-attachments/assets/3320b95e-cb8f-47dc-ad23-26325aeb8477" />

Kurulum ve Başlatma


Bu projeyi yerel ortamınızda çalıştırmak için aşağıdaki adımları takip edin:


Ön Gereksinimler

Flutter SDK

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


/lib

|-- /models

|   |-- workout.dart

|   |-- exercise.dart

|   |-- weight_entry.dart 

|   |-- ... (Diğer Hive modelleri)

|-- /providers

|   |-- gym_tracker_provider.dart  

|-- /screens

|   |-- dashboard_screen.dart 

|   |-- manage_exercises_screen.dart 

|   |-- personal_data_screen.dart   

|   |-- ... (Diğer ekranlar)

|-- /services

|   |-- db_service.dart            

|-- main.dart                       



Lisans

Bu proje, MIT Lisansı altında yayımlanmıştır. (Detaylar için LICENSE dosyasına bakınız.)

Geliştiren: Batuhan Emin Aktaş




