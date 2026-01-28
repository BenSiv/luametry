
step = {}

-- Helper functions attached to step to avoid global pollution if possible
step.fmt_float = function(n)
    return string.format("%.6E", n)
end

step.fmt_point = function(x, y, z)
    return string.format("(%s,%s,%s)", step.fmt_float(x), step.fmt_float(y), step.fmt_float(z))
end

function step.encode_mesh(mesh, name)
    name = name or "exported_model"
    step_output = {}
    step_id_counter = 1
    
    step_new_id = function()
        sc_id = step_id_counter
        step_id_counter = step_id_counter + 1
        return sc_id
    end
    
    step_push = function(str)
        table.insert(step_output, str)
    end
    
    step_push_entity = function(id, def)
        step_push(string.format("#%d=%s;", id, def))
    end

    -- Header
    step_push("ISO-10303-21;")
    step_push("HEADER;")
    step_push(string.format("FILE_DESCRIPTION(('STEP AP214'),'2;1');"))
    step_push(string.format("FILE_NAME('%s.stp','2023-01-01',('Author'),(''),'','','');", name))
    step_push("FILE_SCHEMA(('AUTOMOTIVE_DESIGN { 1 0 10303 214 1 1 1 1 }'));")
    step_push("ENDSEC;")
    step_push("DATA;")

    -- 1. Create Cartesian Points and Vertex Points for all vertices
    step_vertex_ids = {} -- map vert_index -> vertex_point_id
    step_cartesian_point_ids = {} -- map vert_index -> cartesian_point_id
    
    for i, v in ipairs(mesh.verts) do
        cp_id = step_new_id()
        step_push_entity(cp_id, string.format("CARTESIAN_POINT('',%s)", step.fmt_point(v[1], v[2], v[3])))
        step_cartesian_point_ids[i] = cp_id
        
        vp_id = step_new_id()
        step_push_entity(vp_id, string.format("VERTEX_POINT('',#%d)", cp_id))
        step_vertex_ids[i] = vp_id
    end

    -- 2. Create Edges
    step_edge_map = {} 
    
    step_get_or_create_edge = function(v1_idx, v2_idx)
        u, v = v1_idx, v2_idx
        u = math.floor(u)
        v = math.floor(v)
        min_val = math.min(u, v)
        max_val = math.max(u, v)
        u = min_val
        v = max_val
        edge_key = string.format("%d:%d", u, v)
        
        if step_edge_map[edge_key] != nil then return step_edge_map[edge_key] end
        
        -- Create Line Geometry
        p1 = mesh.verts[u]
        p2 = mesh.verts[v]
        doc_x = p2[1] - p1[1]
        doc_y = p2[2] - p1[2]
        doc_z = p2[3] - p1[3]
        
        edge_len = math.sqrt(doc_x^2 + doc_y^2 + doc_z^2)
        vec_dir_id = step_new_id()
        step_push_entity(vec_dir_id, string.format("DIRECTION('',%s)", step.fmt_point(doc_x/edge_len, doc_y/edge_len, doc_z/edge_len)))
        
        vec_id = step_new_id()
        step_push_entity(vec_id, string.format("VECTOR('',#%d,%s)", vec_dir_id, step.fmt_float(edge_len)))
        
        line_id = step_new_id()
        step_push_entity(line_id, string.format("LINE('',#%d,#%d)", step_cartesian_point_ids[u], vec_id))
        
        -- Create Edge Curve
        edge_id = step_new_id()
        step_push_entity(edge_id, string.format("EDGE_CURVE('',#%d,#%d,#%d,.T.)", step_vertex_ids[u], step_vertex_ids[v], line_id))
        
        step_edge_map[edge_key] = {id=edge_id, u=u, v=v}
        return step_edge_map[edge_key]
    end

    step_face_ids = {}
    
    for _, face in ipairs(mesh.faces) do
        -- Face is v1, v2, v3
        v1, v2, v3 = face[1], face[2], face[3]
        
        -- Create edges
        e1 = step_get_or_create_edge(v1, v2)
        e2 = step_get_or_create_edge(v2, v3)
        e3 = step_get_or_create_edge(v3, v1)
        
        -- Create Oriented Edges
        step_make_oriented_edge = function(edge_def, start_v, end_v)
            orientation = ".T."
            if start_v == edge_def.u then orientation = ".T." else orientation = ".F." end
            
            oe_id = step_new_id()
            step_push_entity(oe_id, string.format("ORIENTED_EDGE('',*,*,#%d,%s)", edge_def.id, orientation))
            return oe_id
        end
        
        oe1 = step_make_oriented_edge(e1, v1, v2)
        oe2 = step_make_oriented_edge(e2, v2, v3)
        oe3 = step_make_oriented_edge(e3, v3, v1)
        
        -- Edge Loop
        loop_id = step_new_id()
        step_push_entity(loop_id, string.format("EDGE_LOOP('',(#%d,#%d,#%d))", oe1, oe2, oe3))
        
        -- Face Bound
        bound_id = step_new_id()
        step_push_entity(bound_id, string.format("FACE_BOUND('',#%d,.T.)", loop_id))
        
        -- Plane
        -- Calculate Normal
        p1, p2, p3 = mesh.verts[v1], mesh.verts[v2], mesh.verts[v3]
        ux, uy, uz = p2[1]-p1[1], p2[2]-p1[2], p2[3]-p1[3]
        vx, vy, vz = p3[1]-p1[1], p3[2]-p1[2], p3[3]-p1[3]
        nx, ny, nz = uy*vz - uz*vy, uz*vx - ux*vz, ux*vy - uy*vx
        len = math.sqrt(nx*nx + ny*ny + nz*nz)
        if len > 0 then nx=nx/len; ny=ny/len; nz=nz/len else nx=0;ny=0;nz=1 end
        
        axis_dir_id = step_new_id()
        step_push_entity(axis_dir_id, string.format("DIRECTION('',%s)", step.fmt_point(nx, ny, nz)))
        
        -- Compute orthogonal vector
        gx, gy, gz = 1, 0, 0
        if math.abs(nx) > 0.9 then gx=0; gy=1; end
        
        ox = ny*gz - nz*gy
        oy = nz*gx - nx*gz
        oz = nx*gy - ny*gx
        olen = math.sqrt(ox*ox + oy*oy + oz*oz)
        if olen > 0 then ox=ox/olen; oy=oy/olen; oz=oz/olen end
        
        axis_ref_dir_id = step_new_id()
        step_push_entity(axis_ref_dir_id, string.format("DIRECTION('',%s)", step.fmt_point(ox, oy, oz)))
        
        -- Plane placement
        placement_id = step_new_id()
        step_push_entity(placement_id, string.format("AXIS2_PLACEMENT_3D('',#%d,#%d,#%d)", step_cartesian_point_ids[v1], axis_dir_id, axis_ref_dir_id))
        
        plane_id = step_new_id()
        step_push_entity(plane_id, string.format("PLANE('',#%d)", placement_id))
        
        -- Advanced Face
        face_id = step_new_id()
        step_push_entity(face_id, string.format("ADVANCED_FACE('',(#%d),#%d,.T.)", bound_id, plane_id))
        
        table.insert(step_face_ids, face_id)
    end
    
    -- Closed Shell
    shell_id = step_new_id()
    face_str_tbl = {}
    current_line = ""
    for _, fid in ipairs(step_face_ids) do 
        item = "#"..fid
        if #current_line + #item > 70 then
             table.insert(face_str_tbl, current_line)
             current_line = item
        else
             if current_line == "" then
                 current_line = item
             else
                 current_line = current_line .. "," .. item
             end
        end
    end
    if current_line != "" then table.insert(face_str_tbl, current_line) end
    
    -- Construct CLOSED_SHELL with newlines
    shell_def = "CLOSED_SHELL('',(" .. table.concat(face_str_tbl, ",\n") .. "))"
    step_push_entity(shell_id, shell_def)
    
    -- Manifold Solid Brep
    solid_id = step_new_id()
    step_push_entity(solid_id, string.format("MANIFOLD_SOLID_BREP('%s',#%d)", name, shell_id))

    -- PRODUCT STRUCTURE WRAPPER
    app_proto_id = step_new_id()
    step_push_entity(app_proto_id, "APPLICATION_PROTOCOL_DEFINITION('international standard','automotive_design',2000,#"..app_proto_id..")")
    
    prod_ctx_id = step_new_id()
    step_push_entity(prod_ctx_id, "PRODUCT_CONTEXT('',#"..app_proto_id..",'mechanical')")
    
    prod_id = step_new_id()
    step_push_entity(prod_id, string.format("PRODUCT('%s','%s','',(#%d))", name, name, prod_ctx_id))
    
    pdf_id = step_new_id()
    step_push_entity(pdf_id, string.format("PRODUCT_DEFINITION_FORMATION('','',#%d)", prod_id))
    
    pd_id = step_new_id()
    step_push_entity(pd_id, string.format("PRODUCT_DEFINITION('design','',#%d,#%d)", pdf_id, prod_ctx_id))
    
    pds_id = step_new_id()
    step_push_entity(pds_id, string.format("PRODUCT_DEFINITION_SHAPE('','',#%d)", pd_id))
    
    sdr_id = step_new_id()
    -- This links the Product (pds_id) to the Geometry (mssr_id)
    -- We need a SHAPE_REPRESENTATION (or subtypes)
    
    geom_ctx_id = step_new_id()
    step_push_entity(geom_ctx_id, "GEOMETRIC_REPRESENTATION_CONTEXT(3)")
    
    mssr_id = step_new_id()
    -- MANIFOLD_SURFACE_SHAPE_REPRESENTATION(name, items, context)
    -- items = list of solid_id
    step_push_entity(mssr_id, string.format("MANIFOLD_SURFACE_SHAPE_REPRESENTATION('',(#%d),#%d)", solid_id, geom_ctx_id))
    
    step_push_entity(sdr_id, string.format("SHAPE_DEFINITION_REPRESENTATION(#%d,#%d)", pds_id, mssr_id))

    step_push("ENDSEC;")
    step_push("END-ISO-10303-21;")
    
    return table.concat(step_output, "\n")
end

return step
