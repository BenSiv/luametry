import re
import collections
import sys
import os

import struct

def read_binary_stl(input_path):
    triangles = []
    try:
        with open(input_path, 'rb') as f:
            header = f.read(80)
            if len(header) < 80: return None
            
            count_bytes = f.read(4)
            if len(count_bytes) < 4: return None
            
            num_triangles = struct.unpack('<I', count_bytes)[0]
            
            # Validation: File size must match 80 + 4 + 50 * num_triangles
            expected_size = 80 + 4 + (50 * num_triangles)
            file_size = os.path.getsize(input_path)
            
            if file_size != expected_size:
                return None
            
            for _ in range(num_triangles):
                data = f.read(50)
                if len(data) < 50: break
                
                floats = struct.unpack('<12f', data[:48])
                # normal = floats[0:3]
                # v1 = floats[3:6]
                # v2 = floats[6:9]
                # v3 = floats[9:12]
                
                triangles.append((floats[3], floats[4], floats[5])) # v1
                triangles.append((floats[6], floats[7], floats[8])) # v2
                triangles.append((floats[9], floats[10], floats[11])) # v3
                
    except Exception:
        return None
        
    return triangles

def analyze_stl(input_path):
    print(f"Analyzing {input_path}...")
    
    vertices = []
    
    # Try binary first
    vertices = read_binary_stl(input_path)
    
    # If binary failed or returned empty (maybe it's ASCII), try ASCII
    if not vertices:
        vertices = []
        # Simple regex parsing for ASCII STL
        # vertex X Y Z
        vertex_pattern = re.compile(r'\s*vertex\s+([-\d\.eE]+)\s+([-\d\.eE]+)\s+([-\d\.eE]+)')
        
        try:
            with open(input_path, 'r') as f:
                for line in f:
                    match = vertex_pattern.search(line)
                    if match:
                        x, y, z = map(float, match.groups())
                        vertices.append((x, y, z))
        except Exception as e:
            print(f"Error reading file: {e}")
            return

    if not vertices:
        print("No vertices found.")
        return

    xs = [v[0] for v in vertices]
    ys = [v[1] for v in vertices]
    zs = [v[2] for v in vertices]

    print("\n=== Bounding Box ===")
    print(f"X: {min(xs):.2f} to {max(xs):.2f} (Width: {max(xs)-min(xs):.2f})")
    print(f"Y: {min(ys):.2f} to {max(ys):.2f} (Depth: {max(ys)-min(ys):.2f})")
    print(f"Z: {min(zs):.2f} to {max(zs):.2f} (Height: {max(zs)-min(zs):.2f})")

    # Analyze Z-levels (histogram/frequency)
    z_counter = collections.Counter([round(z, 2) for z in zs])
    print("\n=== Common Z Levels (Top 10) ===")
    for z, count in z_counter.most_common(10):
        print(f"Z = {z:.2f} : {count} vertices")

    # Analyze X-levels
    x_counter = collections.Counter([round(x, 2) for x in xs])
    print("\n=== Common X Levels (Top 10) ===")
    for x, count in x_counter.most_common(10):
        print(f"X = {x:.2f} : {count} vertices")
        
    # Analyze Y-levels
    y_counter = collections.Counter([round(y, 2) for y in ys])
    print("\n=== Common Y Levels (Top 10) ===")
    for y, count in y_counter.most_common(10):
        print(f"Y = {y:.2f} : {count} vertices")

if __name__ == "__main__":
    input_file = "test/benchy_ref.stl"
    if len(sys.argv) > 1:
        input_file = sys.argv[1]
        
    if not os.path.exists(input_file):
        print(f"Error: File '{input_file}' not found.")
        sys.exit(1)
        
    analyze_stl(input_file)
