import contextlib
import fcntl
import importlib.util
import io
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("collect_databases", Path(__file__).resolve().parents[1] / "tools/collect_databases.py")
queue = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(queue)


class CollectionTests(unittest.TestCase):
    def fixture(self, root):
        (root / "data/seeds").mkdir(parents=True)
        (root / "data/reports").mkdir(parents=True)
        for name in ["wrath", "wrath-generic", "cata", "legacy"]:
            (root / "data/seeds" / (name + ".json")).write_text(json.dumps({"ids": [117]}))

    def report(self, root, version, failures=None, unresolved=None):
        (root / "data/reports" / (version + ".json")).write_text(json.dumps({
            "fetched": 1, "included": 1, "failures": failures or {},
            "unresolved": unresolved or {}, "unavailable": {}}))

    def test_source_denial_stops_all_remaining_profiles_without_activation(self):
        for code in (403, 429):
            with self.subTest(code=code), tempfile.TemporaryDirectory() as folder:
                root = Path(folder)
                self.fixture(root)
                self.report(root, "wrath", {"117": f"HTTP {code}; stop fetching"})
                with patch.object(queue, "ROOT", root), patch.object(queue, "run_import", return_value=0) as run, contextlib.redirect_stdout(io.StringIO()):
                    self.assertEqual(queue.collect_profiles(["wrath", "cata"], 2), 2)
                self.assertEqual(run.call_count, 1)
                command = run.call_args.args[0]
                self.assertNotIn("--activate", command)
                self.assertIn(str(root / "data/seeds/wrath-generic.json"), command)
                state = json.loads((root / ".cache/catalog/collection.json").read_text())
                self.assertEqual(state["state"], "blocked")
                self.assertEqual(state["profiles"]["cata"]["state"], "queued")

    def test_unparsed_effects_do_not_prevent_collecting_other_clients(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            self.fixture(root)
            self.report(root, "wrath", unresolved={"117": ["Dynamic effect"]})
            self.report(root, "cata")
            with patch.object(queue, "ROOT", root), patch.object(queue, "run_import", return_value=0) as run, contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(queue.collect_profiles(["wrath", "cata"], 2), 0)
            self.assertEqual(run.call_count, 2)
            self.assertFalse((root / "data/published").exists())
            state = json.loads((root / ".cache/catalog/collection.json").read_text())
            self.assertEqual(state["profiles"]["wrath"]["unresolved"], 1)

    def test_failed_import_does_not_read_an_old_success_report(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            self.fixture(root)
            self.report(root, "wrath")
            with patch.object(queue, "ROOT", root), patch.object(queue, "run_import", return_value=1) as run, contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(queue.collect_profiles(["wrath", "cata"], 2), 1)
            self.assertEqual(run.call_count, 1)
            state = json.loads((root / ".cache/catalog/collection.json").read_text())
            self.assertEqual(state["profiles"]["wrath"]["state"], "error")

    def test_interruption_checkpoints_the_queue_and_stops(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            self.fixture(root)
            with patch.object(queue, "ROOT", root), patch.object(queue, "run_import", side_effect=KeyboardInterrupt) as run, contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(queue.collect_profiles(["wrath", "cata"], 2), 130)
            self.assertEqual(run.call_count, 1)
            state = json.loads((root / ".cache/catalog/collection.json").read_text())
            self.assertEqual(state["state"], "interrupted")
            self.assertEqual(state["profiles"]["cata"]["state"], "queued")

    def test_second_queue_cannot_start_requests(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            self.fixture(root)
            lock_path = root / ".cache/catalog/collection.lock"
            lock_path.parent.mkdir(parents=True)
            with lock_path.open("a+") as lock:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
                with patch.object(queue, "ROOT", root), patch("sys.argv", ["collect_databases.py", "wrath"]), patch.object(queue, "run_import") as run, contextlib.redirect_stderr(io.StringIO()):
                    with self.assertRaises(SystemExit):
                        queue.main()
                    run.assert_not_called()

    def test_status_uses_rebuilt_report_instead_of_stale_queue_counts(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            self.fixture(root)
            self.report(root, "wrath")
            (root / "data/published").mkdir()
            (root / "data/published/wrath.json").write_text(json.dumps({"activation": {"enabled": True}}))
            output = io.StringIO()
            with patch.object(queue, "ROOT", root):
                queue.write_status({"state": "collected", "profiles": {"wrath": {
                    "state": "collected", "included": 0, "unresolved": 10}}})
                with contextlib.redirect_stdout(output):
                    queue.show_status()
            profile = json.loads(output.getvalue())["profiles"]["wrath"]
            self.assertEqual(profile["included"], 1)
            self.assertEqual(profile["unresolved"], 0)
            self.assertTrue(profile["enabled"])


if __name__ == "__main__":
    unittest.main()
