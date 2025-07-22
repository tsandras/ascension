extends RefCounted

class_name Stats

const BASE_PV_GROWTH = 5
const BASE_ENDURANCE = 2
const BASE_SKILL_SLOTS = 2

func pv_max(stamina: int,level: int) -> int:
    return (stamina + BASE_PV_GROWTH) * level

func endurance_max(strength: int) -> int:
    return strength / 2 + BASE_ENDURANCE

func mana_max(essence: int) -> int:
    return essence * 2

func skill_slots_max(intelligence: int) -> int:
    return intelligence + BASE_SKILL_SLOTS

func block_max(agility: int) -> int:
    return agility

func willpower_max(resolution: int) -> int:
    return resolution

