---
title: "Http Middleware Di Go"
date: 2018-06-10T14:28:00+07:00
draft: false
---
Dalam konteks pembuatan aplikasi web, kita sering dihadapkan oleh berbagai kasus yang sebenarnya tidak berhubungan langsung dengan masalah bisnis yang ingin diselesaikan. Semisal, ketika membuat web untuk menerima order barang, kita perlu melakukan berbagai tugas sebelum order barang tersebut dikerjakan. Contoh paling sederhana, pengecekan hak akses, yaitu pembuatan order hanya boleh dilakukan oleh pihak yang memiliki akses. Dalam menyelesaikan masalah tersebut, kita bisa menggunakan pola atau teknik http middleware.

Middleware merupakan sebuah sebuah layer tambahan sebelum http request dikerjakan oleh action handler atau request handler yang dituju. Middleware yang baik adalah yang hanya melakukan satu tugas, atau menganut pilosofi do one thing well. Sehingga untuk menangani banyak kasus di level middleware, mereka harus mampu bersifat compose-able. Contoh kasus yang bisa ditangani oleh middleware antara lain:

- debugging information
- rate limiting
- pengecekan hak akses
- pengaturan CORS, dan masih banyak lagi

## HTTP Middleware di Go

Sebelum membuat middleware, mari kita ingat kembali bagaimana implementasi request handler di Go.

```
reqHandler := func(w http.RequestWriter, req *http.Request) {
    w.Write([]byte("Halo semua")
}
http.HandleFunc("/hello", reqHandler)
```

Contoh diatas, kita membuat request handler untuk pola routing “/hello”, sehingga ketika routing “/hello” diakses, server akan mengembalikan pesan “Halo semua”.

Selanjutnya mari kita implementasi http middleware untuk kasus yang paling sederhana, yaitu logging ketika web diakses oleh user. Cara paling sederhana untuk membuat middleware adalah sebagai berikut:

- Langkah pertama, bungkus request handler secara eksplisit dengan func(h http.Handler) http.Handler
- Selanjutnya, daftarkan fungsi tersebut ke http server bersama pola routing yang sesuai.

Contoh implementasinya, pertama kita buat middleware yang bertugas sebagai logging ketika web diakses.

```
func logging(nextHandler http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
        log.Printf("URL %s\n", req.URL.String())
        nextHandler.ServeHTTP(w, req)
    })
}
```

Langkah kedua, kita bungkus request handler yang dibuat sebelumnya dengan logging middleware.

```
handlerWithMiddleware := logging(http.HandlerFunc(reqHandler)))
```

Terakhir, kita daftarkan ke http server bersama pola routing-nya.

```
http.Handle("/hello", handlerWithMiddleware)
```

Di potongan kode diatas, kita telah berhasil membungkus request handler dengan middleware sederhana, berikut full kode implementasinya.

```
package main

import (
    "log"
    "net/http"
)

func logging(nextHandler http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
        log.Printf("URL %s\n", req.URL.String())
        nextHandler.ServeHTTP(w, req)
    })
}

func reqHandler(w http.ResponseWriter, req *http.Request) {
    w.Write([]byte("Halo semua"))
}

func main() {
    http.Handle("/hello", logging(http.HandlerFunc(reqHandler)))    http.ListenAndServe(":8080", nil)
}
```

## Do one thing well & be compose-able

Sebelumnya, kita sudah sepakat bahwa middleware yang baik adalah middleware yang bersifat do one thing well dan be compose-able. Jadi selanjutnya, kita coba buktikan apakah middleware diatas mampu bersifat be compose-able atau tidak.

Kasus kali ini, implementasi middleware yang bertugas untuk membuat request ID, lalu mengirimkannya ke request handler.

```
func withReqID(h http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
        reqID, _ := uuid.NewV4()
        ctx := context.WithValue(req.Context(), "X-Request-ID", reqID.String())
        h.ServeHTTP(w, req.WithContext(ctx))
    })
}
```

Selanjutnya kita gabungkan middleware diatas dengan logging middleware yang sudah dibuat sebelumnya.

```
chain := withReqID(logging(http.HandlerFunc(reqHandler)))
http.Handle("/hello", chain)
```

Di potongan kode diatas, terlihat kita sudah berhasil menggabungkan lebih dari satu middleware ke dalam satu rangkaian middleware yang siap didaftarkan ke http server. Terlihat juga pola rangkaian-nya sebagai berikut:

```
middleware1(middleware2(middleware3(http.HandlerFunc(reqHandler)
```

Full kode implementasi-nya bisa lihat disini

## Kesimpulan

Dari penjelasan diatas, serta contoh implementasi yang telah kita lakukan. Kita bisa ambil kesimpulan bahwa implementasi middleware di Go sangat gampang, walau hanya dengan menggunakan standard library. Namun apabila kita butuh perkakas yang lebih ringkas, kita juga bisa menggunakan perkakas yang sudah tersedia bebas di github, semisal https://github.com/justinas/alice.

Sekian tulisan saya tentang http middleware di Go, apabila ada pertanyaan serta saran, bisa tulis di kolom komentar.

Terimakasih.

## References:
- https://golang.org/pkg/net/http/#Handle
- https://golang.org/pkg/net/http/#HandlerFunc
- https://justinas.org/writing-http-middleware-in-go
