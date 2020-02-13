

LUAVER = 5.1

LUAPC := lua$(LUAVER)
LUA_CFLAGS := $(shell pkg-config --cflags $(LUAPC))

$(LUAVER)/bit32.so: lbitlib.c
	mkdir -p $(LUAVER)
	$(CC) -I c-api $(CFLAGS) $(LUA_CFLAGS) -shared -fPIC $(LDFLAGS) -o $@ $<

