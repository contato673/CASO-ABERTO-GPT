"""Build the original Campo Grande architecture kit with Blender's Python."""
from pathlib import Path
import math
import sys

import bpy

DEST = Path(sys.argv[sys.argv.index("--") + 1])
DEST.mkdir(parents=True, exist_ok=True)

PALETTE = {
    "stucco": "#a4957d",
    "chalk": "#cbbc9d",
    "plinth": "#5e6561",
    "brick": "#9a5148",
    "roof": "#474655",
    "slate": "#404f64",
    "glass": "#293c4d",
    "light": "#dbad6f",
    "steel": "#454757",
    "leaf": "#59755b",
    "soil": "#855d4d",
    "cream": "#e3cba4",
    "teal": "#4d7477",
    "ochre": "#ad7656",
}

def linear(channel):
    channel /= 255
    return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4

def material(key):
    if key in bpy.data.materials:
        return bpy.data.materials[key]
    color = PALETTE[key].lstrip("#")
    rgba = tuple(linear(int(color[i:i+2], 16)) for i in (0, 2, 4)) + (1.0,)
    mat = bpy.data.materials.new(key)
    mat.diffuse_color = rgba
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = rgba
    bsdf.inputs["Roughness"].default_value = 0.89
    if key == "light":
        bsdf.inputs["Emission Color"].default_value = rgba
        bsdf.inputs["Emission Strength"].default_value = 0.23
    return mat

def box(name, xyz, size, color):
    bpy.ops.mesh.primitive_cube_add(size=1, location=xyz)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    obj.data.materials.append(material(color))
    return obj

def hip_roof(name, x, z, w, d, rise, color):
    rim = [(-w/2, -d/2, 0), (w/2, -d/2, 0), (w/2, d/2, 0), (-w/2, d/2, 0)]
    ridge = [(-w/4, 0, rise), (w/4, 0, rise)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(rim + ridge, [], [(0, 1, 5, 4), (1,2,5), (2,3,4,5), (3,0,4)])
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = (x, 0, z)
    obj.data.materials.append(material(color))
    return obj

def window(x, y, z, w, h, lit=False):
    box("Moldura", (x, y, z), (w+0.16, 0.12, h+0.15), "steel")
    box("Vidro", (x, y-0.07, z), (w, 0.035, h), "light" if lit else "glass")
    box("Travessa", (x, y-0.10, z), (0.062, 0.035, h), "steel")
    box("Peitoril", (x, y-0.03, z-h/2), (w+0.30, 0.24, 0.10), "cream")

def planter(x, y):
    box("Floreira", (x, y, 0.22), (1.08, 0.80, 0.44), "plinth")
    box("Folhagem", (x, y, 0.54), (0.88, 0.68, 0.34), "leaf")

def police():
    box("Embasamento", (0, 0, 0.18), (16, 9.5, 0.36), "plinth")
    box("Pavilhão térreo", (0, 0, 2.04), (15.6, 9.0, 3.8), "stucco")
    box("Piso superior", (0, 0.40, 5.01), (15.2, 7.7, 2.28), "chalk")
    box("Cinta artística", (0, 0.10, 3.92), (16, 9.18, 0.26), "slate")
    box("Laje", (0, 0.40, 6.22), (15.7, 8.18, 0.28), "plinth")
    for side in [-1, 1]:
        box("Platibanda transversal", (0, 0.40 + side*3.9, 6.56), (15.5, 0.26, 0.52), "chalk")
        box("Platibanda lateral", (side*7.65, 0.40, 6.56), (0.26, 7.9, 0.52), "chalk")
        for x in (2.7, 4.45, 6.2):
            window(x*side, -4.54, 2.32, 1.04, 1.42, x == 4.45)
            window(x*side, -3.48, 5.05, 1.02, 1.05, x == 2.7)
        planter(side*5.2, -4.85)
        box("Pilastra", (side*1.82, -4.72, 1.84), (0.31, 0.31, 3.45), "chalk")
    box("Marquise", (0, -4.82, 3.63), (4.18, 1.26, 0.26), "slate")
    box("Portal principal", (0, -4.54, 1.51), (2.68, 0.17, 2.7), "steel")
    box("Porta de vidro", (0, -4.65, 1.52), (2.38, 0.06, 2.46), "glass")
    box("Montante central", (0, -4.70, 1.56), (0.11, 0.10, 2.55), "cream")
    box("Letreiro", (0, -3.56, 5.00), (4.14, 0.15, 1.12), "slate")
    box("Iluminação da entrada", (0, -5.08, 3.47), (2.66, 0.24, 0.05), "light")
    box("Degrau", (0, -4.90, 0.095), (3.1, 0.62, 0.19), "plinth")
    box("Casa de máquinas", (4.82, 1.72, 6.77), (1.55, 1.18, 0.80), "roof")
    box("Antena", (-5.54, 2.86, 7.44), (0.09, 0.09, 2.42), "steel")
    for z in (7.05, 7.63, 8.20):
        box("Travessa da antena", (-5.54, 2.86, z), (0.73, 0.08, 0.07), "steel")

def house(wall, roof):
    box("Paredes", (0, 0, 1.57), (8, 6.0, 3.14), wall)
    box("Rodapé", (0, 0, 0.23), (8.06, 6.06, 0.46), "plinth")
    box("Beiral", (0, 0, 3.13), (8.45, 6.45, 0.15), "cream")
    hip_roof("Telhado de quatro águas", 0, 3.22, 8.48, 6.48, 1.36, roof)
    window(-2.33, -3.07, 1.90, 1.22, 1.08, True)
    window(2.31, -3.07, 1.90, 1.37, 1.15)
    box("Entrada", (0, -3.09, 1.16), (1.12, 0.18, 2.22), "steel")
    box("Puxador", (0.29, -3.20, 1.12), (0.10, 0.04, 0.18), "cream")
    box("Degrau", (0, -3.28, 0.12), (1.56, 0.65, 0.24), "plinth")
    planter(2.88, -3.34)
    box("Janela lateral", (4.04, 0.25, 1.91), (0.10, 1.56, 1.11), "glass")

def commerce():
    box("Estrutura", (0, 0, 2.13), (9.2, 6.8, 4.26), "ochre")
    box("Base", (0, 0, 0.25), (9.26, 6.84, 0.50), "plinth")
    box("Coroamento", (0, 0, 4.24), (9.48, 7.08, 0.26), "cream")
    for x in (-2.90, 2.90):
        window(x, -3.43, 1.69, 2.65, 1.97, x > 0)
    box("Vitrine central", (0, -3.47, 1.37), (1.82, 0.12, 2.65), "glass")
    box("Faixa da loja", (0, -3.48, 3.49), (8.65, 0.21, 0.60), "slate")
    for i in range(12):
        awning = box("Toldo", ((i-5.5)*0.72, -3.86, 2.91), (0.72, 0.96, 0.13), "teal" if i % 2 == 0 else "cream")
        awning.rotation_euler.x = math.radians(13)
    box("Caixa de ventilação", (2.54, 0.9, 4.63), (1.32, 1.02, 0.56), "plinth")

def export(name, model):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    model()
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.context.view_layer.objects.active = bpy.context.selected_objects[0]
    bpy.ops.object.join()
    bpy.context.object.name = name
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    bpy.ops.export_scene.gltf(filepath=str(DEST / f"{name}.glb"), export_format="GLB")

export("central_investigacao", police)
export("casa_terracota", lambda: house("stucco", "brick"))
export("casa_azulada", lambda: house("teal", "roof"))
export("comercio_toldo", commerce)
