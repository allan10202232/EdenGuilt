extends Node

var _checks: int = 0
var _failures: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	# Ledger unit tests emit many synchronous events in one frame; audio is covered by the integration suite.
	for event: Signal in [WorldProgress.ability_used,WorldProgress.ability_absorbed,WorldProgress.ability_returned,WorldProgress.checkpoint_changed,GameSession.checkpoint_resumed]:
		for connection: Dictionary in event.get_connections():
			if connection.callable.get_object()==SoundManager:
				event.disconnect(connection.callable)
	WorldProgress.campaign_rules=true
	GameSession.start_run()
	_check(CarbonLedger.enabled and CarbonLedger.gross_kg==0.0,"new campaign opens empty carbon ledger")
	WorldProgress.borrow_ability(&"light_blade")
	WorldProgress.borrow_ability(&"double_jump")
	WorldProgress.report_ability_used(&"double_jump")
	_check(CarbonLedger.gross_kg==5.0,"actual double jump records exactly 5 kg")
	_enter(&"grassland")
	WorldProgress.borrow_ability(&"mineralization")
	CarbonLedger.clock_seconds+=0.75
	WorldProgress.report_ability_used(&"mineralization")
	_check(CarbonLedger.gross_kg==6.0 and is_equal_approx(CarbonLedger.efficiency,0.95),"mineralization adds 1 kg and precise cadence reaches 95 percent")
	_enter(&"remnant_sea")
	WorldProgress.borrow_ability(&"shield")
	WorldProgress.borrow_ability(&"black_pierce")
	CarbonLedger.clock_seconds+=0.75
	WorldProgress.report_ability_used(&"shield")
	_check(CarbonLedger.gross_kg==26.0,"shield activation adds 20 kg")
	CarbonLedger.clock_seconds+=0.75
	WorldProgress.report_ability_used(&"black_pierce")
	_check(CarbonLedger.gross_kg==226.0,"black pierce adds 200 kg")
	_check(CarbonLedger.climate_stage()==2,"emissions above threshold trigger extreme climate")
	var gross_before:=CarbonLedger.gross_kg
	_check(not WorldProgress.report_ability_used(&"dash") and CarbonLedger.gross_kg==gross_before,"unavailable skills cannot create ledger events")
	CarbonLedger.record_action(&"unknown")
	_check(CarbonLedger.gross_kg==gross_before,"unknown actions cannot create emissions")
	CarbonLedger.clock_seconds+=2.0
	WorldProgress.report_ability_used(&"light_blade")
	_check(is_equal_approx(CarbonLedger.gross_kg-gross_before,0.25),"isolated melee uses base carbon rate")
	gross_before=CarbonLedger.gross_kg
	for index in 7:
		CarbonLedger.clock_seconds+=0.10
		WorldProgress.report_ability_used(&"light_blade")
	_check(is_equal_approx(CarbonLedger.gross_kg-gross_before,14.0),"rapid attacks add explicit high frequency emissions")
	_check(CarbonLedger.heat>=80.0 and is_equal_approx(CarbonLedger.efficiency,0.30),"spam overheats and wastes 70 percent energy")
	var snapshot:=CarbonLedger.snapshot()
	var sum_kg: float=0.0
	for stage: Dictionary in snapshot.stages.values(): sum_kg+=stage.gross_kg
	_check(is_equal_approx(sum_kg,snapshot.gross_kg),"stage subtotals reconcile to permanent gross ledger")
	_check(is_equal_approx(snapshot.efficiency,snapshot.useful_energy/snapshot.input_energy),"audit efficiency is energy weighted rather than mean of percentages")
	_check(snapshot.waste_energy>0.0 and snapshot.action_count==12,"audit records useful work, waste and all accepted actions")
	gross_before=CarbonLedger.gross_kg
	_check(CarbonLedger.store_carbon(&"node/test",300.0),"verified game node records separate carbon storage")
	_check(CarbonLedger.gross_kg==gross_before and CarbonLedger.climate_stage()==0,"storage improves air without deleting gross emissions")
	_check(not CarbonLedger.store_carbon(&"node/test",300.0),"same storage node cannot be credited twice")
	_check(not CarbonLedger.store_carbon(&"invalid",-1.0) and not CarbonLedger.store_carbon(&"nan",NAN),"invalid storage quantities are rejected")
	_check(CarbonLedger.recycle(&"scrap/test") and not CarbonLedger.recycle(&"scrap/test"),"circular dismantling is credited once per stable id")
	var heat_before:=CarbonLedger.heat
	GameSession.player_died()
	WorldProgress.report_ability_used(&"black_pierce")
	_check(CarbonLedger.gross_kg==gross_before,"death locks action accounting")
	GameSession.resume_checkpoint()
	_check(CarbonLedger.gross_kg==gross_before and CarbonLedger.stored_kg==300.0 and CarbonLedger.heat==heat_before,"checkpoint does not erase carbon history, storage or heat")
	_check(not WorldProgress.return_ability(&"shield"),"cannot unload abilities before truth and community repair")
	_check(WorldProgress.reveal_truth() and not WorldProgress.can_play(),"truth dialogue freezes gameplay")
	GameSession.complete_level()
	_check(GameSession.state==GameSession.State.PLAYING,"late victory cannot bypass pending moral choice")
	_check(WorldProgress.choose_ending(&"A") and WorldProgress.core_reversed and WorldProgress.returning,"A exposes truth and reverses extractor")
	_check(CarbonLedger.rescued_people==3,"A rescues three people")
	_check(not WorldProgress.choose_ending(&"B"),"choice cannot be submitted a second time")
	_check(WorldProgress.repair_current_region(),"residents jointly repair Eden")
	_check(WorldProgress.return_ability(&"shield") and WorldProgress.return_ability(&"black_pierce"),"Eden unloads shield and black pierce after community work")
	_enter(&"grassland")
	WorldProgress.repair_current_region()
	WorldProgress.return_ability(&"mineralization")
	_enter(&"lone_tree")
	WorldProgress.repair_current_region()
	WorldProgress.return_ability(&"double_jump")
	_check(WorldProgress.required_returns_complete() and CarbonLedger.restored_regions==3,"all four skills unloaded across three community repairs")
	_check(CarbonLedger.gross_kg==gross_before,"all ecological restoration preserves the original carbon debt")
	GameSession.complete_level()
	_check(GameSession.last_result.ending=="A" and GameSession.last_result.audit.restored_regions==3,"A outcome contains frozen sustainability snapshot")
	var paths:=SustainabilityAudit.export_files(GameSession.last_result,"res://test-output/audits")
	_check(paths.get("ok",false),"exports standalone HTML plus JSON and event CSV")
	if paths.get("ok",false):
		var parsed: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(paths.json))
		_check(parsed.ending=="A" and is_equal_approx(parsed.gross_kg,gross_before),"JSON report roundtrips ending and actual emission values")
		var html:=FileAccess.get_file_as_string(paths.html)
		_check("<svg" in html and "EPA" in html and "教学" in html,"HTML contains native chart, primary source and model disclosure")
		_check(FileAccess.get_file_as_string(paths.csv).split("\n",false).size()==13,"CSV contains one row for each accepted action")
	var audit: Dictionary=GameSession.last_result.audit
	_check(is_equal_approx(audit.gasoline_litres_analogy,audit.gross_kg/8.887*3.785411784),"gasoline analogy uses sourced EPA factor and US gallon conversion")
	_check(audit.teaching_ore_avoided_kg==40.0,"ore substitution follows explicit teaching assumptions")
	GameSession.return_to_menu()
	GameSession.start_run()
	_check(CarbonLedger.gross_kg==0.0 and CarbonLedger.recycled_nodes==0 and not WorldProgress.truth_revealed,"new run clears ledger and story state together")
	_enter(&"remnant_sea")
	WorldProgress.reveal_truth()
	_check(WorldProgress.choose_ending(&"B"),"B can choose to remain in the greenwashed enclave")
	_check(GameSession.state==GameSession.State.VICTORY and GameSession.last_result.ending=="B" and not WorldProgress.core_reversed,"B ends immediately without green awakening")
	_check(GameSession.last_result.audit.people==0 and GameSession.last_result.audit.restored_regions==0,"B cannot claim residents or repair achievements")
	_check(GameSession.last_result.audit.efficiency==0.0,"zero-action report does not invent efficiency")
	GameSession.return_to_menu()
	SoundManager.stop_sfx()
	await get_tree().create_timer(0.15).timeout
	print("CARBON: %d checks, %d failures"%[_checks,_failures])
	get_tree().quit(0 if _failures==0 else 1)


func _enter(id: StringName) -> void:
	WorldProgress.enter_scene(id,Vector2(140,596))
	WorldProgress.finish_scene_load()


func _check(condition: bool,label: String) -> void:
	_checks+=1
	if condition: print("PASS: ",label)
	else:
		_failures+=1
		push_error("FAIL: "+label)
