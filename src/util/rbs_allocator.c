/**
 *  @file rbs_allocator.c
 *
 *  A simple arena allocator that can be freed all at once.
 *
 *  This allocator maintains a linked list of pages, which come in two flavours:
 *      1. Small allocation pages, which are the same size as the system page size.
 *      2. Large allocation pages, which are the exact size requested, for sizes greater than the small page size.
 *
 *  Small allocations always fit into the unused space at the end of the "head" page. If there isn't enough room, a new
 *  page is allocated, and the small allocation is placed at its start. This approach wastes that unused slack at the
 *  end of the previous page, but it means that allocations are instant and never scan the linked list to find a gap.
 *
 *  This allocator doesn't support freeing individual allocations. Only the whole arena can be freed at once at the end.
 */

#include "rbs/util/rbs_allocator.h"

#include <stdlib.h>
#include <assert.h>
#include <string.h> // for memset()
#include <stdint.h>

#ifdef _WIN32
    #include <windows.h>
#else
    #include <unistd.h>
    #include <sys/types.h>
#endif

typedef struct rbs_allocator_page {
    uint32_t payload_size;

    // The offset of the next available byte.
    uint32_t offset;

    // The previously allocated page, or NULL if this is the first page.
    struct rbs_allocator_page *next;

    // The variably-sized payload of the page.
    char payload[];
} rbs_allocator_page_t;

// This allocator's normal pages have the same size as the system memory pages, consisting of a fixed-size header
// (sizeof(rbs_allocator_page_t)) followed `default_page_payload_size`  bytes of payload.
// TODO: When we have real-world usage data, we can tune this to use a smaller number of larger pages.
static size_t default_page_payload_size = 0;
static uint32_t large_page_flag = UINT32_MAX;

static size_t get_system_page_size() {
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

void rbs__init_arena_allocator(void) {
    const size_t system_page_size = get_system_page_size();

    // The size of a struct that ends with a flexible array member is the size of the struct without the
    // flexible array member. https://en.wikipedia.org/wiki/Flexible_array_member#Effect_on_struct_size_and_padding
    const size_t page_header_size = sizeof(rbs_allocator_page_t);
    default_page_payload_size = system_page_size - page_header_size;
}

// Returns the number of bytes needed to pad the given pointer up to the nearest multiple of the given `alignment`.
static size_t needed_padding(void *ptr, size_t alignment) {
    const uintptr_t addr = (uintptr_t) ptr;
    const uintptr_t aligned_addr = (addr + (alignment - 1)) & -alignment;
    return (aligned_addr - addr);
}

static rbs_allocator_page_t *rbs_allocator_page_new(size_t payload_size) {
    const size_t page_header_size = sizeof(rbs_allocator_page_t);

    rbs_allocator_page_t *page = calloc(1, page_header_size + payload_size);
    *page = (rbs_allocator_page_t) {
        .payload_size = (uint32_t) payload_size,
        .offset = page_header_size,
        .next = NULL,
    };
    return page;
}

static rbs_allocator_page_t *rbs_allocator_page_new_default(void) {
    return rbs_allocator_page_new(default_page_payload_size);
}

static rbs_allocator_page_t *rbs_allocator_page_new_large(size_t payload_size) {
    rbs_allocator_page_t *page = rbs_allocator_page_new(payload_size);

    page->offset = large_page_flag;

    return page;
}

// Attempts to allocate `size` bytes from `page`, returning NULL if there is insufficient space.
static void *rbs_allocator_page_attempt_alloc(rbs_allocator_page_t *page, size_t size, size_t alignment) {
    const size_t alignment_padding = needed_padding(page->payload + page->offset, alignment);

    const size_t remaining_size = page->payload_size - page->offset;
    const size_t needed_size = alignment_padding + size;
    if (remaining_size < needed_size) return NULL; // Not enough space in this page.

    void *ptr = page->payload + page->offset + alignment_padding;
    page->offset += needed_size;
    return ptr;
}

void rbs_allocator_init(rbs_allocator_t *allocator) {
    *allocator = (rbs_allocator_t) {
        .page = rbs_allocator_page_new_default(),
    };
}

void rbs_allocator_free(rbs_allocator_t *allocator) {
    rbs_allocator_page_t *page = allocator->page;
    while (page) {
        rbs_allocator_page_t *next = page->next;
        free(page);
        page = next;
    }

    *allocator = (rbs_allocator_t) {
        .page = NULL,
    };
}

// Allocates `size` bytes from `allocator`, aligned to an `alignment`-byte boundary.
void *rbs_allocator_malloc_impl(rbs_allocator_t *allocator, size_t size, size_t alignment) {
    assert(size % alignment == 0 && "size must be a multiple of the alignment");

    if (default_page_payload_size < size) { // Big allocation, give it its own page.
        // How much we need to pad the new page's payload in order to get an aligned pointer
        // hack?
        const size_t alignment_padding = needed_padding((void *) (sizeof(rbs_allocator_page_t) + size), alignment);

        rbs_allocator_page_t *new_page = rbs_allocator_page_new_large(alignment_padding + size);

        // This simple allocator can only put small allocations into the head page.
        // Naively prepending this large allocation page to the head of the allocator before the previous head page
        // would waste the remaining space in the head page.
        // So instead, we'll splice in the large page *after* the head page.
        //
        // +-------+    +-----------+        +-----------+
        // | arena |    | head page |        | new_page  |
        // |-------|    |-----------+        |-----------+
        // | *page |--->|  size     |   +--->|  size     |   +---> ... previous tail
        // +-------+    |  offset   |   |    |  offset   |   |
        //              | *next ----+---+    | *next ----+---+
        //              |    ...    |        |    ...    |
        //              +-----------+        +-----------+
        //
        new_page->next = allocator->page->next;
        allocator->page->next = new_page;

        return new_page->payload + alignment_padding;
    }

    void *p = rbs_allocator_page_attempt_alloc(allocator->page, size, alignment);
    if (p != NULL) return p;

    // Not enough space. Allocate a new page and prepend it to the allocator's linked list.
    rbs_allocator_page_t *new_page = rbs_allocator_page_new_default();
    new_page->next = allocator->page;
    allocator->page = new_page;

    p = rbs_allocator_page_attempt_alloc(new_page, size, alignment);
    assert(p != NULL && "Failed to allocate a new allocator page");
    return p;
}

// Note: This will eagerly fill with zeroes, unlike `calloc()` which can map a page in a page to be zeroed lazily.
//       It's assumed that callers to this function will immediately write to the allocated memory, anyway.
void *rbs_allocator_calloc_impl(rbs_allocator_t *allocator, size_t count, size_t size, size_t alignment) {
    void *p = rbs_allocator_malloc_impl(allocator, count * size, alignment);
    memset(p, 0, count * size);
    return p;
}

