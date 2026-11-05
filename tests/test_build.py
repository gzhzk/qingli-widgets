"""Artifact/packaging tests using temporary directories and synthetic edits."""
import hashlib
import importlib.util
import os
from pathlib import Path
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TEMP_PARENT = Path(os.environ.get('QINGLI_TEST_ROOT', str(ROOT / 'work/test-fixtures'))).resolve()
spec = importlib.util.spec_from_file_location('qingli_build', ROOT / 'tools/build.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)

class BuildTests(unittest.TestCase):
    def test_deterministic_archives_and_complete_hashes(self):
        TEMP_PARENT.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='qingli-build-fixture-', dir=TEMP_PARENT) as temp:
            self.assertEqual(Path(temp).resolve().parent, TEMP_PARENT)
            self.assertTrue(Path(temp).name.startswith('qingli-build-fixture-'))
            one, two = Path(temp) / 'one', Path(temp) / 'two'
            result = builder.build(one)
            builder.build(two)
            self.assertFalse(result['rmskin_created'])
            for name in result['files']:
                self.assertEqual((one / name).read_bytes(), (two / name).read_bytes())
            for line in (one / 'SHA256SUMS.txt').read_text().splitlines():
                digest, name = line.split('  ', 1)
                self.assertEqual(hashlib.sha256((one / name).read_bytes()).hexdigest(), digest)
            with zipfile.ZipFile(one / ('Qingli-v' + result['version'] + '-skin.zip')) as archive:
                self.assertIsNone(archive.testzip())
                self.assertIn('Qingli/Start/Start.ini', archive.namelist())
                self.assertIn('tools/Install-Upgrade.ps1', archive.namelist())
                self.assertNotIn('Qingli/@Resources/Refined/QWeather.local.json', archive.namelist())
                self.assertFalse(any(n.endswith(('.log', '.bak', '.exe', '.dll')) for n in archive.namelist()))

    def test_version_mismatch_rejected(self):
        files = {rel: builder.read_file(ROOT / rel) for rel in
                 ['Qingli/' + name for name in builder.skin_files()] + builder.ROOT_FILES +
                 ['docs/' + name for name in builder.DOC_FILES] + builder.DEV_FILES + ['tools/Install-Upgrade.ps1']}
        with self.assertRaises(ValueError): builder.validate('0.1.0-beta.99', files)

    def test_output_cannot_replace_source_root(self):
        with self.assertRaises(ValueError): builder.build(ROOT)

    def test_relative_output_resolves_to_the_requested_sibling(self):
        TEMP_PARENT.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='qingli-build-fixture-', dir=TEMP_PARENT) as temp:
            fixture = Path(temp).resolve()
            self.assertEqual(fixture.parent, TEMP_PARENT)
            project = fixture / 'project'
            project.mkdir()
            previous = Path.cwd()
            try:
                os.chdir(project)
                result = builder.build('../release')
                for name in result['files']: self.assertTrue((fixture / 'release' / name).is_file())
                self.assertFalse((project / 'release').exists())
            finally:
                os.chdir(previous)

if __name__ == '__main__': unittest.main()
