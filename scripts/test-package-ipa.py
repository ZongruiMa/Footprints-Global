"""Exercise packaging guards on synthetic bundles; this does not compile iOS."""
import importlib.util
from pathlib import Path
import plistlib
import struct
import tempfile
import zipfile

spec = importlib.util.spec_from_file_location('package_ipa', Path(__file__).with_name('package-ipa.py'))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    app = root / 'TravelMemory.app'
    app.mkdir()
    info = {'CFBundleSupportedPlatforms': ['iPhoneOS'], 'CFBundleExecutable': 'TravelMemory',
            'CFBundleIdentifier': 'local.personal.travelmemory', 'MinimumOSVersion': '17.0'}
    (app / 'TravelMemory').write_bytes(struct.pack('<II', 0xFEEDFACF, 0x0100000C) + bytes(24))
    (app / 'china_provinces.geojson').write_text('{}')
    def write_info():
        (app / 'Info.plist').write_bytes(plistlib.dumps(info))
    write_info()
    module.package(app, root / 'output/Footprints.ipa')
    with zipfile.ZipFile(root / 'output/Footprints.ipa') as archive:
        assert 'Payload/TravelMemory.app/TravelMemory' in archive.namelist()
    info['CFBundleSupportedPlatforms'] = ['iPhoneSimulator']
    write_info()
    try:
        module.package(app, root / 'simulator.ipa')
    except ValueError as error:
        assert 'simulator' in str(error)
    else:
        raise AssertionError('Simulator bundle was accepted')
    info['CFBundleSupportedPlatforms'] = ['iPhoneOS']
    write_info()
    (app / 'TravelMemory').write_bytes(b'not a device executable')
    try:
        module.package(app, root / 'invalid.ipa')
    except ValueError as error:
        assert 'arm64' in str(error)
    else:
        raise AssertionError('Invalid executable was accepted')
print('PASS: IPA layout, simulator rejection and invalid executable rejection (synthetic fixtures only).')
