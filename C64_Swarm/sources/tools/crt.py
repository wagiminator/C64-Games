# Write a Magic Desk (hardware type 19) cartridge in VICE CRT format
import struct

def magic_desk_crt(rom, name):
    """rom: raw image (multiple of 8 KB), name: cartridge name -> CRT bytes"""
    assert len(rom) % 0x2000 == 0
    hdr = b'C64 CARTRIDGE   ' + struct.pack('>IHHBB', 0x40, 0x0100, 19, 0, 1) + bytes(6)
    hdr += name.encode('ascii')[:32].ljust(32, b'\0')
    out = bytearray(hdr)
    for bank in range(len(rom) // 0x2000):
        out += b'CHIP' + struct.pack('>IHHHH', 0x2010, 0, bank, 0x8000, 0x2000)
        out += rom[bank * 0x2000:(bank + 1) * 0x2000]
    return bytes(out)
