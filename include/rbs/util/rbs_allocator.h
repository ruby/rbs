#ifndef RBS_ALLOCATOR_H
#define RBS_ALLOCATOR_H

#include <stddef.h>

typedef struct rbs_allocator {
    // The head of a linked list of pages, starting with the most recently allocated page.
    struct rbs_allocator_page *page;
} rbs_allocator_t;

void rbs_allocator_init(rbs_allocator_t *);
void rbs_allocator_free(rbs_allocator_t *);
void *rbs_allocator_malloc_impl(rbs_allocator_t *, /*    1    */ size_t size, size_t alignment);
void *rbs_allocator_calloc_impl(rbs_allocator_t *, size_t count, size_t size, size_t alignment);

#define rbs_allocator_alloc(allocator, type)         ((type *) rbs_allocator_malloc_impl((allocator),          sizeof(type), alignof(type)))
#define rbs_allocator_calloc(allocator, count, type) ((type *) rbs_allocator_calloc_impl((allocator), (count), sizeof(type), alignof(type)))

void rbs__init_arena_allocator(void);

#endif
