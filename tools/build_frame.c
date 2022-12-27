#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>

#define SCREEN_WIDTH 40
#define SCREEN_HEIGHT 25

typedef struct {
    unsigned char *data;
    size_t size;
    size_t capacity;
} buffer_t;

int read_file(const char *filename, buffer_t *buffer) {
    FILE *in = fopen(filename, "rb");
    if(in == NULL) {
        fprintf(stderr, "failed to open %s: %s\n", filename, strerror(errno));
        return 0;
    }
    fseek(in, 0, SEEK_END);
    buffer->size = ftell(in);
    fseek(in, 0, SEEK_SET);
    buffer->size -= ftell(in);

    if((buffer->size > buffer->capacity) || (buffer->data == NULL)) {
        buffer->data = (unsigned char*)realloc(buffer->data, buffer->size);
        buffer->capacity = buffer->size;
    }

    fread(buffer->data, 1, buffer->size, in);

    fclose(in);
    return 1;
}

int main(int argc, char **argv) {
    if(argc != 4) {
        fprintf(stderr, "Usage: build_frame char_data color_dada output\n");
        return EXIT_FAILURE;
    }

    buffer_t char_vram = { NULL, 0, 0 };
    buffer_t color_vram = { NULL, 0, 0 };

    FILE *out = fopen(argv[3], "wb");
    if(out == NULL) {
        fprintf(stderr, "failed to open %s: %s\n", argv[3], strerror(errno));
        return EXIT_FAILURE;
    }

    int ret = EXIT_FAILURE;

    if(!read_file(argv[1], &char_vram)) {
        goto err;
    }
    if(!read_file(argv[2], &color_vram)) {
        goto err;
    }

    if((char_vram.size != color_vram.size) && (char_vram.size != (SCREEN_WIDTH * SCREEN_HEIGHT))) {
        fprintf(stderr, "invalid buffer size\n");
        goto err;
    }

    for(int j=0; j<SCREEN_HEIGHT; j++) {
        fwrite(&char_vram.data[j*SCREEN_WIDTH], 1, SCREEN_WIDTH, out);
        fwrite(&color_vram.data[j*SCREEN_WIDTH], 1, SCREEN_WIDTH, out);
    }

    ret = EXIT_SUCCESS;
err:
    if(out) {
        fclose(out);
    }
    if(char_vram.data != NULL) {
        free(char_vram.data);
    }
    if(color_vram.data != NULL) {
        free(color_vram.data);
    }
    return ret;
}