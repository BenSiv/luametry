-- reparameterize.lua
csg = require("csg.manifold")
re = {}

-- Trick for luam: use parameters as locals
function re.get_bounding_box(mesh_bb, min_x_bb, min_y_bb, min_z_bb, max_x_bb, max_y_bb, max_z_bb)
    if mesh_bb == nil or mesh_bb.verts == nil or #mesh_bb.verts == 0 then return nil end
    min_x_bb = math.huge min_y_bb = math.huge min_z_bb = math.huge
    max_x_bb = -math.huge max_y_bb = -math.huge max_z_bb = -math.huge
    for _, v_bb_it in ipairs(mesh_bb.verts) do
        min_x_bb = math.min(min_x_bb, v_bb_it[1]) min_y_bb = math.min(min_y_bb, v_bb_it[2]) min_z_bb = math.min(min_z_bb, v_bb_it[3])
        max_x_bb = math.max(max_x_bb, v_bb_it[1]) max_y_bb = math.max(max_y_bb, v_bb_it[2]) max_z_bb = math.max(max_z_bb, v_bb_it[3])
    end
    return {
        min = {min_x_bb, min_y_bb, min_z_bb},
        max = {max_x_bb, max_y_bb, max_z_bb},
        size = {max_x_bb - min_x_bb, max_y_bb - min_y_bb, max_z_bb - min_z_bb},
        center = {(min_x_bb + max_x_bb) / 2, (min_y_bb + max_y_bb) / 2, (min_z_bb + max_z_bb) / 2}
    }
end

function re.analyze_primitive(man_p, depth_p, tolerance_p, mesh_d_p, vol_p, bbox_p, bbox_vol_p, density_p, max_dim_p, min_dim_p, r_sph_p, sphere_vol_p, h_dims_p, area1_p, area2_p, r1_p, r2_p, cone_vol_p, r_cyl_p, cyl_vol_p, rot_c_p)
    depth_p = depth_p or 0 tolerance_p = tolerance_p or 0.1
    if depth_p > 10 then 
        mesh_d_p = csg.to_mesh(man_p)
        return { type = "mesh", verts = #mesh_d_p.verts, faces = #mesh_d_p.faces, manifold = man_p } 
    end
    mesh_d_p = csg.to_mesh(man_p)
    if mesh_d_p == nil or #mesh_d_p.verts == 0 then return nil end
    vol_p = csg.volume(man_p)
    bbox_p = re.get_bounding_box(mesh_d_p)
    if bbox_p == nil or vol_p < 0.001 then return nil end
    bbox_vol_p = bbox_p.size[1] * bbox_p.size[2] * bbox_p.size[3]
    density_p = vol_p / bbox_vol_p
    
    if bbox_vol_p > 0 and math.abs(vol_p - bbox_vol_p) < tolerance_p * bbox_vol_p then
        return { type = "cube", size = bbox_p.size, translate = bbox_p.min }
    end
    max_dim_p = math.max(bbox_p.size[1], bbox_p.size[2], bbox_p.size[3])
    min_dim_p = math.min(bbox_p.size[1], bbox_p.size[2], bbox_p.size[3])
    if max_dim_p > 0 and (max_dim_p - min_dim_p) / max_dim_p < tolerance_p * 1.5 then
        r_sph_p = max_dim_p / 2
        sphere_vol_p = (4/3) * math.pi * (r_sph_p^3)
        if math.abs(vol_p - sphere_vol_p) < tolerance_p * 2 * vol_p then
            return { type = "sphere", r = r_sph_p, translate = bbox_p.center }
        end
    end
    h_dims_p = {
        {bbox_p.size[1], bbox_p.size[2], bbox_p.size[3], 0, 0, 1}, -- Z
        {bbox_p.size[1], bbox_p.size[3], bbox_p.size[2], 0, 1, 0}, -- Y
        {bbox_p.size[2], bbox_p.size[3], bbox_p.size[1], 1, 0, 0}  -- X
    }
    for _, d_it_p in ipairs(h_dims_p) do
        if d_it_p[3] > 0 and d_it_p[1] > 0 and d_it_p[2] > 0 then
            if d_it_p[6] == 1 then
                area1_p = csg.slice(man_p, bbox_p.min[3] + 0.01)
                area2_p = csg.slice(man_p, bbox_p.max[3] - 0.01)
                r1_p = math.sqrt(area1_p / math.pi)
                r2_p = math.sqrt(area2_p / math.pi)
                cone_vol_p = (1/3) * math.pi * d_it_p[3] * (r1_p^2 + r1_p*r2_p + r2_p^2)
                if math.abs(vol_p - cone_vol_p) < tolerance_p * 2.5 * vol_p then
                    return { type = "cylinder", r1 = r1_p, r2 = r2_p, h = d_it_p[3], translate = bbox_p.center, rotate = {0, 0, 0} }
                end
            end
            if math.abs(d_it_p[1] - d_it_p[2]) / (d_it_p[1] + 0.001) < tolerance_p * 3 then
                 r_cyl_p = (d_it_p[1] + d_it_p[2]) / 4
                 cyl_vol_p = math.pi * (r_cyl_p^2) * d_it_p[3]
                 if math.abs(vol_p - cyl_vol_p) < tolerance_p * 3 * vol_p then
                    rot_c_p = {0, 0, 0}
                    if d_it_p[5] == 1 then rot_c_p = {90, 0, 0} end
                    if d_it_p[4] == 1 then rot_c_p = {0, 90, 0} end
                    return { type = "cylinder", r = r_cyl_p, h = d_it_p[3], translate = bbox_p.center, rotate = rot_c_p }
                 end
            end
        end
    end
    return { type = "mesh", verts = #mesh_d_p.verts, faces = #mesh_d_p.faces, bbox = bbox_p, manifold = man_p, density = density_p, vol = vol_p }
end

function re.detect_patterns(parts_pt, flat_parts_pt, groups_pt, new_parts_pt, found_g_pt, ref_pt, match_pt, used_p_pt, cx_pt, cy_pt, cz_pt, p1_pos_pt, d_p_pt, is_rot_pt, angles_pt, p_l_pos, chk_p_pos, d_chk_p, step_pt)
    if #parts_pt < 2 then return parts_pt end
    -- Flatten unions
    flat_parts_pt = {}
    for _, p_fl_it in ipairs(parts_pt) do
        if p_fl_it.type == "union" then
            for _, sub_p in ipairs(p_fl_it.parts) do table.insert(flat_parts_pt, sub_p) end
        else
            table.insert(flat_parts_pt, p_fl_it)
        end
    end
    if #flat_parts_pt < 3 then return flat_parts_pt end
    
    groups_pt = {}
    for _, p_it_pt in ipairs(flat_parts_pt) do
        found_g_pt = false
        for _, g_it_pt in ipairs(groups_pt) do
            ref_pt = g_it_pt[1] match_pt = false
            if ref_pt.type == p_it_pt.type then
                match_pt = true
                if p_it_pt.type == "cylinder" then
                    if (p_it_pt.r != nil and ref_pt.r != nil and math.abs(p_it_pt.r - ref_pt.r) / (ref_pt.r + 0.001) > 0.1) or
                       (p_it_pt.r1 != nil and ref_pt.r1 != nil and math.abs(p_it_pt.r1 - ref_pt.r1) / (ref_pt.r1 + 0.001) > 0.1) or
                       (math.abs(p_it_pt.h - ref_pt.h) / (ref_pt.h + 0.001) > 0.1) then match_pt = false end
                elseif p_it_pt.type == "cube" then
                    if math.abs(p_it_pt.size[1] - ref_pt.size[1]) > 0.1 or math.abs(p_it_pt.size[3] - ref_pt.size[3]) > 0.1 then match_pt = false end
                elseif p_it_pt.type == "mesh" then
                    if p_it_pt.verts != ref_pt.verts or p_it_pt.faces != ref_pt.faces or math.abs(p_it_pt.bbox.size[1] - ref_pt.bbox.size[1]) > 0.1 then match_pt = false end
                elseif p_it_pt.type == "union" or p_it_pt.type == "difference" then match_pt = false end
                if match_pt then table.insert(g_it_pt, p_it_pt) found_g_pt = true break end
            end
        end
        if found_g_pt == false then table.insert(groups_pt, {p_it_pt}) end
    end
    new_parts_pt = {}
    for _, g_loop_it in ipairs(groups_pt) do
        used_p_pt = false
        if #g_loop_it >= 3 then
            cx_pt = 0 cy_pt = 0 cz_pt = 0
            for _, p_l_it in ipairs(g_loop_it) do
                p_l_pos = p_l_it.translate or p_l_it.bbox.center
                cx_pt = cx_pt + p_l_pos[1] cy_pt = cy_pt + p_l_pos[2] cz_pt = cz_pt + p_l_pos[3]
            end
            cx_pt = cx_pt/#g_loop_it cy_pt = cy_pt/#g_loop_it cz_pt = cz_pt/#g_loop_it
            p1_pos_pt = g_loop_it[1].translate or g_loop_it[1].bbox.center
            d_p_pt = math.sqrt((p1_pos_pt[1]-cx_pt)^2 + (p1_pos_pt[2]-cy_pt)^2)
            if d_p_pt > 0.5 then
                is_rot_pt = true angles_pt = {}
                for _, p_chk_it in ipairs(g_loop_it) do
                    chk_p_pos = p_chk_it.translate or p_chk_it.bbox.center
                    d_chk_p = math.sqrt((chk_p_pos[1]-cx_pt)^2 + (chk_p_pos[2]-cy_pt)^2)
                    if math.abs(d_chk_p - d_p_pt) > 3.0 or math.abs(chk_p_pos[3] - cz_pt) > 3.0 then is_rot_pt = false break end
                    table.insert(angles_pt, math.deg(math.atan2(chk_p_pos[2]-cy_pt, chk_p_pos[1]-cx_pt)))
                end
                if is_rot_pt then
                    table.sort(angles_pt)
                    step_pt = (angles_pt[2] - angles_pt[1] + 360) % 360
                    if math.abs(step_pt * #g_loop_it - 360) < 50 then
                        table.insert(new_parts_pt, { type = "pattern", count = #g_loop_it, base = g_loop_it[1], center = {cx_pt, cy_pt, cz_pt}, radius = d_p_pt, start_angle = angles_pt[1], step_angle = step_pt })
                        used_p_pt = true
                    end
                end
            end
        end
        if used_p_pt == false then for _, p_ins_it in ipairs(g_loop_it) do table.insert(new_parts_pt, p_ins_it) end end
    end
    return new_parts_pt
end

function re.render_analysis(analysis_ra, r1_ra, r2_ra, c_p_ra, r_l_ra, r_it_ra_val, b_p_ra, s_p_ra, r_p_l_ra, it_ra_obj, uu_ra)
    if analysis_ra == nil then return nil end
    if analysis_ra.type == "cube" then
        return csg.translate(csg.cube(analysis_ra.size[1], analysis_ra.size[2], analysis_ra.size[3], false), analysis_ra.translate[1], analysis_ra.translate[2], analysis_ra.translate[3])
    elseif analysis_ra.type == "sphere" then
        return csg.translate(csg.sphere(analysis_ra.r, 32), analysis_ra.translate[1], analysis_ra.translate[2], analysis_ra.translate[3])
    elseif analysis_ra.type == "cylinder" then
        r1_ra = analysis_ra.r1 or analysis_ra.r r2_ra = analysis_ra.r2 or analysis_ra.r
        c_p_ra = csg.cylinder(analysis_ra.h, r1_ra, r2_ra, 32, true)
        if analysis_ra.rotate[1] != 0 or analysis_ra.rotate[2] != 0 or analysis_ra.rotate[3] != 0 then c_p_ra = csg.rotate(c_p_ra, analysis_ra.rotate[1], analysis_ra.rotate[2], analysis_ra.rotate[3]) end
        return csg.translate(c_p_ra, analysis_ra.translate[1], analysis_ra.translate[2], analysis_ra.translate[3])
    elseif analysis_ra.type == "union" then
        r_l_ra = {}
        for _, p_ra_it in ipairs(analysis_ra.parts) do
            r_it_ra_val = re.render_analysis(p_ra_it)
            if r_it_ra_val != nil then table.insert(r_l_ra, r_it_ra_val) end
        end
        if #r_l_ra == 0 then return nil end
        return csg.union_batch(r_l_ra)
    elseif analysis_ra.type == "difference" then
        b_p_ra = re.render_analysis(analysis_ra.base) s_p_ra = re.render_analysis(analysis_ra.subtract)
        if b_p_ra != nil and s_p_ra != nil then return csg.difference(b_p_ra, s_p_ra) end
        return b_p_ra
    elseif analysis_ra.type == "pattern" then
        r_p_l_ra = {}
        for idx_ra_it=0, analysis_ra.count-1 do
            it_ra_obj = re.render_analysis(analysis_ra.base)
            if it_ra_obj != nil then
                it_ra_obj = csg.translate(it_ra_obj, analysis_ra.radius, 0, 0)
                it_ra_obj = csg.rotate(it_ra_obj, 0, 0, analysis_ra.start_angle + idx_ra_it * analysis_ra.step_angle)
                table.insert(r_p_l_ra, it_ra_obj)
            end
        end
        uu_ra = csg.union_batch(r_p_l_ra)
        return csg.translate(uu_ra, analysis_ra.center[1], analysis_ra.center[2], analysis_ra.center[3])
    elseif analysis_ra.type == "mesh" then return analysis_ra.manifold end
    return nil
end

function re.calculate_fidelity_score(orig_f, recon_f, v_o_f, u_f_v, i_f_v, d_f_v, v_d_f)
    if recon_f == nil then return 0 end
    v_o_f = csg.volume(orig_f)
    if v_o_f < 0.001 then return 1 end
    u_f_v = csg.union(orig_f, recon_f) i_f_v = csg.intersection(orig_f, recon_f)
    d_f_v = csg.difference(u_f_v, i_f_v) v_d_f = csg.volume(d_f_v)
    return math.max(0, 1.0 - (v_d_f / v_o_f))
end

function re.analyze(node_a, cad_init, man_a_obj, best_a_obj, best_s_val, md_a_val, tl_a_val, cur_a_obj, rec_a_obj, s_v_a)
    cad = cad_init or _G.cad man_a_obj = cad.render(node_a)
    best_a_obj = nil best_s_val = -1
    for eff_a_it=1, 3 do
        md_a_val = 5 + eff_a_it * 2 tl_a_val = 0.05 + eff_a_it * 0.05
        cur_a_obj = re.analyze_recursive(man_a_obj, 0, md_a_val, tl_a_val)
        rec_a_obj = re.render_analysis(cur_a_obj)
        s_v_a = re.calculate_fidelity_score(man_a_obj, rec_a_obj)
        if s_v_a > best_s_val then best_s_val = s_v_a best_a_obj = cur_a_obj end
        if s_v_a > 0.95 then break end
    end
    return best_a_obj
end

function re.analyze_recursive(man_rec, d_rec, m_d_rec, tol_rec, parts_rec, res_list_rec, ar_rec, a_s_rec, bb_rec, vl_rec, l_r_rec, ax_list_r, nnx, nny, nnz, b_s_rec, s_v_v, e_v_v, l_a_v, p_v_rec, area_v_rec, p1_split, p2_split, re1_res, re2_res, h_m_rec, h_a_rec, rm_o_rec, rm_v_rec, rm_a_rec)
    if d_rec > m_d_rec then return nil end
    parts_rec = csg.decompose(man_rec)
    if #parts_rec > 1 then
        res_list_rec = {}
        for _, p_rec_it in ipairs(parts_rec) do
            ar_rec = re.analyze_recursive(p_rec_it, d_rec + 1, m_d_rec, tol_rec)
            if ar_rec != nil then table.insert(res_list_rec, ar_rec) end
        end
        if #res_list_rec == 0 then return nil end
        if #res_list_rec == 1 then return res_list_rec[1] end
        return { type = "union", parts = re.detect_patterns(res_list_rec) }
    end
    a_s_rec = re.analyze_primitive(man_rec, d_rec, tol_rec)
    if a_s_rec == nil then return nil end
    if a_s_rec.type != "mesh" then return a_s_rec end
    
    -- Try Subtraction BEFORE splitting
    h_m_rec = csg.hull(man_rec)
    h_a_rec = re.analyze_primitive(h_m_rec, d_rec + 1, tol_rec)
    if h_a_rec != nil and h_a_rec.type != "mesh" then
        rm_o_rec = csg.difference(h_m_rec, man_rec)
        rm_v_rec = csg.volume(rm_o_rec)
        if rm_v_rec > 0.01 * csg.volume(h_m_rec) then
            rm_a_rec = re.analyze_recursive(rm_o_rec, d_rec + 1, m_d_rec, tol_rec)
            if rm_a_rec != nil then return { type = "difference", base = h_a_rec, subtract = rm_a_rec } end
        end
    end

    bb_rec = a_s_rec.bbox vl_rec = a_s_rec.vol
    if a_s_rec.density < 0.6 or d_rec < 3 then
        l_r_rec = 3
        if bb_rec.size[1] > 1.5 * math.max(bb_rec.size[2], bb_rec.size[3]) then l_r_rec = 1
        elseif bb_rec.size[2] > 1.5 * math.max(bb_rec.size[1], bb_rec.size[3]) then l_r_rec = 2 end
        ax_list_r = {l_r_rec}
        if l_r_rec == 3 then table.insert(ax_list_r, 1) table.insert(ax_list_r, 2) end
        for _, ax_v_rec in ipairs(ax_list_r) do
            nnx = 0 nny = 0 nnz = 0
            if ax_v_rec == 1 then nnx = 1 elseif ax_v_rec == 2 then nny = 1 else nnz = 1 end
            b_s_rec = nil
            if ax_v_rec == 3 then
                s_v_v = bb_rec.min[3] e_v_v = bb_rec.max[3] l_a_v = nil
                for j_rec=1, 10 do
                    p_v_rec = s_v_v + j_rec * (e_v_v - s_v_v) / 11
                    area_v_rec = csg.slice(man_rec, p_v_rec)
                    if l_a_v != nil and math.abs(area_v_rec - l_a_v) / (l_a_v + 0.001) > 0.3 then b_s_rec = p_v_rec break end
                    l_a_v = area_v_rec
                end
            end
            if b_s_rec == nil then b_s_rec = bb_rec.min[ax_v_rec] + bb_rec.size[ax_v_rec] / 2 end
            p1_split, p2_split = csg.split_by_plane(man_rec, nnx, nny, nnz, b_s_rec)
            if csg.volume(p1_split) > 0.05 * vl_rec and csg.volume(p2_split) > 0.05 * vl_rec then
                re1_res = re.analyze_recursive(p1_split, d_rec + 1, m_d_rec, tol_rec)
                re2_res = re.analyze_recursive(p2_split, d_rec + 1, m_d_rec, tol_rec)
                if re1_res != nil and re2_res != nil then return { type = "union", parts = re.detect_patterns({re1_res, re2_res}) } end
            end
        end
    end
    return a_s_rec
end

function re.format_node(an_fn, d_fn, parts_f_l, bc_fn)
    if an_fn.type == "cube" then
        return "cad.translate(cad.cube({size={" .. tostring(an_fn.size[1]) .. ", " .. tostring(an_fn.size[2]) .. ", " .. tostring(an_fn.size[3]) .. "}, center=false}), {" .. tostring(an_fn.translate[1]) .. ", " .. tostring(an_fn.translate[2]) .. ", " .. tostring(an_fn.translate[3]) .. "})"
    elseif an_fn.type == "sphere" then
         return "cad.translate(cad.sphere(" .. tostring(an_fn.r) .. "), {" .. tostring(an_fn.translate[1]) .. ", " .. tostring(an_fn.translate[2]) .. ", " .. tostring(an_fn.translate[3]) .. "})"
    elseif an_fn.type == "cylinder" then
        return "cad.translate(" .. (((an_fn.rotate[1] != 0 or an_fn.rotate[2] != 0 or an_fn.rotate[3] != 0) and ("cad.rotate(" .. ((an_fn.r1 != nil and "cad.cylinder({r1=" .. tostring(an_fn.r1) .. ", r2=" .. tostring(an_fn.r2) .. ", h=" .. tostring(an_fn.h) .. ", center=true})") or ("cad.cylinder({r=" .. tostring(an_fn.r) .. ", h=" .. tostring(an_fn.h) .. ", center=true})")) .. ", {" .. tostring(an_fn.rotate[1]) .. ", " .. tostring(an_fn.rotate[2]) .. ", " .. tostring(an_fn.rotate[3]) .. "} )") or ((an_fn.r1 != nil and "cad.cylinder({r1=" .. tostring(an_fn.r1) .. ", r2=" .. tostring(an_fn.r2) .. ", h=" .. tostring(an_fn.h) .. ", center=true})") or ("cad.cylinder({r=" .. tostring(an_fn.r) .. ", h=" .. tostring(an_fn.h) .. ", center=true})")))) .. ", {" .. tostring(an_fn.translate[1]) .. ", " .. tostring(an_fn.translate[2]) .. ", " .. tostring(an_fn.translate[3]) .. "})"
    elseif an_fn.type == "union" then
        parts_f_l = {}
        for _, p_fn_it in ipairs(an_fn.parts) do table.insert(parts_f_l, re.format_node(p_fn_it)) end
        return "cad.union({" .. table.concat(parts_f_l, ", ") .. "})"
    elseif an_fn.type == "difference" then
        return "cad.difference(" .. re.format_node(an_fn.base) .. ", " .. re.format_node(an_fn.subtract) .. ")"
    elseif an_fn.type == "pattern" then
        bc_fn = re.format_node(an_fn.base)
        return "(function()\n        p_l_fn = {}\n        for i_lp=0," .. tostring(an_fn.count-1) .. " do\n            it_lp = cad.rotate(cad.translate(" .. bc_fn .. ", {" .. tostring(an_fn.radius) .. ", 0, 0}), {0, 0, " .. tostring(an_fn.start_angle) .. " + i_lp * " .. tostring(an_fn.step_angle) .. "})\n            table.insert(p_l_fn, it_lp)\n        end\n        return cad.translate(cad.union(p_l_fn), {" .. tostring(an_fn.center[1]) .. ", " .. tostring(an_fn.center[2]) .. ", " .. tostring(an_fn.center[3]) .. "})\n    end)()"
    elseif an_fn.type == "mesh" then
        return "-- Complex mesh (" .. tostring(an_fn.verts) .. " verts, " .. tostring(an_fn.faces) .. " faces)"
    end
    return "-- Unknown"
end

function re.to_code(an_tc)
    if an_tc == nil then return "return nil" end
    return "return " .. re.format_node(an_tc)
end

return re
