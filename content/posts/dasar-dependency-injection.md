---
title: "Dasar Dependency Injection"
date: 2017-04-25T13:52:08+07:00
draft: false
---
Mungkin ini termasuk topik yang agak membosankan di bidang pengembangan perangkat lunak. Tapi menurut saya gak ada salahnya untuk bahas topik ini, semoga dapat berguna di masa depan. Di artikel ini, saya tidak akan menggunakan perkakas tambahan apapun, sehingga diharapkan setiap orang dapat memahami konsep dasarnya dengan mudah.

## Apa itu Dependency Injection (DI)?

Sederhananya, Dependency Injection merupakan sebuah teknik untuk mengatur cara bagaimana suatu objek dibentuk ketika terdapat objek lain yang membutuhkan. Ada 2 istilah dalam DI, yaitu:
- Service, merupakan suatu objek atau komponen yang melakukan tugas tertentu, dan dapat digunakan oleh client.
- Client, merupakan suatu objek atau komponen yang mempunyai ketergantungan terhadap objek Service dalam mengerjakan tugas nya.

Namun perlu digaris bawahi, bahwa objek Service juga bisa menjadi Client untuk objek Service lainnya, begitu juga dengan objek Client, bisa juga sebagai Service untuk objek Client lainnya.
Manfaat Dependency Injection

Dengan menggunakan teknik DI, proses pemisahan komponen berdasarkan tanggung jawab masing- masing akan menjadi lebih mudah. Hal ini dikarenakan, Client tidak perlu tahu bagaimana proses instansiasi objek Service, dan Client juga tidak perlu tau apa saja yang dibutuhkan oleh Service ketika ingin digunakan. Berikut contoh kasus yang dapat dimudahkan oleh penggunaan teknik DI.

- Unit tests, karena dangan teknik DI, proses mocking jadi lebih gampang 
- Scaling application architecture, karena kita bisa mengubah implementasi suatu service dengan mudah tanpa mengganggu proses didalam objek client

## Studi Kasus

Semisal, kita mempunyai tugas untuk membuat suatu class atau komponen yang betugas untuk melakukan proses registrati akun baru. Lalu berikut flow dari proses registrasi akun baru.

- Menerima nama, email dan password
- Mengecek email apakah sudah terdaftar atau belum
- Apabila sudah, lempar pesan error
- Apabila belum, simpan data tersebut sebagai user baru.
- Kirim email konfirmasi
- Kembalikan object user baru tersebut

Berdasarkan flow diatas, terdapat beberapa tugas yang mesti dilakukan komponen ini menerima permintaan akun baru. Namun apabila kita lihat kembali tugas- tugas yang dilakukan, sebenarnya hal tersebut juga dilakukan oleh komponen lainnya. Contohnya tugas- tugas berikut:
- Mengecek email sudah terdaftar, tugas ini bisa dilakukan oleh komponen lain, misal objek database layer.
- Menyimpan data sebagai user baru, juga dilakukan oleh database layer
- Kirim email konfirmasi, tugas ini bisa dilakukan oleh komponen yang didedikasikan untuk mengirim email

Selanjutnya, kita beri nama komponen yang melakukan proses registrasi sebagai RegistrationService, lalu kita jabarkan komponen atau objek lain yang dibutuhkan
- UserDAO, bertugas untuk melakukan pembacaan dan penulisan data di database.
- EmailService, bertugas untuk melakukan pengiriman email.

Apabila kita lihat kembali penjelasan tentang DI, kita bisa anggap UserDAO dan EmailService sebagai Service yang dibutuhkan oleh Client yaitu RegistrationService.


### Tanpa Dependency Injection

Langkah selanjutnya, kita coba implementasi kasus diatas tanpa menggunakan teknik DI.

```
class RegistrationService { 
  private final Connection conn;
  private final UserDAO userDao;
  private final EmailService emailService;
  public RegistrationService() {
    this.conn = new Connection("localhost", "root", "password");
    this.userDao = new UserDAO(this.conn);
    this.emailService = new EmailService("sender@gmail.com", "password-rahasia");  }
}
```

Pada implementasi diatas, ketika melakukan instansiasi objek RegistrationService, kita juga melakukan instansiasi objek UserDAO dan EmailService di dalam RegisrationService. Hal ini mengakibatkan RegistrationService perlu tahu apa yang dibutuhkan oleh UserDAO dan EmailService.

Padahal seharusnya RegistrationService tidak perlu tahu tentang bagaimana UserDAO dan EmailService bekerja. Sehingga dimasa depan kita dapat mengubah implementasi EmailService dan UserDAO tanpa mengganggu RegistrationService. Dengan kata lain, kita bisa mengubah implementasi Service tanpa mengubah bagaimana Clientdi instansiasi.

### Dengan Dependency Injection

Oke, selanjutnya kita gunakan teknik DI.

```
interface UserDAO {
  void store(User user);
  bool existsByEmail(String email);
}

interface EmailService {
  void sendEmail(String title, HtmlContent content);
}

class RegistrationService {  
  private final UserDAO userDao;  
  private final EmailService emailService;
  public RegistrationService(UserDAO userDao, EmailService emailService) {
    this.userDao = userDao;
    this.emailService = emailService;  
  }
}

class Application {
  public function void main(String[] args) {
    Connection conn = new Connection("localhost", "root","");
    UserDAO userDao = new MysqlUserDAO(conn);
    EmailService emailService = new  GmailService("user@example.com","secretPassword");
    RegistrationService registrationService = new RegistrationService(userDao, emailService);  
  }
}
```

Bisa dilihat dari kode diatas, RegistrationService tidak perlu tahu bagaimana melakukan instansiasi UserDAO dan EmailService. RegistrationService hanya perlu jelasin, “kalau mau pake gue, lo harus sediain UserDAO dan EmailService.

## Kesimpulan

Bisa kita lihat, teknik DI memberikan banyak manfaat, selain itu teknik ini sangat netral terhadap jenis technology-stack, sehingga dapat diimplementasi di berbagai macam technology-stack (bahasa pemrograman atau framework).

Sekian tulisan saya tentang dasar DI, semoga bermanfaat. Apabila ada pertanyaan atau saran silahkan tinggalkan komentar.

Terimakasih.

Catatan Kaki
- https://en.wikipedia.org/wiki/Dependency_injection