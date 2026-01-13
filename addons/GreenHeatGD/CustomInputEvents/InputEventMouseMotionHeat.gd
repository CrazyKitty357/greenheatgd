extends InputEventMouseMotion
## Class used to pass the id through the event while making it easier to differentiate from a normal mouse event.
class_name InputEventMouseMotionHeat
## Id used to pass twitch id through the event
var id : String

func _to_string():
	var parentString : String = super.to_string()
	parentString = parentString.trim_prefix("InputEventMouseMotion")
	parentString = "InputEventMouseMotionHeat" + parentString
	parentString += ", id='" + id + "'"
	return parentString
