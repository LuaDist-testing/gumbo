-- This file was automatically generated for the LuaDist project.

package = "gumbo"
version = "0.2-1"
supported_platforms = {"unix"}

description = {
    summary = "Lua bindings for the Gumbo HTML5 parsing library",
    homepage = "https://github.com/craigbarnes/lua-gumbo",
    license = "ISC"
}

-- LuaDist source
source = {
  tag = "0.2-1",
  url = "git://github.com/LuaDist-testing/gumbo.git"
}
-- Original source
-- source = {
--     url = "git://github.com/craigbarnes/lua-gumbo.git",
--     tag = "0.2"
-- }

dependencies = {
    "lua >= 5.1"
}

external_dependencies = {
    GUMBO = {
        library = "gumbo",
        header = "gumbo.h"
    }
}

build = {
    type = "make",
    variables = {
        LUA = "$(LUA)",
        LUA_INCDIR = "$(LUA_INCDIR)",
        LUA_LIBDIR = "$(LUA_LIBDIR)"
    },
    build_variables = {
        CFLAGS = "$(CFLAGS)",
        LDFLAGS = "$(LIBFLAG)",
        LUA_CFLAGS = "-I$(LUA_INCDIR)",
        GUMBO_CFLAGS = "-I$(GUMBO_INCDIR)",
        GUMBO_LDFLAGS = "-L$(GUMBO_LIBDIR)"
    },
    install_variables = {
        LUA_CMOD_DIR = "$(LIBDIR)",
        LUA_LMOD_DIR = "$(LUADIR)"
    }
}