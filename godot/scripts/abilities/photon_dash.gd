extends "res://scripts/abilities/particle_ability.gd"

@export var dash_speed_bonus: float = 260.0
@export var dash_evasion_multiplier: float = 1.35
@export var dash_control_multiplier: float = 0.65
@export var energy_cost: float = 20.0

func _init() -> void:
    ability_name = "Photon Dash"
    cooldown = 4.5
    activation_duration = 1.4
    resource_costs = {&"energy": energy_cost}
    description = "Accelerate into a beamline sprint, slipping past hazards while destabilising control surfaces." \
        + " Movement speed and evasion spike as the particle blurs through phase space."
    activation_profile = {
        "bonuses": {
            "speed": dash_speed_bonus,
        },
        "multipliers": {
            "evasion": dash_evasion_multiplier,
            "control": dash_control_multiplier,
        },
        "keywords": [StringName("phased"), StringName("velocity")],
    }
    activation_log_message = "Photon Dash cascades into superluminal lanes."
    animation_state = &"dash"
    animation_speed = 1.6
