extends Node3D

@onready var Animation_Player = get_node("%AnimationPlayer")

var Current_Weapon = null

# an array of weapons currently held by the player
var Weapon_Stack = []

var Weapon_Indicator = 0

var Next_Weapon: String

var Weapon_List = {}

@export var _weapon_resources: Array[Weapon_Resource]

@export var Start_Weapons: Array[String]


# Functions
func _ready():
	# enter the weapon system state machine
	Initialize(Start_Weapons)


func _input(event):
	# monitor inputs
	if event.is_action_pressed("rifle"):
		Exit(Weapon_Stack[0])
	elif event.is_action_pressed("pistol"):
		Exit(Weapon_Stack[1])
	elif event.is_action_pressed("knife"):
		Exit(Weapon_Stack[2])
	elif event.is_action_pressed("sniper"):
		Exit(Weapon_Stack[3])
	# if it's the same weapon, then put away weapon and change to hands (melee)


func Initialize(_start_weapons: Array):
	# first, create dict of all weapons in the game to refer to
	for weapon in _weapon_resources:
		Weapon_List[weapon.Weapon_Name] = weapon

	# append all start weapons to the weapon stack
	for i in _start_weapons:
		Weapon_Stack.push_back(i)

	# set first weapon in weapon stack as current weapon
	Current_Weapon = Weapon_List[Weapon_Stack[0]]

	# begin first weapon resource animation/setup
	Enter()

func Enter():
	# called when switched to a new weapon
	Animation_Player.queue(Current_Weapon.Init_Anim)


func Exit(_next_weapon: String):
	# called before changing weapon, performs checks

	# switching to different weapon
	if _next_weapon != Current_Weapon.Weapon_Name:
		if Animation_Player.get_current_animation() != Current_Weapon.Term_Anim:
			Animation_Player.play(Current_Weapon.Term_Anim)
			Next_Weapon = _next_weapon

	# storing away weapon to hands
	else:
		pass


func Change_Weapon(weapon_name: String):
	Current_Weapon = Weapon_List[weapon_name]
	Next_Weapon = ''
	Enter()


func _on_animation_player_animation_finished(anim_name:StringName):
	# prevent animation spamming
	if anim_name == Current_Weapon.Term_Anim:
		Change_Weapon(Next_Weapon)
