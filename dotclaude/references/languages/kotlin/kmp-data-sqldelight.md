# KMP Data Persistence (SQLDelight)

Local database implementation using SQLDelight in Kotlin Multiplatform.

> **Related Documentation**: [KMP Architecture Guide](./kmp-architecture.md) | [SQLDelight Official](https://cashapp.github.io/sqldelight/)

---

## Schema Definition

```sql
-- shared/src/commonMain/sqldelight/com/example/shared/AppDatabase.sq

-- User table
CREATE TABLE UserEntity (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    joined_at INTEGER NOT NULL,
    status TEXT NOT NULL
);

-- Get user list
getUsers:
SELECT * FROM UserEntity
ORDER BY name ASC;

-- Get single user
getUser:
SELECT * FROM UserEntity
WHERE id = ?;

-- Insert/update user
insertUser:
INSERT OR REPLACE INTO UserEntity(id, name, email, joined_at, status)
VALUES (?, ?, ?, ?, ?);

-- Delete all users
deleteAllUsers:
DELETE FROM UserEntity;

-- Delete single user
deleteUser:
DELETE FROM UserEntity
WHERE id = ?;
```

---

## LocalDataSource Implementation

```kotlin
// commonMain/kotlin/com/example/shared/data/local/UserLocalDataSource.kt

/**
 * User local data source
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
 * Local data source implementation using SQLDelight
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

## Entity Mapping

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
 * Since SQLDelight-generated Entity is not a data class,
 * a separate data class may be defined
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
 * Entity data class (used for insertion)
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

## Best Practices

- Define schema in common code
- Implement Driver for each platform
- Use transactions appropriately
- Monitor changes with Flow
