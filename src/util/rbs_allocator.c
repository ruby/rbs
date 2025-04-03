/**
 *  @file rbs_allocator.c
 *
 *  A simple arena allocator that can be freed all at once.
 *
 *  This allocator doesn't support freeing individual allocations. Only the whole arena can be freed at once at the end.
 */

#include "rbs/util/rbs_allocator.h"
#include "rbs/util/rbs_assert.h"

#include <stdlib.h>
#include <string.h> // for memset()
#include <stdint.h>
#include <inttypes.h>

#ifdef _WIN32
    #include <windows.h>
#else
    #include <unistd.h>
    #include <sys/types.h>
    #include <sys/mman.h>
#endif

#if defined(__APPLE__) || defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__sun)
#define MAP_ANONYMOUS MAP_ANON
#endif


struct rbs_allocator {
    uintptr_t heap_ptr;
    uintptr_t size;
};

static size_t get_system_page_size(void) {
#ifdef _WIN32
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    return si.dwPageSize;
#else
    long sz = sysconf(_SC_PAGESIZE);
    if (sz == -1) return 4096; // Fallback to the common 4KB page size
    return (size_t) sz;
#endif
}

static void *map_memory(size_t size) {
#ifdef _WIN32
    LPVOID result = VirtualAlloc(NULL, size, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
    rbs_assert(result != NULL, "VirtualAlloc failed");
#else
    void *result = mmap(NULL, size, PROT_READ | PROT_WRITE,
                        MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    rbs_assert(result != MAP_FAILED, "mmap failed");
#endif
    return result;
}

static void destroy_memory(void *memory, size_t size) {
#ifdef _WIN32
    VirtualFree(memory, 0, MEM_RELEASE);
#else
    munmap(memory, size);
#endif
}

static void guard_page(void *memory, size_t page_size) {
#ifdef _WIN32
    DWORD old_protect_;
    BOOL result = VirtualProtect(memory, page_size, PAGE_NOACCESS, &old_protect_);
    rbs_assert(result != 0, "VirtualProtect failed");
#else
    int result = mprotect(memory, page_size, PROT_NONE);
    rbs_assert(result == 0, "mprotect failed");
#endif
}

static size_t rbs_allocator_default_mem(void) {
    size_t kib = 1024;
    size_t mib = kib * 1024;
    size_t gib = mib * 1024;
    return 4 * gib;
}

static inline bool is_power_of_two(uintptr_t value) {
    return value > 0 && (value & (value - 1)) == 0;
}

// Align `val' to nearest multiple of `alignment'.
static uintptr_t align(uintptr_t size, uintptr_t alignment) {
    rbs_assert(is_power_of_two(alignment), "alignment is not a power of two");
    return (size + alignment - 1) & ~(alignment - 1);
}

rbs_allocator_t *rbs_allocator_init(void) {
    size_t size = rbs_allocator_default_mem();
    size_t page_size = get_system_page_size();
    size = align(size, page_size);
    void *mem = map_memory(size + page_size);
    // Guard page; remove range checks in alloc fast path and hard fail if we
    // consume all memory
    void *last_page = (char *) mem + size;
    guard_page(last_page, page_size);
    uintptr_t start = (uintptr_t) mem;
    rbs_allocator_t header = (rbs_allocator_t) {
      .heap_ptr = start + sizeof header,
      .size = size + page_size,
    };
    memcpy(mem, &header, sizeof header);
    return (rbs_allocator_t *) mem;
}

void rbs_allocator_free(rbs_allocator_t *allocator) {
    destroy_memory((void *) allocator, allocator->size);
}

// Allocates `new_size` bytes from `allocator`, aligned to an `alignment`-byte boundary.
// Copies `old_size` bytes from `ptr` to the new allocation.
// It always reallocates the memory in new space and thus wastes the old space.
void *rbs_allocator_realloc_impl(rbs_allocator_t *allocator, void *ptr, size_t old_size, size_t new_size, size_t alignment) {
    void *p = rbs_allocator_malloc_impl(allocator, new_size, alignment);
    memcpy(p, ptr, old_size);
    return p;
}

// Allocates `size` bytes from `allocator`, aligned to an `alignment`-byte boundary.
void *rbs_allocator_malloc_impl(rbs_allocator_t *allocator, size_t size, size_t alignment) {
    rbs_assert(size % alignment == 0, "size must be a multiple of the alignment. size: %zu, alignment: %zu", size, alignment);
    uintptr_t aligned = align(allocator->heap_ptr, alignment);
    allocator->heap_ptr = aligned + size;
    return (void *) aligned;
}

// Note: This will eagerly fill with zeroes, unlike `calloc()` which can map a page in a page to be zeroed lazily.
//       It's assumed that callers to this function will immediately write to the allocated memory, anyway.
void *rbs_allocator_calloc_impl(rbs_allocator_t *allocator, size_t count, size_t size, size_t alignment) {
    void *p = rbs_allocator_malloc_many_impl(allocator, count, size, alignment);
#if defined(__linux__)
    // mmap with MAP_ANONYMOUS gives zero-filled pages.
#else
    memset(p, 0, count * size);
#endif
    return p;
}

// Similar to `rbs_allocator_malloc_impl()`, but allocates `count` instances of `size` bytes, aligned to an `alignment`-byte boundary.
void *rbs_allocator_malloc_many_impl(rbs_allocator_t *allocator, size_t count, size_t size, size_t alignment) {
    return rbs_allocator_malloc_impl(allocator, count * size, alignment);
}
