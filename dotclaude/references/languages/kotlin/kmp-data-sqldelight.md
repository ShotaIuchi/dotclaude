# KMP Data Persistence (SQLDelight)

Local database implementation using SQLDelight in Kotlin Multiplatform.

> **Related Documentation**: [KMP Architecture Guide](./kmp-architecture.md) | [SQLDelight Official](https://cashapp.github.io/sqldelight/)

---

## Gradle Setup

Add SQLDelight plugin and dependencies to your project:

```kotlin
// build.gradle.kts (project root)
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

## Platform-specific Driver Setup

SQLDelight requires platform-specific database drivers. Define a common interface and implement for each platform:

```kotlin
// commonMain/kotlin/com/example/shared/data/DatabaseDriverFactory.kt
expect class DatabaseDriverFactory {
    fun createDriver(): SqlDriver
}
```

### Android Implementation

```kotlin
// androidMain/kotlin/com/example/shared/data/DatabaseDriverFactory.kt
actual class DatabaseDriverFactory(private val context: Context) {
    actual fun createDriver(): SqlDriver {
        return AndroidSqliteDriver(AppDatabase.Schema, context, "app.db")
    }
}
```

### iOS Implementation

```kotlin
// iosMain/kotlin/com/example/shared/data/DatabaseDriverFactory.kt
actual class DatabaseDriverFactory {
    actual fun createDriver(): SqlDriver {
        return NativeSqliteDriver(AppDatabase.Schema, "app.db")
    }
}
```

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

SQLDelight generates a `UserEntity` interface (not a data class) from the schema. Since generated entities lack copy() and other data class features, we define a separate `UserEntityData` class for easier manipulation and insertion.

```kotlin
// commonMain/kotlin/com/example/shared/data/mapper/UserMapper.kt

/**
 * SQLDelight Entity → Domain
 *
 * Converts SQLDelight-generated UserEntity (interface) to domain User model.
 * UserEntity is auto-generated from the .sq schema file.
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
 * Converts domain User to UserEntityData for database insertion.
 * We use UserEntityData (data class) instead of UserEntity (interface)
 * because SQLDelight-generated entities are interfaces without constructors.
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
 * Entity data class for database insertion
 *
 * This data class mirrors the UserEntity schema but provides:
 * - Constructor for easy instantiation
 * - copy() method for modifications
 * - equals/hashCode for comparisons
 *
 * Use this class when inserting data via queries.insertUser()
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

## Dependency Injection with Koin

Basic setup for injecting database and data sources:

```kotlin
// commonMain/kotlin/com/example/shared/di/DatabaseModule.kt
val databaseModule = module {
    // Database driver (platform-specific)
    single { get<DatabaseDriverFactory>().createDriver() }

    // Database instance
    single { AppDatabase(get()) }

    // Data sources
    single<UserLocalDataSource> { UserLocalDataSourceImpl(get()) }
}

// For complete DI setup, see kmp-di-koin.md
```

---

## Error Handling

Wrap database operations with proper error handling:

```kotlin
// Using Result type for safe operations
suspend fun getUserSafely(userId: String): Result<User> {
    return runCatching {
        queries.getUser(userId)
            .executeAsOne()
            .toDomain()
    }
}

// In LocalDataSource with exception handling
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
            // Log error and rethrow or handle
            throw DatabaseException("Failed to insert user: ${user.id}", e)
        }
    }
}

// Custom exception for database errors
class DatabaseException(message: String, cause: Throwable? = null) : Exception(message, cause)
```

---

## Migration

SQLDelight supports schema migrations via numbered `.sqm` files:

```
shared/src/commonMain/sqldelight/
├── com/example/shared/
│   ├── AppDatabase.sq       # Current schema
│   └── migrations/
│       ├── 1.sqm            # Migration from version 1 to 2
│       └── 2.sqm            # Migration from version 2 to 3
```

Example migration file (`1.sqm`):

```sql
-- Migration from schema version 1 to 2
ALTER TABLE UserEntity ADD COLUMN avatar_url TEXT;
```

Configure schema version in Gradle:

```kotlin
sqldelight {
    databases {
        create("AppDatabase") {
            packageName.set("com.example.shared")
            schemaOutputDirectory.set(file("src/commonMain/sqldelight/databases"))
            verifyMigrations.set(true)
        }
    }
}
```

---

## Best Practices

- **Define schema in common code**: Place `.sq` files in `commonMain` so schema is shared across all platforms
- **Implement Driver for each platform**: Use `expect/actual` pattern for `DatabaseDriverFactory` to provide platform-specific drivers (AndroidSqliteDriver, NativeSqliteDriver)
- **Use transactions appropriately**: Wrap multiple write operations in `queries.transaction {}` for atomicity and better performance
- **Monitor changes with Flow**: Use `asFlow().mapToList()` for reactive data observation; UI automatically updates when data changes
