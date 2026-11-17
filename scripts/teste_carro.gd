extends SceneTree
# Teste automático da compra e da troca de carro (roda sem tela e restaura o save no fim).

func _initialize() -> void:
	_run()


func _run() -> void:
	var sp := "user://casa_v2.json"
	var had := FileAccess.file_exists(sp)
	var bak := FileAccess.get_file_as_string(sp) if had else ""
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for i in range(5):
		await process_frame
	var home = main.home
	var ok := true
	main.money = 9000
	home.money_now = 9000
	home.owned["carros"] = [home.DEFAULT_CAR]
	home.cfg["carro"] = home.DEFAULT_CAR
	var car0: Node3D = main.car_root
	for idx in [1, 2]:
		var c: Dictionary = home.CARS[idx]
		var m0: int = main.money
		home._buy_car(c)
		var bought: bool = (home.owned["carros"] as Array).has(str(c["path"]))
		var paid: bool = main.money == m0 - int(c["preco"])
		home._use_car(str(c["path"]))
		await process_frame
		await process_frame
		var swapped: bool = is_instance_valid(main.car_root) and main.car_root != car0 and main.car_root.get_child_count() > 0
		var sel: bool = home.get_car_path() == str(c["path"])
		print("CARRO ", c["nome"], " comprado=", bought, " pago=", paid, " trocado=", swapped, " selecionado=", sel, " saldo=", main.money)
		ok = ok and bought and paid and swapped and sel
		car0 = main.car_root
	var m1: int = main.money
	home._buy_car({"path": "res://x.glb", "nome": "Caro", "preco": 999999})
	var refused: bool = main.money == m1 and not (home.owned["carros"] as Array).has("res://x.glb")
	print("SEM DINHEIRO recusado=", refused)
	ok = ok and refused
	var saved = JSON.parse_string(FileAccess.get_file_as_string(sp))
	var persisted: bool = saved is Dictionary and str((saved["cfg"] as Dictionary).get("carro", "")) == str(home.CARS[2]["path"])
	print("SALVO carro=", persisted)
	ok = ok and persisted
	main._enter_home()
	await process_frame
	var hidden: bool = main.in_home and not main.car_root.visible
	main._exit_home()
	await process_frame
	var back: bool = not main.in_home and main.car_root.visible
	print("CASA entra=", hidden, " sai=", back)
	ok = ok and hidden and back
	if had:
		var f := FileAccess.open(sp, FileAccess.WRITE)
		f.store_string(bak)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(sp))
	print("RESULTADO ", "APROVADO" if ok else "FALHOU")
	quit()
