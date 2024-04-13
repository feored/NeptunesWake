extends Control

@onready var trigger_container = %TriggerContainer
@onready var duration_container = %DurationContainer

@onready var trigger_label : Label = %TriggerLabel
@onready var duration_label : Label = %DurationLabel
@onready var duration_trigger_label : Label = %DurationTriggerLabel
@onready var type_label : Label = %TypeLabel
@onready var tier_label : Label = %TierLabel
@onready var name_label : Label = %NameLabel

const type_short = {
	Effect.Type.Power : "Power",
	Effect.Type.Active: "Active",
	Effect.Type.Resource: "Resource"
}


var effect : Effect = null


# Called when the node enters the scene tree for the first time.
func _ready():
	self.config()

func init(e: Effect):
	self.effect = e

func config():
	if self.effect == null:
		return
	self.trigger_label.text = "[" + Effect.Trigger.keys()[self.effect.active_trigger] + "]"
	if self.effect.active_trigger == Effect.Trigger.Instant:
		self.trigger_container.hide()
	
	self.duration_label.text = str(self.effect.duration)
	self.duration_trigger_label.text = "[" + Effect.Trigger.keys()[self.effect.duration_trigger] + "]"
	if self.effect.duration == 0:
		self.duration_container.hide()
	
	self.type_label.text = self.type_short[self.effect.type]
	self.tier_label.text = "T" + str(self.effect.tier)
	self.name_label.text = self.effect.name
		

	
