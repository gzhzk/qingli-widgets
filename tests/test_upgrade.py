"""Synthetic filesystem tests; never install or control Rainmeter."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
POWERSHELL = shutil.which('powershell.exe')
TEMP_PARENT = Path(os.environ.get('QINGLI_TEST_ROOT', str(ROOT / 'work/test-fixtures'))).resolve()

def snap(root):
    return {p.relative_to(root).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in root.rglob('*') if p.is_file()}

@unittest.skipUnless(POWERSHELL, 'Windows PowerShell is needed for updater tests')
class UpgradeTests(unittest.TestCase):
    def setUp(self):
        TEMP_PARENT.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix='qingli-upgrade-fixture-', dir=TEMP_PARENT)
        fixture_path = Path(self.temp.name).resolve()
        if fixture_path.parent != TEMP_PARENT or not fixture_path.name.startswith('qingli-upgrade-fixture-'):
            raise RuntimeError('Unexpected fixture directory; refuse recursive cleanup')
        self.addCleanup(self.temp.cleanup)
        self.base = fixture_path
        self.package = self.base / 'package'
        shutil.copytree(ROOT / 'Qingli', self.package / 'Qingli')
        (self.package / 'tools').mkdir()
        shutil.copyfile(ROOT / 'tools/Install-Upgrade.ps1', self.package / 'tools/Install-Upgrade.ps1')
        self.skins = self.base / 'portable/Skins'
        self.skins.mkdir(parents=True)
        self.dest = self.skins / 'Qingli'
        self.host_ini = self.skins.parent / 'Rainmeter.ini'
        self.host_ini.write_bytes(b'[Qingli\\Widgets\\Calendar]\nWindowX=321\nWindowY=123\n')
        other = self.skins / 'OtherWidget/Other.ini'
        other.parent.mkdir()
        other.write_bytes(b'other skin fixture')

    def run_updater(self, apply=False, skins=None):
        command = [POWERSHELL, '-NoLogo', '-NoProfile', '-NonInteractive',
                   '-ExecutionPolicy', 'Bypass', '-File', str(self.package / 'tools/Install-Upgrade.ps1'),
                   '-SkinsDirectory', str(skins or self.skins)]
        if apply: command.append('-Apply')
        return subprocess.run(command, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=45)

    def test_preview_does_not_create_or_modify_files(self):
        before = snap(self.base)
        result = self.run_updater()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('PREVIEW ONLY', result.stdout)
        self.assertEqual(snap(self.base), before)
        self.assertFalse(self.dest.exists())

    def test_fresh_install_only_writes_qingli(self):
        before = snap(self.skins.parent)
        result = self.run_updater(True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(snap(self.dest), snap(self.package / 'Qingli'))
        after = snap(self.skins.parent)
        for rel, value in before.items(): self.assertEqual(after[rel], value)
        self.assertFalse((self.dest / '@Resources/Refined/QWeather.local.json').exists())

    def test_upgrade_preserves_user_files_and_backs_up_managed_code(self):
        shutil.copytree(self.package / 'Qingli', self.dest)
        fixtures = {
            '@Resources/Refined/Settings.inc': b'[Variables]\nScale=1.25\nWeatherProvider=QWeather\n',
            '@Resources/Refined/Accent.inc': b'[Variables]\nCalendarAccent=Purple\n',
            '@Resources/Refined/Material.inc': b'[Variables]\nMaterialProfile=Quiet\n',
            '@Resources/Refined/QWeather.local.json': b'fixture-only-preserve-verbatim',
            'Widgets/Weather/custom-cache.json': b'fixture-only-cache',
            'UserNotes.txt': b'user notes fixture',
        }
        for rel, content in fixtures.items():
            p = self.dest / rel; p.parent.mkdir(parents=True, exist_ok=True); p.write_bytes(content)
        code = self.dest / '@Resources/Refined/Calendar.lua'
        code.write_bytes(b'-- old managed code fixture\n')
        protected_before = snap(self.skins.parent)
        result = self.run_updater(True)
        self.assertEqual(result.returncode, 0, result.stderr)
        for rel, content in fixtures.items(): self.assertEqual((self.dest / rel).read_bytes(), content)
        self.assertEqual(code.read_bytes(), (self.package / 'Qingli/@Resources/Refined/Calendar.lua').read_bytes())
        backups = list((self.dest / '@UpgradeBackup').rglob('Calendar.lua'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_bytes(), b'-- old managed code fixture\n')
        self.assertFalse(list((self.dest / '@UpgradeBackup').rglob('QWeather.local.json')))
        after = snap(self.skins.parent)
        self.assertEqual(after['Rainmeter.ini'], protected_before['Rainmeter.ini'])
        self.assertEqual(after['Skins/OtherWidget/Other.ini'], protected_before['Skins/OtherWidget/Other.ini'])
        second = self.run_updater(True)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual(snap(self.skins.parent), after)

    def test_corrupt_payload_fails_before_destination_writes(self):
        (self.package / 'Qingli/README.txt').write_bytes(b'tampered fixture')
        before = snap(self.base)
        result = self.run_updater(True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Payload hash mismatch', result.stderr)
        self.assertEqual(snap(self.base), before)

    def test_manifest_traversal_fails_before_writes(self):
        p = self.package / 'Qingli/MANIFEST.json'
        manifest = json.loads(p.read_text(encoding='utf-8'))
        manifest['../outside.txt'] = '0' * 64
        p.write_text(json.dumps(manifest), encoding='utf-8')
        before = snap(self.base)
        result = self.run_updater(True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Invalid manifest path', result.stderr)
        self.assertEqual(snap(self.base), before)

    def test_extra_runtime_credential_rejected_before_writes(self):
        p = self.package / 'Qingli/@Resources/Refined/QWeather.local.json'
        p.write_bytes(b'fixture-only-not-a-secret')
        manifest_path = self.package / 'Qingli/MANIFEST.json'
        manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
        manifest['@Resources/Refined/QWeather.local.json'] = hashlib.sha256(p.read_bytes()).hexdigest()
        manifest_path.write_text(json.dumps(manifest), encoding='utf-8')
        before = snap(self.base)
        result = self.run_updater(True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('private runtime file', result.stderr)
        self.assertEqual(snap(self.base), before)

    def test_wrong_target_directory_rejected(self):
        before = snap(self.base)
        result = self.run_updater(True, self.base / 'NotSkins')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('local directory named Skins', result.stderr)
        self.assertEqual(snap(self.base), before)

    def test_source_destination_overlap_rejected(self):
        before = snap(self.base)
        result = self.run_updater(True, self.package / 'Skins')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('source package and destination overlap', result.stderr)
        self.assertEqual(snap(self.base), before)

    def test_destination_directory_conflict_fails_before_writes(self):
        (self.dest / 'README.txt').mkdir(parents=True)
        before = snap(self.base)
        result = self.run_updater(True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('occupied by a directory', result.stderr)
        self.assertEqual(snap(self.base), before)

if __name__ == '__main__': unittest.main()
