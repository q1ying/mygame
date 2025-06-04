extends Node
class_name AIDecision

const BASE_ACTIONS: Array = ["approach", "retreat", "attack", "skill", "parry", "idle"]

const L: int = 3 
const TOP_N: int = 10
const TEMPERATURE: float = 1.8

var w_hp: Dictionary = {
	"approach":  0.35,
	"retreat":  -0.85,
	"attack":    0.60,
	"skill":     0.50,
	"parry":     0.25,
	"idle":     -1.0,
}

var w_mp: Dictionary = {
	"approach":  0.10,  
	"retreat":   0.40,  
	"attack":    0.15,
	"skill":    -0.85,
	"parry":     1.35,
	"idle":     -0.60,
}

var w_dist: Dictionary = {
	"approach":  0.85,
	"retreat":  -0.90,
	"attack":   -0.95,
	"skill":    -0.65,
	"parry":    -0.45,
	"idle":     -1.0,
}

var bias: Dictionary = {
	"approach":  0.60,
	"retreat":   0.65,
	"attack":    0.85,
	"skill":     0.70,
	"parry":     0.75,
	"idle":     -2.5,
}

var U_trans: Dictionary = {
	"approach": {"attack": 1.8, "skill": 1.5, "parry": 1.2},
	"attack":   {"retreat": 2.5, "parry": 1.8, "approach": -0.5, "skill": -1.0},
	"skill":    {"retreat": 2.5, "approach": 1.5, "parry": 1.2, "attack": -0.8},
	"parry":    {"attack": 1.5, "skill": 1.2, "retreat": 1.3, "approach": 0.8},
	"retreat":  {"skill": 2.0, "attack": 1.8, "approach": 1.5, "parry": 1.0},
	"idle":     {"attack": 1.5, "skill": 1.3, "approach": 1.0, "retreat": 0.8},
}

var weave_bonus: Dictionary = {
	["approach", "attack", "retreat"]: 1.5,
	["retreat", "skill", "approach"]: 1.3,
	["parry", "attack", "retreat"]: 1.2,
}

var all_sequences: Array = []

func _ready() -> void:
	randomize()
	all_sequences.clear()
	for a in BASE_ACTIONS:
		for b in BASE_ACTIONS:
			for c in BASE_ACTIONS:
				all_sequences.append([a, b, c])

func decide_sequence(env: Dictionary) -> Array:
	"""
	input：
	  - "player_hp" (float)
	  - "boss_hp"   (float)
	  - "player_mp" (float)
	  - "boss_mp"   (float)
	  - "dist_diff" (float，范围 0～200)
	return Array，like ["attack","idle","attack"]。
	"""
	var all_scores: Array = []
	for combo in all_sequences:
		var total_score: float = 0.0
		for i in range(L):
			var act: String = combo[i] as String
			total_score += _get_single_utility(act, env)
			if i > 0:
				var prev_act: String = combo[i - 1] as String
				total_score += _get_transition_utility(prev_act, act)
		all_scores.append([total_score, combo.duplicate()])

	all_scores.sort()
	all_scores.reverse()

	var topk: Array = all_scores.slice(0, min(TOP_N, all_scores.size()))

	var scores: Array = []
	for item in topk:
		scores.append(item[0] as float)

	var probs: Array = _softmax_probs(scores, TEMPERATURE)

	var idx: int = _sample_from_probs(probs)

	return topk[idx][1] as Array

func _get_single_utility(action: String, env: Dictionary) -> float:
	var player_hp: float = env.get("player_hp", 0.0) as float
	var boss_hp:   float = env.get("boss_hp",   0.0) as float
	var player_mp: float = env.get("player_mp", 0.0) as float
	var boss_mp:   float = env.get("boss_mp",   0.0) as float
	var dist_diff: float = env.get("dist_diff", 0.0) as float

	dist_diff = clamp(dist_diff, 0.0, 200.0)
	
	var hp_d_norm: float = player_hp / 100.0 - boss_hp / 1000.0
	
	var mp_d_norm: float = boss_mp / 500.0 - player_mp / 100.0
	
	var dist_d_norm: float = dist_diff / 200.0

	return (w_hp[action]   as float) * hp_d_norm \
		 + (w_mp[action]   as float) * mp_d_norm \
		 + (w_dist[action] as float) * dist_d_norm \
		 + (bias[action]   as float)

func _get_transition_utility(prev: String, curr: String) -> float:
	if U_trans.has(prev):
		var subd: Dictionary = U_trans[prev] as Dictionary
		if subd.has(curr):
			return subd[curr] as float
	return 0.0

func _softmax_probs(scores: Array, temperature: float) -> Array:
	var max_u: float = scores[0] as float
	for u in scores:
		if (u as float) > max_u:
			max_u = u as float

	var exps: Array = []
	for u in scores:
		var x: float = ((u as float) - max_u) / temperature
		exps.append(_exp(x))

	var s: float = 0.0
	for e in exps:
		s += e as float

	var probs: Array = []
	for e in exps:
		probs.append((e as float) / s)
	return probs

func _sample_from_probs(probs: Array) -> int:
	var r: float = randf()
	var accum: float = 0.0
	for i in range(probs.size()):
		accum += (probs[i] as float)
		if r <= accum:
			return i
	return probs.size() - 1

const E_CONST: float = 2.718281828459045
func _exp(x: float) -> float:
	return pow(E_CONST, x)
