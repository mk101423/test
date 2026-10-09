/*
 * CPSC 355 Assignment 1, Problem C1: Simple Memory Allocator
 *
 * A first-fit memory allocator that manages one static 4096-byte array.
 * Every block in the heap is laid out as:
 *
 *     [ header | payload bytes ... ]
 *
 * Blocks sit back to back and exactly cover the whole array, so the next
 * block always starts at (this block's offset + header size + capacity).
 *
 * Input (standard input): a command count n, then n commands:
 *     M <size>   allocate size bytes with my_malloc
 *     F <index>  free the pointer returned by the index-th M command
 *     D          print the heap layout with heap_dump
 *
 * Defensive choices for cases the specification leaves undefined
 * (none of them print anything):
 *   - M with a size of 0 or a negative size records a NULL pointer.
 *   - my_free ignores pointers that are not the start of a used block's
 *     payload, so freeing an unknown pointer or an already free block
 *     does nothing.
 *   - F with an out-of-range index is ignored. After F frees an index, that
 *     history slot is set to NULL, so repeating F on the same index cannot
 *     free a newer block that happens to reuse the same address.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define HEAP_SIZE 4096

/*
 * Metadata stored immediately before every block's payload.
 *   capacity       - payload bytes this block physically owns
 *   requested_size - bytes the user asked for (only meaningful when used)
 *   is_free        - 1 if the block is free, 0 if it is in use
 *
 * capacity and requested_size differ when an allocation takes a whole
 * block that was too small to split.
 */
typedef struct {
    size_t capacity;
    size_t requested_size;
    int is_free;
} BlockHeader;

#define HEADER_SIZE sizeof(BlockHeader)

_Static_assert(sizeof(BlockHeader) <= 32, "block header must be at most 32 bytes");

/* The entire heap managed by the allocator. */
static unsigned char heap[HEAP_SIZE];

/*
 * read_header
 * Purpose: copy the header stored at a heap offset into an aligned struct.
 *          memcpy is used because heap bytes may not be suitably aligned
 *          for a BlockHeader, so casting the address would be undefined.
 * Inputs:  offset - index in heap where the header begins
 *          header - where the copied header is written
 * Returns: nothing; fills *header.
 * State:   does not change the heap.
 */
static void read_header(size_t offset, BlockHeader *header)
{
    memcpy(header, &heap[offset], HEADER_SIZE);
}

/*
 * write_header
 * Purpose: copy a header struct into the heap at a given offset.
 * Inputs:  offset - index in heap where the header begins
 *          header - the header values to store
 * Returns: nothing.
 * State:   overwrites HEADER_SIZE bytes of the heap starting at offset.
 */
static void write_header(size_t offset, const BlockHeader *header)
{
    memcpy(&heap[offset], header, HEADER_SIZE);
}

/*
 * my_init
 * Purpose: set up the heap as a single free block covering all 4096 bytes.
 * Inputs:  none.
 * Returns: nothing.
 * State:   writes one header at offset 0; the free block's capacity is
 *          everything after that header.
 */
void my_init(void)
{
    BlockHeader first_block;

    first_block.capacity = HEAP_SIZE - HEADER_SIZE;
    first_block.requested_size = 0;
    first_block.is_free = 1;
    write_header(0, &first_block);
}

/*
 * my_malloc
 * Purpose: allocate size bytes using first fit.
 * Inputs:  size - number of bytes requested.
 * Returns: pointer to the payload of the chosen block, or NULL if size is 0
 *          or no free block is large enough.
 * State:   marks the chosen block used and records size. If enough space is
 *          left over for a header plus at least one byte, the block is split
 *          and the leftover becomes a new free block.
 */
void *my_malloc(size_t size)
{
    size_t offset = 0;
    BlockHeader header;

    if (size == 0) {
        return NULL;
    }

    /* First fit: walk blocks from the start of the heap. */
    while (offset < HEAP_SIZE) {
        read_header(offset, &header);

        if (header.is_free && header.capacity >= size) {
            size_t leftover = header.capacity - size;

            /* Split only if the leftover can hold a header and 1+ bytes. */
            if (leftover >= HEADER_SIZE + 1) {
                BlockHeader remainder;
                size_t remainder_offset = offset + HEADER_SIZE + size;

                remainder.capacity = leftover - HEADER_SIZE;
                remainder.requested_size = 0;
                remainder.is_free = 1;
                write_header(remainder_offset, &remainder);

                /* The allocated block shrinks to exactly the request. */
                header.capacity = size;
            }
            /* Otherwise the block keeps its full capacity (no split). */

            header.requested_size = size;
            header.is_free = 0;
            write_header(offset, &header);

            /* The payload starts right after the header. */
            return &heap[offset + HEADER_SIZE];
        }

        /* Move to the next block using this block's size. */
        offset += HEADER_SIZE + header.capacity;
    }

    return NULL;
}

/*
 * my_free
 * Purpose: free a block returned by my_malloc and merge it with any free
 *          neighbour immediately before or after it.
 * Inputs:  ptr - a payload pointer returned by my_malloc, or NULL.
 * Returns: nothing.
 * State:   marks the block free and coalesces: a free right neighbour is
 *          absorbed into this block, and this block is absorbed into a free
 *          left neighbour. Each merge recovers the absorbed block's header
 *          bytes as capacity. NULL, unknown pointers, and already free
 *          blocks are ignored.
 */
void my_free(void *ptr)
{
    size_t offset = 0;
    size_t previous_offset = 0;
    int has_previous = 0;
    BlockHeader header;
    BlockHeader previous;

    if (ptr == NULL) {
        return;
    }

    /* Walk the heap, remembering the previous block, until ptr is found. */
    while (offset < HEAP_SIZE) {
        size_t next_offset;

        read_header(offset, &header);
        next_offset = offset + HEADER_SIZE + header.capacity;

        if ((void *)&heap[offset + HEADER_SIZE] == ptr) {
            if (header.is_free) {
                return;
            }

            header.is_free = 1;
            header.requested_size = 0;

            /* Right neighbour free: absorb it, including its header. */
            if (next_offset < HEAP_SIZE) {
                BlockHeader next;

                read_header(next_offset, &next);
                if (next.is_free) {
                    header.capacity += HEADER_SIZE + next.capacity;
                }
            }

            /* Left neighbour free: it absorbs this block and its header. */
            if (has_previous && previous.is_free) {
                previous.capacity += HEADER_SIZE + header.capacity;
                write_header(previous_offset, &previous);
            } else {
                write_header(offset, &header);
            }
            return;
        }

        previous = header;
        previous_offset = offset;
        has_previous = 1;
        offset = next_offset;
    }
}

/*
 * heap_dump
 * Purpose: print the current heap layout.
 * Inputs:  none.
 * Output:  "blocks <count>", then one line per block in address order:
 *          "used <requested size>" or "free".
 * State:   does not change the heap.
 */
void heap_dump(void)
{
    size_t offset = 0;
    int block_count = 0;
    BlockHeader header;

    /* First pass: count the blocks. */
    while (offset < HEAP_SIZE) {
        read_header(offset, &header);
        block_count++;
        offset += HEADER_SIZE + header.capacity;
    }

    printf("blocks %d\n", block_count);

    /* Second pass: print each block. */
    offset = 0;
    while (offset < HEAP_SIZE) {
        read_header(offset, &header);
        if (header.is_free) {
            printf("free\n");
        } else {
            printf("used %zu\n", header.requested_size);
        }
        offset += HEADER_SIZE + header.capacity;
    }
}

/*
 * main
 * Purpose: read commands from standard input and run them on the allocator.
 * Inputs:  standard input: n, then n commands (M <size>, F <index>, D).
 * Output:  only D prints anything (through heap_dump).
 * State:   initializes the heap, then allocates and frees blocks. Pointers
 *          returned by M are stored in allocation order so F <index> can
 *          find them. That history array uses the standard calloc/free and
 *          is only bookkeeping for main; it is not part of the custom heap.
 * Returns: 0 on success, 1 if the history array cannot be allocated.
 */
int main(void)
{
    int command_count;
    int allocation_count = 0;
    void **allocations = NULL;
    char command[16];

    my_init();

    if (scanf("%d", &command_count) != 1 || command_count <= 0) {
        return 0;
    }

    /* At most command_count M commands can occur, so this many slots suffice. */
    allocations = calloc((size_t)command_count, sizeof *allocations);
    if (allocations == NULL) {
        fprintf(stderr, "could not allocate pointer history\n");
        return 1;
    }

    for (int i = 0; i < command_count; i++) {
        if (scanf("%15s", command) != 1) {
            break;
        }

        if (strcmp(command, "M") == 0) {
            int size;

            if (scanf("%d", &size) != 1) {
                break;
            }
            /* Index allocation_count refers to this M, even if it fails. */
            if (size > 0) {
                allocations[allocation_count] = my_malloc((size_t)size);
            } else {
                allocations[allocation_count] = NULL;
            }
            allocation_count++;
        } else if (strcmp(command, "F") == 0) {
            int index;

            if (scanf("%d", &index) != 1) {
                break;
            }
            if (index >= 0 && index < allocation_count) {
                my_free(allocations[index]);
                allocations[index] = NULL;
            }
        } else if (strcmp(command, "D") == 0) {
            heap_dump();
        }
    }

    free(allocations);
    return 0;
}
