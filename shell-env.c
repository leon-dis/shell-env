#include <lua.h>
#include <lauxlib.h>
#include <stdlib.h>
#include <stdio.h>


int main()
{
    int result;
    lua_State * L;
    L = luaL_newstate();
    luaL_openlibs(L);
#ifdef PREFIX
    result = luaL_loadfile(L, PREFIX "/bin/shell-env.lua");
#else
    result = luaL_loadfile(L, "/tmp/shell-env.lua");
#endif
    if (result) {
        fprintf(stderr, "Error loading: %s\n", lua_tostring(L, -1));
        exit(1);
    }
    lua_pushnumber(L, 2);
    lua_setglobal(L, "var");
    result = lua_pcall(L, 0, LUA_MULTRET, 0);
    if (result) {
         fprintf(stderr, "Error running: %s\n", lua_tostring(L, -
1));
         exit(1);
     }
//     printf("Ok\n");
     lua_close(L);
     return EXIT_SUCCESS;
}

