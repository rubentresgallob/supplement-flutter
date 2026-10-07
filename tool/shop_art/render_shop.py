"""Renderiza en 3D los objetos de la tienda (medallas, escudo y banners) con Blender.

Uso (desde flutter_app):
    "C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe" -b --python tool\\shop_art\\render_shop.py -- <salida> [code ...]

Sin códigos renderiza todos. Cada objeto sale como <salida>/<code>.png|jpg: medallas y escudo
en PNG con fondo transparente (400x400); banners en JPG a sangre (800x400).
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Vector

SIZE = 400  # se muestran como mucho a ~130 px lógicos (x3 en pantallas densas)
SAMPLES = 96

# ── Materiales ──────────────────────────────────────────────────────────────

METALS = {
    'gold': (1.00, 0.70, 0.10),
    'bronze': (0.80, 0.42, 0.22),
    'silver': (0.80, 0.82, 0.86),
    'rose': (1.00, 0.50, 0.60),
    'mint': (0.30, 0.86, 0.74),
    'violet': (0.46, 0.32, 0.92),
    'platinum': (0.90, 0.90, 0.97),
}


def _set(bsdf, name, value):
    if name in bsdf.inputs:
        bsdf.inputs[name].default_value = value


def metal(name, color, roughness=0.26):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes['Principled BSDF']
    _set(bsdf, 'Base Color', (*color, 1))
    _set(bsdf, 'Metallic', 0.55)
    _set(bsdf, 'Roughness', roughness)
    _set(bsdf, 'Coat Weight', 0.8)
    _set(bsdf, 'Coat Roughness', 0.08)
    return mat


def iridescent(name):
    """Metal nacarado: rosa → lavanda → cian en diagonal sobre el objeto."""
    mat = metal(name, (0.8, 0.7, 1.0), roughness=0.2)
    nt = mat.node_tree
    bsdf = nt.nodes['Principled BSDF']
    coord = nt.nodes.new('ShaderNodeTexCoord')
    sep = nt.nodes.new('ShaderNodeSeparateXYZ')
    add = nt.nodes.new('ShaderNodeMath')
    add.operation = 'ADD'
    rng = nt.nodes.new('ShaderNodeMapRange')
    rng.inputs['From Min'].default_value = -1.2
    rng.inputs['From Max'].default_value = 1.2
    ramp = nt.nodes.new('ShaderNodeValToRGB')
    els = ramp.color_ramp.elements
    els[0].position, els[0].color = 0.0, (0.25, 0.85, 0.95, 1)
    els[1].position, els[1].color = 1.0, (1.0, 0.50, 0.80, 1)
    mid = els.new(0.5)
    mid.color = (0.58, 0.42, 1.0, 1)
    nt.links.new(coord.outputs['Object'], sep.inputs['Vector'])
    nt.links.new(sep.outputs['X'], add.inputs[0])
    nt.links.new(sep.outputs['Z'], add.inputs[1])
    nt.links.new(add.outputs['Value'], rng.inputs['Value'])
    nt.links.new(rng.outputs['Result'], ramp.inputs['Fac'])
    nt.links.new(ramp.outputs['Color'], bsdf.inputs['Base Color'])
    return mat


def satin(name, color):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes['Principled BSDF']
    _set(bsdf, 'Base Color', (*color, 1))
    _set(bsdf, 'Metallic', 0.0)
    _set(bsdf, 'Roughness', 0.38)
    _set(bsdf, 'Coat Weight', 0.5)
    _set(bsdf, 'Coat Roughness', 0.15)
    return mat


def gem(name, color):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes['Principled BSDF']
    _set(bsdf, 'Base Color', (*color, 1))
    _set(bsdf, 'Metallic', 0.75)
    _set(bsdf, 'Roughness', 0.06)
    _set(bsdf, 'Emission Color', (*color, 1))
    _set(bsdf, 'Emission Strength', 0.25)
    return mat


def faceted(name):
    """Diamante: cada faceta toma un tono distinto según hacia dónde mira."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes['Principled BSDF']
    _set(bsdf, 'Metallic', 0.3)
    _set(bsdf, 'Roughness', 0.05)
    geo = nt.nodes.new('ShaderNodeNewGeometry')
    sep = nt.nodes.new('ShaderNodeSeparateXYZ')
    mix = nt.nodes.new('ShaderNodeMath')
    mix.operation = 'MULTIPLY_ADD'
    mix.inputs[1].default_value = 0.9
    rng = nt.nodes.new('ShaderNodeMapRange')
    rng.inputs['From Min'].default_value = -1.0
    rng.inputs['From Max'].default_value = 1.0
    ramp = nt.nodes.new('ShaderNodeValToRGB')
    els = ramp.color_ramp.elements
    els[0].position, els[0].color = 0.0, (0.10, 0.35, 0.85, 1)
    els[1].position, els[1].color = 1.0, (1, 1, 1, 1)
    for pos, col in ((0.35, (0.35, 0.75, 1.0, 1)), (0.65, (0.75, 0.95, 1.0, 1))):
        els.new(pos).color = col
    nt.links.new(geo.outputs['Normal'], sep.inputs['Vector'])
    nt.links.new(sep.outputs['X'], mix.inputs[0])
    nt.links.new(sep.outputs['Z'], mix.inputs[2])
    nt.links.new(mix.outputs['Value'], rng.inputs['Value'])
    nt.links.new(rng.outputs['Result'], ramp.inputs['Fac'])
    nt.links.new(ramp.outputs['Color'], bsdf.inputs['Base Color'])
    nt.links.new(ramp.outputs['Color'], bsdf.inputs['Emission Color'])
    _set(bsdf, 'Emission Strength', 0.35)
    return mat


# ── Geometría ───────────────────────────────────────────────────────────────


def chaikin(points, rounds=2):
    """Suaviza un contorno cerrado."""
    for _ in range(rounds):
        out = []
        n = len(points)
        for i in range(n):
            (x0, z0), (x1, z1) = points[i], points[(i + 1) % n]
            out.append((0.75 * x0 + 0.25 * x1, 0.75 * z0 + 0.25 * z1))
            out.append((0.25 * x0 + 0.75 * x1, 0.25 * z0 + 0.75 * z1))
        points = out
    return points


def circle(radius, n=96, wobble=0.0, lobes=0):
    return [
        (
            radius * (1 + wobble * math.cos(lobes * a)) * math.sin(a),
            radius * (1 + wobble * math.cos(lobes * a)) * math.cos(a),
        )
        for a in (2 * math.pi * i / n for i in range(n))
    ]


def ngon(radius, sides, rot=0.0):
    return [
        (radius * math.sin(rot + 2 * math.pi * i / sides), radius * math.cos(rot + 2 * math.pi * i / sides))
        for i in range(sides)
    ]


def scaled(points, s):
    return [(x * s, z * s) for x, z in points]


def moved(points, dx=0.0, dz=0.0):
    return [(x + dx, z + dz) for x, z in points]


def _finish(bm, name, mat, bevel, segments=5):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    for p in mesh.polygons:
        p.use_smooth = True
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    if bevel > 0:
        mod = obj.modifiers.new('bevel', 'BEVEL')
        mod.width = bevel
        mod.segments = segments
        mod.limit_method = 'ANGLE'
        mod.angle_limit = math.radians(40)
        mod.harden_normals = True
    return obj


def prism(name, points, y_front, y_back, mat, bevel=0.03):
    """Contorno 2D (x, z) extruido en profundidad; la cámara mira desde -Y."""
    bm = bmesh.new()
    front = [bm.verts.new((x, y_front, z)) for x, z in points]
    back = [bm.verts.new((x, y_back, z)) for x, z in points]
    bm.faces.new(front)
    bm.faces.new(list(reversed(back)))
    n = len(points)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((front[i], front[j], back[j], back[i]))
    return _finish(bm, name, mat, bevel)


def ring(name, outer, inner, y_front, y_back, mat, bevel=0.02):
    """Aro entre dos contornos con el mismo número de puntos (canto de la medalla)."""
    bm = bmesh.new()
    of = [bm.verts.new((x, y_front, z)) for x, z in outer]
    inf = [bm.verts.new((x, y_front, z)) for x, z in inner]
    ob = [bm.verts.new((x, y_back, z)) for x, z in outer]
    inb = [bm.verts.new((x, y_back, z)) for x, z in inner]
    n = len(outer)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((of[i], of[j], inf[j], inf[i]))
        bm.faces.new((ob[j], ob[i], inb[i], inb[j]))
        bm.faces.new((of[j], of[i], ob[i], ob[j]))
        bm.faces.new((inf[i], inf[j], inb[j], inb[i]))
    return _finish(bm, name, mat, bevel, segments=4)


def sphere(name, loc, radius, mat, scale=(1, 1, 1), rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=loc, segments=64, ring_count=32)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.rotation_euler = rot
    bpy.ops.object.shade_smooth()
    obj.data.materials.append(mat)
    return obj


def torus(name, loc, major, minor, mat):
    """Aro con el eje hacia la cámara."""
    bpy.ops.mesh.primitive_torus_add(location=loc, rotation=(math.pi / 2, 0, 0),
                                     major_radius=major, minor_radius=minor,
                                     major_segments=48, minor_segments=16)
    obj = bpy.context.object
    obj.name = name
    bpy.ops.object.shade_smooth()
    obj.data.materials.append(mat)
    return obj


# ── Emblemas (van en relieve sobre la cara, que está en y = FACE) ───────────

FACE = -0.07


def star(mat, r=0.41):
    pts = []
    for i in range(10):
        rr = r if i % 2 == 0 else r * 0.52
        a = math.pi * i / 5
        pts.append((rr * math.sin(a), rr * math.cos(a)))
    prism('star', pts, FACE - 0.14, FACE + 0.02, mat, bevel=0.065)


FLAME = [(0.0, -0.40), (0.18, -0.37), (0.30, -0.22), (0.32, -0.04), (0.25, 0.12), (0.17, 0.22),
         (0.15, 0.36), (0.06, 0.50), (-0.02, 0.34), (-0.06, 0.20), (-0.13, 0.30), (-0.22, 0.16),
         (-0.30, -0.02), (-0.30, -0.20), (-0.18, -0.36)]
FLAME_CORE = [(0.0, -0.33), (0.11, -0.30), (0.17, -0.19), (0.15, -0.06), (0.08, 0.06), (0.02, 0.18),
              (-0.06, 0.06), (-0.14, -0.07), (-0.16, -0.20), (-0.10, -0.30)]


def flame(mat, core_mat=None, s=1.0, y=FACE):
    prism('flame', scaled(chaikin(FLAME), s), y - 0.12, y + 0.02, mat, bevel=0.055)
    prism('flame_core', scaled(chaikin(FLAME_CORE), s), y - 0.19, y - 0.08, core_mat or mat, bevel=0.045)


def capsule(mat):
    ang = math.radians(40)
    d = Vector((math.sin(ang), 0, math.cos(ang)))
    y = FACE - 0.06
    for sign, name in ((1, 'cap_a'), (-1, 'cap_b')):
        c = d * (0.115 * sign)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.15, depth=0.21, location=(c.x, y, c.z),
                                            rotation=(0, ang, 0), vertices=48)
        o = bpy.context.object
        o.name = name
        o.scale = (1, 0.55, 1)
        bpy.ops.object.shade_smooth()
        o.data.materials.append(mat)
        e = d * (0.22 * sign)
        sphere(name + '_end', (e.x, y, e.z), 0.15, mat, scale=(1, 0.55, 1))
    # ranura entre las dos mitades
    bpy.ops.mesh.primitive_cylinder_add(radius=0.158, depth=0.022, location=(0, y, 0),
                                        rotation=(0, ang, 0), vertices=48)
    o = bpy.context.object
    o.scale = (1, 0.57, 1)
    bpy.ops.object.shade_smooth()
    o.data.materials.append(mat)


def laurel(mat):
    for side in (-1, 1):
        for k in range(7):
            a = math.radians(248 - k * 22)  # rama izquierda, de abajo hacia arriba
            x, z = 0.33 * math.cos(a), 0.33 * math.sin(a)
            theta = math.pi - a - 0.45  # hoja tangente al círculo, abierta hacia fuera
            sphere(f'leaf{side}{k}', (x * -side, FACE - 0.04, z - 0.02), 1.0, mat,
                   scale=(0.055, 0.04, 0.115), rot=(0, theta * -side, 0))
    sphere('laurel_knot', (0, FACE - 0.045, -0.36), 0.06, mat, scale=(1, 0.7, 1))


def crown(mat, jewel):
    pts = [(-0.31, -0.24), (0.31, -0.24), (0.37, 0.16), (0.19, -0.02), (0.0, 0.27),
           (-0.19, -0.02), (-0.37, 0.16)]
    prism('crown', pts, FACE - 0.09, FACE + 0.02, mat, bevel=0.035)
    prism('crown_band', [(-0.33, -0.27), (0.33, -0.27), (0.33, -0.17), (-0.33, -0.17)],
          FACE - 0.115, FACE + 0.02, mat, bevel=0.03)
    for x, z in ((0.37, 0.19), (0.0, 0.30), (-0.37, 0.19)):
        sphere('crown_tip', (x, FACE - 0.05, z), 0.055, mat)
    for x in (-0.19, 0.0, 0.19):
        sphere('crown_jewel', (x, FACE - 0.115, -0.22), 0.04, jewel)


def diamond(mat):
    bm = bmesh.new()
    n = 8
    rot = math.pi / n
    table = [bm.verts.new((0.22 * math.sin(rot + 2 * math.pi * i / n), 0.22 * math.cos(rot + 2 * math.pi * i / n) * 0.6, 0.26))
             for i in range(n)]
    girdle = [bm.verts.new((0.42 * math.sin(rot + 2 * math.pi * i / n), 0.42 * math.cos(rot + 2 * math.pi * i / n) * 0.6, 0.10))
              for i in range(n)]
    apex = bm.verts.new((0, 0, -0.38))
    bm.faces.new(table)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((table[j], table[i], girdle[i], girdle[j]))
        bm.faces.new((girdle[i], apex, girdle[j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new('diamond')
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new('diamond', mesh)  # caras planas: son las facetas
    obj.location = (0, FACE - 0.20, 0.03)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)


# ── Objetos ─────────────────────────────────────────────────────────────────


def medal(metal_mat, emblem, outline=None, rim_mat=None, ribbon_mat=None):
    outline = outline or circle(0.66)
    prism('disc', outline, FACE, 0.09, metal_mat, bevel=0.05)
    ring('rim', outline, scaled(outline, 0.83), FACE - 0.05, FACE + 0.02, rim_mat or metal_mat, bevel=0.022)
    emblem()
    # enganche y cinta
    torus('bail', (0, 0.02, 0.70), 0.10, 0.032, rim_mat or metal_mat)
    ribbon = ribbon_mat or satin('ribbon', (0.62, 0.42, 0.98))
    prism('ribbon', [(-0.30, 0.74), (0.30, 0.74), (0.30, 1.16), (-0.30, 1.16)], -0.06, 0.10, ribbon, bevel=0.06)
    prism('ribbon_fold', [(-0.34, 1.08), (0.34, 1.08), (0.34, 1.26), (-0.34, 1.26)], -0.09, 0.12, ribbon, bevel=0.06)
    return 0.30, 2.25  # centro vertical y alto de encuadre


SHIELD = [(0.0, 0.80), (0.30, 0.70), (0.62, 0.64), (0.64, 0.10), (0.54, -0.30), (0.30, -0.62),
          (0.0, -0.84), (-0.30, -0.62), (-0.54, -0.30), (-0.64, 0.10), (-0.62, 0.64), (-0.30, 0.70)]


def shield():
    outline = chaikin(SHIELD, 3)
    prism('shield', outline, -0.10, 0.12, iridescent('shield_rim'), bevel=0.07)
    prism('shield_panel', scaled(outline, 0.80), -0.15, 0.0, satin('shield_panel', (0.50, 0.34, 0.95)), bevel=0.05)
    gold = metal('gold', METALS['gold'])
    flame(gold, metal('gold_light', (1.0, 0.88, 0.25)), s=0.95, y=-0.15)
    return 0.0, 1.95


def build(code):
    m = {k: metal(k, v) for k, v in METALS.items()}
    if code == 'medal_gold':
        return medal(m['gold'], lambda: star(m['gold']))
    if code == 'medal_silver':
        return medal(m['silver'], lambda: star(m['silver']))
    if code == 'medal_bronze':
        return medal(m['bronze'], lambda: star(m['bronze']))
    if code == 'medal_capsule':
        return medal(m['gold'], lambda: capsule(m['gold']))
    if code == 'medal_streak_30':
        return medal(m['rose'], lambda: flame(metal('rose_deep', (0.92, 0.22, 0.42)), metal('rose_light', (1.0, 0.80, 0.82)), s=1.05))
    if code == 'medal_streak_100':
        return medal(m['mint'], lambda: laurel(m['mint']), outline=chaikin(ngon(0.76, 6, rot=math.pi / 6), 1))
    if code == 'medal_streak_365':
        iri = iridescent('iri')
        return medal(iri, lambda: crown(m['gold'], gem('ruby', (1.0, 0.25, 0.55))),
                     outline=circle(0.66, n=144, wobble=0.035, lobes=12))
    if code == 'medal_pro_diamond':
        return medal(m['violet'], lambda: diamond(faceted('ice')), rim_mat=m['platinum'])
    if code == 'streak_freeze':
        return shield()
    raise SystemExit(f'Código desconocido: {code}')


# ── Banners (escenas 2:1; x de -2 a 2, z de -1 a 1) ─────────────────────────


def lin(hex_color):
    """#RRGGBB (sRGB) → color lineal de Blender."""
    h = hex_color.lstrip('#')
    out = []
    for i in (0, 2, 4):
        c = int(h[i:i + 2], 16) / 255
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return tuple(out)


def mix(a, b, t):
    return tuple(x + (y - x) * t for x, y in zip(a, b))


WHITE, BLACK = (1, 1, 1), (0, 0, 0)


def glow(name, color, strength=1.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    em = nt.nodes.new('ShaderNodeEmission')
    em.inputs['Color'].default_value = (*color, 1)
    em.inputs['Strength'].default_value = strength
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    nt.links.new(em.outputs['Emission'], out.inputs['Surface'])
    return mat


def backdrop(bottom, top):
    """Plano de fondo con degradado vertical (no le afecta la luz)."""
    mat = bpy.data.materials.new('backdrop')
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    coord = nt.nodes.new('ShaderNodeTexCoord')
    sep = nt.nodes.new('ShaderNodeSeparateXYZ')
    rng = nt.nodes.new('ShaderNodeMapRange')
    rng.inputs['From Min'].default_value = -1
    rng.inputs['From Max'].default_value = 1
    ramp = nt.nodes.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].color = (*bottom, 1)
    ramp.color_ramp.elements[1].color = (*top, 1)
    em = nt.nodes.new('ShaderNodeEmission')
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    nt.links.new(coord.outputs['Object'], sep.inputs['Vector'])
    nt.links.new(sep.outputs['Z'], rng.inputs['Value'])
    nt.links.new(rng.outputs['Result'], ramp.inputs['Fac'])
    nt.links.new(ramp.outputs['Color'], em.inputs['Color'])
    nt.links.new(em.outputs['Emission'], out.inputs['Surface'])
    prism('backdrop', [(-2.6, -1.4), (2.6, -1.4), (2.6, 1.4), (-2.6, 1.4)], 3.0, 3.1, mat, bevel=0)


def band(name, base, amp, freq, phase, y, mat, depth=0.5, bottom=-1.5, amp2=0.0, freq2=1.0):
    """Franja a todo lo ancho con el borde superior ondulado (colinas, olas)."""
    n = 96
    top = []
    for i in range(n + 1):
        x = -2.5 + 5.0 * i / n
        z = base + amp * math.sin(freq * x + phase) + amp2 * math.sin(freq2 * x + phase * 1.7)
        top.append((x, z))
    pts = [(-2.5, bottom)] + top + [(2.5, bottom)]
    return prism(name, list(reversed(pts)), y, y + depth, mat, bevel=0.06)


def ribbon_band(name, base, amp, freq, phase, thickness, y, mat):
    """Cinta ondulada (aurora)."""
    n = 96
    top, low = [], []
    for i in range(n + 1):
        x = -2.5 + 5.0 * i / n
        z = base + amp * math.sin(freq * x + phase)
        t = thickness * (0.75 + 0.25 * math.sin(freq * 1.7 * x + phase))
        top.append((x, z + t))
        low.append((x, z - t))
    return prism(name, top + list(reversed(low)), y, y + 0.1, mat, bevel=0)


def cloud(x, z, y, mat, s=1.0):
    for dx, dz, r in ((-0.26, -0.03, 0.17), (0.0, 0.05, 0.24), (0.27, -0.02, 0.19), (0.12, -0.08, 0.17), (-0.12, -0.08, 0.16)):
        sphere('cloud', (x + dx * s, y, z + dz * s), r * s, mat, scale=(1, 0.6, 0.85))


def pine(x, z, y, h, mat, trunk):
    for k, (rad, off) in enumerate(((0.36, 0.0), (0.29, 0.26), (0.21, 0.50))):
        bpy.ops.mesh.primitive_cone_add(vertices=40, radius1=rad * h, radius2=0, depth=0.48 * h,
                                        location=(x, y, z + (off + 0.34) * h))
        o = bpy.context.object
        bpy.ops.object.shade_smooth()
        o.data.materials.append(mat)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.05 * h, depth=0.2 * h, location=(x, y, z + 0.05 * h))
    bpy.context.object.data.materials.append(trunk)


def stars(count, seed, mat, zmin=-0.2):
    import random
    rnd = random.Random(seed)
    for _ in range(count):
        r = rnd.choice((0.012, 0.016, 0.022, 0.03))
        sphere('star', (rnd.uniform(-2, 2), 2.0, rnd.uniform(zmin, 0.98)), r, mat)


def banner(code):
    if code == 'banner_sunrise':
        c1, c2 = lin('#FF6B35'), lin('#F7931E')
        backdrop(mix(c2, WHITE, 0.35), mix(c1, BLACK, 0.05))
        sphere('sun', (0.0, 2.2, -0.30), 0.60, glow('sun', (1.0, 0.86, 0.45), 1.15), scale=(1, 0.2, 1))
        sphere('halo', (0.0, 2.7, -0.30), 0.95, glow('halo', mix(c2, WHITE, 0.30), 1.0), scale=(1, 0.05, 1))
        cloud(-1.25, 0.42, 1.2, satin('cloud', mix(c2, WHITE, 0.75)), 1.0)
        cloud(1.30, 0.20, 1.2, satin('cloud2', mix(c2, WHITE, 0.75)), 0.8)
        band('hill3', -0.55, 0.10, 1.3, 0.4, 1.0, satin('h3', mix(c1, BLACK, 0.18)))
        band('hill2', -0.72, 0.13, 1.0, 2.2, 0.5, satin('h2', mix(c1, BLACK, 0.38)))
        band('hill1', -0.90, 0.10, 1.6, 4.0, 0.0, satin('h1', mix(c1, BLACK, 0.58)))
    elif code == 'banner_ocean':
        c1, c2 = lin('#2193B0'), lin('#6DD5ED')
        backdrop(mix(c2, WHITE, 0.25), mix(c2, WHITE, 0.6))
        sphere('sun', (1.25, 2.0, 0.50), 0.26, glow('sun', (1.0, 0.98, 0.85), 1.1))
        cloud(-1.2, 0.55, 1.6, satin('cloud', (1, 1, 1)), 0.8)
        band('w4', 0.05, 0.07, 2.6, 0.3, 1.5, satin('w4', mix(c2, WHITE, 0.15)), amp2=0.03, freq2=6)
        band('w3', -0.22, 0.09, 2.2, 2.0, 1.0, satin('w3', c2), amp2=0.03, freq2=5)
        band('w2', -0.50, 0.10, 2.0, 3.6, 0.5, satin('w2', mix(c1, c2, 0.4)), amp2=0.03, freq2=5)
        band('w1', -0.78, 0.09, 2.4, 5.0, 0.0, satin('w1', c1), amp2=0.02, freq2=6)
        bubble = satin('bubble', mix(c2, WHITE, 0.7))
        for x, z, r in ((-1.5, -0.30, 0.06), (-1.32, -0.12, 0.035), (0.35, -0.42, 0.05), (1.55, -0.62, 0.06), (1.70, -0.45, 0.03)):
            sphere('bubble', (x, -0.3, z), r, bubble)
    elif code == 'banner_forest':
        c1, c2 = lin('#134E5E'), lin('#71B280')
        backdrop(mix(c2, WHITE, 0.55), mix(c2, WHITE, 0.2))
        sphere('sun', (-1.2, 2.0, 0.52), 0.24, glow('sun', (1.0, 0.98, 0.85), 1.1))
        band('far', -0.05, 0.14, 1.2, 0.5, 2.0, satin('far', mix(c2, WHITE, 0.25)))
        band('mid', -0.35, 0.12, 1.5, 2.4, 1.2, satin('mid', c2))
        band('near', -0.70, 0.10, 1.1, 4.1, 0.2, satin('near', mix(c1, c2, 0.35)))
        far_pine, mid_pine, near_pine = satin('p1', mix(c1, c2, 0.55)), satin('p2', mix(c1, c2, 0.25)), satin('p3', c1)
        trunk = satin('trunk', mix(c1, BLACK, 0.4))
        for x, z, h in ((-1.7, -0.30, 0.55), (-0.9, -0.42, 0.5), (0.2, -0.36, 0.6), (1.0, -0.26, 0.5), (1.75, -0.36, 0.55)):
            pine(x, z, 1.0, h, far_pine, trunk)
        for x, z, h in ((-1.35, -0.62, 0.8), (-0.35, -0.72, 0.9), (0.65, -0.70, 0.78), (1.45, -0.66, 0.9)):
            pine(x, z, 0.0, h, mid_pine if h < 0.85 else near_pine, trunk)
    elif code == 'banner_galaxy':
        c1, c2 = lin('#667EEA'), lin('#764BA2')
        backdrop(mix(c2, BLACK, 0.45), mix(c1, BLACK, 0.25))
        sphere('neb1', (-1.1, 2.6, 0.2), 0.9, glow('neb1', mix(c1, BLACK, 0.18), 1.0), scale=(1.6, 0.05, 0.7))
        sphere('neb2', (1.2, 2.7, -0.3), 0.8, glow('neb2', mix(c2, BLACK, 0.30), 1.0), scale=(1.5, 0.05, 0.6))
        stars(46, 7, glow('star', (1, 1, 1), 1.4), zmin=-1.0)
        planet = satin('planet', mix(c1, WHITE, 0.35))
        sphere('planet', (0.55, 0.0, -0.05), 0.46, planet)
        bpy.ops.mesh.primitive_torus_add(location=(0.55, 0.0, -0.05), rotation=(math.radians(16), math.radians(-20), 0),
                                         major_radius=0.78, minor_radius=0.045, major_segments=96, minor_segments=12)
        o = bpy.context.object
        o.scale = (1, 1, 0.25)
        bpy.ops.object.shade_smooth()
        o.data.materials.append(satin('ringp', mix(c2, WHITE, 0.6)))
        sphere('moon', (-1.25, 0.0, 0.42), 0.15, satin('moon', mix(c2, WHITE, 0.45)))
        sphere('moon2', (1.62, 0.0, 0.50), 0.07, satin('moon2', mix(c1, WHITE, 0.6)))
    elif code == 'banner_aurora':
        c1, c2 = lin('#00C9A7'), lin('#845EC2')
        backdrop(mix(c2, BLACK, 0.55), (0.012, 0.02, 0.07))
        stars(40, 3, glow('star', (1, 1, 1), 1.3), zmin=0.0)
        ribbon_band('a3', 0.38, 0.16, 1.5, 0.3, 0.16, 1.9, glow('a3', mix(c2, WHITE, 0.1), 0.85))
        ribbon_band('a2', 0.16, 0.18, 1.3, 1.6, 0.17, 1.6, glow('a2', mix(c1, c2, 0.5), 0.9))
        ribbon_band('a1', -0.08, 0.15, 1.7, 3.1, 0.15, 1.3, glow('a1', c1, 0.95))
        peaks = [(-2.5, -1.4), (-2.5, -0.55), (-1.9, -0.20), (-1.4, -0.60), (-0.8, -0.10), (-0.2, -0.62),
                 (0.5, -0.25), (1.0, -0.58), (1.6, -0.05), (2.1, -0.50), (2.5, -0.30), (2.5, -1.4)]
        prism('mount_far', peaks, 0.6, 1.0, satin('mf', mix(c2, BLACK, 0.72)), bevel=0.03)
        prism('mount_near', moved(scaled(list(reversed([(-x, z) for x, z in peaks])), 1.0), dz=-0.32), 0.0, 0.4,
              satin('mn', (0.02, 0.03, 0.08)), bevel=0.03)
    else:
        raise SystemExit(f'Banner desconocido: {code}')
    return 0.0, 2.0


BANNERS = ['banner_sunrise', 'banner_ocean', 'banner_forest', 'banner_galaxy', 'banner_aurora']

ALL = ['medal_bronze', 'medal_silver', 'medal_gold', 'medal_capsule', 'medal_streak_30',
       'medal_streak_100', 'medal_streak_365', 'medal_pro_diamond', 'streak_freeze'] + BANNERS

# ── Escena ──────────────────────────────────────────────────────────────────


def area_light(name, loc, power, color, size):
    data = bpy.data.lights.new(name, 'AREA')
    data.energy = power
    data.color = color
    data.size = size
    obj = bpy.data.objects.new(name, data)
    obj.location = loc
    obj.rotation_euler = (Vector((0, 0, 0.2)) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
    bpy.context.collection.objects.link(obj)


def setup_scene(center_z, height, wide=False):
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = SAMPLES
    scene.cycles.use_denoising = True
    scene.render.film_transparent = not wide
    scene.render.resolution_x = SIZE * 2 if wide else SIZE
    scene.render.resolution_y = SIZE
    if wide:
        scene.render.image_settings.file_format = 'JPEG'
        scene.render.image_settings.color_mode = 'RGB'
        scene.render.image_settings.quality = 88
    else:
        scene.render.image_settings.file_format = 'PNG'
        scene.render.image_settings.color_mode = 'RGBA'
        scene.render.image_settings.compression = 100
    scene.view_settings.view_transform = 'Standard'

    cam = bpy.data.cameras.new('cam')
    cam.type = 'ORTHO'
    cam.ortho_scale = height * 2 if wide else height  # ortho_scale mide el lado mayor
    cam_obj = bpy.data.objects.new('cam', cam)
    cam_obj.location = (0, -10, center_z)
    cam_obj.rotation_euler = (math.pi / 2, 0, 0)
    bpy.context.collection.objects.link(cam_obj)
    scene.camera = cam_obj

    # Entorno: degradado cian → lavanda → rosa → blanco, que es lo que reflejan los metales
    world = bpy.data.worlds.new('world')
    world.use_nodes = True
    scene.world = world
    nt = world.node_tree
    bg = nt.nodes['Background']
    coord = nt.nodes.new('ShaderNodeTexCoord')
    sep = nt.nodes.new('ShaderNodeSeparateXYZ')
    rng = nt.nodes.new('ShaderNodeMapRange')
    rng.inputs['From Min'].default_value = -1
    rng.inputs['From Max'].default_value = 1
    ramp = nt.nodes.new('ShaderNodeValToRGB')
    els = ramp.color_ramp.elements
    els[0].position, els[0].color = 0.0, (0.02, 0.06, 0.10, 1)
    els[1].position, els[1].color = 1.0, (1, 1, 1, 1)
    for pos, col in ((0.45, (0.10, 0.07, 0.22, 1)), (0.72, (0.85, 0.55, 0.85, 1))):
        e = els.new(pos)
        e.color = col
    nt.links.new(coord.outputs['Generated'], sep.inputs['Vector'])
    nt.links.new(sep.outputs['Z'], rng.inputs['Value'])
    nt.links.new(rng.outputs['Result'], ramp.inputs['Fac'])
    nt.links.new(ramp.outputs['Color'], bg.inputs['Color'])
    bg.inputs['Strength'].default_value = 0.85

    area_light('key', (-3.0, -5.0, 4.0), 600, (1, 1, 1), 3)
    area_light('fill', (3.5, -4.0, -0.5), 90, (1.0, 0.70, 0.92), 5)
    area_light('rim', (2.5, 2.0, 3.0), 250, (0.6, 0.9, 1.0), 4)


def render(code, out_dir):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    wide = code in BANNERS
    center_z, height = banner(code) if wide else build(code)
    setup_scene(center_z, height, wide)
    bpy.context.scene.render.filepath = os.path.join(out_dir, code + ('.jpg' if wide else '.png'))
    bpy.ops.render.render(write_still=True)


if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    out = os.path.abspath(args[0]) if args else os.path.abspath('assets/shop')
    os.makedirs(out, exist_ok=True)
    for c in (args[1:] or ALL):
        render(c, out)
        print('RENDER OK', c)
