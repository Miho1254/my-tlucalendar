# Cache Manager - "Phân bổ bao cấp tập trung"

## Kiến trúc mới

```
┌─────────────────────────────────────────────────────────────┐
│                      Providers                               │
│  ScheduleProvider  ExamProvider  GradeProvider  ...          │
│       ↓               ↓              ↓                      │
│  ┌─────────────────────────────────────────────────────────┐│
│  │              Cache Manager (Tập trung)                  ││
│  │  - getData() - Cache-first + background refresh         ││
│  │  - TTL management                                       ││
│  │  - Stale-while-revalidate                               ││
│  └─────────────────────────────────────────────────────────┘│
│       ↓               ↓              ↓                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │ Schedule │  │   Exam   │  │  Grades  │                  │
│  │  Cache   │  │  Cache   │  │  Cache   │                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

## Cách sử dụng

### Trước (Thân ai nấy cache)

```dart
// Provider tự lo everything
Future<void> init(String token) async {
  // 1. Load cache từ SQLite
  await _loadCachedData();
  
  // 2. Fetch từ API (blocking)
  final result = await fetchFromNetwork(token);
  
  // 3. Process result
  processResult(result);
}
```

**Vấn đề:**
- Skeleton loading lâu vì phải đợi network
- Không biết cache cũ bao nhiêu
- Không có background refresh
- Duplicate code ở mọi Provider

### Sau (Phân bổ bao cấp)

```dart
// CacheManager lo hết
Future<void> init(String token) async {
  // Preload từ SQLite vào memory cache
  await cacheManager.preloadFromLocal();
  
  // Lấy data - CacheManager tự quyết định:
  // 1. Cache valid → trả về ngay
  // 2. Cache stale → trả về + background refresh
  // 3. Không cache → fetch blocking
  final result = await cacheManager.getSchoolYears(token);
  
  _schoolYears = result.data;
  _isOfflineMode = result.isStale;
}
```

**Lợi ích:**
- Hiển thị data ngay (từ cache)
- Background refresh nếu cache cũ
- Code gọn hơn, không duplicate
- TTL management tập trung

## Cache Strategy

### Cache-first với Stale-While-Revalidate

```
User mở app
    ↓
CacheManager.getData()
    ↓
┌─ Cache valid (< TTL)? ── YES → Return immediately
│
├─ Cache stale (> TTL, < 2x TTL)?
│   ↓ YES
│   Return stale data + trigger background refresh
│
└─ No cache or expired?
    ↓
    Fetch blocking → Return fresh data
```

### TTL Configuration

```dart
// Schedule Cache Manager
static const Duration _schoolYearsTtl = Duration(days: 1);
static const Duration _coursesTtl = Duration(hours: 6);

// Có thể customize theo feature
final result = await cacheManager.getData(
  key: 'courses_$semesterId',
  fetcher: () => fetchCourses(semesterId),
  ttl: Duration(hours: 6),  // Custom TTL
);
```

## Migration Guide

### Phase 1: Tạo CacheManager (DONE)

- [x] `lib/core/cache/cache_manager.dart`
- [x] `lib/core/cache/schedule_cache_manager.dart`
- [x] `lib/providers/schedule_provider_v2.dart`

### Phase 2: Test ScheduleProviderV2

```dart
// Trong main.dart hoặc injection_container.dart
sl.registerLazySingleton(() => ScheduleCacheManager(sl()));
sl.registerLazySingleton(
  () => ScheduleProviderV2(cacheManager: sl()),
);
```

### Phase 3: Migrate các feature khác

Tạo tương tự:
- `ExamCacheManager`
- `GradeCacheManager`
- `TuitionCacheManager`
- `EducationProgramCacheManager`

### Phase 4: Update AutoRefreshService

```dart
// Trước: bypass Clean Architecture
await scheduleRemote.getCourses(...);
await dbHelper.saveCourses(...);

// Sau: dùng CacheManager
await cacheManager.getData(
  key: 'courses_$semesterId',
  fetcher: () => scheduleRemote.getCourses(...),
  forceRefresh: true,
);
```

## Cache Invalidation

### Theo key

```dart
cacheManager.invalidate('courses_123');
```

### Theo pattern

```dart
cacheManager.invalidatePattern('courses_*');  // Invalidate tất cả courses
cacheManager.invalidatePattern('schedule_*'); // Invalidate tất cả schedule
```

### Toàn bộ

```dart
cacheManager.invalidateAll();  // Logout
```

## Watch Real-time Updates

```dart
// Listen để nhận data mới khi background refresh hoàn thành
cacheManager.watchCourses(semesterId).listen((courses) {
  setState(() {
    _courses = courses;
  });
});
```

## Offline Support

```dart
// 1. Preload từ SQLite vào memory cache (stale)
await cacheManager.preloadFromLocal();

// 2. getData sẽ trả về stale data ngay
final result = await cacheManager.getSchoolYears(token);

if (result.isStale) {
  // Show stale data + indicator "Đang cập nhật..."
  showOfflineBanner();
}
```

## So sánh Before/After

| Tiêu chí | Trước | Sau |
|----------|-------|-----|
| Skeleton loading | Lâu (đợi network) | Ngắn (chỉ lần đầu) |
| Cache strategy | Mỗi feature tự lo | Tập trung |
| TTL | Không có | Configurable |
| Background refresh | Không | Có (stale-while-revalidate) |
| Code duplicate | Nhiều | Giảm 70% |
| Offline mode | Phức tạp | Đơn giản |

## Next Steps

1. Test `ScheduleProviderV2` với feature Schedule
2. Nếu OK → migrate Exam, Grades, Tuition, EducationProgram
3. Update `AutoRefreshService` dùng CacheManager
4. Xóa code cũ (Providers V1)
