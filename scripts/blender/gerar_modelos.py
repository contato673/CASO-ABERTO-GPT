# Gera os modelos 3D do jogo Caso Aberto como arquivos GLB.
# Rodar no Blender em modo sem tela, com a pasta de saída como argumento:
#   blender.exe --background --python gerar_modelos.py -- "C:\...\CasoAberto\assets\modelos"
# Convenção: Blender usa Z para cima. O exportador converte para Y para cima no Godot.
# Móveis: base em z=0, centro em x/y. Avatar: a frente do corpo fica em -y.

import bpy
import math
import os
import random
import sys

argv = sys.argv
OUT = argv[argv.index("--") + 1] if "--" in argv else os.path.join(os.getcwd(), "modelos")
os.makedirs(os.path.join(OUT, "moveis"), exist_ok=True)
os.makedirs(os.path.join(OUT, "avatar"), exist_ok=True)

MATS = {}


def mat(name, rgb, rough=0.6, metal=0.0, emit=None, emit_strength=0.0):
    if name in MATS:
        return MATS[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (rgb[0], rgb[1], rgb[2], 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit is not None:
        b.inputs["Emission Color"].default_value = (emit[0], emit[1], emit[2], 1.0)
        b.inputs["Emission Strength"].default_value = emit_strength
    MATS[name] = m
    return m


def _link(o, m, name):
    o.name = name
    o.data.materials.clear()
    if m is not None:
        o.data.materials.append(m)
    return o


def cube(name, size, loc, m, bevel=0.012):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    o = bpy.context.active_object
    o.scale = (size[0], size[1], size[2])
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0:
        md = o.modifiers.new("Bisel", 'BEVEL')
        md.width = bevel
        md.segments = 2
        bpy.ops.object.modifier_apply(modifier=md.name)
    return _link(o, m, name)


def cyl(name, r, h, loc, m, verts=16):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h, location=loc)
    o = bpy.context.active_object
    bpy.ops.object.shade_smooth()
    return _link(o, m, name)


def cone(name, r1, r2, h, loc, m, verts=20):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r1, radius2=r2, depth=h, location=loc)
    o = bpy.context.active_object
    bpy.ops.object.shade_smooth()
    return _link(o, m, name)


def ball(name, r, loc, m, scale=(1.0, 1.0, 1.0)):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=r, location=loc)
    o = bpy.context.active_object
    o.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bpy.ops.object.shade_smooth()
    return _link(o, m, name)


def limpar():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for me in list(bpy.data.meshes):
        if me.users == 0:
            bpy.data.meshes.remove(me)


def exportar(caminho):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.export_scene.gltf(filepath=caminho, export_format='GLB', use_selection=True,
                              export_apply=True, export_yup=True)
    print("OK", caminho)


# ---------- móveis (tamanhos batem com FURN em home.gd) ----------

def m_cama():
    madeira = mat("Madeira", (0.42, 0.26, 0.14))
    lencol = mat("Lencol", (0.93, 0.93, 0.96))
    cobertor = mat("Acento", (0.72, 0.3, 0.28))
    travesseiro = mat("Travesseiro", (0.97, 0.97, 0.92))
    cube("Estrutura", (1.0, 2.0, 0.22), (0, 0, 0.11), madeira, 0.01)
    cube("Colchao", (0.92, 1.9, 0.18), (0, 0.02, 0.31), lencol, 0.02)
    cube("Cobertor", (0.94, 1.1, 0.03), (0, -0.35, 0.415), cobertor, 0.006)
    cube("Travesseiro", (0.6, 0.3, 0.12), (0, 0.7, 0.44), travesseiro, 0.03)
    cube("Cabeceira", (1.0, 0.06, 0.5), (0, 0.97, 0.25), madeira, 0.01)


def m_sofa():
    tecido = mat("Acento", (0.35, 0.45, 0.55), rough=0.9)
    escuro = mat("Tecido", (0.25, 0.32, 0.4), rough=0.9)
    cube("Base", (2.0, 0.8, 0.3), (0, 0.05, 0.15), escuro, 0.03)
    cube("Encosto", (2.0, 0.2, 0.3), (0, -0.35, 0.45), escuro, 0.04)
    cube("Braco", (0.2, 0.8, 0.42), (-0.9, 0.05, 0.21), escuro, 0.04)
    cube("Braco", (0.2, 0.8, 0.42), (0.9, 0.05, 0.21), escuro, 0.04)
    cube("Almofada", (0.86, 0.6, 0.12), (-0.45, 0.08, 0.36), tecido, 0.05)
    cube("Almofada", (0.86, 0.6, 0.12), (0.45, 0.08, 0.36), tecido, 0.05)


def m_mesa():
    madeira = mat("Madeira", (0.55, 0.4, 0.25))
    cube("Tampo", (1.2, 0.8, 0.06), (0, 0, 0.72), madeira, 0.012)
    for x in (-0.52, 0.52):
        for y in (-0.32, 0.32):
            cyl("Perna", 0.035, 0.69, (x, y, 0.345), madeira, 12)


def m_cadeira():
    madeira = mat("Madeira", (0.5, 0.35, 0.2))
    estofado = mat("Acento", (0.7, 0.45, 0.3), rough=0.9)
    cube("Assento", (0.46, 0.46, 0.05), (0, 0, 0.45), estofado, 0.02)
    cube("Encosto", (0.46, 0.05, 0.42), (0, 0.22, 0.7), madeira, 0.01)
    for x in (-0.2, 0.2):
        for y in (-0.2, 0.2):
            cyl("Perna", 0.02, 0.43, (x, y, 0.215), madeira, 10)


def m_estante():
    madeira = mat("Madeira", (0.45, 0.32, 0.2))
    fundo = mat("Tecido", (0.3, 0.22, 0.14))
    cube("Lateral", (0.03, 0.35, 1.8), (-0.485, 0, 0.9), madeira, 0.006)
    cube("Lateral", (0.03, 0.35, 1.8), (0.485, 0, 0.9), madeira, 0.006)
    cube("Topo", (1.0, 0.35, 0.03), (0, 0, 1.785), madeira, 0.006)
    cube("Base", (1.0, 0.35, 0.03), (0, 0, 0.015), madeira, 0.006)
    cube("Fundo", (0.94, 0.02, 1.76), (0, 0.165, 0.9), fundo, 0.0)
    cores = [(0.7, 0.2, 0.2), (0.2, 0.4, 0.7), (0.9, 0.7, 0.2), (0.3, 0.6, 0.35), (0.85, 0.85, 0.8)]
    rnd = random.Random(7)
    for z in (0.45, 0.9, 1.35):
        cube("Prateleira", (0.94, 0.34, 0.03), (0, 0, z), madeira, 0.005)
        x = -0.42
        while x < 0.4:
            larg = rnd.uniform(0.04, 0.09)
            alt = rnd.uniform(0.25, 0.36)
            cor = mat("Livro%d" % rnd.randint(0, 4), cores[rnd.randint(0, 4)], rough=0.8)
            cube("Livro", (larg, 0.22, alt), (x + larg / 2, 0.0, z + 0.015 + alt / 2), cor, 0.004)
            x += larg + 0.01


def m_planta():
    vaso = mat("Terracota", (0.66, 0.36, 0.22))
    terra = mat("Terra", (0.2, 0.13, 0.08))
    folha = mat("Folha", (0.2, 0.52, 0.25), rough=0.7)
    haste = mat("Haste", (0.3, 0.5, 0.25))
    cyl("Vaso", 0.17, 0.3, (0, 0, 0.15), vaso, 18)
    cyl("Terra", 0.16, 0.02, (0, 0, 0.3), terra, 18)
    cyl("Haste", 0.012, 0.6, (0, 0, 0.6), haste, 6)
    rnd = random.Random(3)
    for i in range(9):
        ang = i * 0.7 + rnd.uniform(0, 0.3)
        alt = 0.5 + (i % 4) * 0.12
        dist = 0.1 + rnd.uniform(0, 0.05)
        ball("Folha", 0.12, (math.cos(ang) * dist, math.sin(ang) * dist, alt), folha,
             scale=(0.7, 0.22, 0.45))


def m_luminaria():
    metal = mat("Metal", (0.2, 0.2, 0.22), rough=0.3, metal=0.8)
    luz = mat("Abajur", (0.95, 0.88, 0.6), rough=0.9, emit=(1.0, 0.9, 0.6), emit_strength=0.8)
    cyl("Base", 0.13, 0.04, (0, 0, 0.02), metal, 20)
    cyl("Haste", 0.012, 1.3, (0, 0, 0.69), metal, 8)
    cone("Abajur", 0.16, 0.09, 0.25, (0, 0, 1.45), luz, 20)


def m_tv():
    preto = mat("Tela", (0.08, 0.08, 0.1), rough=0.2)
    tela = mat("Vidro", (0.1, 0.18, 0.3), rough=0.1, emit=(0.2, 0.4, 0.7), emit_strength=0.3)
    metal = mat("Metal", (0.2, 0.2, 0.22), rough=0.3, metal=0.8)
    cube("Tela", (1.2, 0.05, 0.62), (0, 0, 0.4), preto, 0.01)
    cube("Vidro", (1.12, 0.01, 0.56), (0, -0.03, 0.4), tela, 0.0)
    cube("Pescoco", (0.1, 0.05, 0.12), (0, 0, 0.06), metal, 0.01)
    cube("Pe", (0.5, 0.1, 0.02), (0, 0, 0.01), metal, 0.005)


MOVEIS = {"cama": m_cama, "sofa": m_sofa, "mesa": m_mesa, "cadeira": m_cadeira,
          "estante": m_estante, "planta": m_planta, "luminaria": m_luminaria, "tv": m_tv}


# ---------- avatar (peças separadas: o Godot anima perna e braço) ----------

def a_torso():
    pele = mat("Pele", (0.96, 0.82, 0.68), rough=0.7)
    camisa = mat("Camisa", (0.2, 0.35, 0.6), rough=0.8)
    calca = mat("Calca", (0.18, 0.18, 0.22), rough=0.8)
    cinto = mat("Cinto", (0.1, 0.07, 0.05), rough=0.5)
    branco = mat("OlhoBranco", (0.97, 0.97, 0.97), rough=0.3)
    preto = mat("Olho", (0.05, 0.04, 0.04), rough=0.2)
    boca = mat("Boca", (0.55, 0.2, 0.2), rough=0.6)
    sobr = mat("Cabelo", (0.35, 0.22, 0.12), rough=0.9)
    cube("Torso", (0.46, 0.27, 0.62), (0, 0, 1.19), camisa, 0.09)
    cube("Quadril", (0.44, 0.26, 0.16), (0, 0, 0.86), calca, 0.05)
    cube("Cinto", (0.46, 0.28, 0.05), (0, 0, 0.93), cinto, 0.01)
    cyl("Gola", 0.09, 0.05, (0, 0, 1.51), camisa)
    cyl("Pescoco", 0.06, 0.1, (0, 0, 1.54), pele)
    ball("Cabeca", 0.2, (0, 0, 1.73), pele, (1.0, 0.95, 1.05))
    for sx in (-1, 1):
        ball("Orelha", 0.045, (0.2 * sx, 0.0, 1.72), pele, (0.6, 1.0, 1.2))
        ball("OlhoBranco", 0.042, (0.075 * sx, -0.165, 1.76), branco, (1.0, 0.5, 1.2))
        ball("Olho", 0.024, (0.075 * sx, -0.186, 1.755), preto, (1.0, 0.5, 1.2))
        cube("Sobrancelha", (0.07, 0.015, 0.015), (0.075 * sx, -0.178, 1.825), sobr, 0.004)
    ball("Nariz", 0.03, (0, -0.195, 1.7), pele)
    cube("Boca", (0.08, 0.012, 0.018), (0, -0.184, 1.635), boca, 0.004)


def a_perna():
    calca = mat("Calca", (0.18, 0.18, 0.22), rough=0.8)
    sapato = mat("Sapato", (0.15, 0.1, 0.08), rough=0.4)
    sola = mat("Sola", (0.6, 0.58, 0.52), rough=0.6)
    cyl("Perna", 0.088, 0.74, (0, 0, -0.41), calca)
    cube("Sapato", (0.19, 0.3, 0.11), (0, -0.05, -0.83), sapato, 0.045)
    cube("Sola", (0.2, 0.31, 0.03), (0, -0.05, -0.885), sola, 0.008)


def a_braco():
    camisa = mat("Camisa", (0.2, 0.35, 0.6), rough=0.8)
    pele = mat("Pele", (0.96, 0.82, 0.68), rough=0.7)
    ball("Ombro", 0.09, (0, 0, -0.02), camisa)
    cyl("Manga", 0.072, 0.34, (0, 0, -0.2), camisa)
    cyl("Antebraco", 0.056, 0.28, (0, 0, -0.5), pele)
    ball("Mao", 0.075, (0, 0, -0.68), pele)


def a_cabelo(estilo):
    cabelo = mat("Cabelo", (0.35, 0.22, 0.12), rough=0.9)
    ball("Cabelo", 0.215, (0, 0.05, 1.8), cabelo, (1.03, 0.95, 0.75))
    if estilo == "curto":
        cube("Franja", (0.3, 0.05, 0.07), (0, -0.16, 1.875), cabelo, 0.02)
    elif estilo == "longo":
        cube("Costas", (0.4, 0.12, 0.5), (0, 0.15, 1.6), cabelo, 0.05)
        for sx in (-1, 1):
            cube("Mecha", (0.06, 0.2, 0.4), (0.2 * sx, 0.06, 1.62), cabelo, 0.025)
        cube("Franja", (0.3, 0.05, 0.06), (0, -0.16, 1.88), cabelo, 0.02)
    elif estilo == "coque":
        ball("Coque", 0.1, (0, 0.12, 1.99), cabelo)


def a_oculos():
    preto = mat("Oculos", (0.1, 0.1, 0.12), rough=0.3)
    for sx in (-1, 1):
        cube("Lente", (0.11, 0.02, 0.07), (0.075 * sx, -0.2, 1.76), preto, 0.005)
        cube("Haste", (0.012, 0.2, 0.012), (0.2 * sx, -0.1, 1.77), preto, 0.0)
    cube("Ponte", (0.05, 0.015, 0.015), (0, -0.2, 1.77), preto, 0.0)


def main():
    limpar()
    for nome, fn in MOVEIS.items():
        limpar()
        fn()
        exportar(os.path.join(OUT, "moveis", nome + ".glb"))
    partes = [("torso", a_torso), ("perna", a_perna), ("braco", a_braco), ("oculos", a_oculos)]
    for nome, fn in partes:
        limpar()
        fn()
        exportar(os.path.join(OUT, "avatar", nome + ".glb"))
    for estilo in ("curto", "longo", "coque"):
        limpar()
        a_cabelo(estilo)
        exportar(os.path.join(OUT, "avatar", "cabelo_" + estilo + ".glb"))
    print("FIM: modelos gerados em", OUT)


main()
