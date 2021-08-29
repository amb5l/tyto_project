#include <stdint.h>
#include "fb.h"

#define HAGL_HAS_HAL_INIT
#define HAGL_HAS_HAL_VARIABLE_DISPLAY_SIZE

#define DISPLAY_DEPTH (32)
#define DISPLAY_WIDTH fb_width
#define DISPLAY_HEIGHT fb_height

typedef uint32_t color_t;

void hagl_hal_put_pixel(int16_t x, int16_t y, color_t color);
