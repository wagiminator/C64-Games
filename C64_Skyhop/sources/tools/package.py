# Build the distribution images from the assembled game (build/skyhop.prg):
#   build/skyhop_ip.prg  crunched in-place image (used by disk, cartridge and tape)
#   build/skyhop.d64     1541 disk with the 2-bit fastloader
#   build/skyhop.bin     64 KB Magic Desk ROM image (8 banks of 8 KB)
#   build/skyhop.crt     the same as VICE CRT file (hardware type 19)
import subprocess, os, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
B = os.path.join(ROOT, 'build')
TS = os.environ.get('TSCRUNCH', 'tscrunch')
POL = sys.argv[1] if len(sys.argv) > 1 else '0'
sys.path.insert(0, os.path.dirname(__file__))
import d64 as D64
import crt as CRT

def run(*a, **kw):
    r = subprocess.run(a, capture_output=True, text=True, **kw)
    if r.returncode != 0:
        print(r.stdout, r.stderr); raise SystemExit(1)
    return r.stdout

# ---- crunch the game into an in-place decrunching image
game = os.path.join(B, 'skyhop.prg')
ip = os.path.join(B, 'skyhop_ip.prg')
run(TS, '-i', game, ip)
blob = open(ip, 'rb').read()
la = blob[0] | blob[1] << 8
print("game %d bytes -> crunched %d bytes, load $%04x..$%04x" % (os.path.getsize(game), len(blob), la, la + len(blob) - 2))
assert la + len(blob) - 2 < 0xd000

# ---- disk: tiny boot file + data file read by the fastloader
LD = os.path.join(ROOT, 'src', 'loader')
boot = os.path.join(B, 'boot.prg')
run('64tass', '-q', '-C', '-a', '--cbm-prg', '-D', 'POLARITY=%s' % POL, '-D', 'NOREAD=0', '-o', boot,
    '-L', os.path.join(B, 'boot.lst'), 'boot.asm', cwd=LD)
img = D64.build([('skyhop', open(boot, 'rb').read(), 10), ('skyhop data', blob, 14)], 'skyhop', 'sk')
open(os.path.join(B, 'skyhop.d64'), 'wb').write(img)
print("disk ok")

# ---- cartridge: boot code in bank 0, crunched game behind it
cb = os.path.join(B, 'cartboot.bin')
run('64tass', '-q', '-C', '-a', '-b', '-D', 'BLOBLEN=%d' % (len(blob) - 2), '-o', cb,
    '-L', os.path.join(B, 'cart.lst'), 'cart.asm', cwd=LD)
rom = bytearray(65536)
c = open(cb, 'rb').read()
assert len(c) <= 0x400
rom[0:len(c)] = c
assert 0x400 + len(blob) <= 65536
rom[0x400:0x400 + len(blob)] = blob
open(os.path.join(B, 'skyhop.bin'), 'wb').write(rom)
open(os.path.join(B, 'skyhop.crt'), 'wb').write(CRT.magic_desk_crt(bytes(rom), 'SKYHOP'))
print("cartridge ok")
