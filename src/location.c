#include "rbs/location.h"

rbs_location_range_list_t *rbs_location_range_list_new(rbs_allocator_t *allocator) {
    rbs_location_range_list_t *list = rbs_allocator_alloc(allocator, rbs_location_range_list_t);
    *list = (rbs_location_range_list_t) {
        .allocator = allocator,
        .head = NULL,
        .tail = NULL,
        .length = 0,
    };

    return list;
}

void rbs_location_range_list_append(rbs_location_range_list_t *list, rbs_location_range range) {
    rbs_location_range_list_node_t *node = rbs_allocator_alloc(list->allocator, rbs_location_range_list_node_t);
    *node = (rbs_location_range_list_node_t) {
        .range = range,
        .next = NULL,
    };

    if (list->head == NULL) {
        list->head = node;
        list->tail = node;
    } else {
        list->tail->next = node;
        list->tail = node;
    }

    list->length++;
}