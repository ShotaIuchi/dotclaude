# KMP データ永続化 (SQLDelight)

Kotlin Multiplatform における SQLDelight を使用したローカルデータベース実装。

---

## 概要

SQLDelight は、SQL スキーマから型安全な Kotlin API を生成するライブラリです。KMP プロジェクトでは、共通のスキーマ定義からプラットフォーム固有のドライバーを使用してデータベース操作を行います。

---

## Gradle セットアップ

プロジェクトに SQLDelight プラグインと依存関係を追加します：

```kotlin
// build.gradle.kts（プロジェクトルート）
plugins {
    id("app.cash.sqldelight") version "2.0.2" apply false
}

// shared/build.gradle.kts
plugins {
    kotlin("multiplatform")
    id("app.cash.sqldelight")
}

kotlin {
    sourceSets {
        commonMain.dependencies {
            implementation("app.cash.sqldelight:coroutines-extensions:2.0.2")
        }
        androidMain.dependencies {
            implementation("app.cash.sqldelight:android-driver:2.0.2")
        }
        iosMain.dependencies {
            implementation("app.cash.sqldelight:native-driver:2.0.2")
        }
    }
}

sqldelight {
    databases {
        create("AppDatabase") {
            packageName.set("com.example.shared")
        }
    }
}
```

---

## プラットフォーム固有ドライバー

SQLDelight はプラットフォーム固有のデータベースドライバーが必要です。共通インターフェースを定義し、各プラットフォームで実装します：

```kotlin
// commonMain/kotlin/com/example/shared/data/DatabaseDriverFactory.kt
expect class DatabaseDriverFactory {
    fun createDriver(): SqlDriver
}
```

### Android 実装

```kotlin
// androidMain/kotlin/com/example/shared/data/DatabaseDriverFactory.kt
actual class DatabaseDriverFactory(private val context: Context) {
    actual fun createDriver(): SqlDriver {
        return AndroidSqliteDriver(AppDatabase.Schema, context, "app.db")
    }
}
```

### iOS 実装

```kotlin
// iosMain/kotlin/com/example/shared/data/DatabaseDriverFactory.kt
actual class DatabaseDriverFactory {
    actual fun createDriver(): SqlDriver {
        return NativeSqliteDriver(AppDatabase.Schema, "app.db")
    }
}
```

---

## スキーマ定義

```sql
-- shared/src/commonMain/sqldelight/com/example/shared/AppDatabase.sq

-- User テーブル
CREATE TABLE UserEntity (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    joined_at INTEGER NOT NULL,
    status TEXT NOT NULL
);

-- ユーザーリスト取得
getUsers:
SELECT * FROM UserEntity
ORDER BY name ASC;

-- 単一ユーザー取得
getUser:
SELECT * FROM UserEntity
WHERE id = ?;

-- ユーザー挿入/更新
insertUser:
INSERT OR REPLACE INTO UserEntity(id, name, email, joined_at, status)
VALUES (?, ?, ?, ?, ?);

-- 全ユーザー削除
deleteAllUsers:
DELETE FROM UserEntity;

-- 単一ユーザー削除
deleteUser:
DELETE FROM UserEntity
WHERE id = ?;
```

---

## LocalDataSource 実装

```kotlin
// commonMain/kotlin/com/example/shared/data/local/UserLocalDataSource.kt

/**
 * User ローカルデータソース
 */
interface UserLocalDataSource {
    fun getUsers(): Flow<List<UserEntity>>
    fun getUser(userId: String): Flow<UserEntity>
    suspend fun insertUser(user: UserEntity)
    suspend fun insertUsers(users: List<UserEntity>)
    suspend fun replaceAllUsers(users: List<UserEntity>)
    suspend fun deleteUser(userId: String)
}

/**
 * SQLDelight を使用したローカルデータソース実装
 */
class UserLocalDataSourceImpl(
    private val database: AppDatabase
) : UserLocalDataSource {

    private val queries = database.appDatabaseQueries

    override fun getUsers(): Flow<List<UserEntity>> {
        return queries.getUsers()
            .asFlow()
            .mapToList(Dispatchers.IO)
    }

    override fun getUser(userId: String): Flow<UserEntity> {
        return queries.getUser(userId)
            .asFlow()
            .mapToOne(Dispatchers.IO)
    }

    override suspend fun insertUser(user: UserEntity) {
        withContext(Dispatchers.IO) {
            queries.insertUser(
                id = user.id,
                name = user.name,
                email = user.email,
                joined_at = user.joinedAt,
                status = user.status
            )
        }
    }

    override suspend fun insertUsers(users: List<UserEntity>) {
        withContext(Dispatchers.IO) {
            queries.transaction {
                users.forEach { user ->
                    queries.insertUser(
                        id = user.id,
                        name = user.name,
                        email = user.email,
                        joined_at = user.joinedAt,
                        status = user.status
                    )
                }
            }
        }
    }

    override suspend fun replaceAllUsers(users: List<UserEntity>) {
        withContext(Dispatchers.IO) {
            queries.transaction {
                queries.deleteAllUsers()
                users.forEach { user ->
                    queries.insertUser(
                        id = user.id,
                        name = user.name,
                        email = user.email,
                        joined_at = user.joinedAt,
                        status = user.status
                    )
                }
            }
        }
    }

    override suspend fun deleteUser(userId: String) {
        withContext(Dispatchers.IO) {
            queries.deleteUser(userId)
        }
    }
}
```

---

## エンティティマッピング

SQLDelight はスキーマから `UserEntity` インターフェース（データクラスではない）を生成します。生成されたエンティティには copy() などのデータクラス機能がないため、操作と挿入を容易にするために別の `UserEntityData` クラスを定義します。

```kotlin
// commonMain/kotlin/com/example/shared/data/mapper/UserMapper.kt

/**
 * SQLDelight Entity → Domain
 *
 * SQLDelight が生成した UserEntity（インターフェース）を
 * ドメインの User モデルに変換します。
 * UserEntity は .sq スキーマファイルから自動生成されます。
 */
fun UserEntity.toDomain(): User {
    return User(
        id = id,
        name = name,
        email = email,
        joinedAt = Instant.fromEpochMilliseconds(joined_at),
        status = UserStatus.valueOf(status)
    )
}

/**
 * Domain → SQLDelight Entity Data
 *
 * ドメインの User をデータベース挿入用の UserEntityData に変換します。
 * SQLDelight が生成するエンティティはコンストラクタを持たないインターフェースのため、
 * UserEntity（インターフェース）ではなく UserEntityData（データクラス）を使用します。
 */
fun User.toEntity(): UserEntityData {
    return UserEntityData(
        id = id,
        name = name,
        email = email,
        joinedAt = joinedAt.toEpochMilliseconds(),
        status = status.name
    )
}

/**
 * データベース挿入用のエンティティデータクラス
 *
 * このデータクラスは UserEntity スキーマを反映しつつ、以下を提供します：
 * - 簡単なインスタンス化のためのコンストラクタ
 * - 変更のための copy() メソッド
 * - 比較のための equals/hashCode
 *
 * queries.insertUser() でデータを挿入する際にこのクラスを使用します
 */
data class UserEntityData(
    val id: String,
    val name: String,
    val email: String,
    val joinedAt: Long,
    val status: String
)
```

---

## Koin による依存性注入

データベースとデータソースを注入するための基本セットアップ：

```kotlin
// commonMain/kotlin/com/example/shared/di/DatabaseModule.kt
val databaseModule = module {
    // データベースドライバー（プラットフォーム固有）
    single { get<DatabaseDriverFactory>().createDriver() }

    // データベースインスタンス
    single { AppDatabase(get()) }

    // データソース
    single<UserLocalDataSource> { UserLocalDataSourceImpl(get()) }
}

// 完全な DI セットアップについては kmp-di-koin.md を参照
```

---

## エラーハンドリング

データベース操作を適切なエラーハンドリングでラップ：

```kotlin
// 安全な操作のために Result 型を使用
suspend fun getUserSafely(userId: String): Result<User> {
    return runCatching {
        queries.getUser(userId)
            .executeAsOne()
            .toDomain()
    }
}

// 例外処理を含む LocalDataSource
override suspend fun insertUser(user: UserEntity) {
    withContext(Dispatchers.IO) {
        try {
            queries.insertUser(
                id = user.id,
                name = user.name,
                email = user.email,
                joined_at = user.joinedAt,
                status = user.status
            )
        } catch (e: Exception) {
            // エラーをログに記録し、再スローまたは処理
            throw DatabaseException("ユーザーの挿入に失敗しました: ${user.id}", e)
        }
    }
}

// データベースエラー用のカスタム例外
class DatabaseException(message: String, cause: Throwable? = null) : Exception(message, cause)
```

---

## マイグレーション

SQLDelight は番号付き `.sqm` ファイルによるスキーママイグレーションをサポート：

```
shared/src/commonMain/sqldelight/
├── com/example/shared/
│   ├── AppDatabase.sq       # 現在のスキーマ
│   └── migrations/
│       ├── 1.sqm            # バージョン 1 から 2 へのマイグレーション
│       └── 2.sqm            # バージョン 2 から 3 へのマイグレーション
```

マイグレーションファイルの例（`1.sqm`）：

```sql
-- スキーマバージョン 1 から 2 へのマイグレーション
ALTER TABLE UserEntity ADD COLUMN avatar_url TEXT;
```

---

## ベストプラクティス

- **共通コードでスキーマを定義**: すべてのプラットフォームでスキーマが共有されるよう `.sq` ファイルを `commonMain` に配置
- **各プラットフォームで Driver を実装**: `DatabaseDriverFactory` の `expect/actual` パターンでプラットフォーム固有ドライバー（AndroidSqliteDriver, NativeSqliteDriver）を提供
- **トランザクションを適切に使用**: 複数の書き込み操作を `queries.transaction {}` でラップしてアトミック性とパフォーマンスを向上
- **Flow で変更を監視**: `asFlow().mapToList()` を使用してリアクティブなデータ監視を実現、データ変更時に UI が自動更新
