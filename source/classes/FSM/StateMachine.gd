class_name StateMachine
extends Node

signal state_changed(from_state: StringName, to_state: StringName)

@export var initiate_state: State = null
@onready var current_state: State = initiate_state

var states: Dictionary[StringName, State] = {}

func _ready() -> void:
	_debbug()
	_set_states()
	_enter_initial_state()

func _set_states():
	for child in get_children(true):
		if child is State:
			states[child.name] = (child as State)

func _enter_initial_state() -> void:
	current_state.enter(owner, self)
	state_changed.emit(&"", current_state.name)

func _process(delta: float) -> void:
	current_state.update(delta, owner, self)

func _physics_process(delta: float) -> void:
	current_state.physics_update(delta, owner, self)

func change_state(next_state_name: StringName) -> void:
	if next_state_name == &"": return
	var next_state: State = states[next_state_name]
	if current_state == next_state:
		push_warning("You're already at the same state named '%s'"%str(next_state_name))
		return
	if !next_state:
		push_error("There is no a State with name of '%s'"%str(next_state_name))
		return
	current_state.exit(owner, self)
	next_state.enter(owner, self)
	state_changed.emit(current_state.name, next_state_name)
	current_state = next_state

func _debbug() -> void:
	if initiate_state == null:
		push_error("There is no initial state")
		return
	state_changed.connect(Callable(self, "_state_changed_message"))

func _state_changed_message(from: StringName, to: StringName):
	print("'%s' Changed state from '%s' to '%s'"%[owner.name, from, to])
