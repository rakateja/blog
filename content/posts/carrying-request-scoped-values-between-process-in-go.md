---
title: "Carrying Request Scoped Values Between Process in Go with Context"
date: 2018-06-10T14:58:04+07:00
draft: false
---
Di artikel sebelumnya, saya menjelaskan tentang implementasi HTTP middleware di Go. Dalam praktiknya implementasi middleware juga sangat terkait dengan bagaimana kita menangani nilai yang kita hasilkan di middleware dapat di konsumsi oleh proses lain di aplikasi. Semisal saya ambil contoh implementasi secured endpoint yang hanya boleh diakses oleh user yang sudah login. Middleware yang bertugas untuk pengecekan user login juga perlu mengirim informasi user ke proses selanjutnya atau agar API boundaries yang lain bisa menerima informasi tersebut.

Lalu bagaimana Context mampu menyelesaikan masalah diatas? Untuk memahami itu, berikut penjelasan singkat tentang Context dari dokumentasi resminya.
> Package context defines the Context type, which carries deadlines, cancelation signals, and other request-scoped values across API boundaries and between processes.

Dari penjelasan diatas, ketika aplikasi diakses oleh user/client, Context akan membawa nilai yang berhubungan dengan siklus user request ke proses yang lain.

## Implementasi

Oke, langsung saja ke implementasinya, flow aplikasinya sebagai berikut.

![image alt text](/middleware.png)

- user request adalah request model yang dikirim oleh user/client
- middleware(s) merupakan layer yang bertugas untuk memproses request model sebelum ditangai oleh request handler/API boundaries yang lain.
- API boundaries, merupakan proses yang terjadi di dalam aplikasi baik itu transport layer, domain (business logic) layer, dan database layer.

### Middleware (pengecekan user login)
Berikut middleware yang kita perlukan untuk kasus ini.

```
func withLoggedUser(userQuery UserQuery) func(http.Handler) http.Handler {
  return func(h http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
      credKey := req.Header.Get("credential-key")
        if credKey == "" {
          w.Write([]byte("ForbiddenAccess"))
          return
      }
      user, err := userQuery.ResolveUserByCredential(req.Context(), credKey)
      if err != nil {
      	w.Write([]byte("InternalServerError"))
      	return
      }
      ctx := context.WithValue(req.Context(), "logged-user-id", user.ID)
      h.ServeHTTP(w, req.WithContext(ctx))
    })
  }
}
```

Di potongan kode diatas, ketika mengeksekusi fungsi userQuery.ResolveByCrendetial, selain melempar nilai credential key, kita juga melempar Context sebagai argumen pertama. Hal ini dilakukan agar userQuery dapat menggunakan nilai dalam Context untuk berbagai hal, misal untuk request cancellation.

### Request Handler/ application API boundaries

```
userQuery := user.NewQuery()

withLoggedUserMiddleware := withLoggedUser(userQuery)

reqHandler := withLoggedUserMiddleware(http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
  w.Write([]byte(fmt.Sprintf("Hello %s", req.Context().Value("logged-user-id"))))
}))

http.Handle("/secured-endpoint", reqHandler)
```

## Kesimpulan

Context sangat berguna untuk menangani berbagai kasus terkait request-scoped values. Dalam dokumentasi resmi-nya, Context juga bisa digunakan untuk menangani kasus request deadline serta request cancellation.

Sekian artikel kali ini, apabila teman- teman ada pertanyaan, saran atau tips tentang penggunaan Context, bisa tulis di kolom komentar.

Terimakasih.

## References
- https://golang.org/pkg/context/
- https://blog.golang.org/context
- https://dave.cheney.net/2017/08/20/context-isnt-for-cancellation

