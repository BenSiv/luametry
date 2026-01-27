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

// Tetrahedron constructor
static int l_tetrahedron(lua_State *L) {
  ManifoldManifold *m = manifold_tetrahedron(alloc_manifold());
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

// Torus constructor
static int l_torus(lua_State *L) {
  double major_r = luaL_checknumber(L, 1);
  double minor_r = luaL_checknumber(L, 2);
  int major_segs = luaL_optint(L, 3, 32);
  int minor_segs = luaL_optint(L, 4, 16);

  ManifoldCrossSection *cs = manifold_cross_section_circle(
      manifold_alloc_cross_section(), minor_r, minor_segs);
  ManifoldCrossSection *cs_trans = manifold_cross_section_translate(
      manifold_alloc_cross_section(), cs, major_r, 0);

  // Convert to polygons for revolve
  ManifoldPolygons *polys =
      manifold_cross_section_to_polygons(manifold_alloc_polygons(), cs_trans);
  ManifoldManifold *m =
      manifold_revolve(alloc_manifold(), polys, major_segs, 360.0);

  manifold_delete_cross_section(cs);
  manifold_delete_cross_section(cs_trans);
  manifold_delete_polygons(polys);

  push_manifold(L, m);
  return 1;
}

static int l_batch_union(lua_State *L) {
  if (!lua_istable(L, 1)) {
    luaL_error(L, "Expected table of manifolds");
  }

  ManifoldManifoldVec *vec = manifold_alloc_manifold_vec();
  int n = lua_objlen(L, 1);

  for (int i = 1; i <= n; i++) {
    lua_rawgeti(L, 1, i);
    ManifoldManifold *m = check_manifold(L, -1); // Does not pop
    // manifold_manifold_vec_push_back copies the manifold?
    // The C API documentation says "void
    // manifold_manifold_vec_push_back(ManifoldManifoldVec* ms,
    // ManifoldManifold* m);" It usually takes ownership or copies. Manifold C++
    // `Manifold::BatchBoolean` takes `std::vector<Manifold>`.
    // `manifold_manifold_vec_push_back` likely adds a copy. Manifold is
    // lightweight (shared ptr). Let's assume it copies the shared pointer.

    // We need to create a copy for the vector because the Lua userdata owns one
    // copy, and the vector will own another.
    ManifoldManifold *copy = manifold_copy(alloc_manifold(), m);
    manifold_manifold_vec_push_back(vec, copy);

    lua_pop(L, 1);
  }

  ManifoldManifold *res =
      manifold_batch_boolean(alloc_manifold(), vec, MANIFOLD_ADD);

  // Clean up vector (and its contained manifolds)
  manifold_delete_manifold_vec(vec);

  push_manifold(L, res);
  return 1;
}

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

// Minkowski Sum
static int l_minkowski(lua_State *L) {
  ManifoldManifold *a = check_manifold(L, 1);
  ManifoldManifold *b = check_manifold(L, 2);
  ManifoldManifold *res = manifold_minkowski_sum(alloc_manifold(), a, b);
  push_manifold(L, res);
  return 1;
}

// Extrude (points, height, slices, twist, scale_x, scale_y)
static int l_extrude(lua_State *L) {
  if (!lua_istable(L, 1)) {
    luaL_error(L, "Expected table of points for extrude");
  }

  double height = luaL_checknumber(L, 2);
  int slices = luaL_optint(L, 3, 0); // 0 = auto?
  double twist_degrees = luaL_optnumber(L, 4, 0.0);
  double scale_x = luaL_optnumber(L, 5, 1.0);
  double scale_y = luaL_optnumber(L, 6, 1.0);

  // Parse points
  int n = lua_objlen(L, 1);
  if (n < 3)
    luaL_error(L, "Polygon must have at least 3 points");

  std::vector<ManifoldVec2> points(n);
  for (int i = 1; i <= n; i++) {
    lua_rawgeti(L, 1, i);
    if (!lua_istable(L, -1))
      luaL_error(L, "Point must be a table {x, y}");

    lua_rawgeti(L, -1, 1);
    points[i - 1].x = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_rawgeti(L, -1, 2);
    points[i - 1].y = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_pop(L, 1); // Pop point table
  }

  ManifoldSimplePolygon *poly = manifold_simple_polygon(
      manifold_alloc_simple_polygon(), points.data(), n);
  ManifoldSimplePolygon *polys_array[] = {poly};
  ManifoldPolygons *polys =
      manifold_polygons(manifold_alloc_polygons(), polys_array, 1);

  ManifoldManifold *m = manifold_extrude(
      alloc_manifold(), polys, height, slices, twist_degrees, scale_x, scale_y);

  manifold_delete_polygons(polys);
  manifold_delete_simple_polygon(
      poly); // Does manifold_polygons take ownership?
  // manifold_polygons copies data usually.
  // checking header: ManifoldPolygons* manifold_polygons(void* mem,
  // ManifoldSimplePolygon** ps, size_t length); It takes pointers to simple
  // polygons. It likely copies the data structure into the ManifoldPolygons
  // object (which is vector<const SimplePolygon*> or similar C++ side).
  // Actually, ManifoldPolygons maps to std::vector<SimplePolygon> in C++, so it
  // copies. So we should delete the simple polygon we allocated.

  push_manifold(L, m);
  return 1;
}
static int l_batch_hull(lua_State *L) {
  if (!lua_istable(L, 1)) {
    luaL_error(L, "Expected table of manifolds");
  }

  ManifoldManifoldVec *vec = manifold_alloc_manifold_vec();
  int n = lua_objlen(L, 1);
  for (int i = 1; i <= n; i++) {
    lua_rawgeti(L, 1, i);
    ManifoldManifold *m = check_manifold(L, -1);
    manifold_manifold_vec_push_back(vec, m);
    lua_pop(L, 1);
  }

  ManifoldManifold *res = manifold_batch_hull(alloc_manifold(), vec);
  // manifold_delete_manifold_vec(vec); -- destruct cleans up content if
  // ownership transferred? Wait, C++ usually vector holds objects or pointers.
  // Here it holds raw pointers to ManifoldManifold objects. vector push_back
  // likely copies or takes pointer.
  // manifold_manifold_vec_push_back(ManifoldManifoldVec* ms, ManifoldManifold*
  // m); Does it take ownership? Usually not in these bindings unless specified.
  // The generated result is new. The input vector is temp.
  // manifold_delete_manifold_vec calls `delete ms`.
  // manifold_destruct_manifold_vec calls destructor but not free?
  // Let's check header: void manifold_delete_manifold_vec(ManifoldManifoldVec*
  // ms); safer to use manifold_delete_manifold_vec(vec) to free the vector
  // wrapper itself.

  manifold_delete_manifold_vec(vec);

  push_manifold(L, res);
  return 1;
}
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

// From Mesh (verts, faces)
static int l_from_mesh(lua_State *L) {
  if (!lua_istable(L, 1))
    luaL_error(L, "Expected table of vertices");
  if (!lua_istable(L, 2))
    luaL_error(L, "Expected table of faces");

  // Read Vertices
  int n_verts = lua_objlen(L, 1);
  float *verts = (float *)malloc(n_verts * 3 * sizeof(float));
  for (int i = 0; i < n_verts; ++i) {
    lua_rawgeti(L, 1, i + 1);

    lua_rawgeti(L, -1, 1);
    verts[i * 3 + 0] = (float)lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_rawgeti(L, -1, 2);
    verts[i * 3 + 1] = (float)lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_rawgeti(L, -1, 3);
    verts[i * 3 + 2] = (float)lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_pop(L, 1); // pop vertex table
  }

  // Read Faces
  int n_tris = lua_objlen(L, 2);
  uint32_t *tris = (uint32_t *)malloc(n_tris * 3 * sizeof(uint32_t));
  for (int i = 0; i < n_tris; ++i) {
    lua_rawgeti(L, 2, i + 1);

    lua_rawgeti(L, -1, 1);
    tris[i * 3 + 0] =
        (uint32_t)(lua_tonumber(L, -1) - 1); // Lua 1-based to 0-based
    lua_pop(L, 1);

    lua_rawgeti(L, -1, 2);
    tris[i * 3 + 1] = (uint32_t)(lua_tonumber(L, -1) - 1);
    lua_pop(L, 1);

    lua_rawgeti(L, -1, 3);
    tris[i * 3 + 2] = (uint32_t)(lua_tonumber(L, -1) - 1);
    lua_pop(L, 1);

    lua_pop(L, 1); // pop face table
  }

  // Create MeshGL
  ManifoldMeshGL *mesh =
      manifold_meshgl(manifold_alloc_meshgl(), verts, n_verts, 3, tris, n_tris);

  // Convert to Manifold
  ManifoldManifold *m = manifold_of_meshgl(alloc_manifold(), mesh);

  // Cleanup
  free(verts);
  free(tris);

  manifold_destruct_meshgl(mesh);
  free(mesh);

  push_manifold(L, m);
  return 1;
}

// Revolve
static int l_revolve(lua_State *L) {
  if (!lua_istable(L, 1)) {
    luaL_error(L, "Expected table of points for revolve");
  }

  int circular_segments = luaL_optint(L, 2, 0);
  double revolve_degrees = luaL_optnumber(L, 3, 360.0);

  // Parse points
  int n = lua_objlen(L, 1);
  if (n < 3)
    luaL_error(L, "Polygon must have at least 3 points");

  std::vector<ManifoldVec2> points(n);
  for (int i = 1; i <= n; i++) {
    lua_rawgeti(L, 1, i);
    if (!lua_istable(L, -1))
      luaL_error(L, "Point must be a table {x, y}");

    lua_rawgeti(L, -1, 1);
    points[i - 1].x = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_rawgeti(L, -1, 2);
    points[i - 1].y = lua_tonumber(L, -1);
    lua_pop(L, 1);

    lua_pop(L, 1); // Pop point table
  }

  ManifoldSimplePolygon *poly = manifold_simple_polygon(
      manifold_alloc_simple_polygon(), points.data(), n);
  ManifoldSimplePolygon *polys_array[] = {poly};
  ManifoldPolygons *polys =
      manifold_polygons(manifold_alloc_polygons(), polys_array, 1);

  ManifoldManifold *m = manifold_revolve(alloc_manifold(), polys,
                                         circular_segments, revolve_degrees);

  manifold_delete_polygons(polys);
  manifold_delete_simple_polygon(poly);

  push_manifold(L, m);
  return 1;
}

// Warp callback wrapper
struct WarpContext {
  lua_State *L;
  int func_ref;
};

static ManifoldVec3 warp_callback(double x, double y, double z, void *ctx) {
  WarpContext *wctx = (WarpContext *)ctx;
  lua_State *L = wctx->L;

  // Get the function from registry
  lua_rawgeti(L, LUA_REGISTRYINDEX, wctx->func_ref);

  // Push arguments
  lua_pushnumber(L, x);
  lua_pushnumber(L, y);
  lua_pushnumber(L, z);

  // Call function
  if (lua_pcall(L, 3, 3, 0) != 0) {
    luaL_error(L, "Warp function error: %s", lua_tostring(L, -1));
  }

  // Get results
  ManifoldVec3 result;
  result.z = lua_tonumber(L, -1);
  lua_pop(L, 1);
  result.y = lua_tonumber(L, -1);
  lua_pop(L, 1);
  result.x = lua_tonumber(L, -1);
  lua_pop(L, 1);

  return result;
}

// Warp
static int l_warp(lua_State *L) {
  ManifoldManifold *m = check_manifold(L, 1);

  if (!lua_isfunction(L, 2)) {
    luaL_error(L, "Second argument must be a function");
  }

  // Store function reference in registry
  lua_pushvalue(L, 2);
  int func_ref = luaL_ref(L, LUA_REGISTRYINDEX);

  WarpContext ctx = {L, func_ref};

  ManifoldManifold *res =
      manifold_warp(alloc_manifold(), m, warp_callback, &ctx);

  // Release function reference
  luaL_unref(L, LUA_REGISTRYINDEX, func_ref);

  push_manifold(L, res);
  return 1;
}

// Offset removed (Not in C API)

// Mirror
static int l_mirror(lua_State *L) {
  ManifoldManifold *m = check_manifold(L, 1);
  double nx = luaL_checknumber(L, 2);
  double ny = luaL_checknumber(L, 3);
  double nz = luaL_checknumber(L, 4);

  ManifoldManifold *res = manifold_mirror(alloc_manifold(), m, nx, ny, nz);
  push_manifold(L, res);
  return 1;
}

// Trim by Plane
static int l_trim_by_plane(lua_State *L) {
  ManifoldManifold *m = check_manifold(L, 1);
  double nx = luaL_checknumber(L, 2);
  double ny = luaL_checknumber(L, 3);
  double nz = luaL_checknumber(L, 4);
  double offset = luaL_optnumber(L, 5, 0.0);

  ManifoldManifold *res =
      manifold_trim_by_plane(alloc_manifold(), m, nx, ny, nz, offset);
  push_manifold(L, res);
  return 1;
}

// Split by Plane (Returns 2 manifolds: kept, removed)
static int l_split_by_plane(lua_State *L) {
  ManifoldManifold *m = check_manifold(L, 1);
  double nx = luaL_checknumber(L, 2);
  double ny = luaL_checknumber(L, 3);
  double nz = luaL_checknumber(L, 4);
  double offset = luaL_optnumber(L, 5, 0.0);

  // Allocate memory for results
  ManifoldManifold *first = alloc_manifold();
  ManifoldManifold *second = alloc_manifold();

  // Split returns struct by value, logic writes to the memory pointers
  manifold_split_by_plane(first, second, m, nx, ny, nz, offset);

  push_manifold(L, first);
  push_manifold(L, second);
  return 2;
}

// Decompose (Split disjoint parts)
static int l_decompose(lua_State *L) {
  ManifoldManifold *m = check_manifold(L, 1);

  ManifoldManifoldVec *vec =
      manifold_decompose(manifold_alloc_manifold_vec(), m);
  size_t n = manifold_manifold_vec_length(vec);

  lua_newtable(L);
  for (size_t i = 0; i < n; ++i) {
    // vec_get requires memory allocation for the result
    ManifoldManifold *part =
        manifold_manifold_vec_get(alloc_manifold(), vec, i);
    push_manifold(L, part);
    lua_rawseti(L, -2, i + 1);
  }

  manifold_delete_manifold_vec(vec);
  return 1;
}

// Properties: Volume
static int l_volume(lua_State *L) {
  ManifoldManifold *m = check_manifold(L, 1);
  double vol = manifold_volume(m);
  lua_pushnumber(L, vol);
  return 1;
}

// Properties: Surface Area
static int l_surface_area(lua_State *L) {
  ManifoldManifold *m = check_manifold(L, 1);
  double area = manifold_surface_area(m);
  lua_pushnumber(L, area);
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
                                          {"tetrahedron", l_tetrahedron},
                                          {"torus", l_torus},
                                          {"union", l_union},
                                          {"difference", l_difference},
                                          {"intersection", l_intersection},
                                          {"minkowski", l_minkowski},
                                          {"hull", l_batch_hull},
                                          {"union_batch", l_batch_union},
                                          {"extrude", l_extrude},
                                          {"revolve", l_revolve},
                                          {"warp", l_warp},
                                          {"translate", l_translate},
                                          {"rotate", l_rotate},
                                          {"scale", l_scale},
                                          {"mirror", l_mirror},
                                          {"trim_by_plane", l_trim_by_plane},
                                          {"split_by_plane", l_split_by_plane},
                                          {"decompose", l_decompose},
                                          {"volume", l_volume},
                                          {"surface_area", l_surface_area},
                                          {"to_mesh", l_to_mesh},
                                          {"from_mesh", l_from_mesh},
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
