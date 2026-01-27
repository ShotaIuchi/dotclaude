# Kotlin / KMP Reference

Kotlin Multiplatform development reference based on official documentation.

---

## 公式ドキュメント

### Kotlin Multiplatform

| Topic | URL |
|-------|-----|
| KMP Overview | https://kotlinlang.org/docs/multiplatform.html |
| Get Started with KMP | https://kotlinlang.org/docs/multiplatform-get-started.html |
| Share Code on Platforms | https://kotlinlang.org/docs/multiplatform-share-on-platforms.html |
| expect/actual Declarations | https://kotlinlang.org/docs/multiplatform-expect-actual.html |
| Hierarchical Project Structure | https://kotlinlang.org/docs/multiplatform-hierarchy.html |
| KMP Compatibility Guide | https://kotlinlang.org/docs/multiplatform-compatibility-guide.html |

### Compose Multiplatform

| Topic | URL |
|-------|-----|
| Compose Multiplatform | https://www.jetbrains.com/compose-multiplatform/ |
| Getting Started | https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-multiplatform-getting-started.html |
| Resources in Compose MP | https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-multiplatform-resources.html |
| Navigation in Compose MP | https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-navigation-routing.html |

### Kotlin Coroutines

| Topic | URL |
|-------|-----|
| Coroutines Guide | https://kotlinlang.org/docs/coroutines-guide.html |
| Flow | https://kotlinlang.org/docs/flow.html |
| StateFlow and SharedFlow | https://kotlinlang.org/docs/stateflow-and-sharedflow.html |
| Channels | https://kotlinlang.org/docs/channels.html |
| Coroutine Context and Dispatchers | https://kotlinlang.org/docs/coroutine-context-and-dispatchers.html |
| Exception Handling | https://kotlinlang.org/docs/exception-handling.html |

### Koin (DI)

| Topic | URL |
|-------|-----|
| Koin for KMP | https://insert-koin.io/docs/reference/koin-mp/kmp/ |
| Koin Compose | https://insert-koin.io/docs/reference/koin-compose/compose/ |
| Koin Annotations | https://insert-koin.io/docs/reference/koin-annotations/annotations/ |

### SQLDelight

| Topic | URL |
|-------|-----|
| SQLDelight KMP | https://cashapp.github.io/sqldelight/2.0.2/multiplatform_sqlite/ |
| SQLDelight Migrations | https://cashapp.github.io/sqldelight/2.0.2/android_sqlite/migrations/ |
| SQLDelight Coroutines Extension | https://cashapp.github.io/sqldelight/2.0.2/native_sqlite/coroutines/ |

### Ktor (Networking)

| Topic | URL |
|-------|-----|
| Ktor Client | https://ktor.io/docs/client-create-new-application.html |
| Content Negotiation | https://ktor.io/docs/client-serialization.html |
| Authentication | https://ktor.io/docs/client-auth.html |
| Logging | https://ktor.io/docs/client-logging.html |

### Testing

| Topic | URL |
|-------|-----|
| Kotlin Test | https://kotlinlang.org/api/latest/kotlin.test/ |
| Turbine (Flow Testing) | https://github.com/cashapp/turbine |
| MockK | https://mockk.io/ |

---

## プロジェクト固有規約

公式ドキュメントでカバーされない本プロジェクト独自のルール:

→ [conventions.md](conventions.md) — 命名規則・ディレクトリ構造・Gradle設定
→ [library-patterns.md](library-patterns.md) — ライブラリ別実装パターン
→ [feature-patterns.md](feature-patterns.md) — 機能別実装パターン

---

## Related Skills

| Skill | Path |
|-------|------|
| `kmp-architecture` | `skills/kmp-architecture/SKILL.md` |

## Related References

- [Clean Architecture](../../common/clean-architecture.md)
- [Testing Strategy](../../common/testing-strategy.md)
- [Android Platform](../../platforms/android/index.md)
- [iOS Platform](../../platforms/ios/index.md)
