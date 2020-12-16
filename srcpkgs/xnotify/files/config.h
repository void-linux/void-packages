static struct Config config = {
	/* fonts, separate different fonts with comma */
	.titlefont = "ubuntu:size=10:style=bold",
	.bodyfont = "ubuntu:size=9",

	/* colors */
	.background_color = "#263238",
	.foreground_color = "#ececec",
	.border_color = "#ececec",

	/* geometry and gravity (see the manual) */
	.geometryspec = "250x0-5+25",
	.gravityspec = "NE",

	/* size of border, gaps and image (in pixels) */
	.border_pixels = 1,
	.gap_pixels = 5,
	.image_pixels = 0,     /* if 0, the image will fit the notification */
	.leading_pixels = 5,    /* space between title and body texts */
	.padding_pixels = 10,   /* space around content */

	/* text alignment, set to LeftAlignment, CenterAlignment or RightAlignment */
	.alignment = RightAlignment,

	/* set to nonzero to shrink notification width to its content size */
	.shrink = 0,

	/* time, in seconds, for a notification to stay alive */
	.sec = 15
};
