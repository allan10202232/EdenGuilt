class_name SustainabilityAudit
extends RefCounted
## Standalone, offline-readable audit files. All graphs are native SVG, not image assets.


static func export_files(result: Dictionary,directory: String="user://audits") -> Dictionary:
	var data: Dictionary=result.get("audit",{}).duplicate(true)
	if data.is_empty():
		return {"ok":false,"error":GameText.t("本局没有审计数据。")}
	var error:=DirAccess.make_dir_recursive_absolute(directory)
	if error!=OK:
		return {"ok":false,"error":GameText.t("无法创建审计目录：%s")%error_string(error)}
	var stamp:=Time.get_datetime_string_from_system().replace(":","-")+"-"+str(Time.get_ticks_msec())
	var base:=directory.path_join("sustainability-"+stamp)
	var document:=data.duplicate(true)
	document["ending"]=result.get("ending","")
	document["elapsed_seconds"]=result.get("elapsed_seconds",0.0)
	document["score"]=result.get("score",0)
	document["language"]=GameText.language
	var files: Dictionary={"json":JSON.stringify(document,"\t"),"html":html(result),"csv":csv(data)}
	var paths: Dictionary={"ok":true}
	for extension: String in files:
		var path:=base+"."+extension
		var file:=FileAccess.open(path,FileAccess.WRITE)
		if file==null:
			return {"ok":false,"error":GameText.t("审计文件写入失败：%s")%error_string(FileAccess.get_open_error())}
		file.store_string(files[extension])
		file.flush()
		if file.get_error()!=OK:
			return {"ok":false,"error":GameText.t("审计文件写入未完成。")}
		paths[extension]=ProjectSettings.globalize_path(path)
	return paths


static func csv(data: Dictionary) -> String:
	var rows:=PackedStringArray(["time_s,region,skill,CO2_kg,efficiency,heat,rapid,precise"])
	for event: Dictionary in data.events:
		rows.append('%.3f,"%s","%s",%.3f,%.4f,%.3f,%s,%s'%[
			event.time_s,String(event.region).replace('"','""'),String(event.skill).replace('"','""'),
			event.kg,event.efficiency,event.heat,event.rapid,event.precise])
	return "\n".join(rows)+"\n"


static func html(result: Dictionary) -> String:
	var data: Dictionary=result.audit
	var choice_a: bool=result.get("ending","")=="A"
	var title: String=GameText.t("A · 把绿色还给世界") if choice_a else GameText.t("B · 边界以内的春天")
	var reflection: String=GameText.t("力量曾让你独自越过深渊。回家的桥，却是和别人一起修好的。账本没有忘记过去，世界仍可从下一次选择开始改变。") if choice_a else GameText.t("你保住了窗内的春天。窗外的人仍替你呼吸。世界没有变得更轻，只是有人把重量移出了视线。")
	var stage_rows: String=""
	var svg: String=GameText.t('<svg viewBox="0 0 720 170" role="img" aria-label="各关技能碳排放柱状图">')
	var maximum: float=1.0
	for stage: Dictionary in data.stages.values():
		maximum=maxf(maximum,float(stage.gross_kg))
	var index:=0
	for stage: Dictionary in data.stages.values():
		var y:=20+index*48
		var width:=430.0*float(stage.gross_kg)/maximum
		svg+='<text x="0" y="%d" fill="#e7dcc0">%s</text><rect x="110" y="%d" width="%.1f" height="16" fill="#d6a159"/><text x="560" y="%d" fill="#e7dcc0">%.2f kg</text>'%[y+13,GameText.t(String(stage.name)).xml_escape(),y,width,y+13,stage.gross_kg]
		stage_rows+="<tr><td>%s</td><td>%.2f kg</td><td>%.2f kg</td><td>%d</td></tr>"%[GameText.t(String(stage.name)).xml_escape(),stage.gross_kg,stage.stored_kg,stage.casts]
		index+=1
	svg+="</svg>"
	var skill_rows: String=""
	for skill: Dictionary in data.skills.values():
		skill_rows+="<tr><td>%s</td><td>%d</td><td>%.2f kg</td></tr>"%[GameText.t(String(skill.name)).xml_escape(),skill.casts,skill.gross_kg]
	return GameText.audit_template()%[
		title,reflection,data.gross_kg,data.stored_kg,data.efficiency*100.0,
		(1.0-data.efficiency)*100.0 if data.input_energy>0 else 0.0,svg,stage_rows,skill_rows,
		data.people,data.restored_regions,data.recycled_nodes,data.recycled_material_kg,data.factors.teaching_ore_ratio,
		data.teaching_ore_avoided_kg,data.gross_kg,data.gasoline_litres_analogy,
		GameText.t(String(data.methodology)).xml_escape(),CarbonLedger.MAX_DETAIL_EVENTS,data.omitted_detail_events,CarbonLedger.EPA_SOURCE,CarbonLedger.DOE_SOURCE]
