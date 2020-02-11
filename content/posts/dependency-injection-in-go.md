---
title: "Dependency Injection in Go"
date: 2018-09-07T15:06:09+07:00
draft: false
---
Dependency Injection (DI) merupakan salah satu teknik yang cukup sederhana namun sangat powerful dalam pengembangan perangkat lunak. Teknik ini bertujuan untuk membuat unit atau komponen yang independent dan testable.

## Goals

Dengan menulis artikel ini, diharapkan bisa menjawab beberapa pertanyaan berikut.

- Bagaimana implementasi Dependency Injection di Go?
- Perkakas apa yang bisa digunakan untuk Dependency Injection di Go?

## Case Study

Kasus yang digunakan pada artikel ini adalah menambahkan daftar following pada jejaring sosial, seperti Instagram atau Twitter. Berikut struktur data model yang digunakan untuk menggambarkan masalah daftar following pada jejaring sosial.

```
type Following struct {
    ID int
    Username string
    FullName string
}
func NewFollowing(username string, fullName string) Following {
    return Following{0, username, fullName}
}
```

### Phase 1, Put everything in main()

Solusi paling straightforward ketika membuat Go program, adalah menaruh semuanya di main function.

```
package main

import (
    "database/sql"
    "fmt"
    "log"   _ "github.com/go-sql-driver/mysql"
)

var (
    mysqlHost     = "localhost"
    mysqlUser     = "root"
    mysqlPassword = "root_pass"
)

func main() {
    connString := fmt.Sprintf("%s:%s@tcp(%s:3306)/following?parseTime=true", mysqlUser, mysqlPassword, mysqlHost)
    sqlDB, err := sql.Open("mysql", connString)
    if err != nil {
        log.Fatalf("Error %v", err)
    }
    if err := sqlDB.Ping(); err != nil {
        log.Fatalf("Error %v", err)
    }
    stmt, err := sqlDB.Prepare("INSERT INTO following (username, full_name) VALUES (?, ?)")
    if err != nil {
        log.Fatalf("Error %v", err)
    }
    defer stmt.Close()
    _, err = stmt.Exec("root", "I'm Root")
    if err != nil {
        log.Fatalf("Error %v", err)
    }
    log.Println("Done!")
}
```

### Pase 2, Put specific task in specific function

Selanjutnya, kita bisa menaruh scope tertentu di specific function, semisal scope program yang bertugas untuk membuat koneksi database, mengambil spesifik data, menyimpan data di database dan lain sebagainya.

```
package main

import (
    "database/sql"
    "fmt"
    "log"    _ "github.com/go-sql-driver/mysql"
)

func newSql(mysqlHost, mysqlUser, mysqlPassword string) (*sql.DB, error) {
    connString := fmt.Sprintf("%s:%s@tcp(%s:3306)/following", mysqlUser, mysqlPassword, mysqlHost)
    sqlDB, err := sql.Open("mysql", connString)
    if err != nil {
        return nil, err
    }
    if err := sqlDB.Ping(); err != nil {
        return nil, err
    }
    return sqlDB, nil
}

func storeNewEntry(sqlDB *sql.DB, entity Following) error {
    stmt, err := sqlDB.Prepare("INSERT INTO following (username, full_name) VALUES (?, ?)")
    if err != nil {
        return err
    }
    defer stmt.Close()
    _, err = stmt.Exec(entity.Username, entity.FullName)
    if err != nil {
        return err
    }
    return nil
}

func main() {
    sqlDB, err := newSql("localhost", "root", "root-is-not-used")
    if err != nil {
        log.Fatalf("Error %v", err)
    }
    newFollowing := NewFollowing("root", "I'm Root!")
    if err := storeNewEntry(sqlDB, newFollowing); err != nil {
        log.Fatalf("Error %v", err)
    }
    log.Println("Done!")
}
```

Contoh diatas, saya membuat 2 fungsi baru, yaitu fungsi untuk menyimpan data di database dan fungsi untuk membuat koneksi database.

### Phase 3, Use dependency injection

Contoh selanjutnya, ialah memisahkan scope tersebut sesuai concern masing-masing, semisal scope yang berhubungan dengan interaksi ke database saya taruh di FollowingRepository. Selanjutnya, hal yang berhubungan dengan business logic saya taruh di FollowingService.

Nantinya `FollowingRepository` akan di-inject ke FollowingService. Sehingga FollowingService dapat menggunakan FollowingRepository apabila dibutuhkan proses yang berhubungan dengan database, semisal menyimpan dan mengambil data.

```
package main

import (
    "database/sql"
    "fmt"
    "log"    _ "github.com/go-sql-driver/mysql"
)

type Repository interface {
    Store(following Following) error
}

func NewMysqlRepository(sqlDB *sql.DB) Repository {
    return MysqlRepository{sqlDB: sqlDB}
}

type MysqlRepository struct {
    sqlDB *sql.DB
}

func (sql MysqlRepository) Store(following Following) error {
    stmt, err := sql.sqlDB.Prepare("INSERT INTO following (username, full_name) VALUES (?, ?)")
    if err != nil {
        return err
    }
    defer stmt.Close()
    if _, err := stmt.Exec(following.Username, following.FullName); err != nil {
        return err
    }
    return nil
}

func newSql(mysqlHost, mysqlUser, mysqlPassword string) (*sql.DB, error) {
    connString := fmt.Sprintf("%s:%s@tcp(%s:3306)/following", mysqlUser, mysqlPassword, mysqlHost)
    sqlDB, err := sql.Open("mysql", connString)
    if err != nil {
        return nil, err
    }
    if err := sqlDB.Ping(); err != nil {
        return nil, err
    }
    return sqlDB, nil
}

type Service struct {
    followingRepository Repository
}

func NewService(followingRepository Repository) Service {
    return Service{followingRepository}
}

func (service Service) Insert(username, fullName string) error {
    err := service.followingRepository.Store(NewFollowing(username, fullName))
    if err != nil {
        return err
    }
    return nil
}

var (
    mysqlHost     = "localhost"
    mysqlUser     = "root"
    mysqlPassword = "root_pass"
)

func main() {
    sqlDB, err := newSql(mysqlHost, mysqlUser, mysqlPassword)
    if err != nil {
        log.Fatalf("Error %v", err)
    }
    mysqlRepository := NewMysqlRepository(sqlDB)
    followingService := NewService(mysqlRepository)
    if err := followingService.Insert("root", "I'm Root!"); err != nil {
        log.Fatalf("Error %v", err)
    }
    log.Println("Done!")
}
```

## Unit Testing

Salah satu keunggulan dependency injection ialah kita bisa membuat komponen yang mandiri dan testable. Berikut contoh bagaimana kita membuat mock repository yang akan digunakan oleh layer service.

```
package main_test

import (
    "testing"    following "github.com/rakateja/di-go/manual-di"
)

type MockRepository struct{}func NewMockRepository() following.Repository {
    return MockRepository{}
}

func (mock MockRepository) Store(entity following.Following) error {
    return nil
}

func TestInsertFollowing(t *testing.T) {
    followingRepository := NewMockRepository()
    followingService := following.NewService(followingRepository)
    if err := followingService.Insert("root", "I'm Root"); err != nil {
        t.Errorf("Got %v, expect nil  when inserting new following", err.Error())
    }
}
```

## Conclusion

- Di artikel ini kita sudah berhasil memisahkan scope program berdasarkan concern masing- masing
- Kita telah berhasil menerapkan pradigma pemrograman berorientasi objek dan teknik Dependency Injection
- Kita menggunakan type interface untuk membuat abstraksi unit yang berhubungan dengan database. Hal ini dilakukan untuk memudahkan proses unit testing, serta memudahkan kita apabila implementasi repository menggunakan database yang lain, selain MySQL
-  Di Go, kita tidak perlu menggunakan perkakas tambahan untuk implementasi DI. Selama kita paham bagaimana konsep DI, kita bisa langsung mengimplementasikannya dengan mudah. Walaupun demikian, tersedia juga pilihan yang lain, seperti DI library dari Uber (https://github.com/uber-go/dig) dan Facebook (https://github.com/facebookgo/inject)

Sekian artikel tentang Dependency Injection di Go. Contoh kode di artikel ini, bisa lihat disini. Terimakasih dan semoga bermanfaat.

## References
- https://medium.com/@zach_4342/dependency-injection-in-golang-e587c69478a8