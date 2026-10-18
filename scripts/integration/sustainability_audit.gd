class_name SustainabilityAudit
extends RefCounted
## Standalone, offline-readable audit files. All graphs are native SVG, not image assets.


static func export_files(result: Dictionary,directory: String="user://audits") -> Dictionary:
	var data: Dictionary=result.get("audit",{}).duplicate(true)
	if data.is_empty():
		return {"ok":false,"error":"本局没有审计数据。"}
	var error:=DirAccess.make_dir_recursive_absolute(directory)
	if error!=OK:
		return {"ok":false,"error":"无法创建审计目录：%s"%error_string(error)}
	var stamp:=Time.get_datetime_string_from_system().replace(":","-")+"-"+str(Time.get_ticks_msec())
	var base:=directory.path_join("sustainability-"+stamp)
	var document:=data.duplicate(true)
	document["ending"]=result.get("ending","")
	document["elapsed_seconds"]=result.get("elapsed_seconds",0.0)
	document["score"]=result.get("score",0)
	var files: Dictionary={"json":JSON.stringify(document,"\t"),"html":html(result),"csv":csv(data)}
	var paths: Dictionary={"ok":true}
	for extension: String in files:
		var path:=base+"."+extension
		var file:=FileAccess.open(path,FileAccess.WRITE)
		if file==null:
			return {"ok":false,"error":"审计文件写入失败：%s"%error_string(FileAccess.get_open_error())}
		file.store_string(files[extension])
		file.flush()
		if file.get_error()!=OK:
			return {"ok":false,"error":"审计文件写入未完成。"}
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
	var title: String="A · 把绿色还给世界" if choice_a else "B · 边界以内的春天"
	var reflection: String="力量曾让你独自越过深渊。回家的桥，却是和别人一起修好的。账本没有忘记过去，世界仍可从下一次选择开始改变。" if choice_a else "你保住了窗内的春天。窗外的人仍替你呼吸。世界没有变得更轻，只是有人把重量移出了视线。"
	var stage_rows: String=""
	var svg: String='<svg viewBox="0 0 720 170" role="img" aria-label="各关技能碳排放柱状图">'
	var maximum: float=1.0
	for stage: Dictionary in data.stages.values():
		maximum=maxf(maximum,float(stage.gross_kg))
	var index:=0
	for stage: Dictionary in data.stages.values():
		var y:=20+index*48
		var width:=430.0*float(stage.gross_kg)/maximum
		svg+='<text x="0" y="%d" fill="#d9e7db">%s</text><rect x="110" y="%d" width="%.1f" height="16" fill="#d6a159"/><text x="560" y="%d" fill="#d9e7db">%.2f kg</text>'%[y+13,String(stage.name).xml_escape(),y,width,y+13,stage.gross_kg]
		stage_rows+="<tr><td>%s</td><td>%.2f kg</td><td>%.2f kg</td><td>%d</td></tr>"%[String(stage.name).xml_escape(),stage.gross_kg,stage.stored_kg,stage.casts]
		index+=1
	svg+="</svg>"
	var skill_rows: String=""
	for skill: Dictionary in data.skills.values():
		skill_rows+="<tr><td>%s</td><td>%d</td><td>%.2f kg</td></tr>"%[String(skill.name).xml_escape(),skill.casts,skill.gross_kg]
	return """<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>EdenGuilt · Sustainability Audit Report</title><style>
body{margin:0;background:#101b1c;color:#e6eee0;font:16px/1.7 system-ui,sans-serif}main{max-width:1040px;margin:auto;padding:38px}h1{font-size:34px}h2{font-size:23px;color:#badcba}small,.muted{color:#a7b8ae}.cards{display:grid;grid-template-columns:repeat(3,1fr);gap:16px}.card{border:1px solid #40564c;padding:18px;background:#172728}.number{font-size:30px;color:#e7ba71}table{width:100%%;border-collapse:collapse}td,th{text-align:left;padding:9px;border-bottom:1px solid #33483e}a{color:#a9d7c3}svg{width:100%%}blockquote{border-left:3px solid #b8cb87;padding:15px;background:#1a2929}@media(max-width:680px){.cards{grid-template-columns:1fr}main{padding:20px}}
</style><main><small>EDENGUILT / SUSTAINABILITY AUDIT REPORT · 玩家个人可持续行为审计</small><h1>%s</h1><blockquote>%s</blockquote>
<div class="cards"><div class="card">累计排放 CO₂<div class="number">%.2f kg</div><small>永久历史，不因修复清零</small></div><div class="card">已固定 CO₂<div class="number">%.2f kg</div><small>单列矿化与社区固碳模型</small></div><div class="card">有效能利用率<div class="number">%.1f%%</div><small>总有效功 / 总输入；废热 %.1f%%</small></div></div>
<h2>三幕排放去向</h2>%s<table><tr><th>场景</th><th>排放</th><th>固碳</th><th>技能次数</th></tr>%s</table>
<h2>技能明细</h2><table><tr><th>技能</th><th>次数</th><th>排放</th></tr>%s</table>
<h2>共同修复与循环经济</h2><p>救出居民 %d 人 · 修复 %d / 3 地区 · 循环拆解 %d 个节点 · 回收材料 %.1f kg。<br>按游戏教学假设 1 kg 回收材料替代 %.1f kg 原生矿石，对应 %.1f kg 矿石替代量。这不是现实中的电子垃圾回收或采矿实测。</p>
<h2>现实量级类比</h2><p>本局模拟排放 %.2f kg CO₂，按 EPA 的汽油燃烧因子类比约 %.2f 升汽油。只用于帮助理解量级；不代表玩家在现实中排放、减少或抵销了这些碳。</p>
<h2>方法与来源</h2><p>%s</p><p>Exergy 是可用能利用率的游戏化指标；能量为无量纲模型，不是完整热力学或生命周期核算。未使用技能时利用率记为 0，不填造数据。详细事件仅保留前 %d 条，省略 %d 条；汇总包含所有事件。</p>
<p><a href="%s">EPA · 汽油燃烧 8.887 kg CO₂ / 美制加仑</a><br><a href="%s">DOE · 碳矿化路径</a></p><small>配套 JSON 保存汇总、采用参数和事件；CSV 保存逐次技能记录。报告不声称具有现实碳核查效力。</small></main></html>"""%[
		title,reflection,data.gross_kg,data.stored_kg,data.efficiency*100.0,
		(1.0-data.efficiency)*100.0 if data.input_energy>0 else 0.0,svg,stage_rows,skill_rows,
		data.people,data.restored_regions,data.recycled_nodes,data.recycled_material_kg,data.factors.teaching_ore_ratio,
		data.teaching_ore_avoided_kg,data.gross_kg,data.gasoline_litres_analogy,
		String(data.methodology).xml_escape(),CarbonLedger.MAX_DETAIL_EVENTS,data.omitted_detail_events,CarbonLedger.EPA_SOURCE,CarbonLedger.DOE_SOURCE]
