"""Package an unsigned iphoneos bundle for local AltStore signing."""
from pathlib import Path
import hashlib
import json
import os
import plistlib
import struct
import sys
import zipfile


def package(app: Path, output: Path) -> None:
    info = plistlib.loads((app / 'Info.plist').read_bytes())
    if info.get('CFBundleSupportedPlatforms') != ['iPhoneOS']:
        raise ValueError('Refusing a simulator or non-iPhoneOS bundle')
    executable = info.get('CFBundleExecutable', '')
    if not executable or Path(executable).name != executable:
        raise ValueError('Invalid executable name')
    binary = (app / executable).read_bytes()
    if len(binary) < 32 or struct.unpack_from('<II', binary) != (0xFEEDFACF, 0x0100000C):
        raise ValueError('Expected a 64-bit arm64 Mach-O executable')
    if not (app / 'china_provinces.geojson').exists():
        raise ValueError('Bundled offline map is missing')
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(app.rglob('*')):
            if path.is_symlink():
                raise ValueError(f'Unexpected bundle symlink: {path.name}')
            if path.is_file():
                archive.write(path, 'Payload/' + app.name + '/' + path.relative_to(app).as_posix())
    with zipfile.ZipFile(output) as archive:
        if archive.testzip() is not None:
            raise ValueError('IPA integrity verification failed')
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    (output.parent / 'SHA256SUMS.txt').write_text(f'{digest}  {output.name}\n', encoding='utf-8')
    metadata = {
        'bundleIdentifier': info['CFBundleIdentifier'],
        'minimumOSVersion': info.get('MinimumOSVersion'),
        'version': info.get('CFBundleShortVersionString'),
        'build': info.get('CFBundleVersion'),
        'commit': os.environ.get('GITHUB_SHA', 'local'),
        'signing': 'unsigned; sign locally using your own Apple ID with AltStore',
        'sha256': digest,
    }
    (output.parent / 'build-info.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Packaged {output.name}: {output.stat().st_size} bytes; SHA256 {digest}')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit('Usage: package-ipa.py path/to/TravelMemory.app path/to/Footprints.ipa')
    package(Path(sys.argv[1]), Path(sys.argv[2]))
