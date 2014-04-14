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

/* levels (in percent) to use when zooming via '-' and '+':
 * (first/last value is used as min/max zoom level)
 */
static const float zoom_levels[] = {
	 12.5,  25.0,  50.0,  75.0,
	100.0, 150.0, 200.0, 400.0, 800.0
};

/* default slideshow delay (in sec, overwritten via -S option): */
enum { SLIDESHOW_DELAY = 5 };

/* default settings for multi-frame gif images: */
enum {
	GIF_DELAY    = 100, /* delay time (in ms) */
	GIF_AUTOPLAY = 1,   /* autoplay when loaded [0/1] */
	GIF_LOOP     = 0    /* loop? [0: no, 1: endless, -1: as specified in file] */
};

/* gamma correction: the user-visible ranges [-GAMMA_RANGE, 0] and
 * (0, GAMMA_RANGE] are mapped to the ranges [0, 1], and (1, GAMMA_MAX].
 * */
static const double GAMMA_MAX   = 10.0;
static const int    GAMMA_RANGE = 32;

/* if false, pixelate images at zoom level != 100%,
 * toggled with 'a' key binding
 */
static const bool ANTI_ALIAS = true;

/* if true, use a checkerboard background for alpha layer,
 * toggled with 'A' key binding
 */
static const bool ALPHA_LAYER = false;

#endif
#ifdef _THUMBS_CONFIG

/* default dimension of thumbnails (width == height): */
enum { THUMB_SIZE = 60 };

#endif
#ifdef _MAPPINGS_CONFIG

/* keyboard mappings for image and thumbnail mode: */
static const keymap_t keys[] = {
	/* modifiers    key               function              argument */
	{ 0,            XK_q,             it_quit,              (arg_t) None },
	{ 0,            XK_Return,        it_switch_mode,       (arg_t) None },
	{ 0,            XK_f,             it_toggle_fullscreen, (arg_t) None },
	{ 0,            XK_b,             it_toggle_bar,        (arg_t) None },

	{ ControlMask,  XK_x,             it_prefix_external,   (arg_t) None },

	{ 0,            XK_r,             it_reload_image,      (arg_t) None },
	{ 0,            XK_R,             t_reload_all,         (arg_t) None },
	{ 0,            XK_D,             it_remove_image,      (arg_t) None },

	{ 0,            XK_n,             i_navigate,           (arg_t) +1 },
	{ 0,            XK_space,         i_navigate,           (arg_t) +1 },
	{ 0,            XK_p,             i_navigate,           (arg_t) -1 },
	{ 0,            XK_BackSpace,     i_navigate,           (arg_t) -1 },
	{ 0,            XK_bracketright,  i_navigate,           (arg_t) +10 },
	{ 0,            XK_bracketleft,   i_navigate,           (arg_t) -10 },
	{ ControlMask,  XK_6,             i_alternate,          (arg_t) None },
	{ 0,            XK_g,             it_first,             (arg_t) None },
	{ 0,            XK_G,             it_n_or_last,         (arg_t) None },

	{ ControlMask,  XK_n,             i_navigate_frame,     (arg_t) +1 },
	{ ControlMask,  XK_p,             i_navigate_frame,     (arg_t) -1 },
	{ ControlMask,  XK_space,         i_toggle_animation,   (arg_t) None },

	{ 0,            XK_m,             it_toggle_image_mark, (arg_t) None },
	{ 0,            XK_M,             it_reverse_marks,     (arg_t) None },
	{ 0,            XK_N,             it_navigate_marked,   (arg_t) +1 },
	{ 0,            XK_P,             it_navigate_marked,   (arg_t) -1 },

	{ 0,            XK_h,             it_scroll_move,       (arg_t) DIR_LEFT },
	{ 0,            XK_Left,          it_scroll_move,       (arg_t) DIR_LEFT },
	{ 0,            XK_j,             it_scroll_move,       (arg_t) DIR_DOWN },
	{ 0,            XK_Down,          it_scroll_move,       (arg_t) DIR_DOWN },
	{ 0,            XK_k,             it_scroll_move,       (arg_t) DIR_UP },
	{ 0,            XK_Up,            it_scroll_move,       (arg_t) DIR_UP },
	{ 0,            XK_l,             it_scroll_move,       (arg_t) DIR_RIGHT },
	{ 0,            XK_Right,         it_scroll_move,       (arg_t) DIR_RIGHT },

	{ ControlMask,  XK_h,             it_scroll_screen,     (arg_t) DIR_LEFT },
	{ ControlMask,  XK_Left,          it_scroll_screen,     (arg_t) DIR_LEFT },
	{ ControlMask,  XK_j,             it_scroll_screen,     (arg_t) DIR_DOWN },
	{ ControlMask,  XK_Down,          it_scroll_screen,     (arg_t) DIR_DOWN },
	{ ControlMask,  XK_k,             it_scroll_screen,     (arg_t) DIR_UP },
	{ ControlMask,  XK_Up,            it_scroll_screen,     (arg_t) DIR_UP },
	{ ControlMask,  XK_l,             it_scroll_screen,     (arg_t) DIR_RIGHT },
	{ ControlMask,  XK_Right,         it_scroll_screen,     (arg_t) DIR_RIGHT },

	{ 0,            XK_H,             i_scroll_to_edge,     (arg_t) DIR_LEFT },
	{ 0,            XK_J,             i_scroll_to_edge,     (arg_t) DIR_DOWN },
	{ 0,            XK_K,             i_scroll_to_edge,     (arg_t) DIR_UP },
	{ 0,            XK_L,             i_scroll_to_edge,     (arg_t) DIR_RIGHT },

	{ 0,            XK_plus,          i_zoom,               (arg_t) +1 },
	{ 0,            XK_KP_Add,        i_zoom,               (arg_t) +1 },
	{ 0,            XK_minus,         i_zoom,               (arg_t) -1 },
	{ 0,            XK_KP_Subtract,   i_zoom,               (arg_t) -1 },
	{ 0,            XK_equal,         i_set_zoom,           (arg_t) 100 },
	{ 0,            XK_w,             i_fit_to_win,         (arg_t) SCALE_DOWN },
	{ 0,            XK_W,             i_fit_to_win,         (arg_t) SCALE_FIT },
	{ 0,            XK_e,             i_fit_to_win,         (arg_t) SCALE_WIDTH },
	{ 0,            XK_E,             i_fit_to_win,         (arg_t) SCALE_HEIGHT },

	{ 0,            XK_less,          i_rotate,             (arg_t) DEGREE_270 },
	{ 0,            XK_greater,       i_rotate,             (arg_t) DEGREE_90 },
	{ 0,            XK_question,      i_rotate,             (arg_t) DEGREE_180 },

	{ 0,            XK_bar,           i_flip,               (arg_t) FLIP_HORIZONTAL },
	{ 0,            XK_underscore,    i_flip,               (arg_t) FLIP_VERTICAL },

	{ 0,            XK_s,             i_slideshow,          (arg_t) None },

	{ 0,            XK_a,             i_toggle_antialias,   (arg_t) None },
	{ 0,            XK_A,             i_toggle_alpha,       (arg_t) None },

	{ 0,            XK_braceleft,     i_change_gamma,       (arg_t) -1 },
	{ 0,            XK_braceright,    i_change_gamma,       (arg_t) +1 },
	{ ControlMask,  XK_g,             i_change_gamma,       (arg_t)  0 },
};

/* mouse button mappings for image mode: */
static const button_t buttons[] = {
	/* modifiers    button            function              argument */
	{ 0,            Button1,          i_navigate,           (arg_t) +1 },
	{ 0,            Button3,          i_navigate,           (arg_t) -1 },
	{ 0,            Button2,          i_drag,               (arg_t) None },
	{ 0,            Button4,          it_scroll_move,       (arg_t) DIR_UP },
	{ 0,            Button5,          it_scroll_move,       (arg_t) DIR_DOWN },
	{ ShiftMask,    Button4,          it_scroll_move,       (arg_t) DIR_LEFT },
	{ ShiftMask,    Button5,          it_scroll_move,       (arg_t) DIR_RIGHT },
	{ ControlMask,  Button4,          i_zoom,               (arg_t) +1 },
	{ ControlMask,  Button5,          i_zoom,               (arg_t) -1 },
};

#endif
