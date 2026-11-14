import importlib.util
import unittest
import tempfile
import contextlib
import io
import json
import os
from unittest.mock import patch
from pathlib import Path

SPEC = importlib.util.spec_from_file_location("import_database", Path(__file__).resolve().parents[1] / "tools/import_database.py")
db = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(db)


def raw(text, subclass=5, name="Test Food", use=None, item_id=117):
    return {"id": item_id, "name": name, "class": 0, "subclass": subclass,
            "tooltip": text, "item": {"reqlevel": 5}, "use": use or {}}


@patch.dict(os.environ, {"AC_DATABASE_SOURCE_URL": "https://catalog.example"})
class ImportTests(unittest.TestCase):
    def assert_client_deferred(self, record, issues):
        self.assertEqual(issues, [])
        self.assertTrue(record["runtimeRestorationRequired"])
        self.assertTrue(record["sourceIssues"])
        self.assertEqual(sum(record[k] for k in ("h", "m", "hp", "mp")), 0)

    def test_healthstones_restore_life_and_empty_gems_are_not_recovery(self):
        value = raw("Use: Instantly restores 600 life. (2 Min Cooldown)", subclass=0, name="Healthstone")
        record, issues = db.normalize(value, "forever")
        self.assertEqual(issues, [])
        self.assertEqual((record["kind"], record["h"]), ("healthstone", 600))
        record, issues = db.normalize(raw("Empty Mana Gem Item Level 28 Conjured Item Unique", subclass=0, name="Empty Mana Gem"))
        self.assertIsNone(record)
        self.assertEqual(issues, [])

    def test_soulstone_family_requires_a_resurrection_effect(self):
        for text, name in [("Charged Soulstone Item Level 8 Conjured Item Unique", "Charged Soulstone"),
                           ("Use: Crush the stone and increase reputation by 1000. Can only be used on Argus.", "Demon's Soulstone")]:
            record, issues = db.normalize(raw(text, subclass=8, name=name))
            self.assertIsNone(record)
            self.assertEqual(issues, [])
        value = raw("Use: Stores the soul of the target, allowing resurrection upon death.", subclass=8, name="Soulstone")
        record, issues = db.normalize(value, "retail")
        self.assertEqual(issues, [])
        self.assertEqual(record["kind"], "soulstone")

    def test_reviewed_dynamic_healthstone_is_a_family_without_fake_amounts(self):
        for version, text in [
            ("cata", "Use: Instantly restores [17183 health][health equal to 45% of the base health of a Warlock your level]."),
            ("mop", "Use: [ Glyph of Healthstone : Restores 40% of your health over until cancelled / Instantly restores 20% of your health.]"),
        ]:
            value = raw(text, subclass=0, name="Healthstone", item_id=5512)
            record, issues = db.normalize(value, version)
            self.assertEqual(issues, [])
            self.assertEqual(record["kind"], "healthstone")
            self.assertTrue(record["familyOnlyRestoration"])
            self.assertEqual(sum(record[k] for k in ["h", "m", "hp", "mp"]), 0)
            other, issues = db.normalize(value, "retail")
            self.assert_client_deferred(other, issues)
            self.assertNotIn("familyOnlyRestoration", other)

    def test_conditional_health_effects_are_not_added(self):
        for text in ["Restores 40% of your health over until cancelled / Instantly restores 20% of your health.", "Restores 100 health or 200 mana."]:
            record, issues = db.normalize(raw(text, subclass=1, name="Conditional Potion"))
            self.assertIsNone(record)
            self.assertTrue(issues)

    def test_mop_loose_mana_uses_documented_equal_total_not_zero_placeholder(self):
        value = raw("Use: Restores [ Glyph of Loose Mana : 0 mana over until cancelled / 45000 mana.]", subclass=0, name="Mana Jade", item_id=5513)
        record, issues = db.normalize(value, "mop")
        self.assertEqual(issues, [])
        self.assertEqual((record["kind"], record["m"]), ("managem", 45000))
        self.assertEqual(record["totalInvariantUnderGlyph"], "Glyph of Loose Mana")
        self.assertEqual(record["sourceRule"], db.LOOSE_MANA_RULE)
        other, issues = db.normalize(value, "retail")
        self.assert_client_deferred(other, issues)
        self.assertNotIn("sourceRule", other)
    def test_later_food_ratings_are_retained(self):
        for stat, key in [("Expertise Rating", "Expertise"), ("Armor Penetration Rating", "ArmorPenetration"), ("haste", "Haste"), ("mastery", "Mastery"), ("Dodge Rating", "Dodge")]:
            record, issues = db.normalize(raw(f"Restores 22500 health over 30 sec. You become well fed and gain 40 {stat} and 40 Stamina for 1 hour."))
            self.assertEqual(issues, [])
            self.assertEqual(record["bs"][key], 40)

    def test_retail_quest_food_and_health_cap_preserve_exact_semantics(self):
        value = raw("Restores 4.8 health over 24 sec. Must remain seated while eating.")
        value["class"] = 12
        record, issues = db.normalize(value, "retail")
        self.assertEqual(issues, [])
        self.assertEqual((record["kind"], record["h"]), ("food", 4.8))
        value = raw("Restores 50% health, up to 175000.", subclass=1)
        record, issues = db.normalize(value, "retail")
        self.assertEqual(issues, [])
        self.assertEqual((record["hp"], record["healthCap"]), (50, 175000))
        self.assertNotIn("runtimeRestorationRequired", record)

    def test_retail_runtime_constraints_and_periodic_metadata_are_retained(self):
        record, issues = db.normalize(raw("Heals the current target for 10% of their maximum health every 1 sec for 8 sec. Does not work on players over level 49.", subclass=7), "retail")
        self.assert_client_deferred(record, issues)
        self.assertEqual((record["runtimeInterval"], record["runtimeDuration"], record["maximumLevel"]), (1, 8, 49))
        record, issues = db.normalize(raw("Restores health. Only usable outdoors.", subclass=1), "retail")
        self.assert_client_deferred(record, issues)
        self.assertTrue(record["outdoorsOnly"])
        record, issues = db.normalize(raw("Heals the caster for 10% of their maximum health. Does not work in Instances or Battlegrounds.", subclass=1), "retail")
        self.assertTrue(record["worldOnly"])

    def test_nightmare_recovery_is_not_an_instant_combat_potion(self):
        record, issues = db.normalize(raw("Puts the imbiber in a slumber where they restore 5400 health and 5400 mana, but they are defenseless.", subclass=1, name="Potion of Nightmares"), "wrath")
        self.assertEqual(issues, [])
        self.assertEqual(record["kind"], "recoverypotion")

    def test_food_total_does_not_use_duration(self):
        record, issues = db.normalize(raw("Restores 61 health over 18 sec. Must remain seated."))
        self.assertEqual(issues, [])
        self.assertEqual((record["h"], record["m"], record["kind"]), (61, 0, "food"))

    def test_retail_bounded_percent_food_has_explicit_total(self):
        text = "Restores up to 4% of your maximum health and mana every second over 20 sec. Must remain seated while eating."
        record, issues = db.normalize(raw(text), "retail")
        self.assertEqual(issues, [])
        self.assertEqual((record["kind"], record["hp"], record["mp"]), ("both", 80, 80))
        self.assertTrue(record["restorationUpperBound"])
        self.assertTrue(db.normalize(raw(text), "forever")[1])
        self.assert_client_deferred(*db.normalize(raw("Restores up to 10000 health."), "retail"))
        mixed = text.replace("Must remain seated", "Restores up to 20% of your maximum mana. Must remain seated")
        self.assert_client_deferred(*db.normalize(raw(mixed), "retail"))
        decimal, issues = db.normalize(raw(text.replace("4%", "2.5%")), "retail")
        self.assertEqual(issues, [])
        self.assertEqual((decimal["hp"], decimal["mp"]), (50, 50))

    def test_full_recovery_is_relative_to_player_resources(self):
        for text, hp, mp in [("Restores you to full health and mana over 20 sec.", 100, 100),
                             ("Restores you to full mana over 20 sec.", 0, 100)]:
            record, issues = db.normalize(raw(text), "retail")
            self.assertEqual(issues, [])
            self.assertEqual((record["hp"], record["mp"]), (hp, mp))
            self.assertEqual((record["h"], record["m"]), (0, 0))

    def test_exclamation_ends_recovery_before_unrelated_requirements(self):
        record, issues = db.normalize(raw("Restores 8 health from your never-ending vial! (5 Min Cooldown) Requires Level 50", subclass=1), "retail")
        self.assertEqual(issues, [])
        self.assertEqual(record["h"], 8)

    def test_missing_and_zero_export_values_require_the_client(self):
        for text in ["Restores 0 mana.", "Restores health.", "Restores health and mana every sec for 20 sec."]:
            record, issues = db.normalize(raw(text), "retail")
            self.assert_client_deferred(record, issues)

    def test_forever_water_is_mana(self):
        record, issues = db.normalize(raw("Restores 1915 mana over 30 sec.", name="Conjured Mineral Water", item_id=8077))
        self.assertEqual((record["h"], record["m"], record["kind"]), (0, 1915, "drink"))
        self.assertEqual(issues, [])

    def test_drinking_regeneration_is_not_well_fed(self):
        record, _ = db.normalize(raw("Restores 1915 mana over 30 sec.", use={"manargn": 332}))
        self.assertEqual(record["kind"], "drink")
        self.assertFalse(record["wf"])

    def test_tooltip_requirement_takes_precedence(self):
        value = raw("Requires Level 35. Restores 1915 mana over 30 sec.")
        value["item"]["reqlevel"] = 99
        record, _ = db.normalize(value)
        self.assertEqual(record["requiredLevel"], 35)

    def test_buff_values_are_structured_not_restore_amounts(self):
        record, issues = db.normalize(raw(
            "Restores 2452 health over 30 sec. If you spend at least 10 sec eating you will become Well Fed and gain 25 Agility and 10 Stamina for 15 min.",
            use={"agi": 25, "sta": 10}))
        self.assertEqual((record["h"], record["kind"], record["bs"]), (2452, "buff", {"Agility": 25, "Stamina": 10}))
        self.assertEqual(issues, [])

    def test_forever_buff_does_not_require_json_use_values(self):
        record, issues = db.normalize(raw(
            "Restores 841 health over 27 sec. If you spend at least 10 sec eating, you will become well fed and gain 10 Stamina for 15 min. Additionally, experience gained from kills is increased by 5%."))
        self.assertEqual(issues, [])
        self.assertEqual(record["bs"], {"Stamina": 10, "ExperienceFromKillsPercent": 5})

    def test_shared_stamina_and_spirit_is_preserved(self):
        record, _ = db.normalize(raw("Restores 531 health over 24 sec. You become well fed and gain 6 Stamina and Spirit for 15 min."))
        self.assertEqual(record["bs"], {"Stamina": 6, "Spirit": 6})

    def test_nightfin_mana_buff_is_not_drinking_restoration(self):
        record, issues = db.normalize(raw("Restores 874.8 health over 27 sec. Must remain seated while eating. Also restores 8 Mana every 5 seconds for 10 min."))
        self.assertEqual(issues, [])
        self.assertEqual((record["kind"], record["h"], record["m"], record["bs"]), ("buff", 874.8, 0, {"MP5": 8}))

    def test_generic_quest_food_is_not_lost_to_subclass_filter(self):
        record, issues = db.normalize(raw("Restores 552 health over 24 sec. Must remain seated while eating.", subclass=0, name="Flank of Meat"))
        self.assertEqual(issues, [])
        self.assertEqual((record["kind"], record["h"]), ("food", 552))

    def test_placed_feast_is_not_direct_food_restoration(self):
        record, issues = db.normalize(raw("Use: Serve a delicious feast that lasts for 3 min and serves up to 40 players. Food Restores 2452 health over 30 sec. Must remain seated while eating. You become Well Fed and gain 10 Stamina for 45 min.", subclass=8))
        self.assertEqual(issues, [])
        self.assertEqual(record["kind"], "placedfood")

    def test_source_availability_disclaimer_is_preserved(self):
        record, issues = db.normalize(raw("Use: Restores 6363 mana over 30 sec. Must remain seated while drinking. Added in Season of Discovery. May not be in WoW: Forever."))
        self.assertEqual(issues, [])
        self.assertTrue(record["availabilityUncertain"])
        self.assertIn("May not be in WoW: Forever.", record["warnings"][0])

    def test_quest_named_after_sleep_potion_is_not_recovery(self):
        record, issues = db.normalize(raw("Craftsman's Writ: Dreamless Sleep Potion. This Item Begins a Quest. Acquire the requested items.", subclass=8, name="Craftsman's Writ: Dreamless Sleep Potion"))
        self.assertEqual(issues, [])
        self.assertIsNone(record)

    def test_unused_marker_after_item_name_is_excluded(self):
        record, issues = db.normalize(raw("Restores 2% of your health per second for 25 sec. Must remain seated while eating.", name="Winter Veil Cookie UNUSED"))
        self.assertEqual(issues, [])
        self.assertIsNone(record)

    def test_cenarion_salve_uses_only_its_coilfang_instances(self):
        value = raw("Restores 1500 to 2500 health. Only works inside Coilfang: The Serpentshrine, The Underbog, The Steamvaults, The Slave Pens.", subclass=0, name="Cenarion Healing Salve")
        record, issues = db.normalize(value, "tbc")
        self.assertEqual(issues, [])
        self.assertEqual(record["allowedInstanceIDs"], [548, 546, 545, 547])
        other, _ = db.normalize(value, "retail")
        self.assertTrue(other["contextUnknown"])

    def test_injector_is_recovery_even_in_generic_subclass(self):
        record, issues = db.normalize(raw("Restores 1500 to 2500 health. (2 Min Cooldown) 20 Charges", subclass=8, name="Healing Potion Injector"))
        self.assertEqual(issues, [])
        self.assertEqual((record["kind"], record["h"]), ("healthpotion", 2000))

    def test_refreshed_food_and_increases_wording_are_recognized(self):
        record, issues = db.normalize(raw("Restores 840 health and 1260 mana over 21 sec. Must remain seated while eating. You become refreshed and gain 6 Mana every 5 seconds for 15 min.", subclass=0))
        self.assertEqual(issues, [])
        self.assertEqual(record["bs"], {"MP5": 6})
        record, issues = db.normalize(raw("Restores 1933.2 health over 27 sec. Must remain seated while eating. Also increases your Stamina by 10 for 10 min.", subclass=8))
        self.assertEqual(issues, [])
        self.assertEqual(record["bs"], {"Stamina": 10})

    def test_health_cost_is_not_counted_as_healing(self):
        record, issues = db.normalize(raw("Restores 900 to 1500 mana at the cost of 600 to 1000 health.", subclass=0, name="Dark Rune"))
        self.assertEqual(issues, [])
        self.assertEqual((record["h"], record["m"], record["kind"]), (0, 1200, "sacrificialrecovery"))

    def test_sagefish_buff_is_separate_from_drinking_mana(self):
        record, issues = db.normalize(raw("Restores 840 health and 1260 mana over 21 sec. Must remain seated while eating. You become well fed and gain 6 Mana every 5 seconds for 15 min."))
        self.assertEqual(issues, [])
        self.assertEqual((record["h"], record["m"], record["bs"]), (840, 1260, {"MP5": 6}))

    def test_bloodfin_all_resistance_buff_is_not_lost(self):
        record, _ = db.normalize(raw("Restores 4320 health over 30 sec. Must remain seated while eating. You become well fed and gain 8 resistance to all schools of magic for 30 min."))
        self.assertEqual(record["bs"], {"ResistAll": 8})

    def test_salmon_regeneration_is_not_a_mana_drink(self):
        record, issues = db.normalize(raw("Restores 874.8 health over 27 sec. Must remain seated while eating. Also restores 6 health every 5 seconds for 10 min."))
        self.assertEqual(issues, [])
        self.assertEqual((record["kind"], record["h"], record["m"], record["bs"]), ("buff", 874.8, 0, {"HP5": 6}))

    def test_named_mana_gem_does_not_depend_on_source_item_class(self):
        value = raw("Restores 375 to 425 mana.", subclass=0, name="Mana Agate", item_id=5514)
        value["class"] = 4
        record, issues = db.normalize(value)
        self.assertEqual(issues, [])
        self.assertEqual((record["kind"], record["m"]), ("managem", 400))

    def test_crit_percentage_is_not_crit_rating(self):
        record, _ = db.normalize(raw("Restores 841 health. You become well fed and gain 1% Critical Strike chance for 15 min.", use={"critstrkrtng": 14}))
        self.assertEqual(record["bs"], {"CritPercent": 1})

    def test_unknown_buff_does_not_invent_numbers(self):
        record, _ = db.normalize(raw("Restores 2% of your health per second for 24 sec. You become well fed and gain Stamina and Spirit for 15 min."))
        self.assertNotIn("bs", record)
        self.assertTrue(record["warnings"])

    def test_combined_food_and_drink(self):
        record, _ = db.normalize(raw("Restores 2000 health and 4000 mana over 30 sec."))
        self.assertEqual((record["h"], record["m"], record["kind"]), (2000, 4000, "both"))

    def test_rejuvenation_range_applies_to_mana_and_health(self):
        record, issues = db.normalize(raw("Restores 1440 to 1760 mana and health.", subclass=1))
        self.assertEqual(issues, [])
        self.assertEqual((record["h"], record["m"]), (1600, 1600))

    def test_potion_range_uses_average(self):
        record, issues = db.normalize(raw("Requires Level 70. Restores 2,700 to 4,500 health. (1 Min Cooldown)", subclass=1))
        self.assertEqual((record["h"], record["kind"]), (3600, "healthpotion"))
        self.assertEqual(issues, [])

    def test_bandage_uses_damage_healed(self):
        record, _ = db.normalize(raw("Heals 66 damage over 6 sec.", subclass=7, name="Linen Bandage"))
        self.assertEqual((record["h"], record["kind"]), (66, "bandage"))

    def test_ticking_effect_has_total(self):
        record, _ = db.normalize(raw("Restores 10 health every 2 seconds for 20 seconds."))
        self.assertEqual(record["h"], 100)

    def test_percent_is_not_flat_healing(self):
        record, _ = db.normalize(raw("Restores 20% of your maximum health over 30 sec."))
        self.assertEqual((record["h"], record["hp"]), (0, 20))

    def test_shared_percentage_covers_both_resources(self):
        record, issues = db.normalize(raw("Restores 3% of your health and mana per second for 10 seconds."))
        self.assertEqual(issues, [])
        self.assertEqual((record["hp"], record["mp"], record["kind"]), (30, 30, "both"))

    def test_per_second_is_not_total(self):
        record, issues = db.normalize(raw("Restores 10 health per second for 20 seconds."))
        self.assertEqual(issues, [])
        self.assertEqual(record["h"], 200)

    def test_missing_second_resource_is_not_silently_dropped(self):
        record, issues = db.normalize(raw("Restores 100 health and an unknown amount of mana."))
        self.assertIsNone(record)
        self.assertTrue(issues)

    def test_formula_without_parentheses_is_not_a_number(self):
        record, issues = db.normalize(raw("Restores 106918 - 106918%50 health."))
        self.assertIsNone(record)
        self.assertTrue(issues)

    def test_mop_constant_mana_arithmetic_is_exact(self):
        record, issues = db.normalize(raw("Restores 300000 health and ( 75000 / 5 * 20) mana over 20 sec. Must remain seated while eating."), "mop")
        self.assertEqual(issues, [])
        self.assertEqual((record["h"], record["m"]), (300000, 300000))
        self.assertEqual(db.fold_constant_arithmetic("Restores ((25 * 18) / 5) health."), "Restores 90 health.")

    def test_constant_arithmetic_rejects_unsafe_or_unknown_operations(self):
        for expression in ["(1 / 0)", "(2 ** 30)", "(10000000000000 * 10000000000000)", "(level * 10)", "(__import__('os').getpid())"]:
            self.assertEqual(db.fold_constant_arithmetic(expression), expression)

    def test_reviewed_concentration_potion_keeps_channel_upper_bound(self):
        value = raw("Use: Puts the imbiber in an elevated state of concentration where they can restore up to (2200 * 10) mana over 10 sec, but they are defenseless until their concentration is broken.", subclass=1, name="Potion of Concentration", item_id=57194)
        record, issues = db.normalize(value, "mop")
        self.assertEqual(issues, [])
        self.assertEqual((record["kind"], record["m"]), ("recoverypotion", 22000))
        self.assertTrue(record["requiresChannel"])
        self.assertTrue(record["restorationUpperBound"])
        retail, issues = db.normalize(value, "retail")
        self.assert_client_deferred(retail, issues)
        self.assertEqual(retail["kind"], "recoverypotion")

    def test_formula_is_reported_not_guessed(self):
        record, issues = db.normalize(raw("Restores (106918 - 106918%50) health and 14012 mana.", subclass=1))
        self.assertIsNone(record)
        self.assertTrue(issues)

    def test_unknown_restoration_is_reported(self):
        record, issues = db.normalize(raw("Restores some health."))
        self.assertIsNone(record)
        self.assertTrue(issues)

    def test_protection_is_not_healing(self):
        record, issues = db.normalize(raw("Absorbs 1000 fire damage for 1 hour.", subclass=1))
        self.assertIsNone(record)
        self.assertEqual(issues, [])

    def test_dreamless_sleep_is_not_a_combat_potion(self):
        record, issues = db.normalize(raw("Puts the imbiber in a dreamless sleep for 12 sec. During that time the imbiber heals 2100 health and 2100 mana.", subclass=1))
        self.assertEqual(issues, [])
        self.assertEqual(record["kind"], "recoverypotion")

    def test_discolored_potion_keeps_its_negative_effect(self):
        record, _ = db.normalize(raw("Restores 2625 to 2975 health instantly, however you also suffer 75% of that amount over time.", subclass=1))
        self.assertTrue(record["hasHarmfulAfterEffect"])
        self.assertEqual(record["h"], 2800)

    def test_battleground_restriction_is_retained(self):
        record, _ = db.normalize(raw("Restores 980 to 1260 health. This item may only be used in PvP Battlegrounds.", subclass=1))
        self.assertTrue(record["battlegroundOnly"])

    def test_bandage_restriction_is_a_specific_battleground(self):
        record, issues = db.normalize(raw("Heals 640 damage over 8 sec. Usable only inside Arathi Basin.", subclass=7, name="Defiler's Silk Bandage"), "tbc")
        self.assertEqual(issues, [])
        self.assertEqual(record["allowedInstanceIDs"], [529])
        self.assertTrue(record["battlegroundOnly"])

    def test_unknown_zone_restriction_is_not_dropped(self):
        record, _ = db.normalize(raw("Restores 1500 health. Only works in an unknown zone.", subclass=1), "tbc")
        self.assertTrue(record["contextUnknown"])
        self.assertTrue(record["warnings"])

    def test_darkspear_restriction_uses_forever_instance_not_area_or_ui_map(self):
        value = raw("Restores 2148 health and 4410 mana over 30 sec. Must remain seated while eating. Usable only inside Darkspear Islands.", subclass=8)
        record, issues = db.normalize(value, "forever")
        self.assertEqual(issues, [])
        self.assertEqual(record["allowedInstanceIDs"], [2997])
        self.assertTrue(record["battlegroundOnly"])
        self.assertNotIn("contextUnknown", record)
        for version in ["era", "tbc", "wrath", "cata", "mop", "retail"]:
            other, _ = db.normalize(value, version)
            self.assertTrue(other["contextUnknown"])
            self.assertNotIn("allowedInstanceIDs", other)

    def test_nethergon_is_limited_to_the_four_tempest_keep_instances(self):
        record, _ = db.normalize(raw("Restores 1800 to 3000 mana. Only works inside Tempest Keep: The Eye, The Arcatraz, The Botanica, The Mechanar.", subclass=1), "tbc")
        self.assertEqual(record["allowedInstanceIDs"], [550, 552, 553, 554])
        self.assertNotIn("contextUnknown", record)

    def test_fel_mana_potion_keeps_its_spellpower_penalty(self):
        record, _ = db.normalize(raw("Restores 3200 mana over 24 sec, but at a cost. Also reduces spell damage by 25 and healing done by 50 for 15 min.", subclass=1))
        self.assertTrue(record["hasHarmfulAfterEffect"])

    def test_classic_battleground_ids_do_not_leak_into_retail(self):
        record, _ = db.normalize(raw("Heals 640 damage over 8 sec. Usable only inside Arathi Basin.", subclass=7), "retail")
        self.assertTrue(record["contextUnknown"])
        self.assertNotIn("allowedInstanceIDs", record)

    def test_missing_source_list_is_not_empty_success(self):
        with self.assertRaises(ValueError):
            db.discover("<html>Please enable JavaScript</html>")

    def test_list_ids_are_scoped_to_items(self):
        self.assertEqual(db.discover('var other={"id":999}; var listviewitems = [{"id":117},{"id":159}];'), [117, 159])

    def test_xml_id_mismatch_is_rejected(self):
        with self.assertRaises(ValueError):
            db.read_xml(b'<catalog><item id="159"/></catalog>', 117)

    def test_explicit_item_not_found_is_distinct_from_transport_failure(self):
        with self.assertRaises(db.ItemUnavailable):
            db.read_xml(b'<catalog><error>Item not found!</error></catalog>', 21990, "forever")

    def test_source_cannot_silently_switch_clients(self):
        body = b'<catalog><item id="117"><link>https://catalog.example/classic/item=117/tough-jerky</link></item></catalog>'
        with self.assertRaises(ValueError):
            db.read_xml(body, 117, "forever")

    def test_missing_source_configuration_is_rejected(self):
        with patch.dict(os.environ, {}, clear=True), self.assertRaisesRegex(ValueError, "AC_DATABASE_SOURCE_URL"):
            db.item_url("forever", 117)

    def test_source_configuration_requires_an_http_url(self):
        for base in ("file:///tmp/export", "https://", "https://catalog.example/?token=x"):
            with self.subTest(base=base), patch.dict(os.environ, {"AC_DATABASE_SOURCE_URL": base}):
                with self.assertRaises(ValueError):
                    db.source_base_url()

    def test_configured_source_validates_returned_host(self):
        body = b'<catalog><item id="117"><link>https://other.example/forever/item=117/test</link></item></catalog>'
        with self.assertRaisesRegex(ValueError, "Source link"):
            db.read_xml(body, 117, "forever")

    def test_configured_source_supports_a_base_path(self):
        with patch.dict(os.environ, {"AC_DATABASE_SOURCE_URL": "https://catalog.example/database/"}):
            self.assertEqual(db.item_url("forever", 117),
                             "https://catalog.example/database/forever/item=117&xml")

    def test_source_profiles_do_not_share_urls(self):
        self.assertEqual(len({db.item_url(version, 8077) for version in db.VERSIONS}), 7)

    def test_mana_regeneration_is_not_a_buff_stat_on_water(self):
        record, _ = db.normalize(raw("Restores 1915 mana over 30 sec.", use={"manargn": 332}))
        self.assertNotIn("bs", record)

    def test_rebuild_is_deterministic(self):
        snapshot = {"version": "forever", "items": [raw("Restores 61 health over 18 sec.")],
                    "discovery": {"coverage": "partial"}, "failures": {}}
        self.assertEqual(db.build(snapshot), db.build(snapshot))

    def test_resume_keeps_later_cached_records_after_denial(self):
        with tempfile.TemporaryDirectory() as folder:
            cache = Path(folder)
            (cache / "159.xml").write_text("cached")
            prior = raw("Restores 151 mana.", item_id=159)
            def fetch(url, path, offline, interval, refresh=False):
                if path.stem == "117":
                    raise RuntimeError("HTTP 403; stop fetching")
                self.assertTrue(offline)
                return b"cached"
            with patch.object(db, "fetch", side_effect=fetch), patch.object(db, "read_xml", return_value=prior):
                result = db.collect_items("forever", [117, 159, 414], {}, cache)
            self.assertEqual([row["id"] for row in result["items"]], [159])
            self.assertIn("414", result["failures"])

    def test_current_source_can_be_refetched_without_deleting_cache(self):
        with tempfile.TemporaryDirectory() as folder:
            cache = Path(folder) / "117.xml"
            cache.write_bytes(b"old source")
            with patch.object(db.urllib.request, "urlopen") as request, patch.object(db.time, "sleep"):
                self.assertEqual(db.fetch("https://example.test/item", cache), b"old source")
                request.assert_not_called()
                request.return_value.__enter__.return_value.read.return_value = b"new source"
                self.assertEqual(db.fetch("https://example.test/item", cache, refresh=True), b"new source")
            self.assertEqual(cache.read_bytes(), b"new source")

    def test_denied_refresh_preserves_last_successful_response(self):
        with tempfile.TemporaryDirectory() as folder:
            cache = Path(folder) / "117.xml"
            cache.write_bytes(b"old source")
            error = db.urllib.error.HTTPError("https://example.test/item", 403, "Forbidden", {}, None)
            with patch.object(db.urllib.request, "urlopen", side_effect=error), patch.object(db.time, "sleep"):
                with self.assertRaisesRegex(RuntimeError, "stop fetching"):
                    db.fetch("https://example.test/item", cache, refresh=True)
            self.assertEqual(cache.read_bytes(), b"old source")

    def test_resume_works_without_http_cache(self):
        saved = raw("Restores 151 mana.", item_id=159)
        with tempfile.TemporaryDirectory() as folder, patch.object(db, "fetch") as fetch:
            result = db.collect_items("forever", [159], {}, Path(folder),
                                      previous={"version": "forever", "items": [saved]})
            fetch.assert_not_called()
        self.assertEqual(result["items"], [saved])

    def test_resume_cannot_mix_clients(self):
        with self.assertRaises(ValueError):
            db.collect_items("era", [], {}, Path("unused"), previous={"version": "forever", "items": []})

    def test_regular_refresh_does_not_replace_enabled_database(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            runtime = root / "data/generated/forever.lua"
            runtime.parent.mkdir(parents=True)
            runtime.write_text("-- previous enabled dataset\n")
            seed = root / "seed.json"
            seed.write_text(json.dumps([117]))
            cache = root / ".cache/catalog/forever/117.xml"
            cache.parent.mkdir(parents=True)
            cache.write_text('<catalog><item id="117"><name>Tough Jerky</name><class id="0"/><subclass id="5"/><htmlTooltip>Restores 59 health over 18 sec.</htmlTooltip><link>https://catalog.example/forever/item=117/tough-jerky</link></item></catalog>')
            with patch.object(db, "ROOT", root), patch("sys.argv", ["import_database.py", "forever", "--seed", str(seed), "--offline"]), contextlib.redirect_stdout(io.StringIO()):
                db.main()
            self.assertEqual(runtime.read_text(), "-- previous enabled dataset\n")
            self.assertIn("enabled = false", (root / "data/staged/forever.lua").read_text())

    def test_failed_import_cannot_be_activated(self):
        with self.assertRaises(ValueError):
            db.validate_activation({"version": "forever"}, {"failures": {"117": "HTTP 403"}, "unresolved": {}})

    def test_missing_food_categories_cannot_replace_working_database(self):
        with self.assertRaisesRegex(ValueError, "required categories"):
            db.validate_activation({"version": "era", "discovery": {"errors": {}}},
                                   {"failures": {}, "unresolved": {}, "categories": {"healthstone": 5}})

    def test_competing_healthstone_blocks_unranked_family_activation(self):
        with self.assertRaisesRegex(ValueError, "competing healthstones"):
            db.validate_activation({}, {"failures": {}, "unresolved": {},
                "familyOnlyRestoration": {"5512": "Glyph-dependent effect"},
                "categories": {"healthstone": 2}})

    def test_losing_known_legacy_recovery_items_blocks_activation(self):
        with self.assertRaisesRegex(ValueError, "legacy recovery"):
            db.validate_activation({"version": "tbc"},
                                   {"failures": {}, "unresolved": {}, "legacyRecoveryExclusions": [23822]})

    def test_manifest_never_includes_unpublished_or_staged_files(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "data/generated").mkdir(parents=True)
            (root / "data/published").mkdir(parents=True)
            (root / "data/staged").mkdir(parents=True)
            (root / "data/generated/forever.lua").write_text("enabled")
            (root / "data/published/forever.json").write_text(json.dumps({"activation": {"enabled": True}}))
            (root / "data/generated/tbc.lua").write_text("unpublished")
            (root / "data/staged/era.lua").write_text("staging")
            with patch.object(db, "ROOT", root):
                db.write_manifest()
            content = (root / "Databases.xml").read_text()
            self.assertIn("forever.lua", content)
            self.assertNotIn("tbc.lua", content)
            self.assertNotIn("era.lua", content)

    def test_supplementary_candidates_require_a_response_and_unchanged_provenance(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "data/seeds").mkdir(parents=True)
            primary = {"core": "ItemDB/Data/Forever/_core/Consumable.lua"}
            extra = {"candidateCore": primary["core"]}
            for name, provenance, ids in [("forever.json", primary, [117]), ("forever-generic.json", extra, [159])]:
                (root / "data/seeds" / name).write_text(json.dumps({"source": provenance, "ids": ids}))
            snapshot = {"version": "forever", "items": [{"id": 117}], "discovery": {"errors": {}, "sources": [
                {"seed": "forever.json", "provenance": primary},
                {"seed": "forever-generic.json", "provenance": extra}]}}
            report = {"failures": {}, "unresolved": {}, "categories": {
                key: 1 for key in ["food", "drink", "buff", "healthpotion", "manapotion", "bandage", "healthstone"]}}
            with patch.object(db, "ROOT", root):
                with self.assertRaisesRegex(ValueError, "Not every catalog candidate"):
                    db.validate_activation(snapshot, report)
                snapshot["unavailable"] = {"159": {"reason": "No item record"}}
                db.validate_activation(snapshot, report)
                (root / "data/seeds/forever-generic.json").write_text(json.dumps({"source": {"changed": True}, "ids": [159]}))
                with self.assertRaisesRegex(ValueError, "catalog has changed"):
                    db.validate_activation(snapshot, report)


if __name__ == "__main__":
    unittest.main()
