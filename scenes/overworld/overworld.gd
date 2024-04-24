extends Node
var current_event : Node = null

@onready var map_view = %MapView
@onready var deck_view = %DeckView
@onready var event_container = %EventContainer
@onready var drachme_label = %DrachmeLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	self.update_view()
	if Info.run.is_beaten():
		SceneTransition.change_scene(SceneTransition.SCENE_END)
	self.map_view.event_started.connect(func(e): start_event(e))
	self.map_view.show()


func start_event(event):
	map_view.hide()
	Utils.log("Starting event: " + event)
	var event_view_prefab = load(Constants.EVENTS[event])
	var event_view = event_view_prefab.instantiate()
	self.current_event = event_view
	event_view.event_over.connect(Callable(self, "end_event"))
	self.event_container.add_child(event_view)
	

func end_event():
	self.map_view.clear()
	self.map_view.draw_map()
	self.map_view.show()
	self.map_view.scroll_to_floor()
	self.current_event.queue_free()
	self.update_view()


func update_view():
	self.drachme_label.text = str(Info.run.gold)

func _on_deck_view_btn_pressed():
	self.deck_view.init(Info.run.deck)
	self.deck_view.show()


