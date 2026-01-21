extern "C" {
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
}
#include <manifold/manifoldc.h>
#include <stdlib.h>
#include <vector>

// Helper to allocate memory for a Manifold object
static ManifoldManifold *alloc_manifold() {
  return (ManifoldManifold *)malloc(manifold_manifold_size());
}

static void free_manifold_wrapper(ManifoldManifold *m) {
  if (m) {
    manifold_destruct_manifold(m);
    free(m);
  }
}

// Helper to check for Manifold userdata
static ManifoldManifold *check_manifold(lua_State *L, int idx) {
  ManifoldManifold **ud =
      (ManifoldManifold **)luaL_checkudata(L, idx, "Manifold");
  if (!ud || !*ud) {
    luaL_error(L, "Expected Manifold object");
  }
  return *ud;
}

// Helper to push Manifold userdata
static void push_manifold(lua_State *L, ManifoldManifold *m) {
  ManifoldManifold **ud =
      (ManifoldManifold **)lua_newuserdata(L, sizeof(ManifoldManifold *));
  *ud = m;
  luaL_getmetatable(L, "Manifold");
  lua_setmetatable(L, -2);
}

// Cube constructor
static int l_cube(lua_State *L) {
  double x = luaL_checknumber(L, 1);
  double y = luaL_checknumber(L, 2);
  double z = luaL_checknumber(L, 3);
  int center = lua_toboolean(L, 4);

  ManifoldManifold *m = manifold_cube(alloc_manifold(), x, y, z, center);
  push_manifold(L, m);
  return 1;
}

// Cylinder constructor
static int l_cylinder(lua_State *L) {
  double h = luaL_checknumber(L, 1);
  double r_low = luaL_checknumber(L, 2);
  double r_high = luaL_checknumber(L, 3);
  int segs = luaL_optint(L, 4, 32);
  int center = lua_toboolean(L, 5);

  ManifoldManifold *m =
      manifold_cylinder(alloc_manifold(), h, r_low, r_high, segs, center);
  push_manifold(L, m);
  return 1;
}

// Sphere constructor
static int l_sphere(lua_State *L) {
  double r = luaL_checknumber(L, 1);
  int segs = luaL_optint(L, 2, 32);

  ManifoldManifold *m = manifold_sphere(alloc_manifold(), r, segs);
  push_manifold(L, m);
  return 1;
}

// Boolean Union
static int l_union(lua_State *L) {
  ManifoldManifold *a = check_manifold(L, 1);
  ManifoldManifold *b = check_manifold(L, 2);
  ManifoldManifold *res = manifold_union(alloc_manifold(), a, b);
  push_manifold(L, res);
  return 1;
}

// Boolean Difference
static int l_difference(lua_State *L) {
  ManifoldManifold *a = check_manifold(L, 1);
  ManifoldManifold *b = check_manifold(L, 2);
  ManifoldManifold *res = manifold_difference(alloc_manifold(), a, b);
  push_manifold(L, res);
  return 1;
}

// Boolean Intersection
static int l_intersection(lua_State *L) {
  ManifoldManifold *a = check_manifold(L, 1);
  ManifoldManifold *b = check_manifold(L, 2);
  ManifoldManifold *res = manifold_intersection(alloc_manifold(), a, b);
  push_manifold(L, res);
  return 1;
}

// Translate
static int l_translate(lua_State *L) {
  ManifoldManifold *m = check_manifold(L, 1);
  double x = luaL_checknumber(L, 2);
  double y = luaL_checknumber(L, 3);
  double z = luaL_checknumber(L, 4);

  ManifoldManifold *res = manifold_translate(alloc_manifold(), m, x, y, z);
  push_manifold(L, res);
  return 1;
}

// Rotate
static int l_rotate(lua_State *L) {
  ManifoldManifold *m = check_manifold(L, 1);
  double x = luaL_checknumber(L, 2);
  double y = luaL_checknumber(L, 3);
  double z = luaL_checknumber(L, 4);

  ManifoldManifold *res = manifold_rotate(alloc_manifold(), m, x, y, z);
  push_manifold(L, res);
  return 1;
}

// Scale
static int l_scale(lua_State *L) {
  ManifoldManifold *m = check_manifold(L, 1);
  double x = luaL_checknumber(L, 2);
  double y = luaL_checknumber(L, 3);
  double z = luaL_checknumber(L, 4);

  ManifoldManifold *res = manifold_scale(alloc_manifold(), m, x, y, z);
  push_manifold(L, res);
  return 1;
}

// Export to mesh data
static int l_to_mesh(lua_State *L) {
  ManifoldManifold *m = check_manifold(L, 1);

  // Allocate mesh memory
  ManifoldMeshGL *mesh = manifold_get_meshgl(malloc(manifold_meshgl_size()), m);

  if (!mesh) {
    lua_pushnil(L);
    return 1;
  }

  size_t n_verts = manifold_meshgl_num_vert(mesh);
  size_t n_tris = manifold_meshgl_num_tri(mesh);
  size_t n_props = manifold_meshgl_num_prop(mesh); // Expected 3 for x,y,z

  size_t verts_len = manifold_meshgl_vert_properties_length(mesh);
  float *verts_copy = (float *)malloc(verts_len * sizeof(float));
  manifold_meshgl_vert_properties(verts_copy, mesh);

  size_t tris_len = manifold_meshgl_tri_length(
      mesh); // This returns total indices (n_tris * 3)
  uint32_t *tris_copy = (uint32_t *)malloc(tris_len * sizeof(uint32_t));
  manifold_meshgl_tri_verts(tris_copy, mesh);

  lua_newtable(L); // Result table

  // Vertices
  lua_newtable(L);
  for (size_t i = 0; i < n_verts; ++i) {
    lua_newtable(L);
    lua_pushnumber(L, verts_copy[i * n_props + 0]);
    lua_rawseti(L, -2, 1);
    lua_pushnumber(L, verts_copy[i * n_props + 1]);
    lua_rawseti(L, -2, 2);
    lua_pushnumber(L, verts_copy[i * n_props + 2]);
    lua_rawseti(L, -2, 3);
    lua_rawseti(L, -2, i + 1);
  }
  lua_setfield(L, -2, "verts");

  // Faces (Tris), 1-based indices for Lua
  lua_newtable(L);
  for (size_t i = 0; i < n_tris; ++i) {
    lua_newtable(L);
    lua_pushnumber(L, tris_copy[i * 3 + 0] + 1);
    lua_rawseti(L, -2, 1);
    lua_pushnumber(L, tris_copy[i * 3 + 1] + 1);
    lua_rawseti(L, -2, 2);
    lua_pushnumber(L, tris_copy[i * 3 + 2] + 1);
    lua_rawseti(L, -2, 3);
    lua_rawseti(L, -2, i + 1);
  }
  lua_setfield(L, -2, "faces");

  free(verts_copy);
  free(tris_copy);

  // Cleanup mesh
  manifold_destruct_meshgl(mesh);
  free(mesh);

  return 1;
}

// Garbage collection
static int l_gc(lua_State *L) {
  ManifoldManifold **ud =
      (ManifoldManifold **)luaL_checkudata(L, 1, "Manifold");
  if (ud && *ud) {
    free_manifold_wrapper(*ud);
    *ud = NULL;
  }
  return 0;
}

// Registration
static const struct luaL_Reg csg_lib[] = {{"cube", l_cube},
                                          {"cylinder", l_cylinder},
                                          {"sphere", l_sphere},
                                          {"union", l_union},
                                          {"difference", l_difference},
                                          {"intersection", l_intersection},
                                          {"translate", l_translate},
                                          {"rotate", l_rotate},
                                          {"scale", l_scale},
                                          {"to_mesh", l_to_mesh},
                                          {NULL, NULL}};

extern "C" int luaopen_csg_manifold(lua_State *L) {
  luaL_newmetatable(L, "Manifold");
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");
  lua_pushcfunction(L, l_gc);
  lua_setfield(L, -2, "__gc");

  luaL_register(L, "csg_manifold", csg_lib);
  return 1;
}
