-- src/threemf.lua
-- 3MF format encoder

threemf = {}

function threemf.encode_model_xml(mesh)
    lines = {
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">',
        '  <metadata name="Title">Luametry Model</metadata>',
        '  <resources>',
        '    <object id="1" type="model">',
        '      <mesh>',
        '        <vertices>'
    }
    
    -- Vertices (0-indexed in 3MF)
    for _, v in ipairs(mesh.verts) do
        table.insert(lines, string.format('          <vertex x="%.6f" y="%.6f" z="%.6f" />', v[1], v[2], v[3]))
    end
    
    table.insert(lines, '        </vertices>')
    table.insert(lines, '        <triangles>')
    
    -- Triangles (0-indexed in 3MF, our mesh is 1-indexed)
    for _, f in ipairs(mesh.faces) do
        table.insert(lines, string.format('          <triangle v1="%d" v2="%d" v3="%d" />', f[1]-1, f[2]-1, f[3]-1))
    end
    
    table.insert(lines, '        </triangles>')
    table.insert(lines, '      </mesh>')
    table.insert(lines, '    </object>')
    table.insert(lines, '  </resources>')
    table.insert(lines, '  <build>')
    table.insert(lines, '    <item objectid="1" />')
    table.insert(lines, '  </build>')
    table.insert(lines, '</model>')
    
    return table.concat(lines, "\n")
end

function threemf.encode_content_types()
    return """<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml" />
  <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml" />
</Types>"""
end

function threemf.encode_rels()
    return """<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rel0" Target="/3D/3dmodel.model" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel" />
</Relationships>"""
end

function threemf.export(mesh, filename)
    -- Create temporary structure
    tmp_id = os.time()
    tmp_dir = "/tmp/luam_3mf_" .. tmp_id
    os.execute("mkdir -p " .. tmp_dir .. "/3D")
    os.execute("mkdir -p " .. tmp_dir .. "/_rels")
    
    -- Write files
    f1 = io.open(tmp_dir .. "/3D/3dmodel.model", "w")
    if f1 != nil then
        io.write(f1, threemf.encode_model_xml(mesh))
        io.close(f1)
    end
    
    f2 = io.open(tmp_dir .. "/_rels/.rels", "w")
    if f2 != nil then
        io.write(f2, threemf.encode_rels())
        io.close(f2)
    end
    
    f3 = io.open(tmp_dir .. "/[Content_Types].xml", "w")
    if f3 != nil then
        io.write(f3, threemf.encode_content_types())
        io.close(f3)
    end
    
    -- Zip it
    cwd = os.getenv("PWD")
    full_path = filename
    if string.match(filename, "^/") == nil then
        full_path = cwd .. "/" .. filename
    end
    
    cmd = "cd " .. tmp_dir .. " && zip -r " .. full_path .. " . > /dev/null"
    res = os.execute(cmd)
    
    -- Cleanup
    os.execute("rm -rf " .. tmp_dir)
    
    return res == 0 or res == true
end

return threemf
