extends Node2D

var non_selected_characters : Array
var allies_array : Array
var enemies_array : Array

var chara_positions : Dictionary = {"ally0": Vector2(270, 200), "ally1": Vector2(200, 300), "ally2": Vector2(270, 400), "enemy0": Vector2(800, 200),"enemy1": Vector2(870, 300),"enemy2": Vector2(800, 400)}

var battle_state
enum STATES {PREBATTLE, CONFIRMSELECTION, CHOOSINGALLY, CHOOSINGATTACK, SELECTINGENEMYTARGET, SELECTINGALLYTARGET, CONFIRMSELECTIONATTACK, FIGHTING}

var selected
var button_selected
var target_selected

var attacks_json = load("res://attacks_list.json").data
var types_table = load("res://type_interactions.json").data

var turn_dictionary : Dictionary
var turn_array : Array

signal clicked

func _ready():
	battle_state = STATES.PREBATTLE
	for child in $characters.get_children():
		non_selected_characters.append(child)
	selected = non_selected_characters[0]
	$selection_hand.position = selected.position
	
func _input(event):
	match battle_state:
		STATES.PREBATTLE:
			selecting_allies(event) 
		STATES.CONFIRMSELECTION:
			confirm_selected(event)
		STATES.CHOOSINGALLY:
			choosing_ally(event)
		STATES.CHOOSINGATTACK:
			select_attack(event)
		STATES.SELECTINGENEMYTARGET:
			selecting_target_enemy(event)
		STATES.SELECTINGALLYTARGET:
			selecting_target_ally(event)
		STATES.CONFIRMSELECTIONATTACK:
			confirm_attack_selected(event)
		STATES.FIGHTING:
			if event.is_action_pressed("ui_accept"):
				clicked.emit()
				
		
func selecting_allies(event):
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		if non_selected_characters.find(selected) == non_selected_characters.size()-1:
			selected = non_selected_characters[0]
		else:
			selected = non_selected_characters[non_selected_characters.find(selected) + 1]
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		selected = non_selected_characters[non_selected_characters.find(selected) - 1]
	$selection_hand.position = selected.position
	$dialog/bottomBoxLabel.text = selected.name + ": " + selected.description + "\nType: " + selected.type_1
	if selected.type_2 != "":
		$dialog/bottomBoxLabel.text += " / " + selected.type_2
	if event.is_action_pressed("ui_accept"):
		prepare_confirm_selection()
		
func prepare_confirm_selection():
	$confirmButtons.show()
	$dialog/topBox.hide()
	$dialog/topBoxLabel.hide()
	button_selected = $confirmButtons/YesBox
	$dialog/bottomBoxLabel.text = "Do you wanna " + selected.name + " in your party?"
	battle_state = STATES.CONFIRMSELECTION
	
func confirm_selected(event):
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		if button_selected == $confirmButtons/YesBox:
			button_selected = $confirmButtons/NoBox
		else:
			button_selected = $confirmButtons/YesBox
	$selection_hand.position = button_selected.position + Vector2(-15,0)
	if event.is_action_pressed("ui_accept"):
		if button_selected == $confirmButtons/YesBox:
			allies_array.append(selected)
			non_selected_characters.erase(selected)
			selected.hide()
			selected = non_selected_characters[0]
		$confirmButtons.hide()
		if allies_array.size() == 3:
			start_battle()
		else:
			$dialog/topBox.show()
			$dialog/topBoxLabel.show()
			battle_state = STATES.PREBATTLE
			
func start_battle():
	for x in non_selected_characters:
		enemies_array.append(x)
	for x in allies_array:
		x.position = chara_positions["ally"+str(allies_array.find(x))]
		x.show()
	for x in enemies_array:
		x.position = chara_positions["enemy"+str(enemies_array.find(x))]
		x.get_node("Sprite2D").flip_h = true
	selected = allies_array[0]
	for child in $characters.get_children():
		child.get_node("ProgressBar").show()
	battle_state = STATES.CHOOSINGALLY
	
func choosing_ally(event):
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		if allies_array.find(selected) == allies_array.size()-1:
			selected = allies_array[0]
		else:
			selected = allies_array[allies_array.find(selected) + 1]
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		selected = allies_array[allies_array.find(selected) - 1]
	$selection_hand.position = selected.position
	if turn_dictionary.has(selected.name):
		$dialog/bottomBoxLabel.text = selected.name + " will attack "
		if turn_dictionary[selected.name].size() >= 3:
			$dialog/bottomBoxLabel.text += turn_dictionary[selected.name][2].name + " "
		$dialog/bottomBoxLabel.text += "with " + turn_dictionary[selected.name][1] + ". Select to change turn."
	else:
		$dialog/bottomBoxLabel.text = "Select to choose what will " + selected.name + " do."
	$dialog/bottomBoxLabel.text += "\nType: " + selected.type_1
	if selected.type_2 != "":
		$dialog/bottomBoxLabel.text += " / " + selected.type_2
	$dialog/bottomBoxLabel.text += "\nAttack: " + str(selected.attack) + "|| Defense: " + str(selected.defense) + "|| Speed: " + str(selected.speed) + "|| Health points: " + str(selected.current_health) + " / " + str(selected.max_health)
	if event.is_action_pressed("ui_accept"):
		show_attacks()

func show_attacks():
	for pos in selected.attacks.size():
		get_node("attackButtons/"+str(pos)+"Box").show()
		get_node("attackButtons/"+str(pos)+"Label").text = selected.attacks[pos]
		get_node("attackButtons/"+str(pos)+"Label").show()
	button_selected = selected.attacks[selected.attacks.size()-1]
	battle_state = STATES.CHOOSINGATTACK
	
func select_attack(event):
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		if selected.attacks.find(button_selected) == selected.attacks.size()-1:
			button_selected = selected.attacks[0]
		else:
			button_selected = selected.attacks[selected.attacks.find(button_selected)+1]
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		button_selected = selected.attacks[selected.attacks.find(button_selected)-1]
	$selection_hand.position = get_node("attackButtons/"+str(selected.attacks.find(button_selected))+"Box").position + Vector2(-65,0)
	$dialog/bottomBoxLabel.text = attacks_json[button_selected]["description"] + "\nType: " + attacks_json[button_selected]["type"] + "\n"
	if attacks_json[button_selected]["damage"] != 0:
			$dialog/bottomBoxLabel.text += "Power attack: " + str(attacks_json[button_selected]["damage"]) + ". "
	if attacks_json[button_selected]["healing"] != 0:
		$dialog/bottomBoxLabel.text += "Healing power: " + str(attacks_json[button_selected]["healing"]) + ". "
	if event.is_action_pressed("ui_accept"):
		for child in $attackButtons.get_children():
			child.hide()
		checking_attack()
		
func checking_attack():
	if attacks_json[button_selected]["is masive"] == true:
		turn_dictionary[selected.name] = [selected, button_selected]
		check_if_all_attacked()
	else:
		if attacks_json[button_selected]["damage"] != 0:
			target_selected = enemies_array[0]
			battle_state = STATES.SELECTINGENEMYTARGET
		else:
			target_selected = selected
			battle_state = STATES.SELECTINGALLYTARGET
		
func selecting_target_enemy(event):
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		if enemies_array.find(target_selected) == enemies_array.size()-1:
			target_selected =  enemies_array[0]
		else:
			target_selected = enemies_array[enemies_array.find(target_selected) + 1]
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		target_selected = enemies_array[enemies_array.find(target_selected) - 1]
	$selection_hand.position = target_selected.position
	$dialog/bottomBoxLabel.text = "Do you want to attack " + target_selected.name + " with " + selected.name + "'s " + button_selected + "?"
	if event.is_action_pressed("ui_accept"):
		turn_dictionary[selected.name] = [selected, button_selected, target_selected]
		check_if_all_attacked()
	
func selecting_target_ally(event):
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		if allies_array.find(target_selected) == allies_array.size()-1:
			target_selected = allies_array[0]
		else:
			target_selected = allies_array[allies_array.find(target_selected) + 1]
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		target_selected = allies_array[allies_array.find(target_selected) - 1]
	$selection_hand.position = target_selected.position
	$dialog/bottomBoxLabel.text = "Do you want to heal " + target_selected.name + "?"
	if event.is_action_pressed("ui_accept"):
		turn_dictionary[selected.name] = [selected, button_selected, target_selected]
		check_if_all_attacked()
	
func check_if_all_attacked():
	if turn_dictionary.size() == allies_array.size():
		confirm_selection_attacks()
	else:
		battle_state = STATES.CHOOSINGALLY
		
func confirm_selection_attacks():
	$confirmButtons.show()
	$dialog/topBox.show()
	$dialog/topBoxLabel.text = "Do you want to do this in this turn?"
	$dialog/topBoxLabel.show()
	$dialog/bottomBoxLabel.text = ""
	for ally in allies_array:
		$dialog/bottomBoxLabel.text += ally.name + " will attack "
		if turn_dictionary[ally.name].size() >= 3:
			$dialog/bottomBoxLabel.text += turn_dictionary[ally.name][2].name + " "
		$dialog/bottomBoxLabel.text += "ussing " + turn_dictionary[ally.name][1] + ".\n"
	button_selected = $confirmButtons/YesBox
	battle_state = STATES.CONFIRMSELECTIONATTACK
	
func confirm_attack_selected(event):
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		if button_selected == $confirmButtons/YesBox:
			button_selected = $confirmButtons/NoBox
		else:
			button_selected = $confirmButtons/YesBox
	$selection_hand.position = button_selected.position + Vector2(-15,0)
	if event.is_action_pressed("ui_accept"):
		if button_selected == $confirmButtons/YesBox:
			assign_enemies_attack()
			$selection_hand.hide()
			battle_state = STATES.FIGHTING
		else:
			selected = allies_array[0]
			battle_state = STATES.CHOOSINGALLY
		$confirmButtons.hide()
		$dialog/topBox.hide()
		$dialog/topBoxLabel.hide()
			
func assign_enemies_attack():
	for chara in enemies_array:
		var attack = chara.attacks.pick_random()
		if attacks_json[attack]["damage"] == 0:
			turn_dictionary[chara.name] = [chara, attack, enemies_array.pick_random()]
		elif attacks_json[attack]["is masive"] == true:
			turn_dictionary[chara.name] = [chara, attack]
		else:
			turn_dictionary[chara.name] = [chara, attack, allies_array.pick_random()]
	ordering_turn()

func ordering_turn():
	for chara in turn_dictionary:
		if attacks_json[turn_dictionary[chara][1]]["is fast"] == true:
			get_node("characters/"+chara).speed = get_node("characters/"+chara).base_speed +100
		elif attacks_json[turn_dictionary[chara][1]]["is slow"] == true:
			get_node("characters/"+chara).speed = get_node("characters/"+chara).base_speed -100
		else:
			get_node("characters/"+chara).speed = get_node("characters/"+chara).base_speed
	for turn in turn_dictionary:
		turn_array.append(turn_dictionary[turn])
	turn_array.sort_custom(sorting_by_speed)
	battle_state = STATES.FIGHTING
	attack_combo()
	
func sorting_by_speed(a, b):
	if a[0].speed >= b[0].speed : return true
	else: return false
	
func attack_combo():
	for attack in turn_array:
		if attack[0] != null:
			if attacks_json[attack[1]]["is masive"] == true:
				$dialog/bottomBoxLabel.text = attack[0].name + " used " + attack[1] + "."
				await clicked
				if allies_array.has(attack[0]):
					for enemy in enemies_array:
						await causing_damage(attack, enemy)
				else:
					for ally in allies_array:
						await causing_damage(attack, ally)
			elif attacks_json[attack[1]]["damage"] == 0:
				if attack[2] != null:
					$dialog/bottomBoxLabel.text = attack[0].name + " used " + attack[1]
					await clicked
					await recovering_life(attack, attack[2])
				else:
					$dialog/bottomBoxLabel.text = attack[0].name + "'s helaing spell wasn't able to reach it's target!"
					await clicked
			else:
				if attack[2] != null:
					$dialog/bottomBoxLabel.text = attack[0].name + " used " + attack[1]
					await clicked
					await causing_damage(attack, attack[2])
					if attacks_json[attack[1]]["healing"] > 0:
						await recovering_life(attack, attack[0])
				else:
					$dialog/bottomBoxLabel.text = attack[0].name + "'s attack wasn't able to reach it's target!"
					await clicked
	turn_array.clear()
	turn_dictionary.clear()
	selected = allies_array[0]
	$selection_hand.show()
	battle_state = STATES.CHOOSINGALLY

func causing_damage(attack, target):
	var type_modifier = types_table[attacks_json[attack[1]]["type"]][target.type_1] * types_table[attacks_json[attack[1]]["type"]][target.type_2]
	var damage = int(attack[0].attack / target.defense * attacks_json[attack[1]]["damage"] * type_modifier)
	target.change_health(damage)
	$dialog/bottomBoxLabel.text = target.name + " looses " + str(damage) + " health points.\n"
	if type_modifier > 1.2:
		$dialog/bottomBoxLabel.text += "It looks like that hurted!\n"
	elif type_modifier < 1:
		$dialog/bottomBoxLabel.text += "It wasn't much of a scratch\n"
	if target.current_health <= 0:
		await clicked
		if allies_array.has(target):
			allies_array.erase(target)
		else:
			enemies_array.erase(target)
		$dialog/bottomBoxLabel.text = target.name + " can't fight anymore!"
		target.get_node("AnimationPlayer").play("death")
		await target.get_node("AnimationPlayer").animation_finished
		target.queue_free()
		await check_if_game_over()
	await clicked
		
func recovering_life(attack, target):
	if target.current_health == target.max_health:
		$dialog/bottomBoxLabel.text = target.name + " is already at their best!"
	else:
		var health_recovered = attacks_json[attack[1]]["healing"] * attack[0].max_health / 100
		if (target.max_health - target.current_health) < health_recovered:
			health_recovered = target.max_health - target.current_health
		target.change_health(-health_recovered)
		$dialog/bottomBoxLabel.text = target.name + " recovered " + str(health_recovered) + " health points."
	await clicked

func check_if_game_over():
	if allies_array.size() == 0 or enemies_array.size() == 0:
		if allies_array.size() == 0:
			$dialog/bottomBoxLabel.text = "Oh no! You loose"
		else:
			$dialog/bottomBoxLabel.text = "Congratulations! You win!" 
		await clicked
		get_tree().reload_current_scene()
