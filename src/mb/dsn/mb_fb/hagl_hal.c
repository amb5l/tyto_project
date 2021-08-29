#include <stdint.h>
#include <stddef.h>
#include "bitmap.h"
#include "hagl_hal.h"
#include "hagl.h"
#include "fb.h"


bitmap_t *hagl_hal_init(void)
{
	hagl_set_clip_window(0, 0, DISPLAY_WIDTH - 1, DISPLAY_HEIGHT -1);
	return NULL;
}

void hagl_hal_put_pixel(int16_t x, int16_t y, color_t color)
{
	*(color_t *)(FB_BASE+(((y * fb_width) + x) << 2)) = color;
}
