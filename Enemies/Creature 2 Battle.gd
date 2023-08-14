extends KinematicBody2D

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

export var ACCELERATION = 800
export var MAX_SPEED = 150
export var FRICTION = 200
export var WANDER_TARGET_RANGE = 4

enum {
	IDLE,
	WANDER,
	CHASE
}

var velocity = Vector2.ZERO
var knockback = Vector2.ZERO

var state = CHASE

onready var sprite = $AnimationEnemy
onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var hurtbox = $Hurtbox
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController
onready var animationPlayer = $AnimationPlayer

func _ready():
	state = pick_random_state([IDLE, WANDER])

func _physics_process(delta):
	update_health()
	knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
	knockback = move_and_slide(knockback)
	
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			seek_player()			
			if wanderController.get_time_left() == 0:
				update_wander()
				$AnimationEnemy.play("Idle")
		WANDER:
			seek_player()
			if wanderController.get_time_left() == 0:
				update_wander()			
			accelerate_towards_point(wanderController.target_position, delta)			
			if global_position.distance_to(wanderController.target_position) <= WANDER_TARGET_RANGE:
				update_wander()
				$AnimationEnemy.play("Idle")
		CHASE:
			var player = playerDetectionZone.player
			if player != null:
				accelerate_towards_point(player.global_position, delta)
			else:
				state = IDLE	
				$AnimationEnemy.play("Idle")
			
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 400		
	velocity = move_and_slide(velocity)
	
func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
	
	
			
func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE
		$AnimationEnemy.play("Attack")
		yield($AnimationEnemy, "animation_finished")
		
func update_wander():
	state = pick_random_state([IDLE, WANDER])
	wanderController.start_wander_timer(rand_range(1, 3))
		
func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	knockback = area.knockback_vector * 150
	hurtbox.create_hit_effect()
	hurtbox.start_invincibility(0.4)
	
func update_health():
	var healthbar = $healthbar
	
	healthbar.value = stats.health
	
	if stats.health >= 200:
		healthbar.visible = false
	else:
		healthbar.visible = true

func _on_Stats_no_health():
	DeathTransition.change_scene("res://Green Swamp/Swamp Boss C.tscn")
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position


func _on_Hurtbox_invincibility_started():
	animationPlayer.play("Start")

func _on_Hurtbox_invincibility_ended():
	animationPlayer.play("Stop")
