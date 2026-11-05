"""Build local Qingli ZIP candidates from a strict source allowlist. No network."""
import argparse
import codecs
import hashlib
import json
import os
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SKIN = ROOT / 'Qingli'
ICONS = ['cloudy-night', 'cloudy', 'drizzle', 'fog', 'location', 'night',
         'overcast', 'rain', 'snow', 'sunny', 'thunder-night', 'thunder', 'unknown']
SCRIPTS = ['Accent.lua', 'Bootstrap.lua', 'Calendar.lua', 'FetchQWeather.ps1', 'Json.lua', 'Launch.lua',
           'Lunar.lua', 'Material.lua', 'QWeather.lua', 'Storage.lua', 'Weather.lua']
ROOT_FILES = ['README.md', 'LICENSE.txt', 'ATTRIBUTION.md', 'CHANGELOG.md', 'VERSION',
              'SOURCE-NOTES.json', 'VALIDATION.md', 'RELEASE-NOTES.md', '.gitignore', '.gitattributes']
DOC_FILES = ['FEATURES.md', 'NETWORK-AND-PRIVACY.md', 'QWEATHER.md', 'TESTING.md',
             'MAINTAINING.md', 'INSTALL-UPGRADE.md', 'PACKAGING.md', 'VM-INSTALL-TEST.md']
DEV_FILES = ['tools/build.py', 'tests/test_build.py', 'tests/test_upgrade.py']
PREVIEW_FILES = ['docs/images/preview.png']
FIXED_TIME = (2026, 11, 4, 0, 0, 0)

def digest(data): return hashlib.sha256(data).hexdigest()
def decode(data):
    return data.decode('utf-16' if data.startswith(codecs.BOM_UTF16_LE) else 'utf-8-sig')
def skin_files():
    resources = ['@Resources/Refined/' + s for s in SCRIPTS]
    resources += ['@Resources/Refined/' + s for s in
                  ['Settings.defaults.inc', 'Accent.defaults.inc', 'Material.defaults.inc', 'QWeather.local.example.json']]
    resources += ['@Resources/Refined/Icons/' + s + '.png' for s in ICONS]
    resources += ['@Resources/Refined/Icons/location.svg']
    return sorted(resources + ['Start/Start.ini', 'Widgets/Calendar/Refined.ini',
        'Widgets/Weather/Refined.ini', 'LICENSE.txt', 'THIRD-PARTY-METEOCONS-LICENSE.txt',
        'THIRD-PARTY-PHOSPHOR-LICENSE.txt', 'ICON-SOURCE.txt', 'METEOCONS-SOURCES.json', 'README.txt'])

def read_file(path):
    if path.is_symlink() or not path.is_file() or not path.resolve().is_relative_to(ROOT):
        raise ValueError('Missing file or unsafe source path: ' + path.name)
    for parent in path.parents:
        if parent == ROOT: break
        if parent.is_symlink(): raise ValueError('Source directory links are unsupported')
    return path.read_bytes()

def validate(version, files):
    if not re.fullmatch(r'\d+\.\d+\.\d+-beta\.\d+', version):
        raise ValueError('VERSION must use the Beta version sequence')
    for relative in ['Start/Start.ini', 'Widgets/Calendar/Refined.ini', 'Widgets/Weather/Refined.ini']:
        content = decode(files['Qingli/' + relative])
        if not re.search(r'(?m)^Version=' + re.escape(version) + r'\s*$', content):
            raise ValueError('INI version mismatch: ' + relative)
        if not re.search(r'(?m)^Name=Qingli', content): raise ValueError('INI brand mismatch')
    if json.loads(decode(files['SOURCE-NOTES.json']))['skin_metadata_version'] != version:
        raise ValueError('Source notes version mismatch')
    settings = decode(files['Qingli/@Resources/Refined/Settings.defaults.inc'])
    defaults = {'WeatherProvider': 'OpenMeteo', 'DirectRouteVerified': '0',
                'LocationMode': 'AutoIP', 'Scale': '0.9', 'ManualCity': '广州市',
                'ManualLatitude': '23.11667', 'ManualLongitude': '113.25', 'WeekStartsMonday': '1'}
    for key, value in defaults.items():
        if not re.search(r'(?m)^' + re.escape(key + '=' + value) + r'\s*$', settings):
            raise ValueError('Public configuration default changed: ' + key)
    if json.loads(decode(files['Qingli/@Resources/Refined/QWeather.local.example.json'])) != {'apiHost': '', 'apiKey': ''}:
        raise ValueError('Credential example must remain empty')
    if files['LICENSE.txt'] != files['Qingli/LICENSE.txt']:
        raise ValueError('Root and skin licenses differ')
    icon_sources = json.loads(decode(files['Qingli/METEOCONS-SOURCES.json']))
    for item in icon_sources['assets']:
        if digest(files['Qingli/@Resources/Refined/Icons/' + item['file']]) != item['sha256']:
            raise ValueError('Meteocons hash mismatch')
    for relative, data in files.items():
        if relative.endswith('.png'): continue
        content = decode(data)
        if re.search(r'-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----|\b(?:gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,}|AKIA[A-Z0-9]{16})\b', content):
            raise ValueError('Possible credential in ' + relative)
        if re.search(r'(?i)\b[A-Z]:[\\/](?:Users|Documents and Settings|home)[\\/]', content):
            raise ValueError('Personal machine path in ' + relative)
        if re.search(r'(?<![\d.])(?:\d{1,3}\.){3}\d{1,3}(?![\d.])', content):
            raise ValueError('IPv4 literal needs review: ' + relative)
        if re.search(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b', content):
            raise ValueError('Email needs review: ' + relative)
        if relative.endswith('.json'): json.loads(content)
        if relative.endswith('.md'):
            for link in re.findall(r'\]\(([^)]+)\)', content):
                if link.startswith(('https://', 'http://', '#')): continue
                target = (Path(relative).parent / link.split('#', 1)[0]).as_posix()
                if target not in files: raise ValueError('Broken local link: ' + relative + ' -> ' + link)
        if relative.endswith(('.ini', '.inc')):
            for key, value in re.findall(r'(?m)^([^;\[\]\r\n=]+)=([^\r\n]*)', content):
                if key.lower().startswith('@include') or key.lower() == 'scriptfile':
                    target = 'Qingli/@Resources/' + value.removeprefix('#@#').replace('\\', '/')
                    if not value.startswith('#@#') or (target not in files and target not in {'Qingli/@Resources/Refined/Settings.inc', 'Qingli/@Resources/Refined/Accent.inc', 'Qingli/@Resources/Refined/Material.inc'}):
                        raise ValueError('Broken skin reference: ' + relative)

def zip_bytes(path, files, prefix=''):
    with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for relative, data in sorted(files.items()):
            info = zipfile.ZipInfo(prefix + relative, date_time=FIXED_TIME)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)

def build(output):
    output = Path(os.path.normpath(os.path.join(os.getcwd(), str(output)))).resolve()
    if output == ROOT or ROOT.is_relative_to(output) or output.is_relative_to(SKIN):
        raise ValueError('Output must not overlap source files or the skin payload')
    version = (ROOT / 'VERSION').read_text(encoding='utf-8').strip()
    selected = ['Qingli/' + rel for rel in skin_files()]
    selected += ROOT_FILES + ['docs/' + rel for rel in DOC_FILES] + DEV_FILES + PREVIEW_FILES + ['tools/Install-Upgrade.ps1']
    files = {rel: read_file(ROOT / rel) for rel in selected}
    # Reject any extra file in the skin, even if the allowlist would omit it.
    actual = {p.relative_to(SKIN).as_posix() for p in SKIN.rglob('*') if p.is_file()}
    if actual - {'MANIFEST.json'} != set(skin_files()):
        raise ValueError('Unexpected or missing skin files; use a clean source checkout')
    validate(version, files)
    manifest = {rel.removeprefix('Qingli/'): digest(data) for rel, data in files.items() if rel.startswith('Qingli/')}
    manifest_data = (json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + '\n').encode('utf-8')
    (SKIN / 'MANIFEST.json').write_bytes(manifest_data)
    files['Qingli/MANIFEST.json'] = manifest_data
    file_list = ''.join(f'{digest(data)}  {rel}\n' for rel, data in sorted(files.items())).encode('utf-8')
    (ROOT / 'FILES.sha256').write_bytes(file_list)
    files['FILES.sha256'] = file_list
    output.mkdir(parents=True, exist_ok=True)
    skin_archive = output / f'Qingli-v{version}-skin.zip'
    source_archive = output / f'Qingli-v{version}-source.zip'
    skin_payload = {rel: data for rel, data in files.items() if rel not in DEV_FILES and rel not in {'.gitignore', 'FILES.sha256'}}
    zip_bytes(skin_archive, skin_payload)
    zip_bytes(source_archive, files, 'qingli-widgets/')
    hashes = ''.join(f'{digest(p.read_bytes())}  {p.name}\n' for p in [skin_archive, source_archive])
    (output / 'SHA256SUMS.txt').write_text(hashes, encoding='ascii', newline='\n')
    return {'version': version, 'skin_files': len(manifest), 'source_archive_files': len(files),
            'skin_archive_files': len(skin_payload), 'files': [skin_archive.name, source_archive.name, 'SHA256SUMS.txt'],
            'rmskin_created': False, 'published': False}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', default=str(ROOT / 'dist'))
    args = parser.parse_args()
    print(json.dumps(build(args.output), ensure_ascii=False, indent=2))
