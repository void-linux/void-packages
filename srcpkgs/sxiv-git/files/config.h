#ifdef _WINDOW_CONFIG

/* default window dimensions (overwritten via -g option): */
enum {
	WIN_WIDTH  = 800,
	WIN_HEIGHT = 600
};

/* bar font:
 * (see X(7) section "FONT NAMES" for valid values)
 */
static const char * const BAR_FONT = "-*-fixed-medium-r-*-*-13-*-*-*-*-60-*-*";

/* colors:
 * (see X(7) section "COLOR NAMES" for valid values)
 */
static const char * const WIN_BG_COLOR = "#777777";
static const char * const WIN_FS_COLOR = "#000000";
static const char * const SEL_COLOR    = "#DDDDDD";
static const char * const BAR_BG_COLOR = "#222222";
static const char * const BAR_FG_COLOR = "#EEEEEE";

#endif
#ifdef _IMAGE_CONFIG

/* how should images be scaled when they are loaded?
 * (also controllable via -d/-s/-Z/-z options)
 *   SCALE_DOWN: 100%, but fit large images into window,
 *   SCALE_FIT:  fit all images into window,
 *   SCALE_ZOOM: use current zoom level, 100% at startup
 */
static const scalemode_t SCALE_MODE = SCALE_DOWN;

/* levels (in percent) to use when zooming via '-' and '+':
 * (first/last value is used as min/max zoom level)
 */
static const float zoom_levels[] = {
	 12.5,  25.0,  50.0,  75.0,
	100.0, 150.0, 200.0, 400.0, 800.0
};

/* default settings for multi-frame gif images: */
enum {
	GIF_DELAY    = 100, /* delay time (in ms) */
	GIF_AUTOPLAY = 1,   /* autoplay when loaded [0/1] */
	GIF_LOOP     = 0    /* endless loop [0/1] */
};

#endif
#ifdef _THUMBS_CONFIG

/* default dimension of thumbnails (width == height): */
enum { THUMB_SIZE = 60 };

#endif
#ifdef _RENDER_CONFIG

/* if false, pixelate images at zoom level != 100%,
 * toggled with 'a' key binding
 */
static const bool RENDER_ANTI_ALIAS = true;

/* if true, use white background for alpha layer,
 * toggled with 'A' key binding
 */
static const bool RENDER_WHITE_ALPHA = false;

#endif
#ifdef _MAPPINGS_CONFIG

/* keyboard mappings for image and thumbnail mode: */
static const keymap_t keys[] = {
	/* ctrl   key               function              argument */
	{ false,  XK_q,             it_quit,              (arg_t) None },
	{ false,  XK_Return,        it_switch_mode,       (arg_t) None },
	{ false,  XK_f,             it_toggle_fullscreen, (arg_t) None },
	{ false,  XK_b,             it_toggle_bar,        (arg_t) None },

	{ false,  XK_r,             it_reload_image,      (arg_t) None },
	{ false,  XK_R,             t_reload_all,         (arg_t) None },
	{ false,  XK_D,             it_remove_image,      (arg_t) None },

	{ false,  XK_n,             i_navigate,           (arg_t) +1 },
	{ false,  XK_space,         i_navigate,           (arg_t) +1 },
	{ false,  XK_p,             i_navigate,           (arg_t) -1 },
	{ false,  XK_BackSpace,     i_navigate,           (arg_t) -1 },
	{ false,  XK_bracketright,  i_navigate,           (arg_t) +10 },
	{ false,  XK_bracketleft,   i_navigate,           (arg_t) -10 },
	{ true,   XK_6,             i_alternate,          (arg_t) None },
	{ false,  XK_g,             it_first,             (arg_t) None },
	{ false,  XK_G,             it_n_or_last,         (arg_t) None },

	{ true,   XK_n,             i_navigate_frame,     (arg_t) +1 },
	{ true,   XK_p,             i_navigate_frame,     (arg_t) -1 },
	{ true,   XK_space,         i_toggle_animation,   (arg_t) None },

	{ false,  XK_m,             it_toggle_image_mark, (arg_t) None },
	{ false,  XK_N,             it_navigate_marked,   (arg_t) +1 },
	{ false,  XK_P,             it_navigate_marked,   (arg_t) -1 },

	{ false,  XK_h,             it_scroll_move,       (arg_t) DIR_LEFT },
	{ false,  XK_Left,          it_scroll_move,       (arg_t) DIR_LEFT },
	{ false,  XK_j,             it_scroll_move,       (arg_t) DIR_DOWN },
	{ false,  XK_Down,          it_scroll_move,       (arg_t) DIR_DOWN },
	{ false,  XK_k,             it_scroll_move,       (arg_t) DIR_UP },
	{ false,  XK_Up,            it_scroll_move,       (arg_t) DIR_UP },
	{ false,  XK_l,             it_scroll_move,       (arg_t) DIR_RIGHT },
	{ false,  XK_Right,         it_scroll_move,       (arg_t) DIR_RIGHT },

	{ true,   XK_h,             it_scroll_screen,     (arg_t) DIR_LEFT },
	{ true,   XK_Left,          it_scroll_screen,     (arg_t) DIR_LEFT },
	{ true,   XK_j,             it_scroll_screen,     (arg_t) DIR_DOWN },
	{ true,   XK_Down,          it_scroll_screen,     (arg_t) DIR_DOWN },
	{ true,   XK_k,             it_scroll_screen,     (arg_t) DIR_UP },
	{ true,   XK_Up,            it_scroll_screen,     (arg_t) DIR_UP },
	{ true,   XK_l,             it_scroll_screen,     (arg_t) DIR_RIGHT },
	{ true,   XK_Right,         it_scroll_screen,     (arg_t) DIR_RIGHT },

	{ false,  XK_H,             i_scroll_to_edge,     (arg_t) DIR_LEFT },
	{ false,  XK_J,             i_scroll_to_edge,     (arg_t) DIR_DOWN },
	{ false,  XK_K,             i_scroll_to_edge,     (arg_t) DIR_UP },
	{ false,  XK_L,             i_scroll_to_edge,     (arg_t) DIR_RIGHT },

	{ false,  XK_plus,          i_zoom,               (arg_t) +1 },
	{ false,  XK_KP_Add,        i_zoom,               (arg_t) +1 },
	{ false,  XK_minus,         i_zoom,               (arg_t) -1 },
	{ false,  XK_KP_Subtract,   i_zoom,               (arg_t) -1 },
	{ false,  XK_equal,         i_set_zoom,           (arg_t) 100 },
	{ false,  XK_w,             i_fit_to_win,         (arg_t) SCALE_FIT },
	{ false,  XK_e,             i_fit_to_win,         (arg_t) SCALE_WIDTH },
	{ false,  XK_E,             i_fit_to_win,         (arg_t) SCALE_HEIGHT },
	{ false,  XK_W,             i_fit_to_img,         (arg_t) None },

	{ false,  XK_less,          i_rotate,             (arg_t) DEGREE_270 },
	{ false,  XK_greater,       i_rotate,             (arg_t) DEGREE_90 },
	{ false,  XK_question,      i_rotate,             (arg_t) DEGREE_180 },

	{ false,  XK_bar,           i_flip,               (arg_t) FLIP_HORIZONTAL },
	{ false,  XK_underscore,    i_flip,               (arg_t) FLIP_VERTICAL },

	{ false,  XK_a,             i_toggle_antialias,   (arg_t) None },
	{ false,  XK_A,             it_toggle_alpha,      (arg_t) None },

	/* open current image with given program: */
	{ true,   XK_g,             it_open_with,         (arg_t) "gimp" },

	/* run shell command line on current file ("$SXIV_IMG"): */
	{ true,   XK_less,          it_shell_cmd,         (arg_t) \
			"mogrify -rotate -90 \"$SXIV_IMG\"" },
	{ true,   XK_greater,       it_shell_cmd,         (arg_t) \
			"mogrify -rotate +90 \"$SXIV_IMG\"" },
	{ true,   XK_question,      it_shell_cmd,         (arg_t) \
			"mogrify -rotate 180 \"$SXIV_IMG\"" },
	{ true,   XK_comma,         it_shell_cmd,         (arg_t) \
			"jpegtran -rotate 270 -copy all -outfile \"$SXIV_IMG\" \"$SXIV_IMG\"" },
	{ true,   XK_period,        it_shell_cmd,         (arg_t) \
			"jpegtran -rotate  90 -copy all -outfile \"$SXIV_IMG\" \"$SXIV_IMG\"" },
	{ true,   XK_slash,         it_shell_cmd,         (arg_t) \
			"jpegtran -rotate 180 -copy all -outfile \"$SXIV_IMG\" \"$SXIV_IMG\"" },
};

/* mouse button mappings for image mode: */
static const button_t buttons[] = {
	/* ctrl   shift   button    function              argument */
	{ false,  false,  Button1,  i_navigate,           (arg_t) +1 },
	{ false,  false,  Button3,  i_navigate,           (arg_t) -1 },
	{ false,  false,  Button2,  i_drag,               (arg_t) None },
	{ false,  false,  Button4,  it_scroll_move,       (arg_t) DIR_UP },
	{ false,  false,  Button5,  it_scroll_move,       (arg_t) DIR_DOWN },
	{ false,  true,   Button4,  it_scroll_move,       (arg_t) DIR_LEFT },
	{ false,  true,   Button5,  it_scroll_move,       (arg_t) DIR_RIGHT },
	{ true,   false,  Button4,  i_zoom,               (arg_t) +1 },
	{ true,   false,  Button5,  i_zoom,               (arg_t) -1 },
};

#endif
