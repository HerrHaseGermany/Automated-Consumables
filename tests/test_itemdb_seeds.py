import importlib.util
import unittest
from pathlib import Path

SPEC = importlib.util.spec_from_file_location("seed_from_itemdb", Path(__file__).resolve().parents[1] / "tools/seed_from_itemdb.py")
seeds = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(seeds)


class SeedTests(unittest.TestCase):
    def test_era_generic_subclasses_do_not_drop_food(self):
        core = '[117]="1\\0310\\031INVTYPE_NON_EQUIP_IGNORE\\0315\\031",\n[118]="1\\0310\\031INVTYPE_NON_EQUIP_IGNORE\\0315\\031",'
        self.assertEqual(seeds.candidate_ids(core, ""), [117, 118])

    def test_named_stones_are_added_only_when_they_are_consumables(self):
        core = '[117]="1\\0315\\031NONE\\0315\\031",\n[5512]="1\\0310\\031NONE\\0311\\031",\n[2593]="1\\0318\\031NONE\\0311\\031",'
        names = '[5512]="Minor Healthstone",\n[999]="Recipe: Healthstone",'
        self.assertEqual(seeds.candidate_ids(core, names), [117, 5512])

    def test_unknown_encoding_does_not_emit_empty_seed(self):
        with self.assertRaises(ValueError):
            seeds.candidate_ids('[117]="changed-format",', "")

    def test_supplementary_names_find_generic_recovery_candidates(self):
        core = '\n'.join('[%d]="1\\031%s\\031NONE\\0311\\031",' % (i, s)
                         for i, s in [(1, '0'), (2, '8'), (3, '6'), (4, '8'), (5, '8')])
        names = '\n'.join('[%d]="%s",' % (i, n) for i, n in [
            (1, 'Field Ration'), (2, 'Healing Salve'), (3, 'Bandage Recipe'),
            (4, 'Bread'), (5, 'Rune of Strength'), (99, 'Mana Potion')])
        self.assertEqual(seeds.generic_candidate_ids(core, names, {4}), [1, 2])


if __name__ == "__main__":
    unittest.main()
