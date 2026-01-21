# KMP データ永続化 (SQLDelight)

Kotlin Multiplatform での SQLDelight を使用したローカルデータベース実装。

> **関連ドキュメント**: [KMP Architecture Guide](./kmp-architecture.md) | [SQLDelight 公式](https://cashapp.github.io/sqldelight/)

---

## スキーマ定義

```sql
-- shared/src/commonMain/sqldelight/com/example/shared/AppDatabase.sq

-- ユーザーテーブル
CREATE TABLE UserEntity (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    joined_at INTEGER NOT NULL,
    status TEXT NOT NULL
);

-- ユーザー一覧取得
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
 * ユーザーローカルデータソース
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

## Entity マッピング

```kotlin
// commonMain/kotlin/com/example/shared/data/mapper/UserMapper.kt

/**
 * SQLDelight Entity → Domain
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
 * Domain → SQLDelight Entity
 *
 * SQLDelight の生成する Entity は data class ではないため、
 * 別途 data class を定義することもある
 */
fun User.toEntity(): com.example.shared.data.model.UserEntityData {
    return UserEntityData(
        id = id,
        name = name,
        email = email,
        joinedAt = joinedAt.toEpochMilliseconds(),
        status = status.name
    )
}

/**
 * Entity 用データクラス（挿入時に使用）
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

## ベストプラクティス

- スキーマは共通で定義
- Driver は各プラットフォームで実装
- トランザクションは適切に使用
- Flow で変更を監視
