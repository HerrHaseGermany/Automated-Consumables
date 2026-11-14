#!/usr/bin/env python3
"""Build version-specific consumable data from cached Wowhead XML exports.

Fetching and publishing are separate: an incomplete discovery or an unparsed
effect must never silently replace the addon's working database.
"""

import argparse
import ast
import hashlib
import html
import json
import math
import re
import time
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSIONS = {
    "forever": "forever/", "era": "classic/", "tbc": "tbc/",
    "wrath": "wotlk/", "cata": "cata/", "mop": "mop-classic/", "retail": "",
}
CATEGORIES = ("food-and-drinks", "potions", "bandages", "other")
HEADERS = {"User-Agent": "Automated-Consumables database builder",
           "Accept": "application/xml, text/html"}
STAT_KEYS = {
    "sta": "Stamina", "spi": "Spirit", "str": "Strength", "agi": "Agility",
    "int": "Intellect", "atkpwr": "AttackPower", "splpwr": "SpellPower",
    "splheal": "Healing", "critstrkrtng": "Crit", "hastertng": "Haste",
    "mastrtng": "Mastery", "versatility": "Versatility", "hitrtng": "Hit",
    "manargn": "MP5", "splcritstrkrtng": "SpellCrit",
    "exprtng": "Expertise", "armorpenrtng": "ArmorPenetration",
    "dodgertng": "Dodge", "parryrtng": "Parry",
    "mlehastertng": "Haste", "rgdhastertng": "Haste", "splhastertng": "Haste",
    "mlecritstrkrtng": "Crit", "rgdcritstrkrtng": "Crit",
    "mlehitrtng": "Hit", "rgdhitrtng": "Hit", "splhitrtng": "Hit",
}


class ItemUnavailable(ValueError):
    """The requested client's source explicitly reports no item record."""


def item_url(version, item_id):
    return f"https://www.wowhead.com/{VERSIONS[version]}item={item_id}&xml"


def fetch(url, cache, offline=False, interval=0.5, refresh=False):
    if cache.exists() and (not refresh or offline):
        return cache.read_bytes()
    if offline:
        raise RuntimeError(f"Not cached: {url}")
    # Keep requests sequential and bounded; respect rate limits rather than
    # trying alternate hosts, proxies or challenge bypasses.
    time.sleep(interval)
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=25) as response:
            body = response.read()
    except urllib.error.HTTPError as error:
        if error.code in (403, 429):
            raise RuntimeError(f"HTTP {error.code}; source denied the request, stop fetching: {url}") from error
        raise
    cache.parent.mkdir(parents=True, exist_ok=True)
    temporary = cache.with_suffix(cache.suffix + ".tmp")
    temporary.write_bytes(body)
    temporary.replace(cache)
    return body


def discover(body):
    """Read IDs only, never execute JavaScript from a source page."""
    match = re.search(r"\b(?:var|let|const)\s+listviewitems\s*=\s*(\[.*?\]);", body, re.S)
    if not match:
        raise ValueError("Item list missing; refusing to interpret this as an empty category")
    ids = sorted({int(value) for value in re.findall(r'"id"\s*:\s*(\d+)', match[1])})
    if not ids:
        raise ValueError("Item list is empty")
    if re.search(r"truncated|first \d+ results|too many results|exceeds.*limit", body, re.I):
        raise ValueError("Source may be truncated; partition the category before publishing")
    return ids


def fragment(text):
    if not text:
        return {}
    return json.loads("{" + text + "}")


def read_xml(body, expected_id, version=None):
    root = ET.fromstring(body)
    if root.findtext("error") == "Item not found!":
        raise ItemUnavailable("Wowhead has no item record for this client")
    item = root.find("item")
    if item is None or int(item.get("id", "0")) != expected_id:
        raise ValueError("Missing item or mismatched item ID")
    if version is not None:
        expected_link = f"https://www.wowhead.com/{VERSIONS[version]}item={expected_id}"
        link = item.findtext("link") or ""
        if link != expected_link and not link.startswith(expected_link + "/"):
            raise ValueError("Source link does not match the requested client and item")
    name = item.findtext("name")
    if not name:
        raise ValueError("Missing item name")
    item_class, subclass = item.find("class"), item.find("subclass")
    if item_class is None or subclass is None:
        raise ValueError("Missing item classification")
    tooltip = item.findtext("htmlTooltip") or ""
    # Preserve boundaries so a cooldown or Well Fed duration is never used as
    # the restoration amount. Decode entities only after stripping HTML.
    text = html.unescape(re.sub(r"<[^>]*>", " ", tooltip))
    text = re.sub(r"\s+", " ", text).strip()
    return {
        "id": expected_id, "name": name,
        "class": int(item_class.get("id")),
        "subclass": int(subclass.get("id")),
        "tooltip": text, "item": fragment(item.findtext("json")),
        "use": fragment(item.findtext("jsonUse")),
        "equip": fragment(item.findtext("jsonEquip")),
        "sha256": hashlib.sha256(body).hexdigest(),
    }


NUMBER = r"\d[\d,]*(?:\.\d+)?"
BUFF_NAMES = {
    "stamina": "Stamina", "spirit": "Spirit", "strength": "Strength",
    "agility": "Agility", "intellect": "Intellect", "attack power": "AttackPower",
    "spell damage": "SpellPower", "spell power": "SpellPower", "healing power": "Healing",
    "critical strike chance": "Crit", "critical strike rating": "Crit",
    "haste rating": "Haste", "mastery rating": "Mastery", "versatility": "Versatility",
    "hit rating": "Hit", "armor": "Armor", "fishing skill": "Fishing",
    "herbalism skill": "Herbalism", "movement speed": "MovementSpeed",
    "resistance to all schools of magic": "ResistAll",
    "expertise rating": "Expertise", "expertise": "Expertise",
    "armor penetration rating": "ArmorPenetration", "armor penetration": "ArmorPenetration",
    "dodge rating": "Dodge", "dodge": "Dodge", "parry rating": "Parry", "parry": "Parry",
    "haste": "Haste", "mastery": "Mastery", "critical strike": "Crit",
}
# Classic instance IDs, independently corroborated by BigWigs' zone registry:
# https://github.com/BigWigsMods/BigWigs/blob/master/Loader.lua
CLASSIC_BATTLEGROUNDS = {"alterac valley": [30], "warsong gulch": [489], "arathi basin": [529]}
# Forever Map.db2 ID, not AreaTable 16606 or UiMap 2524. Corroborated by
# https://github.com/DenoHearth/DenoMap/blob/b915e4ae8ac6bf3c8a5679d2dbf6cc468c2cd824/DenoMap/tools/mjobs.py
# https://github.com/Questie/Questie/blob/master/docs/forever-development.md
FOREVER_BATTLEGROUNDS = {"darkspear islands": [2997]}
TEMPEST_KEEP = "tempest keep: the eye, the arcatraz, the botanica, the mechanar"
TEMPEST_KEEP_INSTANCES = [550, 552, 553, 554]
COILFANG = "coilfang: the serpentshrine, the underbog, the steamvaults, the slave pens"
COILFANG_INSTANCES = [548, 546, 545, 547]
LOOSE_MANA_RULE = "https://worldofwarcraft.blizzard.com/en-us/news/10932273/54-hotfixes-december-2"
MOP_GLYPH_MANA_GEMS = {5513, 5514, 8007, 8008, 22044, 33312, 36799, 81901}


def number(value):
    return float(value.replace(",", ""))


def food_sections(raw):
    text = raw["tooltip"]
    seated = re.search(r"\bmust remain seated\b.*?\.(?!\d)", text, re.I)
    if seated:
        recovery, tail = text[:seated.end()], text[seated.end():]
    else:
        parts = re.split(r"(?:if you spend|you (?:will )?become well[- ]fed)", text, maxsplit=1, flags=re.I)
        recovery = parts[0]
        tail = text[len(recovery):]
    well_fed = bool(re.search(r"well[- ]fed|become refreshed", text, re.I))
    lasting_regen = bool(re.search(r"(?:also\s+)?restores?\s+\d.*?(?:mana|health)\s+every\s+\d+\s+seconds?\s+for\s+\d+\s+min", tail, re.I))
    lasting_stats = bool(re.search(r"(?:also\s+)?increases (?:your )?(?:stamina|spirit|strength|agility|intellect)\s+by\s+\d", tail, re.I))
    return recovery, tail, well_fed or lasting_regen or lasting_stats


def food_buff_stats(raw, buff_text=None):
    """Prefer explicit Well Fed numbers over incomplete structured use fields."""
    tail = buff_text if buff_text is not None else re.split(r"well[- ]fed", raw["tooltip"], maxsplit=1, flags=re.I)[-1]
    stats = {mapped: value for key, mapped in STAT_KEYS.items()
             if isinstance((value := raw["use"].get(key)), (int, float)) and value > 0}
    # Drinking regeneration also appears in jsonUse. Only a stated Well Fed
    # mana effect is evidence of a lasting mana-regeneration buff.
    if not re.search(r"\bmana\b", tail, re.I):
        stats.pop("MP5", None)
    warnings = []
    names = "|".join(re.escape(name) for name in sorted(BUFF_NAMES, key=len, reverse=True))
    gained = re.search(r"\bgain\s+(.*?)(?:\s+for\s+\d+\s+(?:min|sec|hour)|\.(?!\d)|$)", tail, re.I)
    if gained:
        description = gained[1]
        for match in re.finditer(rf"({NUMBER})\s*(%)?\s+({names})\b", description, re.I):
            key = BUFF_NAMES[match[3].lower()]
            if match[2]:
                # A percentage point of crit is not a point of crit rating.
                stats.pop(key, None)
                key += "Percent"
            value = number(match[1])
            stats[key] = value
            shared = re.match(rf"\s+and\s+({names})\b", description[match.end():], re.I)
            if shared:
                stats[BUFF_NAMES[shared[1].lower()] + ("Percent" if match[2] else "")] = value
        if re.search(r"\bwhile\s+in\b", description, re.I):
            warnings.append("Conditional food buff: " + description)
    for match in re.finditer(rf"increases (?:your )?({names})\s+by\s+({NUMBER})", tail, re.I):
        stats[BUFF_NAMES[match[1].lower()]] = number(match[2])
    experience = re.search(rf"experience gained from kills is increased by\s+({NUMBER})%", tail, re.I)
    if experience:
        stats["ExperienceFromKillsPercent"] = number(experience[1])
    for match in re.finditer(rf"(?:restores?|regenerates?|gain)\s+({NUMBER})\s+(health|mana)\s+every\s+({NUMBER})\s+seconds?", tail, re.I):
        key = "HP5" if match[2].lower() == "health" else "MP5"
        stats[key] = number(match[1]) * 5 / number(match[3])
    if not stats:
        warnings.append("Well Fed buff has no known numeric stats in this source")
    return stats, warnings


def fold_constant_arithmetic(text):
    """Reduce numeric tooltip arithmetic only; never execute source text."""
    def evaluate(node, depth=0):
        if depth > 12:
            raise ValueError("Expression too deep")
        if isinstance(node, ast.Constant) and type(node.value) in (int, float):
            value = node.value
        elif isinstance(node, ast.BinOp):
            left, right = evaluate(node.left, depth + 1), evaluate(node.right, depth + 1)
            if isinstance(node.op, ast.Add): value = left + right
            elif isinstance(node.op, ast.Sub): value = left - right
            elif isinstance(node.op, ast.Mult): value = left * right
            elif isinstance(node.op, ast.Div): value = left / right
            else: raise ValueError("Unsupported operator")
        else:
            raise ValueError("Not constant arithmetic")
        if not math.isfinite(value) or abs(value) > 1e12:
            raise ValueError("Expression out of range")
        return value

    def replace(match):
        expression = match[1].strip()
        if len(expression) > 120 or not re.search(r"\d\s*[+*/-]", expression):
            return match[0]
        try:
            tree = ast.parse(expression, mode="eval")
            if sum(1 for _ in ast.walk(tree)) > 64:
                return match[0]
            value = evaluate(tree.body)
            if value < 0:
                return match[0]
            return format(value, ".12g")
        except (ValueError, SyntaxError, ArithmeticError, OverflowError):
            return match[0]

    # Repeated passes handle nested numeric parentheses while keeping unknown
    # variables, spell expressions and conditional branches unresolved.
    for _ in range(12):
        folded = re.sub(r"\(([\d.\s+*/-]+)\)", replace, text)
        if folded == text:
            break
        text = folded
    return text


def restoration(text):
    """Return total restoration and percentages, with ambiguous syntax flagged."""
    # Older healthstone tooltips use "life" for the same health resource.
    text = re.sub(r"\blife\b", "health", text, flags=re.I)
    text = fold_constant_arithmetic(text)
    amounts = {"h": 0, "m": 0, "hp": 0, "mp": 0}
    issues = []
    # Scope to the restoration clause, not later buffs, damage or cooldowns.
    clauses = re.findall(r"(?:restores?|heals?)\b.*?(?:[.!?](?!\d)|$)", text, re.I)
    for clause in clauses:
        # A mana rune's sacrificed health must not be added as healing.
        clause = re.split(r"at (?:the|a) (?:cost|expense) of", clause, maxsplit=1, flags=re.I)[0]
        lower = clause.lower()
        if not re.search(r"health|mana|damage", lower):
            continue
        full = re.fullmatch(rf"restores? you to full (health(?: and mana)?|mana(?: and health)?)(?: (?:over|in) {NUMBER} (?:seconds?|sec))?[.!?]?", clause, re.I)
        if full:
            if "health" in full[1].lower(): amounts["hp"] += 100
            if "mana" in full[1].lower(): amounts["mp"] += 100
            continue
        if re.search(r"\$|\{|\}|\[|\]|\(|\)|\d\s*[+*/=]|%\s*\d|\blevel\b|\bdepending\b|\bup to\b|\buntil cancelled\b|\bor\b", clause, re.I):
            issues.append("Dynamic or formula-based restoration: " + clause)
            continue
        # Examples: 61 health; 2700 to 4500 health; 20% of your maximum mana.
        pattern = (rf"(?<![\d.%])({NUMBER})(?:\s*(?:to|[-–])\s*({NUMBER}))?\s*(%)?"
                   r"\s*(?:(?:of\s+)?(?:your\s+)?(?:(?:maximum|total|base)\s+)?)?(health|mana|damage)")
        matches = list(re.finditer(pattern, clause, re.I))
        if not matches:
            issues.append("Unrecognized restoration: " + clause)
            continue
        for match in matches:
            if match[4].lower() == "damage" and not lower.startswith("heal"):
                issues.append("Damage is not restoration: " + clause)
                continue
            value = (number(match[1]) + number(match[2])) / 2 if match[2] else number(match[1])
            if value == 0:
                issues.append("Zero restoration requires a client tooltip: " + clause)
            resource = "m" if match[4].lower() == "mana" else "h"
            key = resource + ("p" if match[3] else "")
            if "base " in match[0].lower():
                issues.append("Base-resource percentage requires client data: " + clause)
                continue
            # Repeated ticking effects need a duration; never guess a total.
            tick = re.search(rf"(?:every|per)\s+(?:({NUMBER})\s*)?(?:sec|second)", clause, re.I)
            if tick:
                duration = re.search(rf"(?:for|over)\s+({NUMBER})\s*(?:sec|second)", clause, re.I)
                if not duration:
                    issues.append("Tick restoration without duration: " + clause)
                    continue
                value *= number(duration[1]) / (number(tick[1]) if tick[1] else 1)
            amounts[key] += value
            # The same quantity can explicitly apply to both resources.
            if match[4].lower() == "health" and re.match(r"\s+and\s+mana\b", clause[match.end():], re.I):
                amounts["mp" if match[3] else "m"] += value
            elif match[4].lower() == "mana" and re.match(r"\s+and\s+health\b", clause[match.end():], re.I):
                amounts["hp" if match[3] else "h"] += value
        mentioned = {word.lower() for word in re.findall(r"\b(health|mana)\b", clause, re.I)}
        for resource in mentioned:
            key = "h" if resource == "health" else "m"
            if not amounts[key] and not amounts[key + "p"]:
                issues.append("Resource mentioned without a parsed amount: " + clause)
    return amounts, issues


def normalize(raw, version=None):
    text, name = raw["tooltip"], raw["name"]
    if not text:
        return None, ["Missing tooltip"]
    if re.search(r"\b(?:UNUSED|Deprecated)\b", name, re.I):
        return None, []
    is_family = bool(re.search(r"healthstone|soulstone|\bmana (?:agate|jade|citrine|ruby|emerald|sapphire|gem)\b", name, re.I))
    quest_food = version == "retail" and raw["class"] == 12 and "must remain seated" in text.lower()
    if not is_family and not quest_food and (raw["class"] != 0 or raw["subclass"] not in (0, 1, 5, 7, 8)):
        return None, []
    lower = text.lower()
    level = re.search(r"Requires Level\s+(\d+)", text)
    # List-view reqlevel can disagree with both the rendered tooltip and
    # jsonEquip (e.g. Forever item 118: 10 versus 1). Do not inherit it.
    result = {"id": raw["id"], "name": name,
              "requiredLevel": int(level[1]) if level else raw.get("equip", {}).get("reqlevel", 0)}
    is_food = quest_food or (raw["class"] == 0 and (raw["subclass"] == 5 or "must remain seated" in lower))
    recovery, buff_text, is_buff = food_sections(raw) if is_food else (text, "", False)
    channeled_recovery = (version in ("cata", "mop") and raw["id"] in (57194, 76092)
                          and bool(re.search(r"defenseless until their (?:concentration|focus) is broken", lower)))
    parsed_recovery = fold_constant_arithmetic(recovery)
    bounded_food_pattern = rf"\bRestores up to {NUMBER}% of your maximum (?:health(?: and mana)?|mana(?: and health)?) every second over {NUMBER} (?:seconds?|sec)\."
    bounded_food = version == "retail" and is_food and bool(re.search(bounded_food_pattern, parsed_recovery, re.I))
    if bounded_food:
        parsed_recovery = re.sub(bounded_food_pattern, lambda match: re.sub(
            r"up to ", "", match[0], count=1, flags=re.I), parsed_recovery, flags=re.I)
    if channeled_recovery:
        # This is an explicitly bounded, interruptible channel. Retain its
        # upper bound as such, and keep it out of combat-potion selection.
        parsed_recovery = re.sub(r"restore up to (?=\d)", "restore ", parsed_recovery, flags=re.I)
    amounts, issues = restoration(parsed_recovery)
    health_cap = None
    if version == "retail":
        capped = re.search(rf"\bRestores ({NUMBER})% health, up to ({NUMBER})\.", parsed_recovery, re.I)
        if capped and number(capped[1]) > 0 and number(capped[2]) > 0:
            amounts, issues = {"h": 0, "m": 0, "hp": number(capped[1]), "mp": 0}, []
            health_cap = number(capped[2])
    client_issues = None
    client_health = client_mana = False
    if version == "retail" and issues:
        if "restores no health" in lower:
            return None, []
        client_health = bool(re.search(r"\b(?:health|life|heals?)\b", recovery, re.I))
        client_mana = bool(re.search(r"\bmana\b", recovery, re.I))
        if client_health or client_mana:
            client_issues, issues = issues, []
            amounts = {"h": 0, "m": 0, "hp": 0, "mp": 0}
    glyph_total = None
    if version == "mop" and raw["id"] in MOP_GLYPH_MANA_GEMS:
        # Blizzard's 5.4 fix specifies identical total mana with/without this
        # glyph; it changes delivery time. The export's glyph branch contains
        # unresolved zero/duration placeholders, so use only the explicit
        # unglyphed total under that reviewed, MoP-specific equality rule.
        glyph_total = re.search(rf"Restores\s+\[\s*Glyph of Loose Mana\s*:\s*0 mana over until cancelled\s*/\s*({NUMBER}) mana\.\]", text, re.I)
        if glyph_total:
            amounts, issues = {"h": 0, "m": number(glyph_total[1]), "hp": 0, "mp": 0}, []
    family_only = None
    if raw["id"] == 5512 and name.lower() == "healthstone":
        if version == "cata" and "health equal to 45% of the base health of a Warlock your level" in text:
            family_only = "Base health depends on Warlock level; use the usable healthstone without an invented numeric rank"
        elif version == "mop" and "Glyph of Healthstone" in text and "Instantly restores 20% of your health" in text:
            family_only = "Glyph-dependent healing; use the usable healthstone without adding alternative effects"
        if family_only:
            amounts, issues = {"h": 0, "m": 0, "hp": 0, "mp": 0}, []
    result.update(amounts)
    if health_cap is not None:
        result["healthCap"] = health_cap
    has_health = amounts["h"] or amounts["hp"] or client_health
    has_mana = amounts["m"] or amounts["mp"] or client_mana
    # jsonUse also exposes mana-per-five while drinking. It is not evidence
    # of a lasting food buff; the tooltip must identify the Well Fed effect.
    buff_stats, buff_warnings = food_buff_stats(raw, buff_text) if is_buff else ({}, [])
    kind = None
    # Conjured stones belong to client-specific families, not ordinary potions.
    if "soulstone" in name.lower():
        # A name is only a candidate. Some "soulstones" grant reputation,
        # while obsolete ranks no longer have any usable effect at all.
        kind = "soulstone" if re.search(r"\bUse:.*?\bresurrect(?:ion|ed)?\b", text, re.I) else None
    elif "healthstone" in name.lower():
        kind = "healthstone" if has_health or family_only else None
    elif re.search(r"\bmana (?:agate|jade|citrine|ruby|emerald|sapphire|gem)\b", name, re.I):
        kind = "managem" if has_mana else None
    elif raw["class"] == 0 and (raw["subclass"] == 7 or "bandage" in name.lower()):
        kind = "bandage" if has_health else None
    elif raw["class"] == 0 and raw["subclass"] in (0, 1, 8) and not is_food and (has_health or has_mana):
        # Damage, temporary maximum-health buffs and protection potions are
        # deliberately not classified as direct restoration.
        if re.search(r"at (?:the|a) (?:cost|expense) of\s+.*?(?:health|life)", lower):
            kind = "sacrificialrecovery"
        elif "dreamless sleep" in lower or channeled_recovery or "defenseless" in lower:
            kind = "recoverypotion"
        elif has_health:
            kind = "healthpotion"
        elif has_mana:
            kind = "manapotion"
    elif is_food:
        if re.search(r"Use:\s*(?:Serve a .*?feast|Set out a\b|Create a .*?feast)", text, re.I):
            # The embedded food tooltip describes the served meal, not the
            # restoration of the item that places the shared feast.
            kind = "placedfood"
        elif is_buff:
            kind = "buff"
        elif has_health and has_mana:
            kind = "both"
        elif has_health:
            kind = "food"
        elif has_mana:
            kind = "drink"
    if kind:
        result["kind"] = kind
        result["wf"] = is_buff
        if client_issues:
            result["runtimeRestorationRequired"] = True
            result["runtimeHealth"] = client_health
            result["runtimeMana"] = client_mana
            result["sourceIssues"] = client_issues
        elif version == "retail" and kind in ("food", "drink", "both", "buff", "healthpotion", "manapotion", "bandage", "healthstone", "managem") and (amounts["h"] or amounts["m"]):
            # Even nonzero flat exports can depend on item level/quality.
            result["runtimeRestorationPreferred"] = True
            result["runtimeHealth"] = bool(amounts["h"])
            result["runtimeMana"] = bool(amounts["m"])
        if result.get("runtimeRestorationRequired") or result.get("runtimeRestorationPreferred"):
            tick = re.search(rf"(?:every|per)\s+(?:({NUMBER})\s*)?(?:seconds?|sec)\b", parsed_recovery, re.I)
            if tick:
                result["runtimePeriodic"] = True
                result["runtimeInterval"] = number(tick[1]) if tick[1] else 1
                duration = re.search(rf"(?:for|over)\s+({NUMBER})\s*(seconds?|sec|min)\b", parsed_recovery, re.I)
                if duration:
                    result["runtimeDuration"] = number(duration[1]) * (60 if duration[2].lower() == "min" else 1)
        if family_only:
            result["familyOnlyRestoration"] = family_only
            result["restorationText"] = recovery
        if glyph_total:
            result["totalInvariantUnderGlyph"] = "Glyph of Loose Mana"
            result["sourceRule"] = LOOSE_MANA_RULE
        if channeled_recovery:
            result["requiresChannel"] = True
        if channeled_recovery or bounded_food:
            result["restorationUpperBound"] = True
        if is_buff and buff_stats:
            result["bs"] = buff_stats
        if buff_warnings:
            result["warnings"] = buff_warnings
        availability = re.search(r"May not be in WoW:[^.]+\.", text, re.I)
        if availability:
            result["availabilityUncertain"] = True
            result.setdefault("warnings", []).append("Source availability warning: " + availability[0])
        if "however you also suffer" in lower or re.search(r"reduces (?:your )?(?:spell damage|healing done)", lower):
            result["hasHarmfulAfterEffect"] = True
        if version == "retail" and re.search(r"\bbut (?:you )?suffer\b", lower):
            result["hasHarmfulAfterEffect"] = True
        if "only be used in pvp battlegrounds" in lower:
            result["battlegroundOnly"] = True
        restriction = re.search(r"(?:usable only (?:inside|in)|only usable (?:inside|in)|(?:may|can) only be used (?:inside|in)|only works (?:inside|in))\s+([^.!]+)", text, re.I)
        if restriction:
            context = restriction[1].strip().strip('"').lower()
            if context != "pvp battlegrounds":
                result["sourceRestriction"] = restriction[0].strip()
                if context in CLASSIC_BATTLEGROUNDS and version in ("forever", "era", "tbc", "wrath", "cata", "mop"):
                    result["battlegroundOnly"] = True
                    result["allowedInstanceIDs"] = CLASSIC_BATTLEGROUNDS[context]
                elif context in FOREVER_BATTLEGROUNDS and version == "forever":
                    result["battlegroundOnly"] = True
                    result["allowedInstanceIDs"] = FOREVER_BATTLEGROUNDS[context]
                elif context == TEMPEST_KEEP and version == "tbc":
                    result["allowedInstanceIDs"] = TEMPEST_KEEP_INSTANCES
                elif context == COILFANG and version == "tbc":
                    result["allowedInstanceIDs"] = COILFANG_INSTANCES
                else:
                    result["contextUnknown"] = True
                    result.setdefault("warnings", []).append("Unresolved use restriction: " + restriction[0].strip())
        if version == "retail":
            if "only usable outdoors" in lower:
                result["outdoorsOnly"] = True
            elif not restriction and re.search(r"only (?:usable|works)|(?:can|may) only be used", lower):
                result["contextUnknown"] = True
                result.setdefault("warnings", []).append("Unresolved use restriction outside known instance grammar")
            if "does not work in instances or battlegrounds" in lower:
                result["worldOnly"] = True
            maximum = re.search(r"does not work (?:on players over level|past level) (\d+)", lower)
            if maximum:
                result["maximumLevel"] = int(maximum[1])
    # Partial values must never be ranked as if the whole effect was parsed.
    if issues:
        return None, issues
    return result if kind else None, []


def lua(value):
    if isinstance(value, list):
        return "{" + ", ".join(lua(item) for item in value) + "}"
    if isinstance(value, dict):
        return "{" + ", ".join("[" + lua(key) + "]=" + lua(val) for key, val in sorted(value.items())) + "}"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, (int, float)):
        return format(value, ".12g")
    raise TypeError(value)


def build(snapshot):
    records, unresolved, excluded, warnings = [], {}, [], {}
    for raw in snapshot["items"]:
        record, issues = normalize(raw, snapshot["version"])
        if issues:
            unresolved[str(raw["id"])] = issues
        elif record:
            records.append(record)
            if record.get("warnings"):
                warnings[str(raw["id"])] = record["warnings"]
        else:
            excluded.append(raw["id"])
    counts = {}
    for record in records:
        counts[record["kind"]] = counts.get(record["kind"], 0) + 1
    legacy_ids = set()
    for source in snapshot["discovery"].get("sources", []):
        if source.get("seed") == "legacy.json":
            path = ROOT / "data/seeds/legacy.json"
            if path.exists():
                legacy_ids.update(json.loads(path.read_text())["ids"])
    included_ids = {record["id"] for record in records}
    legacy_recovery_exclusions = []
    for raw in snapshot["items"]:
        if raw["id"] in legacy_ids and raw["id"] not in included_ids and str(raw["id"]) not in unresolved:
            if re.search(r"\b(?:restores?|heals?)\b.*?\b(?:health|mana|damage)\b", raw["tooltip"], re.I) and not re.match(r"^(?:UNUSED ITEM|Deprecated)\b", raw["name"], re.I):
                legacy_recovery_exclusions.append(raw["id"])
    report = {"version": snapshot["version"], "discovery": snapshot["discovery"],
              "fetched": len(snapshot["items"]), "included": len(records),
              "categories": counts, "unresolved": unresolved, "excluded": excluded,
              "warnings": warnings, "legacyRecoveryExclusions": sorted(legacy_recovery_exclusions),
              "runtimeRestorationRequired": {str(record["id"]): record["sourceIssues"]
                                             for record in records if record.get("runtimeRestorationRequired")},
              "runtimeRestorationPreferred": sorted(record["id"] for record in records
                                                    if record.get("runtimeRestorationPreferred")),
              "familyOnlyRestoration": {str(record["id"]): record["familyOnlyRestoration"]
                                        for record in records if record.get("familyOnlyRestoration")},
              "unavailable": snapshot.get("unavailable", {}), "failures": snapshot["failures"]}
    lines = ["-- Generated consumable database; do not edit.",
             f"if AC_Database and GetBuildInfo and AC_Database.ClientVersion(select(4, GetBuildInfo())) ~= {lua(snapshot['version'])} then return end",
             f"AC_GENERATED_DATABASES = AC_GENERATED_DATABASES or {{}}",
             f"AC_GENERATED_DATABASES[{lua(snapshot['version'])}] = {{",
             f"  coverage = {lua(snapshot.get('activation', {}).get('coverage', snapshot['discovery']['coverage']))},",
             f"  enabled = {lua(bool(snapshot.get('activation', {}).get('enabled')))},",
             "  items = {"]
    for record in sorted(records, key=lambda row: row["id"]):
        item_id = record["id"]
        lines.append(f"    [{item_id}] = {lua({k: v for k, v in record.items() if k != 'id'})},")
    lines += ["  },", "}", ""]
    return "\n".join(lines), report


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True) + "\n")
    temporary.replace(path)


def write_manifest():
    """Only published runtime files belong in the game's load manifest."""
    lines = ['<!-- Generated database manifest; staging data is never loaded. -->',
             '<Ui xmlns="http://www.blizzard.com/wow/ui/">']
    for version in VERSIONS:
        published = ROOT / "data/published" / (version + ".json")
        runtime = ROOT / "data/generated" / (version + ".lua")
        if published.exists() and runtime.exists():
            if json.loads(published.read_text()).get("activation", {}).get("enabled"):
                lines.append(f'  <Script file="data/generated/{version}.lua"/>')
    lines += ['</Ui>', '']
    path = ROOT / "Databases.xml"
    temporary = path.with_suffix(".xml.tmp")
    temporary.write_text("\n".join(lines))
    temporary.replace(path)


def validate_activation(snapshot, report):
    if report["failures"] or report["unresolved"]:
        raise ValueError("Cannot activate a dataset with failed fetches or unparsed restoration effects")
    if report.get("legacyRecoveryExclusions"):
        raise ValueError("Review discarded legacy recovery items before activation: " + ", ".join(map(str, report["legacyRecoveryExclusions"])))
    if report.get("familyOnlyRestoration") and report.get("categories", {}).get("healthstone") != 1:
        raise ValueError("Review competing healthstones before enabling a family without numeric ranking")
    if snapshot["discovery"].get("errors"):
        raise ValueError("Cannot activate a dataset with failed catalog discovery")
    required = {"food", "drink", "buff", "healthpotion", "manapotion", "bandage", "healthstone"}
    missing = required - {kind for kind, count in report.get("categories", {}).items() if count > 0}
    if missing:
        raise ValueError("Cannot activate a dataset missing required categories: " + ", ".join(sorted(missing)))
    names = {"forever": "Forever", "era": "Vanilla", "tbc": "TBC", "wrath": "Wrath",
             "cata": "Cata", "mop": "Mists", "retail": "Retail"}
    expected = f"ItemDB/Data/{names[snapshot['version']]}/_core/Consumable.lua"
    sources = snapshot["discovery"].get("sources", [])
    catalogs = [source for source in sources if isinstance(source.get("provenance"), dict)
                and source["provenance"].get("core") == expected]
    if not catalogs:
        raise ValueError("Activation requires a version-specific, traceable ItemDB candidate catalog")
    available = {row["id"] for row in snapshot["items"]}
    supplements = [source for source in sources if isinstance(source.get("provenance"), dict)
                   and source["provenance"].get("candidateCore") == expected]
    for catalog in catalogs + supplements:
        path = ROOT / "data/seeds" / catalog["seed"]
        seed = json.loads(path.read_text())
        if seed["source"] != catalog["provenance"]:
            raise ValueError("The saved candidate catalog has changed; import it again before activation")
        covered = available
        if catalog in supplements:
            covered = available | {int(item_id) for item_id in snapshot.get("unavailable", {})}
        if set(seed["ids"]) - covered:
            raise ValueError("Not every catalog candidate has a Wowhead source record")


def collect_items(version, ids, discovery, cache, previous=None, offline=False, interval=0.5, refresh=False):
    """Resume without discarding saved or cached records after a source denial."""
    if previous and previous["version"] != version:
        raise ValueError("Cannot resume a snapshot from another client")
    saved = {row["id"]: row for row in (previous or {}).get("items", [])}
    snapshot = {"version": version, "retrievedAt": datetime.now(timezone.utc).isoformat(),
                "discovery": discovery, "items": [], "failures": {}, "unavailable": {},
                "refreshed": [], "refreshRequested": refresh}
    stopped = False
    stop_reason = "Not attempted after source denied a request"
    # Retain records from earlier runs even when the new candidate list is
    # smaller or the local HTTP cache has been removed.
    ordered_ids = sorted(set(ids) | set(saved))
    for index, item_id in enumerate(ordered_ids, 1):
        url = item_url(version, item_id)
        path = cache / (str(item_id) + ".xml")
        if item_id in saved and not path.exists() and (not refresh or offline or stopped):
            snapshot["items"].append(saved[item_id])
            if stopped:
                snapshot["failures"][str(item_id)] = stop_reason
            continue
        if stopped and not path.exists():
            snapshot["failures"][str(item_id)] = stop_reason
            continue
        try:
            body = fetch(url, path, offline or stopped, interval, refresh and not stopped)
            raw = read_xml(body, item_id, version)
            raw["url"] = url
            if path.exists():
                raw["cachedAt"] = datetime.fromtimestamp(path.stat().st_mtime, timezone.utc).isoformat()
            snapshot["items"].append(raw)
            if refresh and not offline and not stopped:
                snapshot["refreshed"].append(item_id)
        except ItemUnavailable as error:
            snapshot["unavailable"][str(item_id)] = {"reason": str(error), "url": url,
                                                    "sha256": hashlib.sha256(body).hexdigest()}
        except (ValueError, OSError, RuntimeError, ET.ParseError) as error:
            snapshot["failures"][str(item_id)] = str(error)
            if item_id in saved:
                snapshot["items"].append(saved[item_id])
            if not offline:
                print(f"Item {item_id}: {error}", flush=True)
            if isinstance(error, RuntimeError) and "stop fetching" in str(error):
                stopped = True
        except KeyboardInterrupt:
            # A normal interruption should still save progress. Subsequent
            # iterations only read local files; no further request is made.
            snapshot["failures"][str(item_id)] = "Interrupted"
            stop_reason = "Not attempted after import was interrupted"
            stopped = True
        if index % 25 == 0:
            print(f"{version}: {index}/{len(ordered_ids)}", flush=True)
    return snapshot


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version", choices=VERSIONS)
    parser.add_argument("--seed", type=Path, action="append", help="JSON candidate IDs; repeat to combine seeds")
    parser.add_argument("--discover", action="store_true", help="Also discover category lists when using seeds")
    parser.add_argument("--offline", action="store_true", help="Use cached HTTP responses only")
    parser.add_argument("--rebuild", action="store_true", help="Generate from the committed snapshot without HTTP")
    parser.add_argument("--refresh", action="store_true", help="Fetch current source responses instead of using the HTTP cache")
    parser.add_argument("--activate", action="store_true", help="Enable a fully fetched known catalog after review")
    parser.add_argument("--interval", type=float, default=2)
    args = parser.parse_args()
    if args.interval < 0.5:
        parser.error("Use an interval of at least 0.5 seconds")
    if args.refresh and (args.offline or args.rebuild):
        parser.error("--refresh requires a network import; do not combine it with --offline or --rebuild")
    cache = ROOT / ".cache" / "wowhead" / args.version
    snapshot_path = ROOT / "data" / "sources" / (args.version + ".json")
    if args.rebuild:
        snapshot = json.loads(snapshot_path.read_text())
    else:
        discovery = {"coverage": "partial", "sources": [], "errors": {}}
        ids = set()
        if args.seed:
            for seed_path in args.seed:
                seed = json.loads(seed_path.read_text())
                candidates = seed["ids"] if isinstance(seed, dict) else seed
                if any(type(value) is not int or value <= 0 for value in candidates):
                    raise SystemExit(f"Invalid candidate ID in {seed_path}")
                ids.update(candidates)
                discovery["sources"].append({"seed": seed_path.name,
                                              "provenance": seed.get("source") if isinstance(seed, dict) else None})
        if not args.seed or args.discover:
            for category in CATEGORIES:
                url = f"https://www.wowhead.com/{VERSIONS[args.version]}items/consumables/{category}"
                try:
                    body = fetch(url, cache / (category + ".html"), args.offline, args.interval, args.refresh)
                    found = discover(body.decode())
                    ids.update(found)
                    discovery["sources"].append({"url": url, "count": len(found),
                                                   "sha256": hashlib.sha256(body).hexdigest()})
                except (ValueError, OSError, RuntimeError) as error:
                    discovery["errors"][url] = str(error)
                    print(f"Discovery failed: {url}: {error}", flush=True)
                    if isinstance(error, RuntimeError) and "stop fetching" in str(error):
                        break
            if not discovery["errors"]:
                discovery["coverage"] = "category-lists"
        if not ids:
            raise SystemExit("No candidates discovered; existing database was not changed")
        previous = json.loads(snapshot_path.read_text()) if snapshot_path.exists() else None
        snapshot = collect_items(args.version, ids, discovery, cache, previous,
                                 args.offline, args.interval, args.refresh)
        # Save raw normalized source fields, including tooltips, for offline
        # regeneration and review. This is staging data, not runtime activation.
        write_json(snapshot_path, snapshot)
    # New fetches are staging data. An incomplete refresh must never replace
    # the runtime dataset that was previously reviewed and enabled.
    staged_snapshot = dict(snapshot)
    staged_snapshot.pop("activation", None)
    generated, report = build(staged_snapshot)
    staged_output = ROOT / "data" / "staged" / (args.version + ".lua")
    staged_output.parent.mkdir(parents=True, exist_ok=True)
    staged_output.write_text(generated)
    published_path = ROOT / "data" / "published" / (args.version + ".json")
    if args.activate:
        try:
            validate_activation(snapshot, report)
        except ValueError as error:
            raise SystemExit(str(error)) from error
        snapshot["activation"] = {"enabled": True, "coverage": "known-catalog", "sourceCount": len(snapshot["items"])}
        write_json(snapshot_path, snapshot)
        write_json(published_path, snapshot)
    if args.activate or (args.rebuild and published_path.exists()):
        published = json.loads(published_path.read_text())
        generated, published_report = build(published)
        if published_report["unresolved"] or published_report["failures"] or published_report.get("legacyRecoveryExclusions"):
            raise SystemExit("Cannot rebuild the enabled dataset with unresolved effects; existing runtime data was preserved")
        output = ROOT / "data" / "generated" / (args.version + ".lua")
        output.parent.mkdir(parents=True, exist_ok=True)
        temporary = output.with_suffix(".lua.tmp")
        temporary.write_text(generated)
        temporary.replace(output)
        write_manifest()
    write_json(ROOT / "data" / "reports" / (args.version + ".json"), report)
    print(json.dumps({key: report[key] for key in ("version", "fetched", "included")}) +
          f"; unresolved={len(report['unresolved'])}, failed={len(report['failures'])}")
    print("Dataset enabled for its client." if args.activate else
          "Staging rebuilt; existing runtime datasets were preserved.")


if __name__ == "__main__":
    main()
