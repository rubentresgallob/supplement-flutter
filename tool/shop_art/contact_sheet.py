"""Hoja de contactos sobre negro para revisar los renders de un vistazo.

Uso: blender -b --python tool\\shop_art\\contact_sheet.py -- <carpeta> <salida.png> [columnas] [tamaño]
"""
import os
import sys

import bpy
import numpy as np

args = sys.argv[sys.argv.index('--') + 1:]
folder, out = args[0], args[1]
cols = int(args[2]) if len(args) > 2 else 5
cell = int(args[3]) if len(args) > 3 else 256

files = sorted(f for f in os.listdir(folder) if f.endswith(('.png', '.jpg')) and not f.startswith('_'))
rows = (len(files) + cols - 1) // cols
sheet = np.zeros((rows * cell, cols * cell, 4), dtype=np.float32)
sheet[..., 3] = 1

for i, f in enumerate(files):
    img = bpy.data.images.load(os.path.join(folder, f))
    img.colorspace_settings.name = 'Non-Color'  # valores tal cual, sin doble gamma
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    # reducir por vecino más cercano manteniendo proporción dentro de la celda
    scale = min(cell / w, cell / h)
    nw, nh = max(1, int(w * scale)), max(1, int(h * scale))
    ys = (np.arange(nh) / scale).astype(int).clip(0, h - 1)
    xs = (np.arange(nw) / scale).astype(int).clip(0, w - 1)
    small = px[ys][:, xs]
    r, c = rows - 1 - i // cols, i % cols
    y0, x0 = r * cell + (cell - nh) // 2, c * cell + (cell - nw) // 2
    a = small[..., 3:4]
    sheet[y0:y0 + nh, x0:x0 + nw, :3] = small[..., :3] * a + sheet[y0:y0 + nh, x0:x0 + nw, :3] * (1 - a)

res = bpy.data.images.new('sheet', cols * cell, rows * cell, alpha=True)
res.colorspace_settings.name = 'Non-Color'
res.pixels = sheet.ravel()
res.filepath_raw = out
res.file_format = 'PNG'
res.save()
print('SHEET OK', out, files)
