extends Node3D

# Caso Aberto - versão Godot 4
# Carrega data/city.json (mapa de Campo Grande) e monta: ruas, prédios e árvores
# com os modelos GLB dos pacotes, parques, carro do jogador, carros de NPC,
# 300 pedestres, marcos dos pontos de interesse e a caixa de diálogo.
# Controles: W/A/S/D ou setas para dirigir; E para interagir; Esc para fechar o menu.

const CITY_PATH := "res://data/city.json"
const BUILDING_DIR := "res://assets/pack/Buildings"
const TREE_DIR := "res://assets/pack/Terrain"
const VEHICLE_DIR := "res://assets/pack/Vehicles"
const PLAYER_CAR := "res://assets/pack/Vehicles/Car_Coral.glb"

const NPC_COUNT := 300
const TRAFFIC_COUNT := 44
const TREE_MAX := 4400
const BLOCK_MAX := 7500
const CHAR_SCALE := 0.072
const PEDESTRIANS := preload("res://assets/cidade/pedestres.png")
const PED_RANGE := 320.0
const PED_FLEE_DIST := 6.0
const CAR_HIT_DIST := 2.4
const LOT_BUDGET_WEST := 11600
const LOT_BUDGET_EAST := 3600
const CITY_MODELS := "res://assets/cidade/"
const ROAD_ROUTE := preload("res://scripts/road_route.gd")
const ROAD_CLEARANCE := preload("res://scripts/road_clearance.gd")
const STREET_VIEW := 36.0
const PIXEL_WORLD := preload("res://scripts/pixel_world.gdshader")
const CAR_OCCLUSION := preload("res://scripts/car_occlusion.gdshader")
const TINTS := [Color(0.95, 0.9, 0.8), Color(0.82, 0.88, 0.92), Color(0.92, 0.75, 0.65), Color(0.78, 0.85, 0.74), Color(0.96, 0.94, 0.86), Color(0.85, 0.78, 0.7)]
const SHOP_NAMES := ["Mercado Central", "Padaria do Zé", "Farmácia Santa Clara", "Loja de Ferragens", "Lanchonete Sabor do Sul", "Oficina do Tião", "Papelaria Estrela", "Açougue Boi Bravo"]
const SHOP_NPCS := ["Dona Cida", "Seu Tião", "Marta", "Zé Pereira", "Lúcia", "Ricardo", "Nelsinho", "Ivone"]
const SHOP_LINES := ["Aqui a gente ouve tudo. Se quiser saber da noite de sexta, pergunte.", "Um carro preto ficou parado na esquina por horas. Não era de morador.", "Vi o senhor da farmácia sair correndo com uma sacola. Estranho, né?", "Ninguém compra mais aqui desde aquela noite. Mas ainda tenho coisas para vender."]
const CAR_LENGTH := 4.4
const TREE_HEIGHT := 9.0
const MAX_SPEED := 13.0
const ACCEL := 8.0
const BRAKE := 16.0
const TURN_RATE := 2.3
const CAR_RADIUS := 1.8
const TYPE_SPEED := 48.0
const ROAD_W := {"motorway": 14.0, "trunk": 12.0, "primary": 10.0, "secondary": 9.0, "tertiary": 7.0, "residential": 6.0, "service": 4.0, "footway": 2.0}
const OPTIONS := ["Falar", "Perguntar sobre o caso", "Comprar", "Vender", "Ver preços", "Bater na porta", "Sair"]
const FIRST_NAMES := ["Dona Cida", "Seu Tião", "Marta", "Zé", "Lúcia", "Paulo", "Dora", "Edson", "Vera", "Gilberto", "Rosa", "Nilton", "Iara", "Sônia"]
const LAST_NAMES := ["Silva", "Souza", "Oliveira", "Costa", "Pereira", "Alves", "Nunes", "Rocha", "Freitas", "Moraes"]
const ROLES := ["padeiro", "farmacêutico", "vendedora de flores", "mecânico", "dono da lanchonete", "jornaleiro", "costureira", "açougueiro"]
const STORIES := [
	"Eu abro a loja às 6 da manhã. Ontem a rua estava mais silenciosa que o normal, e ninguém passou pela calçada depois da meia-noite.",
	"Meu filho trabalha na estação. Ele disse que o relógio da plataforma andava estranho nas últimas semanas.",
	"Eu vendo remédio e sei quem compra o quê. Tem gente comprando mais calmante do que de costume.",
	"Eu moro em cima da loja. Vi uma moto parando na esquina e uma pessoa de capuz entrando no prédio da frente.",
	"Não tenho pressa de falar. Mas se você me pagar um café, eu conto o que vi na sexta à noite.",
	"O que eu vi não é da sua conta, detetive. Pergunte aos outros e volte aqui quando tiver algo concreto.",
	"Eu cuido dessa praça há vinte anos. Os bancos ficam vazios depois das 2h, e isso não é normal.",
	"Nesse bairro a gente desconfia de todo mundo. Confie no que você vê, não no que ouvem por aí.",
]

var city: Dictionary
var roads: Array = []
var pois: Array = []
var building_polys: Array = []
var tall_buildings: Array = []
var npcs: Array = []
var npc_mm: MultiMesh
var traffic: Array = []

var veh_paths: Array = []
var scene_cache: Dictionary = {}
var road_bk: Dictionary = {}
var prim_bk: Dictionary = {}
var rd_bk: Dictionary = {}
var tree_bk: Dictionary = {}
var bld_bk: Dictionary = {}
var bpoly_bk: Dictionary = {}
var tree_tpl: Dictionary = {}
var tree_batch: Dictionary = {}
var street_label: Label
var sign_layer: Control
var sign_labels: Array[Label] = []
var city_signs: Dictionary = {}
var street_last_pos := Vector2(INF, INF)
var street_names: Dictionary = {}
var aabb_cache: Dictionary = {}

var car_root: Node3D
var car_pos := Vector2.ZERO
var on_foot := false
var survival = preload("res://scripts/survival.gd").new()
var parked_vehicles: Array[Dictionary] = []
var parked_cells: Dictionary = {}
var btn_attack: Button
var walk_pos := Vector2.ZERO
var walker: Sprite3D
var walker_outline: Sprite3D
var walk_cycle := 0.0
var walk_face := 1
var btn_car: Button
var static_people: Array[Sprite3D] = []
var street_hour := 12.0
var car_heading := 0.0
var car_speed := 0.0
var cam: Camera3D

var money := 500
var mm_t := 0.0
var tour_i := 0
var area_rects: Array = []
var park_cache: Array = []
var water_cache: Array = []
var road_bb: Array = []
var sig_bk: Dictionary = {}
var lamp_mats: Array = []
var sig_state := -1
var sig_time := 0.0
var fps_on := false
var fps_t := 0.0
var fps_label: Label
var prof: Array = [0, 0, 0, 0, 0, 0, 0]
var prof_t := 0
var prof_n := 0
var sun_ref: DirectionalLight3D
var env_ref: Environment
var day_f := 1.0
var dn_t := 99.0
var dn_home := false
var time_shift := 0.0
var clock_label: Label
var lamp_head_mat: StandardMaterial3D
var pool_mat: StandardMaterial3D
var night_root: Node3D
var head_glow: MeshInstance3D
var portrait_cache: Dictionary = {}
var q_t := -8.0
var slow_n := 0
var home: Node3D
var in_home := false
var street_pos := Vector2.ZERO
var street_heading := 0.0

# caso 1 (individual): O relógio da estação
const SAVE_PATH := "user://casos_v2.json"
# Marcos reais de Campo Grande (posição convertida do OpenStreetMap para o mapa do jogo)
const LANDMARKS := [
	{"id": "relogio14", "name": "Relógio da 14 de Julho", "address": "Avenida Afonso Pena esquina com Rua 14 de Julho", "model": "relogio", "x": -3644.4, "y": 1421.0, "snapDist": 24.0, "npc": "Relojoeiro Anselmo", "line": "Este é o Relógio da 14, no cruzamento da Afonso Pena com a 14 de Julho. Ele nunca atrasa. Se o da estação parou às 3h17, alguém parou de propósito."},
	{"id": "obelisco", "name": "Obelisco", "model": "obelisco", "x": -2760.6, "y": 1265.0, "snapDist": 24.0, "npc": "Guia Dalva", "line": "O Obelisco homenageia os fundadores da cidade. Daqui se vê a Afonso Pena inteira. Na madrugada um carro ficou parado aqui, de farol apagado."},
	{"id": "ary_coelho", "name": "Praça Ary Coelho", "model": "coreto", "x": -3568.6, "y": 1496.8, "snapDist": 30.0, "npc": "Vendedor de chipa", "line": "A Ary Coelho é o coração do centro. Todo mundo corta caminho por aqui, até quem não quer ser visto."},
	{"id": "feira_central", "name": "Feira Central", "address": "Rua 14 de Julho, 3351", "model": "feira", "clear": 24.0, "res": 27.0, "x": -3967.4, "y": 150.0, "snapDist": 40.0, "npc": "Dona Mieko, do sobá", "line": "Na Feira Central todo mundo fala depois do segundo sobá. Ontem um freguês pagou com uma nota manchada de tinta fresca."},
	{"id": "igreja_batista", "style": "batista", "clear": 26.0, "res": 27.0, "back": 24.0, "name": "Primeira Igreja Batista", "model": "igreja", "x": -3575.6, "y": 1178.0, "snapDist": 32.0, "npc": "Zelador da igreja", "line": "O sino não tocou, mas eu ouvi passos no pátio às três da manhã. Quem era não quis ser visto."},
	{"id": "igreja_presb", "style": "presbiteriana", "clear": 26.0, "res": 27.0, "back": 24.0, "name": "Igreja Presbiteriana", "model": "igreja", "x": -3307.5, "y": 1014.5, "snapDist": 32.0, "npc": "Organista", "line": "Ensaio aqui toda noite. Ontem alguém ficou no último banco até eu apagar as luzes e saiu sem dizer nada."},
	{"id": "igreja_adv", "style": "adventista", "clear": 26.0, "res": 27.0, "back": 24.0, "name": "Igreja Adventista", "model": "igreja", "x": -3074.0, "y": 849.0, "snapDist": 32.0, "npc": "Diácono", "line": "A rua aqui é calma. Por isso estranhei o mesmo carro passar três vezes devagar, sem parar em lugar nenhum."},
	{"id": "catedral", "name": "Catedral N. Sra. da Abadia e Santo Antônio", "model": "igreja", "style": "catedral", "clear": 34.0, "res": 36.0, "back": 28.0, "x": -3790.0, "y": 1672.0, "snapDist": 40.0, "npc": "Sacristão da Catedral", "line": "Santo Antônio é o padroeiro de Campo Grande e protetor das coisas perdidas. Se você procura algo que sumiu, veio ao lugar certo. Ontem deixaram um embrulho aos pés da estátua."},
	{"id": "sao_jose", "name": "Paróquia São José", "model": "igreja", "style": "saojose", "clear": 26.0, "res": 27.0, "back": 24.0, "x": -3102.0, "y": 1041.0, "snapDist": 34.0, "npc": "Dona Zilda, da secretaria", "line": "Aqui na São José todo mundo se conhece. Um rapaz de fora veio perguntar o horário em que a praça fica vazia. Achei estranho."},
	{"id": "parque_nacoes", "name": "Parque das Nações Indígenas", "model": "portal", "res": 18.0, "back": 20.0, "x": 332.0, "y": 691.2, "mx": 329.0, "my": 664.0, "snapDist": 28.0, "npc": "Guarda-parque Jurandir", "line": "O Parque das Nações Indígenas é um dos maiores parques urbanos do país. As capivaras do lago veem tudo. De madrugada vi uma lanterna perto da margem."},
	{"id": "bioparque", "name": "Bioparque Pantanal", "model": "bioparque", "clear": 80.0, "res": 72.0, "yaw": 0.185, "x": 615.8, "y": 556.8, "mx": 631.0, "my": 484.0, "snapDist": 32.0, "npc": "Bióloga Renata", "line": "O Bioparque é o maior aquário de água doce do mundo. Cada tanque tem registro de entrada e saída. Alguém assinou o livro com um nome que não existe."},
]

const HOME_SCRIPT := preload("res://scripts/home.gd")
const CASES := [
	{"name": "O relógio da estação", "steps": [
		{"kind": "talk", "poi": "Central de Investigação", "npc": "Sargento Lima", "role": "sargento", "greeting": "Delegacia. Sargento Lima.", "story": "", "obj": "Fale com o Sargento Lima na Central.", "say": "Uma chave de bronze sumiu do acervo. O vigia Mauro diz que foi às 3h17, a hora em que o relógio parou. Temos três formas de conferir: o registro de saída no museu, a entrega da caixa na Feira Central e o relojoeiro da 14, que recebeu uma visita estranha. Compare os relatos antes de acusar alguém.", "clue": "Ocorrência: sumiu uma chave de bronze do acervo. O vigia apontou 3h17 como a hora do furto."},
		{"kind": "talk", "poi": "Museu dos Trabalhadores Ferroviários", "npc": "Zelador do museu", "role": "zelador", "greeting": "Sou o zelador do museu.", "story": "", "obj": "Confira o relógio no Museu dos Trabalhadores Ferroviários.", "say": "O mecanismo tem um grampo, então o relógio podia ser parado de propósito. Neste livro está a assinatura de Mauro: às 2h40 ele retirou a chave para uma suposta limpeza. Elisa, a restauradora, já havia saído antes da meia-noite. O registro prova a retirada. Falta descobrir para onde a chave foi.", "clue": "Museu: relógio travado de propósito. Mauro retirou a chave às 2h40. Elisa saiu antes da meia-noite."},
		{"kind": "talk", "poi": "Feira Central", "npc": "Dona Mieko", "role": "feirante", "greeting": "Quer um sobá?", "story": "", "obj": "Ouça Dona Mieko na Feira Central.", "say": "Eu estava preparando o caldo quando Mauro deixou a caixa no balcão. Foi às 2h55, logo depois de eu conferir o relógio. Davi veio recolher a encomenda, abriu a caixa na minha frente e achou a chave. Ele chamou a polícia e ficou esperando. A caixa já tinha chegado fechada das mãos de Mauro.", "clue": "Feira: Mauro entregou a caixa às 2h55. Davi a abriu diante de Dona Mieko e pediu que ela chamasse a polícia."},
		{"kind": "talk", "poi": "Relógio da 14 de Julho", "npc": "Relojoeiro Anselmo", "role": "relojoeiro", "greeting": "Qual relógio deu problema?", "story": "", "obj": "Compare os horários no Relógio da 14 de Julho.", "say": "Ontem Mauro me mostrou uma foto do relógio do acervo. Quis saber como prender o ponteiro no 17 sem riscar as engrenagens. Hoje, antes de vir para cá, conferi a hora no meu rádio com Dona Mieko. Se a caixa já estava na feira às 2h55, as 3h17 do acervo eram uma hora montada.", "clue": "Relógio da 14: Mauro pesquisou como imobilizar o ponteiro. A referência de horário da testemunha bate com a saída registrada."},
		{"kind": "accuse", "poi": "Central de Investigação", "obj": "Volte à Central e cruze as pistas no caderno [C].", "suspects": ["Elisa, a restauradora", "Davi, o motorista", "Mauro, o vigia"], "culprit": "Mauro, o vigia", "proofs": ["O motorista abriu a caixa na feira.", "A restauradora trabalhava no museu.", "Mauro retirou a chave e entregou a caixa antes das 3h17."], "proof": 2}
	]},
	{"name": "O bilhete da papelaria", "steps": [
		{"kind": "talk", "poi": "Central de Investigação", "npc": "Sargento Lima", "role": "sargento da Central de Investigação", "greeting": "Sou o Sargento Lima, da Central de Investigação.", "story": "Um novo caso chegou: um bilhete ameaçador apareceu na Papelaria Estrela.", "obj": "Fale com o Sargento Lima na Central de Investigação.", "say": "Sargento Lima: Um bilhete ameaçador apareceu na Papelaria Estrela. Vá ao Mercado Central, depois à Lanchonete Sabor do Sul, e volte aqui com o que descobrir.", "clue": ""},
		{"kind": "talk", "poi": "Mercado Central", "npc": "Marta", "role": "atendente do mercado", "greeting": "Oi, sou a Marta, atendo no caixa do mercado.", "story": "Vejo todo mundo que passa pelo caixa.", "obj": "Vá ao Mercado Central e fale com a Marta.", "say": "Marta: Na sexta à noite vi a Lúcia Rocha discutindo com alguém perto do caixa, por volta das 22h.", "clue": "Marta (mercado): Lúcia Rocha discutiu com alguém perto das 22h de sexta."},
		{"kind": "talk", "poi": "Lanchonete Sabor do Sul", "npc": "Zé Pereira", "role": "dono da lanchonete", "greeting": "Sou o Zé Pereira, da lanchonete.", "story": "Gosto de conversar com quem senta no balcão.", "obj": "Vá à Lanchonete Sabor do Sul e fale com o Zé Pereira.", "say": "Zé Pereira: A Lúcia pediu um táxi às 23h com uma mala grande. Não parecia viagem de lazer.", "clue": "Zé Pereira (lanchonete): Lúcia Rocha saiu de táxi às 23h com uma mala grande."},
		{"kind": "talk", "poi": "Papelaria Estrela", "npc": "Paulo", "role": "dono da papelaria", "greeting": "Sou o Paulo, da papelaria.", "story": "Vendo carimbos, envelopes e papel de carta.", "obj": "Vá à Papelaria Estrela e veja quem comprou o carimbo do bilhete.", "say": "Paulo: O bilhete foi feito com um carimbo de borracha. Quem comprou esse modelo na semana passada foi a Lúcia Rocha.", "clue": "Papelaria Estrela: a Lúcia Rocha comprou o carimbo usado no bilhete."},
		{"kind": "accuse", "poi": "Central de Investigação", "obj": "Volte à Central de Investigação e faça sua acusação.", "suspects": ["Lúcia Rocha", "Gilberto Moraes", "Edson Nunes"], "culprit": "Lúcia Rocha"}
	]},
	{"name": "A oficina silenciosa", "steps": [
		{"kind": "talk", "poi": "Central de Investigação", "npc": "Sargento Lima", "role": "sargento da Central de Investigação", "greeting": "Sou o Sargento Lima, da Central de Investigação.", "story": "Novo caso na mesa: A oficina silenciosa.", "obj": "Fale com o Sargento Lima na Central de Investigação.", "say": "Sargento Lima: Um carro sumiu da oficina do Tião na madrugada. Comece por lá. Depois passe pelos lugares que eu marquei no mapa e volte aqui.", "clue": ""},
		{"kind": "talk", "poi": "Oficina do Tião", "npc": "Tião", "role": "dono da oficina", "greeting": "Sou o Tião, dono da oficina.", "story": "Conheço bem o movimento daqui.", "obj": "Vá até Oficina do Tião e fale com Tião.", "say": "Tião: Levaram um Gol cinza às 1h. Deixaram a chave na ignição, o que não é do meu jeito de trabalhar.", "clue": "Tião (oficina): o Gol cinza saiu às 1h, com a chave deixada na ignição."},
		{"kind": "talk", "poi": "Loja de Ferragens", "npc": "Vanda", "role": "atendente da loja de ferragens", "greeting": "Sou o Vanda, atendente da loja de ferragens.", "story": "Conheço bem o movimento daqui.", "obj": "Vá até Loja de Ferragens e fale com Vanda.", "say": "Vanda: Na quinta, um homem de boné comprou corda e fita isolante. Pagou em dinheiro.", "clue": "Vanda (ferragens): um homem de boné comprou corda e fita isolante na quinta."},
		{"kind": "talk", "poi": "Barbearia Navalha", "npc": "Gilberto", "role": "barbeiro", "greeting": "Sou o Gilberto, barbeiro.", "story": "Conheço bem o movimento daqui.", "obj": "Vá até Barbearia Navalha e fale com Gilberto.", "say": "Gilberto: Vi o Paulo Freitas saindo da oficina com o boné na mão, de madrugada.", "clue": "Gilberto (barbearia): Paulo Freitas foi visto saindo da oficina de madrugada."},
		{"kind": "accuse", "poi": "Central de Investigação", "obj": "Volte à Central de Investigação e faça sua acusação.", "suspects": ["Paulo Freitas", "Edson Nunes", "Vera Rocha"], "culprit": "Paulo Freitas"}
	]},
	{"name": "Flores para ninguém", "steps": [
		{"kind": "talk", "poi": "Central de Investigação", "npc": "Sargento Lima", "role": "sargento da Central de Investigação", "greeting": "Sou o Sargento Lima, da Central de Investigação.", "story": "Novo caso na mesa: Flores para ninguém.", "obj": "Fale com o Sargento Lima na Central de Investigação.", "say": "Sargento Lima: Uma floricultura recebeu um pedido anônimo de buquê fúnebre com o nome de um cliente vivo. Depois passe pelos lugares que eu marquei no mapa e volte aqui.", "clue": ""},
		{"kind": "talk", "poi": "Floricultura Flor do Pantanal", "npc": "Dora", "role": "florista", "greeting": "Sou o Dora, florista.", "story": "Conheço bem o movimento daqui.", "obj": "Vá até Floricultura Flor do Pantanal e fale com Dora.", "say": "Dora: O pedido veio por telefone e foi pago com cartão de outra pessoa. A voz era de homem.", "clue": "Dora (floricultura): pedido anônimo, pago com cartão de outra pessoa."},
		{"kind": "talk", "poi": "Sorveteria Gelo Doce", "npc": "Edson", "role": "atendente da sorveteria", "greeting": "Sou o Edson, atendente da sorveteria.", "story": "Conheço bem o movimento daqui.", "obj": "Vá até Sorveteria Gelo Doce e fale com Edson.", "say": "Edson: Um homem ficou olhando a floricultura pela janela, das 16h às 18h.", "clue": "Edson (sorveteria): um homem vigiou a floricultura das 16h às 18h."},
		{"kind": "talk", "poi": "Livraria Tereré", "npc": "Iara", "role": "livreira", "greeting": "Sou o Iara, livreira.", "story": "Conheço bem o movimento daqui.", "obj": "Vá até Livraria Tereré e fale com Iara.", "say": "Iara: Ele comprou um livro de caligrafia antiga. Assinou o cartão como Renan Costa.", "clue": "Iara (livraria): um homem chamado Renan Costa comprou um livro de caligrafia."},
		{"kind": "accuse", "poi": "Central de Investigação", "obj": "Volte à Central de Investigação e faça sua acusação.", "suspects": ["Renan Costa", "Marta Pires", "Gilberto Moraes"], "culprit": "Renan Costa"}
	]},
	{"name": "O cão desaparecido", "steps": [
		{"kind": "talk", "poi": "Central de Investigação", "npc": "Sargento Lima", "role": "sargento da Central de Investigação", "greeting": "Sou o Sargento Lima, da Central de Investigação.", "story": "Novo caso na mesa: O cão desaparecido.", "obj": "Fale com o Sargento Lima na Central de Investigação.", "say": "Sargento Lima: Um cão de raça sumiu do Pet Shop Patinhas. O dono está desesperado. Depois passe pelos lugares que eu marquei no mapa e volte aqui.", "clue": ""},
		{"kind": "talk", "poi": "Pet Shop Patinhas", "npc": "Lucas", "role": "tratador", "greeting": "Sou o Lucas, tratador.", "story": "Conheço bem o movimento daqui.", "obj": "Vá até Pet Shop Patinhas e fale com Lucas.", "say": "Lucas: O cão Bidu sumiu no domingo. A porta dos fundos estava aberta, e eu tranco tudo.", "clue": "Lucas (pet shop): Bidu sumiu no domingo; a porta dos fundos estava aberta."},
		{"kind": "talk", "poi": "Açougue Boi Bravo", "npc": "Seu Nilton", "role": "açougueiro", "greeting": "Sou o Seu Nilton, açougueiro.", "story": "Conheço bem o movimento daqui.", "obj": "Vá até Açougue Boi Bravo e fale com Seu Nilton.", "say": "Seu Nilton: Um rapaz comprou carne crua no domingo à noite, muita carne, para um cão grande.", "clue": "Seu Nilton (açougue): um rapaz comprou carne crua no domingo à noite."},
		{"kind": "talk", "poi": "Lanchonete Sabor do Sul", "npc": "Sônia", "role": "cozinheira", "greeting": "Sou o Sônia, cozinheira.", "story": "Conheço bem o movimento daqui.", "obj": "Vá até Lanchonete Sabor do Sul e fale com Sônia.", "say": "Sônia: O rapaz do açougue é o Rafael Dias. Ele mora com a tia e tem um cachorro enorme.", "clue": "Sônia (lanchonete): Rafael Dias mora com a tia e tem um cachorro grande."},
		{"kind": "accuse", "poi": "Central de Investigação", "obj": "Volte à Central de Investigação e faça sua acusação.", "suspects": ["Rafael Dias", "Nelsinho Alves", "Dora Silva"], "culprit": "Rafael Dias"}
	]},
	{"name": "O caixa da relojoaria", "steps": [
		{"kind": "talk", "poi": "Central de Investigação", "npc": "Sargento Lima", "role": "sargento da Central de Investigação", "greeting": "Sou o Sargento Lima, da Central de Investigação.", "story": "Novo caso na mesa: O caixa da relojoaria.", "obj": "Fale com o Sargento Lima na Central de Investigação.", "say": "Sargento Lima: A relojoaria Ponteiro perdeu R$ 3 mil do caixa. Não houve arrombamento. Depois passe pelos lugares que eu marquei no mapa e volte aqui.", "clue": ""},
		{"kind": "talk", "poi": "Relojoaria Ponteiro", "npc": "Helena", "role": "relojoeira", "greeting": "Sou o Helena, relojoeira.", "story": "Conheço bem o movimento daqui.", "obj": "Vá até Relojoaria Ponteiro e fale com Helena.", "say": "Helena: Só eu e meu sobrinho tínhamos a chave. Ele estava de folga naquela noite.", "clue": "Helena (relojoaria): só ela e o sobrinho tinham a chave; ele estava de folga."},
		{"kind": "talk", "poi": "Mercado Central", "npc": "Ivone", "role": "caixa do mercado", "greeting": "Sou o Ivone, caixa do mercado.", "story": "Conheço bem o movimento daqui.", "obj": "Vá até Mercado Central e fale com Ivone.", "say": "Ivone: O sobrinho da Helena comprou um celular novo, de uns R$ 3 mil, na sexta de manhã.", "clue": "Ivone (mercado): o sobrinho de Helena comprou celular de R$ 3 mil na sexta."},
		{"kind": "talk", "poi": "Barbearia Navalha", "npc": "Gilberto", "role": "barbeiro", "greeting": "Sou o Gilberto, barbeiro.", "story": "Conheço bem o movimento daqui.", "obj": "Vá até Barbearia Navalha e fale com Gilberto.", "say": "Gilberto: O rapaz, Caio Mendes, disse que ganhou na loteria. Ninguém ganha na loteria aqui.", "clue": "Gilberto (barbearia): Caio Mendes disse ter ganhado na loteria, sem registro."},
		{"kind": "accuse", "poi": "Central de Investigação", "obj": "Volte à Central de Investigação e faça sua acusação.", "suspects": ["Caio Mendes", "Helena Ponte", "Ivone Souza"], "culprit": "Caio Mendes"}
	]},
	{"name": "Sinal no muro", "steps": [
		{"kind": "talk", "poi": "Central de Investigação", "npc": "Sargento Lima", "role": "sargento da Central de Investigação", "greeting": "Sou o Sargento Lima, da Central de Investigação.", "story": "Novo caso na mesa: Sinal no muro.", "obj": "Fale com o Sargento Lima na Central de Investigação.", "say": "Sargento Lima: Apareceu um sinal pichado no muro da escola, com um recado ameaçador. Depois passe pelos lugares que eu marquei no mapa e volte aqui.", "clue": ""},
		{"kind": "talk", "poi": "Livraria Tereré", "npc": "Iara", "role": "livreira", "greeting": "Sou o Iara, livreira.", "story": "Conheço bem o movimento daqui.", "obj": "Vá até Livraria Tereré e fale com Iara.", "say": "Iara: Alguém pichou um sinal de alerta no muro da escola, e o desenho é igual ao de um livro de história que vendi.", "clue": "Iara (livraria): o desenho do muro é igual a um livro que foi vendido recentemente."},
		{"kind": "talk", "poi": "Loja de Ferragens", "npc": "Vanda", "role": "atendente da loja de ferragens", "greeting": "Sou o Vanda, atendente da loja de ferragens.", "story": "Conheço bem o movimento daqui.", "obj": "Vá até Loja de Ferragens e fale com Vanda.", "say": "Vanda: Quem comprou tinta spray preta nesta semana foi a Natália Lopes. Ela tem jeito de artista.", "clue": "Vanda (ferragens): Natália Lopes comprou tinta spray preta esta semana."},
		{"kind": "talk", "poi": "Sorveteria Gelo Doce", "npc": "Edson", "role": "atendente da sorveteria", "greeting": "Sou o Edson, atendente da sorveteria.", "story": "Conheço bem o movimento daqui.", "obj": "Vá até Sorveteria Gelo Doce e fale com Edson.", "say": "Edson: A Natália passou aqui com um rapaz, o Bruno Teles, e os dois ficaram rindo do muro.", "clue": "Edson (sorveteria): Natália e Bruno Teles passaram rindo do muro."},
		{"kind": "accuse", "poi": "Central de Investigação", "obj": "Volte à Central de Investigação e faça sua acusação.", "suspects": ["Natália Lopes", "Bruno Teles", "Lúcio Prado"], "culprit": "Natália Lopes"}
	]},
	{"name": "Passos na madrugada", "steps": [
		{"kind": "talk", "poi": "Central de Investigação", "npc": "Sargento Lima", "role": "sargento da Central de Investigação", "greeting": "Sou o Sargento Lima, da Central de Investigação.", "story": "Novo caso na mesa: Passos na madrugada.", "obj": "Fale com o Sargento Lima na Central de Investigação.", "say": "Sargento Lima: Alguém andou pela rua de madrugada e um comerciante foi assustado. Depois passe pelos lugares que eu marquei no mapa e volte aqui.", "clue": ""},
		{"kind": "talk", "poi": "Padaria do Zé", "npc": "Dona Cida", "role": "dona da padaria", "greeting": "Sou o Dona Cida, dona da padaria.", "story": "Conheço bem o movimento daqui.", "obj": "Vá até Padaria do Zé e fale com Dona Cida.", "say": "Dona Cida: Ouvi passos na rua às 4h, e um cachorro latindo. Era um homem de jaqueta vermelha.", "clue": "Dona Cida (padaria): passos às 4h e um homem de jaqueta vermelha."},
		{"kind": "talk", "poi": "Açougue Boi Bravo", "npc": "Seu Nilton", "role": "açougueiro", "greeting": "Sou o Seu Nilton, açougueiro.", "story": "Conheço bem o movimento daqui.", "obj": "Vá até Açougue Boi Bravo e fale com Seu Nilton.", "say": "Seu Nilton: O homem de jaqueta vermelha pediu uma faca de osso e saiu sem pagar. Eu não cobro de quem tem medo.", "clue": "Seu Nilton (açougue): o homem de jaqueta vermelha levou uma faca sem pagar."},
		{"kind": "talk", "poi": "Oficina do Tião", "npc": "Tião", "role": "dono da oficina", "greeting": "Sou o Tião, dono da oficina.", "story": "Conheço bem o movimento daqui.", "obj": "Vá até Oficina do Tião e fale com Tião.", "say": "Tião: A jaqueta vermelha é do Matheus Brito, que trabalha aqui de vez em quando.", "clue": "Tião (oficina): a jaqueta vermelha pertence a Matheus Brito."},
		{"kind": "accuse", "poi": "Central de Investigação", "obj": "Volte à Central de Investigação e faça sua acusação.", "suspects": ["Matheus Brito", "Lívia Duarte", "Osvaldo Reis"], "culprit": "Matheus Brito"}
	]}
]
var case_idx := 0
var case_pois: Dictionary = {}
var case_locations: Dictionary = {}
var case_step := 0
var case_done := false
var clues: Array = []
var pad_id := ""
var farm_id := ""
var minimap: Control
var case_label: Label
var poi_index := -1
var menu_open := false
var full_line := ""
var typed := 0.0

var money_label: Label
var prompt_label: Label
var ui_panel: PanelContainer
var ui_name: Label
var ui_text: Label
var ui_menu: Container
var ui_portrait: TextureRect
var grass_mat: StandardMaterial3D
var road_mat: StandardMaterial3D
var park_mat: StandardMaterial3D
var flat_cache: Dictionary = {}
var goal_arrow: Node3D = null
var ph := false
var intro_pending := false
var intro_state := 0
var intro_layer: CanvasLayer = null
var intro_lbls: Dictionary = {}
var ui_dirty := true
var nav_arrow: Control
var nav_dir := Vector2.ZERO
var nav_has := false
var road_route := ROAD_ROUTE.new()
var road_clearance := ROAD_CLEARANCE.new()
var landmark_parts: Array = []
var placed_street_objects: Array[PackedVector2Array] = []
var player_marker: Control
var route_points := PackedVector2Array()
var route_origin := Vector2(INF, INF)
var route_target := ""
var lead_ids: Array = []
var cached_target := ""
var cached_target_frame := -1
var btn_talk: Button
var btn_book: Button
var home_icon_ready := false
var mm_scale := 1.3
var BTN_SZ := Vector2(200, 34)
var cam_focus := Vector3.ZERO
var joy: Control
var joy_vec := Vector2.ZERO
var joy_active := false
const WALL_COLORS := [Color(0.93, 0.88, 0.78), Color(0.75, 0.55, 0.42), Color(0.62, 0.7, 0.78), Color(0.85, 0.82, 0.7), Color(0.7, 0.78, 0.66), Color(0.9, 0.6, 0.5), Color(0.55, 0.56, 0.6), Color(0.96, 0.93, 0.84), Color(0.8, 0.7, 0.9), Color(0.95, 0.8, 0.45)]
const ROOF_COLORS := [Color(0.6, 0.25, 0.18), Color(0.35, 0.35, 0.38), Color(0.5, 0.3, 0.2), Color(0.25, 0.3, 0.4)]
const SHOP_TYPES := [
	{"n": "Mercado Central", "sign": Color(0.1, 0.45, 0.2), "awn": Color(0.85, 0.2, 0.2)},
	{"n": "Padaria do Zé", "sign": Color(0.55, 0.3, 0.1), "awn": Color(0.95, 0.85, 0.5)},
	{"n": "Farmácia Santa Clara", "sign": Color(0.1, 0.5, 0.6), "awn": Color(0.95, 0.95, 0.95)},
	{"n": "Loja de Ferragens", "sign": Color(0.2, 0.2, 0.2), "awn": Color(0.9, 0.6, 0.1)},
	{"n": "Lanchonete Sabor do Sul", "sign": Color(0.8, 0.3, 0.1), "awn": Color(0.95, 0.75, 0.2)},
	{"n": "Oficina do Tião", "sign": Color(0.15, 0.2, 0.35), "awn": Color(0.3, 0.3, 0.35)},
	{"n": "Papelaria Estrela", "sign": Color(0.4, 0.2, 0.6), "awn": Color(0.95, 0.5, 0.7)},
	{"n": "Açougue Boi Bravo", "sign": Color(0.5, 0.1, 0.1), "awn": Color(0.7, 0.15, 0.15)},
	{"n": "Relojoaria Ponteiro", "sign": Color(0.6, 0.5, 0.2), "awn": Color(0.2, 0.25, 0.3)},
	{"n": "Floricultura Flor do Pantanal", "sign": Color(0.2, 0.55, 0.35), "awn": Color(0.85, 0.45, 0.75)},
	{"n": "Barbearia Navalha", "sign": Color(0.05, 0.05, 0.1), "awn": Color(0.8, 0.1, 0.1)},
	{"n": "Sorveteria Gelo Doce", "sign": Color(0.2, 0.6, 0.8), "awn": Color(1.0, 0.8, 0.85)},
	{"n": "Livraria Tereré", "sign": Color(0.3, 0.3, 0.5), "awn": Color(0.6, 0.45, 0.25)},
	{"n": "Pet Shop Patinhas", "sign": Color(0.9, 0.5, 0.1), "awn": Color(0.3, 0.6, 0.9)},
]


func _ready() -> void:
	var f := FileAccess.open(CITY_PATH, FileAccess.READ)
	city = JSON.parse_string(f.get_as_text())
	roads = city["roads"]
	pois = city["pois"]
	_init_areas()
	for point in pois:
		if str(point["id"]) == "central":
			point["name"] = "Abrigo · Posto Barão"
	for lm in LANDMARKS:
		var lp: Dictionary = (lm as Dictionary).duplicate()
		lp["marco"] = true
		pois.append(lp)
	veh_paths = _list_glb(VEHICLE_DIR, [], ["Truck", "Fire"])
	_build_road_buckets()
	_build_world()
	_build_pixel_pass()
	_build_trees()
	_scatter_props()
	_build_car()
	road_route.build(roads)
	ph = _detect_phone()
	BTN_SZ = Vector2(170, 52) if ph else BTN_SZ
	get_window().size_changed.connect(func(): ui_dirty = true)
	_build_ui()
	_build_touch_ui()
	fps_on = OS.get_cmdline_user_args().has("--fpslog")
	_setup_survival_places()
	_fill_abandoned_car_gaps()
	_distribute_abandoned_cars()
	walker = _person_sprite(4)
	walker_outline = walker.duplicate()
	walker_outline.no_depth_test = true
	walker_outline.shaded = false
	walker_outline.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	walker_outline.modulate = Color(1.0, 0.91, 0.76, 0.75)
	walker_outline.render_priority = 8
	walker_outline.hide()
	walker.add_child(walker_outline)
	walker.hide()
	_build_fixed_people()
	add_child(survival)
	survival.setup(self)
	cam_focus = walker.position
	_update_camera(1.0)
	_start_music()


func _pm(i: int) -> void:
	var n := Time.get_ticks_usec()
	prof[i] += n - prof_t
	prof_t = n


func _process(delta: float) -> void:
	_fps_tick(delta)
	_daynight_tick(delta)
	if ui_dirty:
		_layout_ui()
	_touch_vis()
	if not menu_open:
		if on_foot:
			_walk(delta)
		else:
			_drive(delta)
	_signals_update(delta)
	survival.tick(delta)
	_update_camera(delta)
	_update_goal_arrow()
	if street_last_pos.distance_squared_to(_actor_pos()) > 6.25:
		street_last_pos = _actor_pos()
		var street := _street_at(street_last_pos)
		if street.is_empty() and survival.available():
			street = str(survival.closest_site.get("address", "")).get_slice(",", 0)
		street_label.text = street if not street.is_empty() else "Fora da via"
	street_label.show()
	_update_signs()
	var actor_height := Vector3.UP * (1.3 if on_foot else 0.85)
	var covered := on_foot and _foot_occluded(walker.position + actor_height)
	walker_outline.visible = covered
	if covered:
		walker_outline.texture = walker.texture
		walker_outline.region_rect = walker.region_rect
		walker_outline.offset = walker.offset
	player_marker.visible = not on_foot or covered
	player_marker.position = cam.unproject_position((walker.position if on_foot else car_root.position) + actor_height)
	player_marker.queue_redraw()
	mm_t += delta
	if mm_t >= 0.12:
		mm_t = 0.0
		minimap.queue_redraw()
		nav_arrow.queue_redraw()
	case_label.text = survival.objective_text()
	if not menu_open and survival.available() and (not ph or survival.closest_site.has("context")):
		prompt_label.text = ("" if ph else "[E] ") + str(survival.closest_site["name"])
		prompt_label.position.y = case_label.position.y + case_label.size.y + 6
		prompt_label.show()
	else:
		prompt_label.hide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if survival.walk_location_click(event.position):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch and event.pressed:
		if survival.walk_location_click(event.position):
			get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_E: _on_touch_interact()
		KEY_F: _toggle_car()
		KEY_I, KEY_C: _on_touch_notebook()
		KEY_SPACE: survival.attack()
		KEY_ESCAPE: survival.close()


# ---------- carregamento de modelos ----------

func _list_glb(dir: String, prefixes: Array, excludes: Array) -> Array:
	var out: Array = []
	var da := DirAccess.open(dir)
	if da == null:
		return out
	da.list_dir_begin()
	var f := da.get_next()
	while f != "":
		if f.ends_with(".glb.import"):
			f = f.trim_suffix(".import")
		if f.ends_with(".glb"):
			var ok := prefixes.is_empty()
			for p in prefixes:
				if f.begins_with(p):
					ok = true
			for e in excludes:
				if f.contains(e):
					ok = false
			if ok and not out.has(dir + "/" + f):
				out.append(dir + "/" + f)
		f = da.get_next()
	da.list_dir_end()
	out.sort()
	return out


func _scene(path: String) -> PackedScene:
	if not scene_cache.has(path):
		scene_cache[path] = load(path)
	return scene_cache[path]


func _proto_aabb(path: String) -> AABB:
	if not aabb_cache.has(path):
		var probe := _scene(path).instantiate() as Node3D
		add_child(probe)
		aabb_cache[path] = _aabb_of(probe)
		probe.queue_free()
	return aabb_cache[path]


func _aabb_of(root: Node3D) -> AABB:
	var out := AABB()
	var first := true
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and n.mesh != null:
			var box: AABB = n.global_transform * n.mesh.get_aabb()
			if first:
				out = box
				first = false
			else:
				out = out.merge(box)
		for c in n.get_children():
			stack.append(c)
	return out


# ---------- mundo ----------

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.75, 0.85)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.85, 0.85, 0.85)
	e.ambient_light_energy = 0.42
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	env_ref = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 125.0
	sun.light_energy = 0.6
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_blur = 0.7
	add_child(sun)
	sun_ref = sun

	var w: Dictionary = city["window"]
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	var gb := _area_bounds().grow(1400.0)
	pm.size = gb.size
	ground.mesh = pm
	grass_mat = _smooth_mat(_surface_tex("grama"))
	grass_mat.uv1_scale = Vector3(pm.size.x / 8.0, pm.size.y / 8.0, 1.0)
	ground.material_override = grass_mat
	ground.position = Vector3(gb.get_center().x, 0.0, gb.get_center().y)
	add_child(ground)

	# ruas
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in roads:
		if str(r["k"]) == "footway":
			continue
		_ribbon(st, r["p"], float(ROAD_W.get(r["k"], 5.0)))
	road_mat = _smooth_mat(_surface_tex("asfalto"))
	_add_mesh(st, road_mat, 0.04)
	# calçadas: faixa de concreto mais larga por baixo da rua
	var cst := SurfaceTool.new()
	cst.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in roads:
		var ck: String = r["k"]
		if ck == "service" or ck == "footway":
			continue
		_ribbon(cst, r["p"], float(ROAD_W.get(ck, 5.0)) + 3.4)
	_add_mesh(cst, _smooth_mat(_surface_tex("calcada")), 0.03)
	# trilhas do parque, lagos e córregos
	var fst := SurfaceTool.new()
	fst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n_foot := 0
	for r in roads:
		if str(r["k"]) == "footway":
			_ribbon(fst, r["p"], 2.6)
			n_foot += 1
	if n_foot > 0:
		_add_mesh(fst, _smooth_mat(_surface_tex("calcada")), 0.036)
	var wst := SurfaceTool.new()
	wst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n_water := 0
	for wp in water_cache:
		_flat_poly(wst, wp["pts"], 0.0)
		n_water += 1
	for s in city.get("streams", []):
		_ribbon(wst, s["p"], 5.0)
		n_water += 1
	if n_water > 0:
		var wm := _mat(Color(0.16, 0.4, 0.58))
		wm.roughness = 0.15
		wm.metallic = 0.35
		_add_mesh(wst, wm, 0.033)
	_build_markings()

	# parques
	var pst := SurfaceTool.new()
	pst.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in city["parks"]:
		var pts := _poly(p["p"])
		if pts.size() >= 3:
			_flat_poly(pst, pts, 0.0)
	park_mat = _smooth_mat(_surface_tex("parque"))
	_add_mesh(pst, park_mat, 0.025)

	# prédios: modelo GLB do pacote; se não houver modelo, bloco procedural
	var bst := SurfaceTool.new()
	bst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var blds: Array = city["buildings"]
	for i in blds.size():
		var b: Dictionary = blds[i]
		var pts := _poly(b["p"])
		if pts.size() < 3:
			continue
		var bb := _bbox(pts)
		if _landmark_spot(bb.get_center()):
			continue
		var h := maxf(float(b["h"]), 3.0)
		for plot in road_clearance.clip(pts):
			if _bbox(plot).get_area() < 7.0 or Geometry2D.triangulate_polygon(plot).is_empty() or not road_clearance.is_clear(plot):
				continue
			_add_bpoly(plot, h, "residence" if h < 9.0 and not b.has("site") else "", str(b.get("site", "")))
			_bk_add(bld_bk, _bbox(plot).get_center())
			_city_building(bst, plot, h, i, str(b.get("site", "")))
		if i % 125 == 124:
			_add_mesh(bst, _mat(Color.WHITE, true), 0.0)
			bst.clear()
			bst.begin(Mesh.PRIMITIVE_TRIANGLES)

	_add_mesh(bst, _mat(Color.WHITE, true), 0.0)
	bst.clear()
	_build_landmarks()
	_place_investigation_hq()
	_fill_lots()

	_make_shops()


func _road_dir_at(q: Vector2) -> Vector2:
	# direção da rua mais próxima (até 60 m), ou zero se não houver
	var best := 60.0
	var bd := Vector2.ZERO
	var kx := floori(q.x / 50.0)
	var ky := floori(q.y / 50.0)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var key := Vector2i(kx + dx, ky + dy)
			if rd_bk.has(key):
				for e in rd_bk[key]:
					var dist: float = (e[0] as Vector2).distance_to(q)
					if dist < best:
						best = dist
						bd = e[1]
	return bd


func _place_tree(pos: Vector2, height: float, rng: RandomNumberGenerator) -> void:
	if not road_clearance.is_clear(_rectangle(pos, Vector2.DOWN, 0.95, 0.95)):
		return
	var variant := str(rng.randi_range(0, 2))
	var scale_factor := height * rng.randf_range(0.87, 1.08)
	var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * scale_factor)
	var transform := Transform3D(basis, Vector3(pos.x, 0.0, pos.y))
	_bk_add(tree_bk, pos)
	var key := variant + "|" + str(floori(pos.x / 140.0)) + "|" + str(floori(pos.y / 140.0))
	if not tree_batch.has(key):
		tree_batch[key] = [[]]
	tree_batch[key][0].append(transform)


func _tree_template(variant: String) -> Array:
	if tree_tpl.has(variant):
		return tree_tpl[variant]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var palettes := [Color("#4b7660"), Color("#637f56"), Color("#8c824f")]
	var crown: Color = palettes[int(variant)]
	_box_c(st, Vector3(0, 0.24, 0), Vector3(0.085, 0.48, 0.085), Color("#685141"), 0.22)
	_tree_crown(st, Vector3(0.0, 0.66, 0.0), Vector3(0.34, 0.34, 0.29), crown)
	_tree_crown(st, Vector3(0.17, 0.59, 0.04), Vector3(0.21, 0.20, 0.22), crown.darkened(0.13))
	_tree_crown(st, Vector3(-0.12, 0.73, -0.06), Vector3(0.21, 0.22, 0.23), crown.lightened(0.07))
	var list := [{"mesh": st.commit(), "mat": _mat(Color.WHITE, true)}]
	tree_tpl[variant] = list
	return list


func _tree_crown(st: SurfaceTool, center: Vector3, radii: Vector3, color: Color) -> void:
	const SIDES := 9
	var heights := [-0.82, -0.42, 0.23, 0.75, 0.98]
	var widths := [0.20, 0.78, 1.0, 0.64, 0.0]
	for band in range(heights.size() - 1):
		for edge in SIDES:
			var a := TAU * float(edge) / SIDES
			var b := TAU * float(edge + 1) / SIDES
			var p := center + Vector3(cos(a) * widths[band], heights[band], sin(a) * widths[band]) * radii
			var q := center + Vector3(cos(b) * widths[band], heights[band], sin(b) * widths[band]) * radii
			var r := center + Vector3(cos(a) * widths[band + 1], heights[band + 1], sin(a) * widths[band + 1]) * radii
			var t := center + Vector3(cos(b) * widths[band + 1], heights[band + 1], sin(b) * widths[band + 1]) * radii
			var normal := (r - p).cross(q - p).normalized()
			var tint := color.lerp(Color("#bdd394"), float(band) * 0.07)
			for point in [p, q, r, q, t, r]:
				_bv(st, point.x, point.y, point.z, normal, tint)


func _flush_trees() -> void:
	var total := 0
	for bkey in tree_batch.keys():
		var path := str(bkey).get_slice("|", 0)
		var tpl := _tree_template(path)
		var batch: Array = tree_batch[bkey]
		for i in tpl.size():
			var xs: Array = batch[i]
			if xs.is_empty():
				continue
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = tpl[i]["mesh"]
			mm.instance_count = xs.size()
			for k in xs.size():
				mm.set_instance_transform(k, xs[k])
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			if tpl[i]["mat"] != null:
				mmi.material_override = tpl[i]["mat"]
			add_child(mmi)
			total += xs.size()
	tree_batch.clear()
	print("arvores em lote: ", total)


func _build_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var placed := 0
	# árvores nos parques
	for p in city["parks"]:
		var pts := _poly(p["p"])
		if pts.size() < 3:
			continue
		var bb := _bbox(pts)
		var stp := maxf(16.0, sqrt(bb.get_area() / 500.0))
		var y := bb.position.y
		while y < bb.end.y and placed < TREE_MAX:
			var x := bb.position.x
			while x < bb.end.x and placed < TREE_MAX:
				var q := Vector2(x, y)
				if Geometry2D.is_point_in_polygon(q, pts) and not _in_water(q) and not _inside_any_building(q) and rng.randf() < 0.6:
					_place_tree(q, TREE_HEIGHT * rng.randf_range(0.8, 1.2), rng)
					placed += 1
				x += stp
			y += stp
	print("arvores nos parques: ", placed)
	# árvores nas calçadas das ruas
	for r in roads:
		var rp: Array = r["p"]
		var wd: float = float(ROAD_W.get(r["k"], 5.0))
		for k in range(rp.size() - 1):
			if placed >= TREE_MAX:
				break
			var a := Vector2(float(rp[k][0]), float(rp[k][1]))
			var b := Vector2(float(rp[k + 1][0]), float(rp[k + 1][1]))
			var d := b - a
			var L := d.length()
			if L < 1.0:
				continue
			var dir := d / L
			var nrm := Vector2(-dir.y, dir.x)
			var t := rng.randf_range(0.0, 20.0)
			while t < L and placed < TREE_MAX:
				var side := 1.0 if rng.randf() < 0.5 else -1.0
				var q := a + dir * t + nrm * side * (wd * 0.5 + rng.randf_range(2.0, 4.0))
				if not _inside_any_building(q):
					_place_tree(q, TREE_HEIGHT * rng.randf_range(0.8, 1.1), rng)
					placed += 1
				t += rng.randf_range(28.0, 45.0)
	print("arvores totais: ", placed)
	_fill_free_trees(rng)
	_flush_trees()


func _fill_free_trees(rng: RandomNumberGenerator) -> void:
	var w: Dictionary = city["window"]
	var R: float = float(w["R"])
	var cx: float = float(w["cx"])
	var cy: float = float(w["cy"])
	var ab := _area_bounds()
	var n := 0
	var x := ab.position.x
	while x < ab.end.x and n < 2800:
		var y := ab.position.y
		while y < ab.end.y and n < 2800:
			var q := Vector2(x + rng.randf_range(-12.0, 12.0), y + rng.randf_range(-12.0, 12.0))
			if _in_area(q) and rng.randf() < 0.45 and not _bk_near(road_bk, q, 14.0) and not _bk_near(bld_bk, q, 12.0) and not _in_park(q):
				_place_tree(q, TREE_HEIGHT * rng.randf_range(0.8, 1.2), rng)
				n += 1
			y += 30.0
		x += 30.0
	print("arvores livres: ", n)


func _in_park(q: Vector2) -> bool:
	for p in park_cache:
		if (p["bb"] as Rect2).has_point(q) and Geometry2D.is_point_in_polygon(q, p["pts"]):
			return true
	return _in_water(q)


func _in_water(q: Vector2) -> bool:
	for p in water_cache:
		if (p["bb"] as Rect2).has_point(q) and Geometry2D.is_point_in_polygon(q, p["pts"]):
			return true
	return false


func _init_areas() -> void:
	area_rects.clear()
	if city.has("areas"):
		for a in city["areas"]:
			area_rects.append(Rect2(float(a[0]), float(a[1]), float(a[2]) - float(a[0]), float(a[3]) - float(a[1])))
	else:
		var w: Dictionary = city["window"]
		var rr: float = float(w["R"])
		area_rects.append(Rect2(float(w["cx"]) - rr, float(w["cy"]) - rr, rr * 2.0, rr * 2.0))
	for p in city["parks"]:
		var pts := _poly(p["p"])
		if pts.size() >= 3:
			park_cache.append({"pts": pts, "bb": _bbox(pts)})
	for p in city.get("water", []):
		var pts := _poly(p["p"])
		if pts.size() >= 3:
			water_cache.append({"pts": pts, "bb": _bbox(pts)})
	for r in roads:
		var rp := _poly(r["p"])
		road_bb.append(_bbox(rp).grow(2.0) if rp.size() > 0 else Rect2())


func _area_bounds() -> Rect2:
	var ab: Rect2 = area_rects[0]
	for a in area_rects:
		ab = ab.merge(a)
	return ab


func _in_area(q: Vector2) -> bool:
	for a in area_rects:
		if (a as Rect2).has_point(q):
			return true
	return false


# afasta o prédio da rua até ele ficar fora da calçada
func _off_sidewalk(c: Vector2, u: Vector2, L: float, D: float) -> Vector2:
	var v := Vector2(-u.y, u.x)
	for pass_i in range(2):
		var need := 0.0
		var bn := Vector2.ZERO
		var kx := floori(c.x / 50.0)
		var ky := floori(c.y / 50.0)
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var key := Vector2i(kx + dx, ky + dy)
				if not rd_bk.has(key):
					continue
				for e in rd_bk[key]:
					var rel: Vector2 = c - (e[0] as Vector2)
					var bd: Vector2 = e[1]
					if absf(rel.dot(bd)) > 6.0:
						continue
					var perp := rel - bd * rel.dot(bd)
					var dist := perp.length()
					if dist < 0.01:
						continue
					var nh := perp / dist
					var ext := absf(nh.dot(u)) * L * 0.5 + absf(nh.dot(v)) * D * 0.5
					var deficit: float = float(e[2]) + ext - dist
					if deficit > need:
						need = deficit
						bn = nh
		if need <= 0.05:
			break
		c += bn * minf(need, 6.0)
	return c


func _daynight_tick(delta: float) -> void:
	dn_t += delta
	if head_glow != null and is_instance_valid(car_root):
		head_glow.visible = day_f < 0.45 and car_root.visible
		if head_glow.visible:
			head_glow.position = car_root.position + Vector3(0.0, 0.1, 0.0)
			head_glow.rotation.y = car_root.rotation.y + PI
	if dn_t < 5.0 and dn_home == in_home:
		return
	dn_t = 0.0
	dn_home = in_home
	# Campo Grande/MS: UTC-4 o ano todo
	var h := fposmod((Time.get_unix_time_from_system() - 4.0 * 3600.0) / 3600.0 + time_shift, 24.0)
	street_hour = h
	var d := 1.0
	if h < 4.75 or h >= 19.0:
		d = 0.0
	elif h < 6.0:
		d = (h - 4.75) / 1.25
	elif h >= 17.75:
		d = 1.0 - (h - 17.75) / 1.25
	day_f = d
	var dl := 1.0 if in_home else d
	if sun_ref != null:
		var night_c := Color(0.5, 0.62, 1.0)
		var dusk_c := Color(1.0, 0.6, 0.36)
		var day_c := Color(1.0, 0.96, 0.88)
		sun_ref.light_color = night_c.lerp(dusk_c, dl * 2.0) if dl < 0.5 else dusk_c.lerp(day_c, (dl - 0.5) * 2.0)
		sun_ref.light_energy = lerpf(0.18, 0.52, dl)
		sun_ref.rotation_degrees = Vector3(lerpf(-68.0, -58.0, dl), 35.0, 0.0)
	if env_ref != null:
		env_ref.background_color = Color(0.02, 0.03, 0.08).lerp(Color(0.55, 0.75, 0.85), dl)
		env_ref.ambient_light_color = Color(0.57, 0.64, 0.84).lerp(Color(0.93, 0.88, 0.84), dl)
		env_ref.ambient_light_energy = lerpf(0.49, 0.54, dl)
	if lamp_head_mat != null:
		lamp_head_mat.emission_enabled = d < 0.6
	if night_root != null:
		night_root.visible = d < 0.6 and not in_home
		pool_mat.albedo_color = Color(1.0, 0.74, 0.38, lerpf(0.55, 0.0, clampf(d / 0.6, 0.0, 1.0)))
	if clock_label == null and money_label != null:
		clock_label = Label.new()
		clock_label.position = Vector2(150, 8)
		clock_label.add_theme_font_size_override("font_size", 20)
		money_label.get_parent().add_child(clock_label)
	if clock_label != null:
		clock_label.text = "%02d:%02d  %s" % [int(h), int(fmod(h, 1.0) * 60.0), ("noite" if d <= 0.0 else ("dia" if d >= 1.0 else ("amanhecer" if h < 12.0 else "entardecer")))]


func _fps_tick(delta: float) -> void:
	# ajuste automático: se o aparelho não dá conta, desliga as sombras para manter a fluidez
	q_t += delta
	if q_t >= 3.0:
		q_t = 0.0
		if Engine.get_frames_per_second() < 27.0 and sun_ref != null and sun_ref.shadow_enabled:
			slow_n += 1
			if slow_n >= 2:
				sun_ref.shadow_enabled = false
				print("qualidade: sombras desligadas para manter a fluidez")
		else:
			slow_n = 0
	if not fps_on:
		return
	if fps_label == null:
		fps_label = Label.new()
		fps_label.position = Vector2(20, 300)
		fps_label.add_theme_font_size_override("font_size", 20)
		money_label.get_parent().add_child(fps_label)
	fps_t += delta
	if fps_t >= 2.0:
		fps_t = 0.0
		var f := int(Engine.get_frames_per_second())
		fps_label.text = "%d quadros/s" % f
		var pn := maxf(1.0, float(prof_n))
		print("perf ms/quadro: dirigir ", snappedf(prof[0] / pn / 1000.0, 0.01), " transito ", snappedf(prof[1] / pn / 1000.0, 0.01), " pedestres ", snappedf(prof[2] / pn / 1000.0, 0.01), " poi ", snappedf(prof[3] / pn / 1000.0, 0.01), " camera ", snappedf(prof[4] / pn / 1000.0, 0.01), " | motor process ", snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.01), " fisica ", snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.01), " primitivas ", int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)), " nos ", int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		prof = [0, 0, 0, 0, 0, 0, 0]
		prof_n = 0
		print("fps: ", f, " draw: ", int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), " objetos: ", int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))


# ---------- semáforos: ciclo de cores e parada do trânsito ----------

func _signals_update(delta: float) -> void:
	if lamp_mats.size() < 6:
		return
	sig_time += delta
	var t := fmod(sig_time, 20.0)
	var st := 0 if t < 8.0 else (1 if t < 10.0 else (2 if t < 18.0 else 3))
	if st == sig_state:
		return
	sig_state = st
	var cols := [Color(0.95, 0.12, 0.1), Color(1.0, 0.8, 0.1), Color(0.15, 0.9, 0.3)]
	var on := [st >= 2, st == 1, st == 0, st <= 1, st == 3, st == 2]
	for i in range(6):
		var lm: StandardMaterial3D = lamp_mats[i]
		var c: Color = cols[i % 3]
		var lit: bool = on[i]
		lm.albedo_color = c if lit else c.darkened(0.8)
		lm.emission_enabled = lit
		lm.emission = c
		lm.emission_energy_multiplier = 1.6


func _red_ahead(pos: Vector2, fwd: Vector2) -> bool:
	if fwd == Vector2.ZERO or sig_state < 0:
		return false
	var kx := floori(pos.x / 50.0)
	var ky := floori(pos.y / 50.0)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var key := Vector2i(kx + dx, ky + dy)
			if not sig_bk.has(key):
				continue
			for e in sig_bk[key]:
				var d: Vector2 = (e[0] as Vector2) - pos
				var along := d.dot(fwd)
				if along < 11.0 or along > 14.5:
					continue
				if absf(d.dot(Vector2(-fwd.y, fwd.x))) > 6.0:
					continue
				var grp := 0 if absf(fwd.dot(e[1] as Vector2)) > 0.7 else 1
				var green := (sig_state == 0) if grp == 0 else (sig_state == 2)
				if not green:
					return true
	return false

func _build_road_buckets() -> void:
	for r in roads:
		var rp: Array = r["p"]
		for k in range(rp.size() - 1):
			var a := Vector2(float(rp[k][0]), float(rp[k][1]))
			var b := Vector2(float(rp[k + 1][0]), float(rp[k + 1][1]))
			var road_width := 2.6 if str(r["k"]) == "footway" else float(ROAD_W.get(r["k"], 5.0))
			road_clearance.add_segment(a, b, road_width)
			var n := int((b - a).length() / 10.0) + 1
			for m in range(n + 1):
				var sp := a.lerp(b, float(m) / float(n))
				_bk_add(road_bk, sp)
				if str(r["k"]).begins_with("primary") or str(r["k"]).begins_with("secondary"):
					_bk_add(prim_bk, sp)
				var key := Vector2i(floori(sp.x / 50.0), floori(sp.y / 50.0))
				if not rd_bk.has(key):
					rd_bk[key] = []
				rd_bk[key].append([sp, (b - a).normalized(), float(ROAD_W.get(str(r["k"]), 5.0)) * 0.5 + (0.4 if str(r["k"]) in ["service", "footway"] else 2.0), str(r["k"]), str(r.get("n", "")), a, b])


# canteiro central: ponto com pista de avenida dos dois lados (não pode receber prédio)
func _in_median(q: Vector2) -> bool:
	var near: Array = []
	var kx := floori(q.x / 50.0)
	var ky := floori(q.y / 50.0)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var key := Vector2i(kx + dx, ky + dy)
			if prim_bk.has(key):
				for p in prim_bk[key]:
					if (p as Vector2).distance_to(q) < 30.0:
						near.append((p as Vector2) - q)
	if near.is_empty():
		return false
	var a: Vector2 = near[0]
	for v in near:
		if (v as Vector2).length() < a.length():
			a = v
	if a.length() < 0.5:
		return true
	var an := a.normalized()
	for v in near:
		var b: Vector2 = v
		var opp := -b.dot(an)
		if opp > 5.0 and (b + an * opp).length() < 12.0:
			return true
	return false


func _bk_add(d: Dictionary, q: Vector2) -> void:
	var key := Vector2i(floori(q.x / 50.0), floori(q.y / 50.0))
	if not d.has(key):
		d[key] = []
	d[key].append(q)


func _bk_near(d: Dictionary, q: Vector2, r: float) -> bool:
	var kx := floori(q.x / 50.0)
	var ky := floori(q.y / 50.0)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var key := Vector2i(kx + dx, ky + dy)
			if d.has(key):
				for p in d[key]:
					if (p as Vector2).distance_to(q) < r:
						return true
	return false


func _add_bpoly(pts: PackedVector2Array, h: float, use := "", site := "") -> void:
	var bb := _bbox(pts)
	var entry := {"pts": pts, "bb": bb, "h": h, "use": use, "site": site}
	building_polys.append(entry)
	if h > 22.0:
		tall_buildings.append(entry)
	var k0 := Vector2i(floori(bb.position.x / 50.0), floori(bb.position.y / 50.0))
	var k1 := Vector2i(floori(bb.end.x / 50.0), floori(bb.end.y / 50.0))
	for kx in range(k0.x, k1.x + 1):
		for ky in range(k0.y, k1.y + 1):
			var key := Vector2i(kx, ky)
			if not bpoly_bk.has(key):
				bpoly_bk[key] = []
			bpoly_bk[key].append(entry)


func _bpolys_at(p: Vector2) -> Array:
	return bpoly_bk.get(Vector2i(floori(p.x / 50.0), floori(p.y / 50.0)), [])


func _inside_any_building(p: Vector2) -> bool:
	for b in _bpolys_at(p):
		if Geometry2D.is_point_in_polygon(p, b["pts"]):
			return true
	return false


func _ribbon(st: SurfaceTool, pts: Array, wd: float) -> void:
	for i in range(pts.size() - 1):
		var a := Vector2(float(pts[i][0]), float(pts[i][1]))
		var b := Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
		var d := b - a
		if d.length() < 0.01:
			continue
		var p := Vector2(-d.y, d.x).normalized() * wd * 0.5
		_v(st, a + p, 0.0); _v(st, a - p, 0.0); _v(st, b + p, 0.0)
		_v(st, a - p, 0.0); _v(st, b - p, 0.0); _v(st, b + p, 0.0)


func _walls(st: SurfaceTool, pts: PackedVector2Array, h: float, c: Color, bottom := -0.14) -> void:
	var n := pts.size()
	for k in range(n):
		var a := pts[k]
		var b := pts[(k + 1) % n]
		var d := b - a
		if d.length() < 0.01:
			continue
		var nrm := Vector3(d.y, 0.0, -d.x).normalized()
		_bv(st, a.x, bottom, a.y, nrm, c)
		_bv(st, b.x, bottom, b.y, nrm, c)
		_bv(st, b.x, h, b.y, nrm, c)
		_bv(st, a.x, bottom, a.y, nrm, c)
		_bv(st, b.x, h, b.y, nrm, c)
		_bv(st, a.x, h, a.y, nrm, c)


func _roof(st: SurfaceTool, pts: PackedVector2Array, h: float, c: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(pts)
	for t in range(0, idx.size(), 3):
		var p0 := pts[idx[t]]
		var p1 := pts[idx[t + 1]]
		var p2 := pts[idx[t + 2]]
		_bv(st, p0.x, h, p0.y, Vector3.UP, c)
		_bv(st, p1.x, h, p1.y, Vector3.UP, c)
		_bv(st, p2.x, h, p2.y, Vector3.UP, c)


func _flat_poly(st: SurfaceTool, pts: PackedVector2Array, y: float) -> void:
	var idx := Geometry2D.triangulate_polygon(pts)
	for t in range(0, idx.size(), 3):
		var p0 := pts[idx[t]]
		var p1 := pts[idx[t + 1]]
		var p2 := pts[idx[t + 2]]
		_v(st, p0, y); _v(st, p1, y); _v(st, p2, y)


func _poly(arr: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in arr:
		out.append(Vector2(float(q[0]), float(q[1])))
	if out.size() > 1 and out[0].is_equal_approx(out[out.size() - 1]):
		out.remove_at(out.size() - 1)
	return out


func _bbox(pts: PackedVector2Array) -> Rect2:
	var mn := pts[0]
	var mx := pts[0]
	for p in pts:
		mn = mn.min(p)
		mx = mx.max(p)
	return Rect2(mn, mx - mn)


func _v(st: SurfaceTool, p2: Vector2, y: float) -> void:
	st.set_normal(Vector3.UP)
	st.set_uv(p2 / 8.0)
	st.add_vertex(Vector3(p2.x, y, p2.y))


func _bv(st: SurfaceTool, x: float, y: float, z: float, nrm: Vector3, c: Color) -> void:
	st.set_color(c)
	st.set_normal(nrm)
	st.add_vertex(Vector3(x, y, z))


func _add_mesh(st: SurfaceTool, mat: Material, y: float, parent: Node = null) -> void:
	var host: Node = parent if parent != null else self
	var arr := st.commit_to_arrays()
	if arr[Mesh.ARRAY_VERTEX] == null:
		return
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	if vs.size() < 3:
		return
	if arr[Mesh.ARRAY_INDEX] != null or vs.size() < 3000:
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var mi := MeshInstance3D.new()
		mi.mesh = am
		mi.material_override = mat
		mi.position.y = y
		host.add_child(mi)
		return
	var has_n: bool = arr[Mesh.ARRAY_NORMAL] != null
	var has_c: bool = arr[Mesh.ARRAY_COLOR] != null
	var has_u: bool = arr[Mesh.ARRAY_TEX_UV] != null
	var ns := PackedVector3Array()
	var cs := PackedColorArray()
	var us := PackedVector2Array()
	if has_n:
		ns = arr[Mesh.ARRAY_NORMAL]
	if has_c:
		cs = arr[Mesh.ARRAY_COLOR]
	if has_u:
		us = arr[Mesh.ARRAY_TEX_UV]
	var cells := {}
	var t := 0
	while t + 2 < vs.size():
		var key := Vector2i(floori(vs[t].x / 140.0), floori(vs[t].z / 140.0))
		if not cells.has(key):
			cells[key] = []
		(cells[key] as Array).append(t)
		t += 3
	for key in cells.keys():
		var tl: Array = cells[key]
		var nv := PackedVector3Array()
		var nn := PackedVector3Array()
		var nc := PackedColorArray()
		var nu := PackedVector2Array()
		for t0 in tl:
			var ti: int = t0
			for k in range(3):
				nv.append(vs[ti + k])
				if has_n:
					nn.append(ns[ti + k])
				if has_c:
					nc.append(cs[ti + k])
				if has_u:
					nu.append(us[ti + k])
		var a2: Array = []
		a2.resize(Mesh.ARRAY_MAX)
		a2[Mesh.ARRAY_VERTEX] = nv
		if has_n:
			a2[Mesh.ARRAY_NORMAL] = nn
		if has_c:
			a2[Mesh.ARRAY_COLOR] = nc
		if has_u:
			a2[Mesh.ARRAY_TEX_UV] = nu
		var am2 := ArrayMesh.new()
		am2.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a2)
		var mi2 := MeshInstance3D.new()
		mi2.mesh = am2
		mi2.material_override = mat
		mi2.position.y = y
		host.add_child(mi2)


func _mat(c: Color, vertex_color := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.vertex_color_use_as_albedo = vertex_color
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


# ---------- carro do jogador ----------

func _build_car() -> void:
	car_root = Node3D.new()
	add_child(car_root)
	_swap_car(PLAYER_CAR)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = STREET_VIEW
	cam.far = 240.0
	add_child(cam)
	cam.current = true


func _build_pixel_pass() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	var pass_rect := ColorRect.new()
	pass_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := ShaderMaterial.new()
	shader.shader = PIXEL_WORLD
	pass_rect.material = shader
	layer.add_child(pass_rect)
	pass_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _detective_car_mesh(paint: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trim := Color("#242539")
	var glass := Color("#153444")
	# Nose is local +Z. World scale is shared with the street map.
	_box_c(st, Vector3(0, 0.55, 0), Vector3(1.87, 0.52, 4.38), trim, 0.0)
	_box_c(st, Vector3(0, 0.89, 0), Vector3(1.85, 0.48, 4.20), paint, 0.0)
	_box_c(st, Vector3(0, 1.25, -0.25), Vector3(1.56, 0.58, 2.12), glass, 0.0)
	_box_c(st, Vector3(0, 1.56, -0.28), Vector3(1.61, 0.15, 1.98), paint.lightened(0.26), 0.0)
	_box_c(st, Vector3(0, 1.14, 1.42), Vector3(1.72, 0.1, 1.25), paint.lightened(0.13), 0.0)
	for x in [-0.77, 0.77]:
		for z in [-1.34, 1.34]:
			_box_c(st, Vector3(x, 0.36, z), Vector3(0.44, 0.72, 0.76), trim, 0.0)
			_box_c(st, Vector3(x * 1.29, 0.36, z), Vector3(0.04, 0.34, 0.34), Color("#8e9a9e"), 0.0)
		_box_c(st, Vector3(x, 0.89, 2.11), Vector3(0.31, 0.20, 0.12), Color("#fff2ab"), 0.0)
		_box_c(st, Vector3(x, 0.89, -2.11), Vector3(0.30, 0.18, 0.12), Color("#fa645d"), 0.0)
		_box_c(st, Vector3(x * 1.03, 1.28, -0.16), Vector3(0.09, 0.52, 0.10), paint, 0.0)
	return st.commit()


func _actor_pos() -> Vector2:
	return walk_pos if on_foot else car_pos


func _person_sprite(variant: int) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = PEDESTRIANS
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, (variant * 2 + 1) * 40, 32, 40)
	sprite.pixel_size = CHAR_SCALE
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.offset = Vector2(0, 19)
	add_child(sprite)
	return sprite


func _toggle_car() -> void:
	survival.toggle_vehicle()


func _walk(delta: float) -> void:
	var keyboard := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	)
	var screen := (keyboard + joy_vec).limit_length() if survival.action_time <= 0.0 else Vector2.ZERO
	var right := cam.global_basis.x
	var forward := cam.global_basis.z
	var dir := Vector2(right.x, right.z) * screen.x + Vector2(forward.x, forward.z).normalized() * screen.y
	survival.direction = screen
	var move: Vector2 = dir * delta * survival.walking_speed()
	_walk_move(move)
	walker.position = Vector3(walk_pos.x, 0.04, walk_pos.y)
	if absf(screen.x) > 0.08:
		walk_face = 0 if screen.x < 0.0 else 1
	walk_cycle += delta * 7.0
	var frame := int(walk_cycle) % 4 if screen.length_squared() > 0.03 else 0
	walker.region_rect = Rect2(frame * 32, (8 + walk_face) * 40, 32, 40)


func _walk_move(motion: Vector2) -> void:
	if _walk_blocked(walk_pos):
		walk_pos = survival.safe
	var pieces := maxi(1, ceili(motion.length() / 0.45))
	var step := motion / float(pieces)
	for i in pieces:
		for part in [Vector2(step.x, 0.0), Vector2(0.0, step.y)]:
			var next: Vector2 = walk_pos + part
			if not _walk_blocked(next):
				walk_pos = next


func _walk_blocked(at: Vector2) -> bool:
	return not _in_area(at) or _in_water(at) or _blocked(at) or not _buildings_clear(_rectangle(at, Vector2.DOWN, 0.82, 0.82))


func _drive(delta: float) -> void:
	var target := 0.0
	var steer := 0.0
	var turn_k := 1.0
	var in_place := false
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		target += MAX_SPEED
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		target -= MAX_SPEED * 0.4
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steer -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steer += 1.0
	if joy_vec.length() > 0.2:
		# o carro vai para onde o dedo aponta na tela (câmera isométrica)
		var wd := Vector2(-joy_vec.x - joy_vec.y, joy_vec.x - joy_vec.y).normalized()
		var diff := angle_difference(car_heading, atan2(wd.y, wd.x))
		var ad := absf(diff)
		steer = clampf(diff * 2.0, -1.0, 1.0)
		var pw := clampf(joy_vec.length() * 1.3, 0.0, 1.0)
		if ad < 1.3:
			target = MAX_SPEED * pw * (1.0 - ad / 1.9)
		else:
			target = 2.0
		in_place = true
		turn_k = 1.0 if absf(car_speed) > 2.0 else 0.8

	if survival.fuel <= 0.0:
		target = 0.0
	var rate := ACCEL if absf(target) > absf(car_speed) and signf(target) == signf(car_speed) or car_speed == 0.0 else BRAKE
	if target == 0.0:
		rate = 10.0
	car_speed = move_toward(car_speed, target, rate * delta)

	var heading := car_heading
	if in_place or absf(car_speed) > 0.5:
		var sg := signf(car_speed) if absf(car_speed) > 0.3 else 1.0
		car_heading += steer * TURN_RATE * turn_k * delta * sg
		if _car_blocked(car_pos):
			car_heading = heading

	_drive_move(Vector2(cos(car_heading), sin(car_heading)) * car_speed * delta)


	car_root.position = Vector3(car_pos.x, 0.0, car_pos.y)
	car_root.rotation.y = atan2(cos(car_heading), sin(car_heading))


func _drive_move(motion: Vector2) -> void:
	if _car_blocked(car_pos):
		_unstick()
		return
	var pieces := maxi(1, ceili(motion.length() / 0.7))
	var step := motion / float(pieces)
	for i in pieces:
		var next := car_pos + step
		if _car_blocked(next):
			car_speed *= -0.23
			return
		car_pos = next


func _car_blocked(p: Vector2) -> bool:
	if not _in_area(p) or _in_water(p) or _blocked(p):
		return true
	for i in _nearby_cars(p, 2.6):
		if i != survival.active_vehicle and p.distance_squared_to(parked_vehicles[i]["pos"]) < 6.75:
			return true
	var fwd := Vector2(cos(car_heading), sin(car_heading))
	return not _buildings_clear(_rectangle(p, fwd, 1.7, CAR_LENGTH))


func _unstick() -> void:
	# procura o ponto livre mais próximo em espiral e coloca o carro lá
	var r := 2.0
	while r < 90.0:
		for k in range(16):
			var a := TAU * float(k) / 16.0
			var c := car_pos + Vector2(cos(a), sin(a)) * r
			if not _car_blocked(c):
				car_pos = c
				car_speed = 0.0
				return
		r += 2.0


func _blocked(p: Vector2) -> bool:
	if _bk_near(tree_bk, p, 2.2):
		return true
	for b in _bpolys_at(p):
		if Geometry2D.is_point_in_polygon(p, b["pts"]):
			return true
	return false


func _on_money_delta(d: int) -> void:
	money += d
	home.money_now = money


func _neighbor_names() -> Array:
	var out: Array = []
	for p in pois:
		var nm := str(p.get("npc", ""))
		if nm != "" and not out.has(nm):
			out.append(nm)
		if out.size() >= 8:
			break
	return out


func _swap_car(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	for child in car_root.get_children():
		car_root.remove_child(child)
		child.queue_free()
	var paint := Color("#dc634b")
	match path.get_file():
		"Car_Blue.glb":
			paint = Color("#538bb9")
		"Police_Car.glb":
			paint = Color("#a3b4d1")
		"Ambulance.glb":
			paint = Color("#e0c8a4")
		"Bus.glb":
			paint = Color("#9eae69")
	var vehicle := MeshInstance3D.new()
	if path.get_file() in ["Car_Coral.glb", "Car_Blue.glb"]:
		vehicle.mesh = _detective_car_mesh(paint)
		var body := _mat(Color.WHITE, true)
		body.emission_enabled = true
		body.emission = paint
		body.emission_energy_multiplier = 0.14
		vehicle.material_override = body
		car_root.add_child(vehicle)
	else:
		var ab := _proto_aabb(path)
		var longest := maxf(ab.size.x, ab.size.z)
		if longest < 0.01:
			return
		var scale_factor := CAR_LENGTH / longest
		var inst := _scene(path).instantiate() as Node3D
		var pivot := Node3D.new()
		car_root.add_child(pivot)
		pivot.add_child(inst)
		inst.scale = Vector3.ONE * scale_factor
		var ctr := ab.get_center()
		inst.position = Vector3(-ctr.x, -ab.position.y, -ctr.z) * scale_factor
		if ab.size.x > ab.size.z:
			pivot.rotation.y = PI * 0.5
	var silhouette := ShaderMaterial.new()
	silhouette.shader = CAR_OCCLUSION
	silhouette.render_priority = 8
	silhouette.set_shader_parameter("occluded_color", Color("#f8bb61"))
	# The proxy sits just above the roof so the car cannot obscure itself.
	# It uses the same yaw and footprint and only draws behind scene geometry.
	var proxy := MeshInstance3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var roof_y := 1.70
	if path.get_file() not in ["Car_Coral.glb", "Car_Blue.glb"]:
		var ab := _proto_aabb(path)
		roof_y = ab.size.y * CAR_LENGTH / maxf(ab.size.x, ab.size.z) + 0.08
	_face_c(st, Vector3(0.0, roof_y, -0.05), Vector3.RIGHT * 0.87, Vector3.BACK * 1.98, Color.WHITE)
	proxy.mesh = st.commit()
	proxy.material_override = silhouette
	proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	car_root.add_child(proxy)


func _enter_home() -> void:
	if in_home or menu_open or on_foot:
		return
	street_pos = car_pos
	street_heading = car_heading
	in_home = true
	poi_index = -1
	car_speed = 0.0
	car_root.visible = false
	minimap.visible = false
	prompt_label.visible = false
	ui_panel.visible = false
	cam.size = 7.6
	home.enter()
	cam_focus = home.focus_point()


func _exit_home() -> void:
	if not in_home or intro_state == 1:
		return
	if intro_state == 2:
		intro_state = 0
	in_home = false
	home.leave()
	car_pos = street_pos
	car_heading = street_heading
	car_root.position = Vector3(car_pos.x, 0.0, car_pos.y)
	car_root.rotation.y = atan2(cos(car_heading), sin(car_heading))
	car_root.visible = true
	minimap.visible = true
	cam.size = STREET_VIEW
	cam_focus = car_root.position


func _update_camera(delta: float) -> void:
	if in_home:
		var ht: Vector3 = home.focus_point()
		var vsz := get_viewport().get_visible_rect().size
		var asp := vsz.x / maxf(vsz.y, 1.0)
		var want := maxf(8.8, 10.8 / asp)
		if intro_state == 1:
			# criação do detetive: câmera perto do personagem, que fica na metade de cima
			ht = (home.avatar["node"] as Node3D).global_position + Vector3(0.0, 0.95, 0.0)
			if asp > 1.15:
				want = 6.2
				ht += Vector3(1.0, 0.0, -1.0).normalized() * (0.2 * want * asp)
			else:
				want = maxf(7.0, 3.8 / asp)
				ht += Vector3(1.0, 0.0, 1.0).normalized() * (0.48 * want)
		cam.size = lerpf(cam.size, want, 1.0 - exp(-delta * 6.0))
		cam_focus = cam_focus.lerp(ht, 1.0 - exp(-delta * 8.0))
		cam.position = cam_focus + Vector3(12.0, 9.8, 12.0)
		cam.look_at(cam_focus, Vector3.UP)
		return
	var target := walker.position if on_foot else car_root.position
	var k := 1.0 - exp(-delta * 5.0)
	cam_focus = cam_focus.lerp(target, k)
	var aspect := get_viewport().get_visible_rect().size.aspect()
	var street_size := maxf(28.0 if on_foot else STREET_VIEW, 24.0 / maxf(aspect, 0.1))
	var closest_tower := 0.0
	for tower in tall_buildings:
		var footprint: Rect2 = tower["bb"]
		var center := footprint.get_center()
		var edge_distance := center.distance_to(car_pos) - footprint.size.length() * 0.5
		if edge_distance < 23.0:
			closest_tower = maxf(closest_tower, float(tower["h"]) * (1.0 - clampf(edge_distance / 23.0, 0.0, 1.0)))
	var expanded := street_size + clampf((closest_tower - 16.0) * 0.46, 0.0, 20.0)
	cam.size = lerpf(cam.size, expanded, 1.0 - exp(-delta * 5.0))
	cam.position = cam_focus + Vector3(-31.0, 74.0, -31.0)
	cam.look_at(cam_focus, Vector3.UP)


# ---------- trânsito: carros de NPC andando pelas ruas ----------

func _road_pts(rng: RandomNumberGenerator) -> PackedVector2Array:
	var good: Array = []
	for r in roads:
		if r["p"].size() >= 2 and not (str(r["k"]) in ["footway", "service", "pedestrian"]):
			good.append(r["p"])
	var rp: Array = good[rng.randi() % good.size()]
	var pts := PackedVector2Array()
	for q in rp:
		pts.append(Vector2(float(q[0]), float(q[1])))
	return pts


func _build_traffic() -> void:
	if veh_paths.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for k in TRAFFIC_COUNT:
		var path: String = veh_paths[rng.randi() % veh_paths.size()]
		var ab := _proto_aabb(path)
		var longest: float = max(ab.size.x, ab.size.z)
		if longest < 0.01:
			continue
		var s: float = CAR_LENGTH / longest
		var inst := _scene(path).instantiate() as Node3D
		inst.scale = Vector3.ONE * s
		add_child(inst)
		var pts := _road_pts(rng)
		var c := {"node": inst, "s": s, "ctr": ab.get_center(), "pmin": ab.position, "pts": pts, "idx": 0, "dir": 1, "pos": pts[0], "speed": rng.randf_range(9.0, 16.0)}
		_set_car(c, pts[0])
		traffic.append(c)


func _set_car(c: Dictionary, p: Vector2) -> void:
	var s: float = c["s"]
	var ctr: Vector3 = c["ctr"]
	var pmin: Vector3 = c["pmin"]
	var node: Node3D = c["node"]
	node.position = Vector3(p.x - s * ctr.x, -s * pmin.y, p.y - s * ctr.z)


func _traffic_update(delta: float) -> void:
	for ci in traffic.size():
		var c: Dictionary = traffic[ci]
		var pts: PackedVector2Array = c["pts"]
		var nxt: int = c["idx"] + c["dir"]
		if nxt < 0 or nxt >= pts.size():
			c["dir"] = -c["dir"]
			nxt = c["idx"] + c["dir"]
		var pos: Vector2 = c["pos"]
		var target: Vector2 = pts[nxt]
		var to := target - pos
		var fwd := to.normalized() if to.length() > 0.01 else Vector2.ZERO
		var step: float = float(c["speed"]) * delta * (0.0 if (_car_ahead(ci, fwd) or _red_ahead(pos, fwd)) else 1.0)
		if to.length() <= step:
			pos = target
			c["idx"] = nxt
		else:
			pos += to.normalized() * step
		c["pos"] = pos
		_set_car(c, pos)
		var node: Node3D = c["node"]
		if to.length() > 0.01:
			node.rotation.y = atan2(to.x, to.y)


# ---------- pedestres (300) ----------

func _build_npcs() -> void:
	var paths: Array = []
	var downtown: Array = []
	var central := Vector2(-3274.0, 1196.0)
	for road in roads:
		var street := str(road.get("n", ""))
		if street.is_empty() or str(road["k"]) in ["motorway", "trunk", "pedestrian"]:
			continue
		var pts: Array = road["p"]
		for k in range(pts.size() - 1):
			var a := Vector2(float(pts[k][0]), float(pts[k][1]))
			var b := Vector2(float(pts[k+1][0]), float(pts[k+1][1]))
			var length := a.distance_to(b)
			if length < 17.0 or length > 220.0:
				continue
			var span := [a, b, street, float(ROAD_W.get(road["k"], 5.0)) * 0.5 + 1.2]
			paths.append(span)
			if a.lerp(b, 0.5).distance_to(central) < 320.0:
				downtown.append(span)
	if paths.is_empty():
		return
	var names := ["Ana", "Bruno", "Cida", "Daniel", "Elisa", "Fábio", "Glória", "Hugo", "Iara", "João", "Karina", "Lucas", "Marta", "Nilo", "Olívia", "Paulo", "Rita", "Sílvio", "Tânia", "Vítor"]
	var surnames := ["Alves", "Barros", "Campos", "Dias", "Freitas", "Gomes", "Lima", "Machado", "Moraes", "Nunes", "Oliveira", "Pereira", "Rocha", "Silva", "Souza"]
	var roles := [
		["padeiro", 5.0, 14.0, "Aprendi a fazer pão com minha avó. Entro cedo para o bairro acordar com pão quente."],
		["técnico de enfermagem", 19.0, 7.0, "Trabalho no plantão da noite. Antes de entrar, passo na rua de casa para ligar para a minha mãe."],
		["costureira", 9.0, 18.0, "Conserto uniformes e faço bainhas para quem mora por aqui. Costumo sair para buscar material no meio do expediente."],
		["entregador", 11.0, 20.0, "Faço entregas a pé neste trecho. Aprendi a reconhecer os endereços pelos toldos."],
		["professora", 7.0, 16.0, "Dou aula de história e gosto de levar os alunos para conhecer os prédios antigos da cidade."],
		["vigilante", 21.0, 6.0, "Trabalho à noite e volto antes de o comércio abrir. No caminho anoto quais postes estão apagados."],
		["zeladora", 6.0, 15.0, "Cuido dos prédios desta quadra. Conheço o horário em que cada loja levanta a porta."],
		["livreiro", 10.0, 19.0, "Trabalho com livros usados. Sempre reservo as histórias sobre Campo Grande para a prateleira da entrada."]
	]
	var memories := [
		"Na infância, atravessava o centro com meu avô para ver os trens.",
		"Aprendi a pedalar nestas quadras antes de começar a trabalhar.",
		"Minha família morava longe. Fiz os primeiros amigos esperando o ônibus aqui.",
		"Antigamente, eu vinha ao centro com uma lista de compras escrita à mão.",
		"Meu primeiro serviço foi ajudar a abrir a loja de um vizinho.",
		"Guardo um álbum de fotos das fachadas que mudaram desde que cheguei.",
		"Comecei a andar por aqui quando precisei acompanhar minha irmã à escola.",
		"Conheci meus vizinhos na fila do pão. Hoje todos me chamam pelo nome.",
		"Quando cheguei, me orientava pelo som dos ônibus nas avenidas."
	]
	for i in NPC_COUNT:
		var pool := downtown if i < 36 and not downtown.is_empty() else paths
		var span: Array = pool[(i * 61 + int(float(i) / 3.0)) % pool.size()]
		var a: Vector2 = span[0]
		var b: Vector2 = span[1]
		var side := a.direction_to(b).orthogonal() * float(span[3]) * (1.0 if i % 2 == 0 else -1.0)
		var role: Array = roles[i % roles.size()]
		var name: String = names[i % names.size()] + " " + surnames[int(float(i) / float(names.size())) % surnames.size()]
		var sprite := _person_sprite(i % 6)
		var origin := a.lerp(b, 0.10) + side
		var office := a.lerp(b, 0.88) + side
		var routine_offset := float(i % 5) * 0.075
		var memory: String = memories[(i * 7 + int(float(i) / roles.size())) % memories.size()]
		var story := "%s %s Hoje meu trajeto passa por %s." % [memory, role[3], span[2]]
		npcs.append({"name": name, "job": role[0], "start": float(role[1]) + routine_offset,
			"end": float(role[2]) + routine_offset, "story": story,
			"street": span[2], "home": origin, "work": office, "pos": origin, "node": sprite,
			"variant": i % 6, "phase": "em casa", "stride": float(i % 4)})
	_npc_update(0.0)
	print("pedestres com rotina: ", npcs.size())


func _npc_update(delta: float) -> void:
	var right := cam.global_basis.x
	for n in npcs:
		var begin: float = n["start"]
		var office_hours := fposmod(float(n["end"]) - begin, 24.0)
		var shift := fposmod(street_hour - begin, 24.0)
		var origin: Vector2 = n["home"]
		var office: Vector2 = n["work"]
		var target := origin
		var phase := "em casa"
		if shift < office_hours:
			target = office
			phase = "no trabalho"
			# Mid-shift errands take place along the same street.
			if absf(shift - office_hours * 0.5) < 0.32:
				target = origin.lerp(office, 0.58)
				phase = "no intervalo"
		elif shift > 23.65:
			target = office
			phase = "a caminho do trabalho"
		elif shift < office_hours + 0.35:
			phase = "voltando para casa"
		n["phase"] = phase
		var pos: Vector2 = n["pos"]
		var sprite: Sprite3D = n["node"]
		if delta == 0.0:
			pos = target
		var active := pos.distance_squared_to(_actor_pos()) < PED_RANGE * PED_RANGE
		sprite.visible = active
		var movement := target - pos
		if active and movement.length_squared() > 0.04:
			var next := pos.move_toward(target, delta * 1.55)
			if not _blocked(next):
				pos = next
			n["stride"] = fposmod(float(n["stride"]) + delta * 6.0, 4.0)
		else:
			n["stride"] = 0.0
			if not active:
				pos = target
		n["pos"] = pos
		sprite.position = Vector3(pos.x, 0.04, pos.y)
		var face := 0 if Vector3(movement.x, 0.0, movement.y).dot(right) < 0.0 else 1
		sprite.region_rect = Rect2(int(n["stride"]) * 32, (int(n["variant"]) * 2 + face) * 40, 32, 40)


func _nearby_citizen() -> Dictionary:
	if not on_foot:
		return {}
	var best := 3.6
	var found: Dictionary = {}
	for n in npcs:
		var distance := walk_pos.distance_to(n["pos"])
		if distance < best:
			best = distance
			found = n
	return found


# ---------- ponto de interesse e diálogo ----------

func _update_poi() -> void:
	if menu_open:
		return
	poi_index = -1
	var best := INF
	var target := _target_id()
	for i in pois.size():
		var p: Dictionary = pois[i]
		var pos := Vector2(float(p.get("access_x", p["x"])), float(p.get("access_y", p["y"])))
		if on_foot:
			pos = p.get("npc_pos", pos)
		var d := _actor_pos().distance_to(pos)
		var radius := 5.2 if on_foot else float(p.get("access_radius", p.get("snapDist", 25.0)))
		if d > radius:
			continue
		if str(p["id"]) == target:
			poi_index = i
			return
		if d < best:
			best = d
			poi_index = i


func _update_dialog(delta: float) -> void:
	if absf(car_speed) > 2.0 and not menu_open and ui_panel.visible:
		_dismiss_dialog()
	var citizen := {} if poi_index >= 0 else _nearby_citizen()
	if poi_index >= 0:
		prompt_label.text = "[E] " + str(pois[poi_index]["name"])
	elif not citizen.is_empty():
		prompt_label.text = "[E] " + str(citizen["name"])
	prompt_label.position.y = case_label.position.y + case_label.size.y + 6.0
	prompt_label.visible = (poi_index >= 0 or not citizen.is_empty()) and not menu_open and not ph
	if typed < full_line.length():
		typed += TYPE_SPEED * delta
		ui_text.text = full_line.substr(0, int(typed))


func _dismiss_dialog() -> void:
	if menu_open:
		_close_menu()
	ui_panel.visible = false


func _say(text: String) -> void:
	full_line = text
	typed = 0.0


func _open_menu() -> void:
	menu_open = true
	ui_menu.visible = true
	for c in ui_menu.get_children():
		c.queue_free()
	for opt in _options_for(pois[poi_index]):
		var b := Button.new()
		b.text = opt
		b.custom_minimum_size = BTN_SZ
		b.add_theme_font_size_override("font_size", 26 if ph else 18)
		b.pressed.connect(_on_option.bind(opt))
		ui_menu.add_child(b)
	ui_panel.visible = true


func _options_for(p: Dictionary) -> Array:
	var id := str(p.get("id", ""))
	if id.begins_with("shop_") or id == pad_id or id == farm_id:
		var o := ["Falar", "Comprar", "Vender", "Ver preços"]
		if id == pad_id or id == farm_id:
			o.append("Perguntar sobre o caso")
		o.append("Sair")
		return o
	if id == "central":
		return ["Falar", "Perguntar sobre o caso", "Sair"]
	if p.has("marco"):
		return ["Falar", "Sair"]
	return ["Falar", "Bater na porta", "Sair"]


func _intro_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.08, 0.08, 0.95)
	sb.border_color = Color(0.7, 0.55, 0.3)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	return sb


func _intro_clear() -> void:
	if intro_layer != null:
		intro_layer.queue_free()
		intro_layer = null
	intro_lbls.clear()


func _intro_panel() -> VBoxContainer:
	_intro_clear()
	intro_layer = CanvasLayer.new()
	intro_layer.layer = 20
	add_child(intro_layer)
	var vs := get_viewport().get_visible_rect().size
	var pn := PanelContainer.new()
	if vs.x > vs.y * 1.15:
		# tela larga: painel na direita, o personagem aparece à esquerda
		pn.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
		pn.offset_left = -minf(430.0, vs.x * 0.45) - 12.0
		pn.offset_right = -12.0
		pn.offset_top = 12.0
		pn.offset_bottom = -12.0
	else:
		pn.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		pn.grow_vertical = Control.GROW_DIRECTION_BEGIN
		var mx := maxf(12.0, (vs.x - 600.0) * 0.5)
		pn.offset_left = mx
		pn.offset_right = -mx
		pn.offset_bottom = -16.0
	pn.add_theme_stylebox_override("panel", _intro_style())
	intro_layer.add_child(pn)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	pn.add_child(vb)
	return vb


func _intro_begin() -> void:
	_enter_home()
	intro_state = 1
	var vb := _intro_panel()
	var t := Label.new()
	t.text = "Crie o seu detetive"
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", Color(0.92, 0.76, 0.42))
	vb.add_child(t)
	var cur := str(home.cfg.get("nome", ""))
	if cur == "Você":
		cur = ""
	if OS.has_feature("web"):
		var nb := Button.new()
		nb.custom_minimum_size = Vector2(0, 58)
		nb.add_theme_font_size_override("font_size", 26)
		var upd := func():
			var n2 := str(home.cfg.get("nome", ""))
			nb.text = "Nome: %s   (toque para digitar)" % ("—" if n2 == "" or n2 == "Você" else n2)
		upd.call()
		nb.pressed.connect(func():
			home.ask_name()
			upd.call())
		vb.add_child(nb)
	else:
		var ne := LineEdit.new()
		ne.placeholder_text = "Digite o seu nome"
		ne.max_length = 14
		ne.custom_minimum_size = Vector2(0, 52)
		ne.text = cur
		ne.text_changed.connect(func(tx: String): home._on_name_changed(tx))
		vb.add_child(ne)
	for r in home.CAT_ROWS:
		var key := str(r[0])
		var count := int(r[2])
		var hb := HBoxContainer.new()
		var lab := Label.new()
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(lab)
		var pv := Button.new()
		pv.text = "<"
		pv.custom_minimum_size = Vector2(68, 50)
		pv.pressed.connect(_intro_cycle.bind(key, -1, count))
		hb.add_child(pv)
		var nx := Button.new()
		nx.text = ">"
		nx.custom_minimum_size = Vector2(68, 50)
		nx.pressed.connect(_intro_cycle.bind(key, 1, count))
		hb.add_child(nx)
		vb.add_child(hb)
		intro_lbls[key] = lab
	var go := Button.new()
	go.text = "Começar investigação"
	go.custom_minimum_size = Vector2(0, 60)
	go.pressed.connect(_intro_story)
	vb.add_child(go)
	_intro_refresh()


func _intro_cycle(key: String, step: int, count: int) -> void:
	home._cycle(key, step, count)
	_intro_refresh()


func _intro_refresh() -> void:
	home._refresh_rows()
	for k in intro_lbls.keys():
		var src: Label = home.row_labels[k]["label"]
		(intro_lbls[k] as Label).text = src.text


func _intro_story() -> void:
	var nm := str(home.cfg.get("nome", "")).strip_edges()
	if nm == "" or nm == "Você":
		nm = "Detetive"
		home._on_name_changed(nm)
	home.cfg["intro_v"] = 2
	home._save()
	intro_state = 2
	var vb := _intro_panel()
	var t := Label.new()
	t.text = "Primeiro dia"
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", Color(0.92, 0.76, 0.42))
	vb.add_child(t)
	var tx := Label.new()
	tx.text = "Hoje é o seu primeiro dia na Central de Investigação, %s.\n\nO Sargento Lima já está esperando por você. Dirija até o ponto dourado no minimapa. Pare na Central. Use Descer ou F para caminhar, o botão de conversa ou E para falar e C para abrir o caderno." % nm
	tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tx.custom_minimum_size = Vector2(300, 0)
	tx.add_theme_font_size_override("font_size", 24)
	vb.add_child(tx)
	var ok := Button.new()
	ok.text = "Entendi"
	ok.custom_minimum_size = Vector2(0, 60)
	ok.pressed.connect(func():
		_intro_clear()
		_exit_home()
		home._update_hud())
	vb.add_child(ok)


func _detect_phone() -> bool:
	var w := Vector2(get_window().size)
	return w.x < w.y or DisplayServer.is_touchscreen_available()


func _build_touch_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	joy = Control.new()
	joy.gui_input.connect(_on_joy_input)
	joy.draw.connect(_draw_joy)
	layer.add_child(joy)
	nav_arrow = Control.new()
	nav_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nav_arrow.draw.connect(_draw_nav)
	layer.add_child(nav_arrow)
	btn_talk = _icon_btn("talk", _on_touch_interact)
	layer.add_child(btn_talk)
	btn_book = _icon_btn("book", _on_touch_notebook)
	layer.add_child(btn_book)
	btn_car = Button.new()
	btn_car.focus_mode = Control.FOCUS_NONE
	btn_car.custom_minimum_size = Vector2(120, 52)
	btn_car.pressed.connect(_toggle_car)
	layer.add_child(btn_car)
	btn_attack = _icon_btn("attack", survival.attack)
	layer.add_child(btn_attack)


func _icon_btn(kind: String, cb: Callable) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(88, 88)
	b.size = Vector2(88, 88)
	b.draw.connect(_draw_icon.bind(b, kind))
	b.pressed.connect(cb)
	return b


func _draw_icon(b: Button, kind: String) -> void:
	var s := b.size
	var c := s * 0.5
	var r := minf(s.x, s.y) * 0.5
	var k := r / 44.0
	var gold := Color(0.92, 0.76, 0.42)
	var cream := Color(0.97, 0.92, 0.82)
	var dark := Color(0.08, 0.07, 0.07)
	b.draw_circle(c, r, Color(0.08, 0.07, 0.07, 0.8))
	b.draw_arc(c, r - 1.5, 0.0, TAU, 40, gold, 3.0)
	if kind == "attack":
		b.draw_arc(c, 20.0 * k, 0.0, TAU, 24, cream, 3.0 * k)
		b.draw_line(c - Vector2(25.0, 0.0) * k, c + Vector2(25.0, 0.0) * k, cream, 3.0 * k)
		b.draw_line(c - Vector2(0.0, 25.0) * k, c + Vector2(0.0, 25.0) * k, cream, 3.0 * k)
	elif kind == "home":
		b.draw_colored_polygon(PackedVector2Array([c + Vector2(-26, -2) * k, c + Vector2(0, -28) * k, c + Vector2(26, -2) * k]), gold)
		b.draw_rect(Rect2(c + Vector2(-18, -2) * k, Vector2(36, 28) * k), cream)
		b.draw_rect(Rect2(c + Vector2(-5, 8) * k, Vector2(10, 18) * k), dark)
	elif kind == "talk":
		b.draw_rect(Rect2(c + Vector2(-26, -22) * k, Vector2(52, 34) * k), cream)
		b.draw_colored_polygon(PackedVector2Array([c + Vector2(-14, 12) * k, c + Vector2(-16, 28) * k, c + Vector2(2, 12) * k]), cream)
		for i in 3:
			b.draw_circle(c + Vector2(-12 + i * 12, -5) * k, 3.6 * k, dark)
	else:
		b.draw_rect(Rect2(c + Vector2(-20, -26) * k, Vector2(40, 52) * k), gold)
		b.draw_rect(Rect2(c + Vector2(-16, -22) * k, Vector2(5, 44) * k), dark)
		for i in 3:
			b.draw_rect(Rect2(c + Vector2(-6, -14 + i * 11) * k, Vector2(20, 3.5) * k), dark)


func _draw_nav() -> void:
	var sz := nav_arrow.size
	var c := sz * 0.5
	var r := sz.x * 0.5
	nav_arrow.draw_circle(c, r, Color(0.07, 0.07, 0.08, 0.8))
	nav_arrow.draw_arc(c, r - 1.5, 0.0, TAU, 32, Color(0.92, 0.76, 0.42), 2.5)
	if not nav_has:
		return
	var sx := (-nav_dir.x + nav_dir.y) * 0.70710678
	var sy := -(nav_dir.x + nav_dir.y) * 0.70710678
	var ang := atan2(sy, sx)
	var u := Vector2(cos(ang), sin(ang))
	var n := Vector2(-u.y, u.x)
	var k := r / 32.0
	nav_arrow.draw_colored_polygon(PackedVector2Array([c + u * 20.0 * k, c - u * 13.0 * k + n * 14.0 * k, c - u * 5.0 * k, c - u * 13.0 * k - n * 14.0 * k]), Color(1.0, 0.85, 0.2))


func _joy_home(j: Vector2) -> Vector2:
	# câmera da casa olha para (-1,-1): "para cima" na tela = (-1,-1)
	return Vector2(j.x + j.y, -j.x + j.y).limit_length(1.0) * minf(j.length(), 1.0)


func _label_bg(l: Label, pad_x: float, pad_y: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.06, 0.07, 0.72)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y
	l.add_theme_stylebox_override("normal", sb)


func _touch_vis() -> void:
	btn_car.visible = not menu_open and survival.vehicle_available()
	btn_car.text = survival.vehicle_caption() + ("" if ph else " [F]")
	if not on_foot:
		btn_car.text += " · %d%%" % roundi(survival.fuel)
	btn_talk.visible = ph and not menu_open and survival.available()
	btn_book.visible = not menu_open
	btn_attack.visible = ph and not menu_open and on_foot
	nav_arrow.visible = minimap.visible and nav_has and not menu_open
	joy.visible = ph and not menu_open
	case_label.visible = true


func _layout_ui() -> void:
	if money_label == null or case_label == null or minimap == null or joy == null or ui_panel == null or clock_label == null or btn_book == null:
		return
	ui_dirty = false
	var win := get_window()
	var ws := Vector2(win.size)
	ph = _detect_phone()
	var base := Vector2(1280, 720)
	if ph:
		base = Vector2(560, 560) if ws.x < ws.y else Vector2(900, 540)
		if win.theme == null:
			var th := Theme.new()
			th.default_font_size = 24
			win.theme = th
	else:
		win.theme = null
	win.content_scale_size = Vector2i(base)
	var sc := minf(ws.x / base.x, ws.y / base.y)
	var vs := ws / sc
	var m := 12.0
	var msz := 190.0 if ph else 230.0
	money_label.position = Vector2(m, 12)
	money_label.add_theme_font_size_override("font_size", 28 if ph else 24)
	_label_bg(money_label, 10, 4)
	money_label.hide()
	clock_label.hide()
	clock_label.position = Vector2(m + (132 if ph else 120), 12)
	clock_label.add_theme_font_size_override("font_size", 24 if ph else 20)
	_label_bg(clock_label, 10, 6)
	var cw := minf(580.0, vs.x - msz - m * 3.0)
	survival.layout(cw)
	street_label.position = Vector2(m, 92 if ph else 77)
	street_label.size.x = cw
	street_label.add_theme_font_size_override("font_size", 21 if ph else 17)
	_label_bg(street_label, 10, 5)
	case_label.position = Vector2(m, 133 if ph else 111)
	case_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	case_label.custom_minimum_size = Vector2(cw, 0)
	case_label.size = Vector2(cw, 0)
	case_label.add_theme_font_size_override("font_size", 22 if ph else 18)
	_label_bg(case_label, 12, 8)
	_label_bg(prompt_label, 10, 5)
	minimap.position = Vector2(vs.x - msz - m, 12)
	minimap.custom_minimum_size = Vector2(msz, msz)
	minimap.size = Vector2(msz, msz)
	minimap.clip_contents = true
	var nsz := 64.0 if ph else 56.0
	nav_arrow.size = Vector2(nsz, nsz)
	nav_arrow.position = Vector2(minimap.position.x + (msz - nsz) * 0.5, 12 + msz + 8)
	var jsz := 220.0 if ph else 200.0
	joy.position = Vector2((vs.x - jsz) * 0.5, vs.y - jsz - 36.0)
	joy.size = Vector2(jsz, jsz)
	btn_book.position = Vector2(vs.x - 88.0 - 16.0, vs.y - 88.0 - 40.0)
	btn_car.position = Vector2(14.0, vs.y - 125.0 if ph else vs.y - 62.0)
	btn_attack.position = Vector2(14.0, vs.y - 230.0)
	btn_talk.position = Vector2(vs.x - 88.0 - 16.0, vs.y - 88.0 * 2.0 - 56.0)
	if ph:
		ui_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		ui_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
		ui_panel.offset_left = 12
		ui_panel.offset_right = -12
		ui_panel.offset_bottom = -(jsz + 52.0)
		ui_panel.offset_top = ui_panel.offset_bottom - 190.0
		ui_name.add_theme_font_size_override("font_size", 28)
		ui_text.add_theme_font_size_override("font_size", 26)
	else:
		ui_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		ui_panel.offset_left = 40
		ui_panel.offset_right = -40
		ui_panel.offset_top = -200
		ui_panel.offset_bottom = -30
		ui_name.add_theme_font_size_override("font_size", 22)
		ui_text.add_theme_font_size_override("font_size", 20)
	ui_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ui_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ui_portrait.custom_minimum_size = Vector2(120, 120) if ph else Vector2(112, 112)
	ui_portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if home != null and home.btn_exit != null and ph:
		home.btn_exit.custom_minimum_size = Vector2(152, 64)
		home.btn_exit.size = Vector2(152, 64)
		home.btn_exit.position = Vector2(16, vs.y - 150.0)
		home.btn_menu.custom_minimum_size = Vector2(152, 64)
		home.btn_menu.size = Vector2(152, 64)
		home.btn_menu.position = Vector2(16, vs.y - 226.0)
	if home != null and home.btn_enter != null:
		var he: Button = home.btn_enter
		if not home_icon_ready:
			home_icon_ready = true
			he.text = ""
			he.flat = true
			he.focus_mode = Control.FOCUS_NONE
			he.draw.connect(_draw_icon.bind(he, "home"))
		he.custom_minimum_size = Vector2(88, 88)
		he.size = Vector2(88, 88)
		he.position = Vector2(16, vs.y - 88.0 - 40.0)
		he.queue_redraw()
	nav_arrow.queue_redraw()
	minimap.queue_redraw()


func _draw_joy() -> void:
	var c := joy.size * 0.5
	var r := joy.size.x * 0.5
	joy.draw_circle(c, r, Color(0.1, 0.09, 0.09, 0.45))
	joy.draw_arc(c, r, 0.0, TAU, 48, Color(0.9, 0.75, 0.4, 0.7), 2.0)
	joy.draw_circle(c + joy_vec * r * 0.6, r * 0.28, Color(0.9, 0.75, 0.4, 0.85))


func _joy_set(pos: Vector2) -> void:
	var r := joy.size.x * 0.5
	joy_vec = ((pos - joy.size * 0.5) / r).limit_length(1.0)
	joy.queue_redraw()


func _on_joy_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		joy_active = (ev as InputEventMouseButton).pressed
		if joy_active:
			_joy_set((ev as InputEventMouseButton).position)
		else:
			joy_vec = Vector2.ZERO
			joy.queue_redraw()
	elif ev is InputEventMouseMotion and joy_active:
		_joy_set((ev as InputEventMouseMotion).position)
	elif ev is InputEventScreenTouch:
		joy_active = (ev as InputEventScreenTouch).pressed
		if joy_active:
			_joy_set((ev as InputEventScreenTouch).position)
		else:
			joy_vec = Vector2.ZERO
			joy.queue_redraw()
	elif ev is InputEventScreenDrag and joy_active:
		_joy_set((ev as InputEventScreenDrag).position)


func _on_touch_interact() -> void:
	if not menu_open:
		survival.interact()


func _on_touch_notebook() -> void:
	survival.inventory()


func _close_menu() -> void:
	menu_open = false
	ui_menu.visible = false


func _on_option(opt: String) -> void:
	match opt:
		"Comprar":
			if money >= 50:
				money -= 50
				_say("Você comprou um item por R$ 50. Saldo: R$ %d." % money)
			else:
				_say("Você não tem dinheiro suficiente.")
		"Vender":
			money += 30
			_say("Você vendeu um item por R$ 30. Saldo: R$ %d." % money)
		"Ver preços":
			_say("Lanterna R$ 80. Caderno R$ 15. Gravador R$ 120. Mapa da cidade R$ 25.")
		"Falar":
			var p: Dictionary = pois[poi_index]
			_say(str(p.get("greeting", "")) + " " + str(p.get("story", p.get("line", ""))))
		"Perguntar sobre o caso":
			var pid := str(pois[poi_index]["id"])
			var pnpc := str(pois[poi_index]["npc"])
			if pid == pad_id:
				_say("Dona Cida: Um carro preto ficou parado na esquina das 2h às 3h. Não era de morador.")
			elif pid == farm_id:
				_say("Otávio: O Ricardo Lima comprou remédio para dormir quase três da manhã. Disse que era para a mãe.")
			else:
				_say(pnpc + ": Não sei de nada sobre o caso. Pergunte a outros moradores.")
		"Bater na porta":
			_say("Ninguém atende. Talvez volte mais tarde.")
		"Sair":
			_dismiss_dialog()
			return
	typed = 9999.0
	ui_text.text = full_line


# ---------- interface ----------

func _foot_occluded(at: Vector3) -> bool:
	var sight := cam.global_basis.z
	var limit := minf(64.0, (cam.global_position - at).dot(sight))
	if limit <= 1.0:
		return false
	for n in range(1, ceili(limit), 2):
		var sample := at + sight * float(n)
		for building in _bpolys_at(Vector2(sample.x, sample.z)):
			if float(building["h"]) >= sample.y and Geometry2D.is_point_in_polygon(Vector2(sample.x, sample.z), building["pts"]):
				return true
	return false


func _draw_player_marker() -> void:
	var span := 25.0
	var cap := 8.0
	var fill := Color("#ffd284")
	for side in [-1.0, 1.0]:
		var x := float(side) * span
		var points := PackedVector2Array([Vector2(x - float(side) * cap, -10), Vector2(x, -10), Vector2(x, 10), Vector2(x - float(side) * cap, 10)])
		player_marker.draw_polyline(points, Color("#211e29"), 5.0)
		player_marker.draw_polyline(points, fill, 2.0)


func _register_sign(text: String, anchor: Vector3) -> void:
	var cell := Vector2i(floori(anchor.x / 50.0), floori(anchor.z / 50.0))
	if not city_signs.has(cell):
		city_signs[cell] = []
	city_signs[cell].append({"text": text, "anchor": anchor})


func _update_signs() -> void:
	var view := get_viewport().get_visible_rect().size
	sign_layer.visible = not menu_open
	if not sign_layer.visible:
		return
	var available := Rect2(Vector2(12, case_label.position.y + case_label.size.y + 42), Vector2(view.x - 24, view.y))
	available.end.y = view.y * (0.72 if ph else 0.91)
	var candidates := []
	var cell := Vector2i(floori(_actor_pos().x / 50.0), floori(_actor_pos().y / 50.0))
	for x in range(-1, 2):
		for y in range(-1, 2):
			for sign in city_signs.get(cell + Vector2i(x, y), []):
				var anchor: Vector3 = sign["anchor"]
				var d := Vector2(anchor.x, anchor.z).distance_squared_to(_actor_pos())
				if d > 49.0 * 49.0:
					continue
				var screen := cam.unproject_position(anchor)
				if available.grow_individual(65.0, 72.0, 65.0, 0.0).has_point(screen):
					candidates.append({"d": d, "pos": screen, "text": sign["text"]})
	candidates.sort_custom(func(a, b): return a["d"] < b["d"])
	var occupied: Array[Rect2] = []
	var index := 0
	for sign in sign_labels:
		sign.hide()
	for item in candidates:
		if index == sign_labels.size():
			break
		var sign := sign_labels[index]
		sign.add_theme_font_size_override("font_size", 22 if ph else 18)
		sign.text = item["text"]
		sign.reset_size()
		var pos: Vector2 = item["pos"] - Vector2(sign.size.x * 0.5, sign.size.y)
		pos.x = clampf(pos.x, available.position.x, available.end.x - sign.size.x)
		pos.y = maxf(pos.y, available.position.y)
		var rect := Rect2(pos, sign.size)
		if not available.encloses(rect) or occupied.any(func(old): return old.grow(5).intersects(rect)):
			continue
		sign.position = rect.position
		sign.show()
		occupied.append(rect)
		index += 1


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	player_marker = Control.new()
	player_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(player_marker)
	player_marker.draw.connect(_draw_player_marker)
	sign_layer = Control.new()
	sign_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(sign_layer)
	for i in 18:
		var sign := Label.new()
		sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sign.add_theme_color_override("font_color", Color("#fff1cc"))
		_label_bg(sign, 8, 3)
		sign_layer.add_child(sign)
		sign_labels.append(sign)
	street_label = Label.new()
	street_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	layer.add_child(street_label)
	var credits := Label.new()
	credits.text = "Mapa © OpenStreetMap contributors"
	credits.add_theme_font_size_override("font_size", 12)
	credits.add_theme_color_override("font_shadow_color", Color.BLACK)
	credits.add_theme_constant_override("shadow_offset_x", 1)
	credits.add_theme_constant_override("shadow_offset_y", 1)
	credits.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(credits)
	credits.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	credits.position += Vector2(-12, -8)

	money_label = Label.new()
	money_label.position = Vector2(20, 16)
	money_label.add_theme_font_size_override("font_size", 24)
	layer.add_child(money_label)

	prompt_label = Label.new()
	prompt_label.text = "[E] Interagir"
	prompt_label.position = Vector2(20, 52)
	prompt_label.add_theme_font_size_override("font_size", 20)
	prompt_label.visible = false
	layer.add_child(prompt_label)

	ui_panel = PanelContainer.new()
	ui_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	ui_panel.offset_left = 40
	ui_panel.offset_right = -40
	ui_panel.offset_top = -200
	ui_panel.offset_bottom = -30
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.09, 0.09, 0.94)
	sb.border_color = Color(0.55, 0.45, 0.25)
	sb.set_border_width_all(4)
	ui_panel.add_theme_stylebox_override("panel", sb)
	ui_panel.visible = false
	layer.add_child(ui_panel)

	var paper := TextureRect.new()
	paper.texture = _noise_tex(Color(0.14, 0.12, 0.11), 0.3, 0.9)
	paper.stretch_mode = TextureRect.STRETCH_TILE
	paper.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_panel.add_child(paper)
	var row := HBoxContainer.new()
	ui_panel.add_child(row)
	var xb := Button.new()
	xb.text = "X"
	xb.custom_minimum_size = Vector2(60, 60)
	xb.size_flags_horizontal = Control.SIZE_SHRINK_END
	xb.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	xb.add_theme_font_size_override("font_size", 28)
	xb.pressed.connect(_dismiss_dialog)
	ui_panel.add_child(xb)
	ui_portrait = TextureRect.new()
	ui_portrait.custom_minimum_size = Vector2(112, 112)
	ui_portrait.stretch_mode = TextureRect.STRETCH_SCALE
	ui_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(ui_portrait)
	_set_portrait({})
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	ui_name = Label.new()
	ui_name.add_theme_color_override("font_color", Color(0.9, 0.75, 0.4))
	ui_name.add_theme_font_size_override("font_size", 22)
	col.add_child(ui_name)
	ui_text = Label.new()
	ui_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ui_text.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8))
	ui_text.add_theme_font_size_override("font_size", 20)
	col.add_child(ui_text)
	ui_menu = HFlowContainer.new() if ph else VBoxContainer.new()
	ui_menu.visible = false
	if ph:
		col.add_child(ui_menu)
	else:
		row.add_child(ui_menu)


# ---------- mundo preenchido: lotes com prédios nas quadras ----------

func _fill_lots() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mat := _mat(Color.WHITE, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var added := 0
	var west_lots := 0
	var east_lots := 0
	for r in roads:
		var kind: String = r["k"]
		if kind not in ["residential", "tertiary", "secondary", "primary", "living_street", "service"]:
			continue
		var rp: Array = r["p"]
		var wd: float = float(ROAD_W.get(kind, 5.0))
		for k in range(rp.size() - 1):
			var a := Vector2(float(rp[k][0]), float(rp[k][1]))
			var b := Vector2(float(rp[k + 1][0]), float(rp[k + 1][1]))
			if kind == "service" and not tall_buildings.any(func(tower): return (tower["bb"] as Rect2).get_center().distance_to((a + b) * 0.5) < 90.0):
				continue
			var eastern := (a.x + b.x) * 0.5 > -1200.0
			var length := a.distance_to(b)
			var dir := a.direction_to(b)
			var nrm := dir.orthogonal()
			var t := 6.8
			while t < length - 6.5 and ((east_lots < LOT_BUDGET_EAST) if eastern else (west_lots < LOT_BUDGET_WEST)):
				for side in [-1.0, 1.0]:
					for row in 2:
						if row == 1 and rng.randf() < (0.45 if eastern else 0.20):
							continue
						var w := rng.randf_range(7.1, 10.6)
						var depth := rng.randf_range(6.4, 9.5)
						var facing: Vector2 = -nrm * float(side)
						var distance := wd * 0.5 + depth * 0.5 + 3.65 + float(row) * 10.8
						var center := a + dir * t - facing * distance
						if not _in_area(center) or _landmark_spot(center) or _near_mapped_place(center) or _in_median(center):
							continue
						var pts := _rectangle(center, facing, w, depth)
						if not _parcel_clear(pts, center):
							continue
						var h := rng.randf_range(3.5, 6.7)
						_add_bpoly(pts, h, "residence" if not (row == 0 and added % 39 == 26) else "")
						_bk_add(bld_bk, center)
						if row == 0 and added % 13 == 0:
							var models := ["casa_terracota", "casa_azulada", "comercio_toldo"]
							var model: String = models[int(float(added) / 13.0) % models.size()]
							var model_path := CITY_MODELS + model + ".glb"
							if added % 130 == 0:
								var voxel := "voxel_casa" if model != "comercio_toldo" else "voxel_comercio"
								var variant := "res://assets/survival_local/" + voxel + ".glb"
								if ResourceLoader.exists(variant):
									model_path = variant
							_place_city_model(model_path, center, facing, Vector3(w, h, depth))
						else:
							_city_building(st, pts, h, added + city["buildings"].size())
						added += 1
						if added % 160 == 0:
							_add_mesh(st, mat, 0.0)
							st.clear()
							st.begin(Mesh.PRIMITIVE_TRIANGLES)
						if eastern:
							east_lots += 1
						else:
							west_lots += 1
				t += rng.randf_range(11.0, 15.0)
	_add_mesh(st, mat, 0.0)
	print("lotes urbanos adicionados: ", added, " (oeste: ", west_lots, ", leste: ", east_lots, ")")


func _place_city_model(path: String, center: Vector2, facing: Vector2, size: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(center.x, 0.0, center.y)
	pivot.rotation.y = atan2(facing.x, facing.y)
	add_child(pivot)
	var bounds := _proto_aabb(path)
	var model := _scene(path).instantiate() as Node3D
	if size != Vector3.ZERO:
		model.scale = size / bounds.size
	var off := bounds.get_center()
	model.position = -Vector3(off.x, bounds.position.y, off.z) * model.scale - Vector3.UP * 0.045
	pivot.add_child(model)
	return pivot


func _place_investigation_hq() -> void:
	for p in pois:
		if str(p["id"]) != "central":
			continue
		var original := Vector2(float(p["x"]), float(p["y"]))
		var path := CITY_MODELS + "central_investigacao.glb"
		var best := INF
		var street := Vector2.ZERO
		var front := Vector2.ZERO
		var site := Vector2.ZERO
		var shape := PackedVector2Array()
		var key := Vector2i(floori(original.x / 50.0), floori(original.y / 50.0))
		for gx in range(-2, 3):
			for gy in range(-2, 3):
				for sample in rd_bk.get(key + Vector2i(gx, gy), []):
					if str(sample[3]) not in ["residential", "tertiary", "secondary", "primary"]:
						continue
					var point: Vector2 = sample[0]
					var dist := point.distance_to(original)
					if dist >= best:
						continue
					var tangent: Vector2 = sample[1]
					var normal := tangent.orthogonal()
					for side in [-1.0, 1.0]:
						var fd: Vector2 = normal * float(side)
						var pos: Vector2 = point - fd * (float(sample[2]) + 6.7)
						var u := tangent * 8.05
						var v := fd * 5.28
						var pts := PackedVector2Array([pos-u-v, pos+u-v, pos+u+v, pos-u+v])
						if _landmark_spot(pos) or not _parcel_clear(pts, pos):
							continue
						best = dist
						street = point
						front = fd
						site = pos
						shape = pts
						break
		if shape.is_empty():
			return
		p["x"] = site.x
		p["y"] = site.y
		p["access_x"] = street.x
		p["access_y"] = street.y
		p["access_radius"] = 17.0
		_add_bpoly(shape, 7.5)
		_bk_add(bld_bk, site)
		_place_city_model(path, site, front, Vector3.ZERO)
		return


func _near_mapped_place(point: Vector2) -> bool:
	for p in pois:
		if p.get("real_place", false) and point.distance_squared_to(Vector2(p["x"], p["y"])) < 28.0 * 28.0:
			return true
	return false


func _parcel_clear(pts: PackedVector2Array, center: Vector2) -> bool:
	if _in_park(center) or _in_water(center) or not road_clearance.is_clear(pts):
		return false
	for corner in pts:
		if _in_park(corner) or _in_water(corner):
			return false
	return _buildings_clear(pts)


func _buildings_clear(pts: PackedVector2Array) -> bool:
	var span := _bbox(pts)
	var lower := Vector2i(floori(span.position.x / 50.0), floori(span.position.y / 50.0))
	var upper := Vector2i(floori(span.end.x / 50.0), floori(span.end.y / 50.0))
	for x in range(lower.x, upper.x + 1):
		for y in range(lower.y, upper.y + 1):
			for building in bpoly_bk.get(Vector2i(x, y), []):
				if span.intersects(building["bb"]) and not Geometry2D.intersect_polygons(pts, building["pts"]).is_empty():
					return false
	return true


func _rectangle(center: Vector2, facing: Vector2, width: float, depth: float) -> PackedVector2Array:
	var u := facing.orthogonal() * width * 0.5
	var v := facing * depth * 0.5
	return PackedVector2Array([center-u-v, center+u-v, center+u+v, center-u+v])


func _hip_roof(st: SurfaceTool, pts: PackedVector2Array, height: float, tile: Color) -> void:
	var center := (pts[0] + pts[1] + pts[2] + pts[3]) * 0.25
	var peak := height + clampf(pts[0].distance_to(pts[2]) * 0.10, 0.45, 1.65)
	for i in 4:
		var a := pts[i]
		var b := pts[(i + 1) % 4]
		var face := tile.lightened(0.13 if i % 3 == 0 else 0.0)
		var av := Vector3(a.x, height, a.y)
		var bv := Vector3(b.x, height, b.y)
		var tip := Vector3(center.x, peak, center.y)
		var n := (tip - av).cross(bv - av).normalized()
		for q in [av, bv, tip]:
			_bv(st, q.x, q.y, q.z, n, face)


func _city_building(st: SurfaceTool, footprint: PackedVector2Array, height: float, index: int, site := "") -> void:
	var pts := footprint
	if Geometry2D.is_polygon_clockwise(pts):
		pts = pts.duplicate()
		pts.reverse()
	var colors := [Color("#b08f78"), Color("#b48a75"), Color("#cac1a5"), Color("#84969a"), Color("#a4a984"), Color("#af8d8e"), Color("#bca784")]
	var roofs := [Color("#804b48"), Color("#41495c"), Color("#6d555c"), Color("#95644b"), Color("#666b6c")]
	var wall: Color = colors[index % colors.size()]
	var roof: Color = roofs[(index * 7) % roofs.size()]
	match site:
		"casa_artesao":
			wall = Color("#e3bf6f")
			roof = Color("#815a49")
		"morada_bais":
			wall = Color("#e4bd57")
			roof = Color("#70534b")
		"market":
			wall = Color("#c1a179")
			roof = Color("#78645b")
		"retail", "mall":
			wall = Color("#a6a9a2")
			roof = Color("#6d7275")
		"pharmacy":
			wall = Color("#d2cbb9")
			roof = Color("#566883")
		"supermarket":
			wall = Color("#c3b6a2")
			roof = Color("#71664f")
		"gaspar":
			wall = Color("#c9b593")
			roof = Color("#766575")
		"hotel":
			wall = Color("#bc9e83")
			roof = Color("#777575")
		"museum", "arena":
			wall = Color("#c2bbb0")
			roof = Color("#8e928e")
		"civic":
			wall = Color("#a4a59d")
			roof = Color("#5c7378")
		"tower":
			wall = Color("#acafac")
			roof = Color("#505963")
	var plinth_height := 0.40 if height > 9.0 else 0.25
	_walls(st, pts, plinth_height, wall.darkened(0.28))
	_walls(st, pts, height - 0.27, wall, plinth_height)
	if pts.size() == 4 and height < 6.5 and index % 4 != 0:
		_hip_roof(st, pts, height, roof)
	else:
		_roof(st, pts, height, roof)
		var center := _bbox(pts).get_center()
		if height >= 6.5 and Geometry2D.is_point_in_polygon(center, pts):
			_box_c(st, Vector3(center.x, height + 0.32, center.y), Vector3(1.14, 0.64, 1.1), roof.lightened(0.17), 0.0)
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		var length := a.distance_to(b)
		if length < 0.04:
			continue
		var dir := a.direction_to(b)
		var outward := dir.orthogonal()
		var span := Vector3(dir.x, 0, dir.y)
		var normal := Vector3(outward.x, 0, outward.y)
		var middle := Vector3((a.x + b.x) * 0.5, 0.0, (a.y + b.y) * 0.5)
		_face_c(st, middle + Vector3.UP * (height - 0.135), Vector3.UP * 0.135, span * length * 0.5, roof.darkened(0.20))
		var columns := mini(17 if height > 22.0 else 6, floori(length / 2.65))
		if site == "gaspar":
			for balcony in range(1, 4):
				var level := float(balcony) * height / 4.0
				_face_c(st, middle + normal * 0.075 + Vector3.UP * level, Vector3.UP * 0.14, span * length * 0.5, wall.lightened(0.24))
				_face_c(st, middle + normal * 0.06 + Vector3.UP * (level + 0.35), Vector3.UP * 0.045, span * length * 0.5, Color("#665965"))
		elif site in ["museum", "arena"]:
			_face_c(st, middle + normal * 0.05 + Vector3.UP * (height - 0.5), Vector3.UP * 0.28, span * length * 0.5, wall.lightened(0.17))
		elif site in ["casa_artesao", "morada_bais"]:
			_heritage_facade(st, middle, span, normal, length, height, site == "morada_bais")
			continue
		elif site in ["market", "retail", "mall", "pharmacy", "supermarket"]:
			var fascia := Color("#315982") if site == "pharmacy" else roof.darkened(0.22)
			_face_c(st, middle + normal * 0.04 + Vector3.UP * 2.8, Vector3.UP * 0.38, span * length * 0.46, fascia)
			if site in ["pharmacy", "supermarket"] and length > 4.0:
				_face_c(st, middle + normal * 0.045 + Vector3.UP * 1.35, Vector3.UP * 0.93, span * minf(2.6, length * 0.36), Color("#557178"))
		var floors := maxi(1, roundi(height / 3.1))
		for col in columns:
			var offset := (float(col + 1) / float(columns + 1) - 0.5) * length
			for level in floors:
				var center := middle + span * offset + normal * 0.022
				center.y = (float(level) + 0.53) * (height - 0.48) / float(floors)
				var lit := (index + col * 3 + level * 7) % 11 == 0
				var glass := Color("#c8a067") if lit else Color("#445969")
				_face_c(st, center, Vector3.UP * 0.56, span * 0.45, glass)
				if height > 6.8 or not site.is_empty():
					_face_c(st, center - Vector3.UP * 0.51 + normal * 0.018, Vector3.UP * 0.08, span * 0.56, wall.lightened(0.22))


func _arch_opening(st: SurfaceTool, pos: Vector3, along: Vector3, out: Vector3, half_width: float, body: float, color: Color) -> void:
	_face_c(st, pos + Vector3.UP * (body * 0.5), along * half_width, Vector3.UP * (body * 0.5), color)
	var spring := pos + Vector3.UP * body
	for i in 8:
		var a := float(i) * PI / 8.0
		var b := float(i + 1) * PI / 8.0
		var v1 := spring + along * (cos(a) * half_width) + Vector3.UP * (sin(a) * half_width * 0.68)
		var v2 := spring + along * (cos(b) * half_width) + Vector3.UP * (sin(b) * half_width * 0.68)
		for vertex in [spring, v1, v2]:
			_bv(st, vertex.x, vertex.y, vertex.z, out, color)


func _heritage_facade(st: SurfaceTool, middle: Vector3, along: Vector3, out: Vector3, length: float, height: float, morada: bool) -> void:
	var trim := Color("#eee1c3")
	var wood := Color("#773a38")
	for h in [0.38, height - 0.68, height - 0.20]:
		_face_c(st, middle + out * 0.043 + Vector3.UP * float(h), along * length * 0.5, Vector3.UP * 0.10, trim)
	if morada:
		_face_c(st, middle + out * 0.045 + Vector3.UP * 3.45, along * length * 0.5, Vector3.UP * 0.12, trim)
	var openings := floori(length / 2.7)
	for i in openings:
		var distance := (float(i + 1) / float(openings + 1) - 0.5) * length
		var opening := middle + along * distance + out * 0.05
		var base := 0.26 if i % 3 == 1 or morada else 0.96
		var body := 2.05 if base < 0.4 else 1.52
		_arch_opening(st, opening + Vector3.UP * base, along, out, 0.65, body + 0.02, trim)
		_arch_opening(st, opening + Vector3.UP * (base + 0.08) + out * 0.022, along, out, 0.48, body - 0.12, wood)
		if morada:
			_arch_opening(st, opening + Vector3.UP * 4.06, along, out, 0.61, 1.65, trim)
			_arch_opening(st, opening + Vector3.UP * 4.16 + out * 0.022, along, out, 0.45, 1.45, Color("#364455"))
			var balcony := opening + Vector3.UP * 4.01 + out * 0.31
			_face_c(st, balcony, along * 0.80, out * 0.24, trim)
			_face_c(st, balcony + out * 0.23 + Vector3.UP * 0.59, along * 0.76, Vector3.UP * 0.045, Color("#494541"))
			for j in 6:
				var rail := balcony + along * ((float(j) - 2.5) * 0.275) + out * 0.23 + Vector3.UP * 0.29
				_face_c(st, rail, along * 0.025, Vector3.UP * 0.27, Color("#494541"))


func _make_shops() -> void:
	var k := 0
	for i in range(0, building_polys.size(), 5):
		if k >= SHOP_TYPES.size():
			break
		var c: Vector2 = building_polys[i]["bb"].get_center()
		var near_hq := false
		for p in pois:
			if str(p["id"]) == "central" and c.distance_to(Vector2(float(p["x"]), float(p["y"]))) < 13.0:
				near_hq = true
				break
		if near_hq:
			continue
		var t: Dictionary = SHOP_TYPES[k % SHOP_TYPES.size()]
		var npc_name: String = FIRST_NAMES[k % FIRST_NAMES.size()] + " " + LAST_NAMES[(k * 7) % LAST_NAMES.size()]
		var role: String = ROLES[k % ROLES.size()]
		pois.append({
			"id": "shop_%d" % k,
			"name": str(t["n"]),
			"npc": npc_name,
			"role": role,
			"greeting": "Olá, sou " + npc_name + ", " + role + ".",
			"story": STORIES[k % STORIES.size()],
			"line": STORIES[k % STORIES.size()],
			"look": k % 8,
			"tint": Color.from_hsv(fposmod(float(k) * 0.37, 1.0), 0.25, 1.0),
			"x": c.x, "y": c.y, "snapDist": 40.0
		})
		_shop_front(c, building_polys[i]["pts"], t)
		k += 1


# ---------- trânsito inteligente: não bate no carro da frente ----------

func _car_ahead(i: int, fwd: Vector2) -> bool:
	if fwd == Vector2.ZERO:
		return false
	var me: Vector2 = traffic[i]["pos"]
	var dp := car_pos - me
	if dp.length() < 7.0 and dp.dot(fwd) > 0.0:
		return true
	for j in traffic.size():
		if j == i:
			continue
		var d: Vector2 = traffic[j]["pos"] - me
		if d.length() < 7.0 and d.dot(fwd) > 0.0:
			return true
	return false


# ---------- bairros afastados: ruas e quadras já preenchidas acima ----------


# ---------- uma casinha por quadra ----------

func _access_near(point: Vector2, address: String) -> Array:
	if address.is_empty():
		return _road_near(point, true)
	var name := address.split(",")[0].split(" esquina")[0].strip_edges()
	name = name.replace("Rua Sete de Setembro", "Rua 7 de Setembro").replace("Rua Marechal Cândido Mariano Rondon", "Rua Marechal Rondon")
	var key := Vector2i(floori(point.x / 50.0), floori(point.y / 50.0))
	var best := 390.0
	var result := []
	for dx in range(-8, 9):
		for dy in range(-8, 9):
			for segment in rd_bk.get(key + Vector2i(dx, dy), []):
				if str(segment[4]) != name or str(segment[3]) in ["footway", "pedestrian"]:
					continue
				var place := Geometry2D.get_closest_point_to_segment(point, segment[5], segment[6])
				var distance := point.distance_to(place)
				if distance < best:
					best = distance
					result = [place, segment[1]]
	if not result.is_empty():
		return result
	var closest := 165.0
	for dx in range(-4, 5):
		for dy in range(-4, 5):
			for segment in rd_bk.get(key + Vector2i(dx, dy), []):
				if str(segment[3]) in ["footway", "pedestrian"]:
					continue
				var place := Geometry2D.get_closest_point_to_segment(point, segment[5], segment[6])
				var distance := point.distance_to(place)
				if distance < closest:
					closest = distance
					result = [place, segment[1]]
	return result


func _street_at(q: Vector2) -> String:
	var best := INF
	var label := ""
	var key := Vector2i(floori(q.x / 50.0), floori(q.y / 50.0))
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for segment in rd_bk.get(key + Vector2i(dx, dy), []):
				if str(segment[3]) in ["footway", "pedestrian"]:
					continue
				var nearest := Geometry2D.get_closest_point_to_segment(q, segment[5], segment[6])
				var distance := q.distance_to(nearest)
				if distance < best and distance < float(segment[2]) + 4.0:
					best = distance
					label = str(segment[4]).strip_edges()
	return label


func _road_near(q: Vector2, drivable := false) -> Array:
	# ponto e direção da rua mais próxima (até 60 m); vazio se não houver rua perto
	var best := 60.0
	var bp := Vector2.ZERO
	var bd := Vector2.ZERO
	var found := false
	var kx := floori(q.x / 50.0)
	var ky := floori(q.y / 50.0)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var key := Vector2i(kx + dx, ky + dy)
			if rd_bk.has(key):
				for e in rd_bk[key]:
					if drivable and str(e[3]) == "footway":
						continue
					var dist: float = (e[0] as Vector2).distance_to(q)
					if dist < best:
						best = dist
						bp = e[0]
						bd = e[1]
						found = true
	if not found:
		return []
	return [bp, bd]


# ---------- objetos de rua: carros estacionados, bancos, lixeiras, hidrantes, arbustos ----------

func _place_street_object(path: String, q: Vector2, dir: Vector2, scale_factor: float, align_long_axis: bool) -> bool:
	var ab := _proto_aabb(path)
	if scale_factor <= 0.0:
		return false
	var yaw := atan2(-dir.x, -dir.y)
	if align_long_axis and ab.size.x > ab.size.z:
		yaw += PI * 0.5
	var heading := Vector2(sin(yaw), cos(yaw))
	var shape := _rectangle(q, heading, ab.size.x * scale_factor, ab.size.z * scale_factor)
	if not road_clearance.is_clear(shape) or not _buildings_clear(shape) or _in_water(q):
		return false
	var bas := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale_factor)
	var ctr := ab.get_center()
	var inst := _scene(path).instantiate() as Node3D
	inst.transform = Transform3D(bas, Vector3(q.x, 0.0, q.y) - bas * Vector3(ctr.x, ab.position.y, ctr.z))
	add_child(inst)
	placed_street_objects.append(shape)
	if align_long_axis:
		var facing := atan2(heading.y, heading.x)
		parked_vehicles.append({"node":inst,"pos":q,"path":path,"basis":bas,"offset":Vector3(ctr.x,ab.position.y,ctr.z),
			"heading":facing,"original_heading":facing,"index":parked_vehicles.size()})
		_index_car(parked_vehicles[-1])
	return true


func _index_car(car: Dictionary) -> void:
	var at: Vector2 = car["pos"]
	var cell := Vector2i(floori(at.x / 50.0), floori(at.y / 50.0))
	var index: int = car["index"]
	if car.has("cell"):
		var old: Vector2i = car["cell"]
		if old == cell:
			return
		parked_cells[old].erase(index)
	if not parked_cells.has(cell):
		parked_cells[cell] = []
	parked_cells[cell].append(index)
	car["cell"] = cell


func _nearby_cars(at: Vector2, radius: float) -> Array:
	var low := (at - Vector2.ONE * radius) / 50.0
	var high := (at + Vector2.ONE * radius) / 50.0
	var found := []
	for x in range(floori(low.x), floori(high.x) + 1):
		for y in range(floori(low.y), floori(high.y) + 1):
			found.append_array(parked_cells.get(Vector2i(x, y), []))
	return found


func _fill_abandoned_car_gaps() -> void:
	var car_pool := [PLAYER_CAR, VEHICLE_DIR + "/Car_Blue.glb"]
	for i in pois.size():
		var p: Dictionary = pois[i]
		if not p.has("access_x") or (str(p["id"]) != "central" and not p.get("real_place", false)):
			continue
		var center := Vector2(p["access_x"], p["access_y"])
		if parked_vehicles.any(func(v): return center.distance_squared_to(v["pos"]) < 47.0 * 47.0):
			continue
		var path: String = car_pool[i % car_pool.size()]
		if not ResourceLoader.exists(path):
			continue
		var model := _proto_aabb(path)
		var length := maxf(model.size.x, model.size.z)
		if length <= 0.01:
			continue
		var cell := Vector2i(floori(center.x / 50.0), floori(center.y / 50.0))
		var placed := false
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				for lane in rd_bk.get(cell + Vector2i(dx, dy), []):
					var point: Vector2 = lane[0]
					var distance := center.distance_to(point)
					if distance < 9.0 or distance > 27.0 or str(lane[3]) in ["footway", "trunk", "motorway"]:
						continue
					var facing: Vector2 = lane[1]
					for side in [-1.0, 1.0]:
						var q := point + facing.orthogonal() * (float(lane[2]) + 2.1) * float(side)
						if _blocked(q) or parked_vehicles.any(func(v): return q.distance_squared_to(v["pos"]) < 6.0 * 6.0):
							continue
						if _place_street_object(path, q, facing, CAR_LENGTH / length, true):
							placed = true
							break
					if placed:
						break
				if placed:
					break
			if placed:
				break


func _distribute_abandoned_cars() -> void:
	# Append to the old list so vehicle IDs in existing saves still point to the same cars.
	var districts := {}
	for road_cell in rd_bk:
		var cell := Vector2i(floori(float(road_cell.x) / 3), floori(float(road_cell.y) / 3))
		if not districts.has(cell):
			districts[cell] = []
		for lane in rd_bk[road_cell]:
			if str(lane[3]) in ["residential", "tertiary", "secondary", "living_street"]:
				districts[cell].append(lane)
	var occupied := {}
	for v in parked_vehicles:
		_bk_add(occupied, v["pos"])
	var furnishings := {}
	for shape in placed_street_objects:
		_bk_add(furnishings, _bbox(shape).get_center())
	var models := [PLAYER_CAR, VEHICLE_DIR + "/Car_Blue.glb"]
	var cells := districts.keys()
	cells.sort()
	var added := 0
	for cell in cells:
		var options: Array = districts[cell]
		if options.is_empty():
			continue
		var center := Vector2(cell) * 150.0 + Vector2(75, 75)
		options.sort_custom(func(a, b): return center.distance_squared_to(a[0]) < center.distance_squared_to(b[0]))
		var path: String = models[added % models.size()]
		var bounds := _proto_aabb(path)
		var longest := maxf(bounds.size.x, bounds.size.z)
		if longest <= 0.01:
			continue
		var placed := 0
		for lane in options:
			var lane_point: Vector2 = lane[0]
			if _bk_near(occupied, lane_point, 25.0):
				continue
			var heading: Vector2 = lane[1]
			for side in [-1.0, 1.0]:
				var parked_at := lane_point + heading.orthogonal() * (float(lane[2]) + 4.2) * float(side)
				if not _in_area(parked_at) or _blocked(parked_at) or _bk_near(occupied, parked_at, 26.0) or _bk_near(furnishings, parked_at, 4.5):
					continue
				if _place_street_object(path, parked_at, heading, CAR_LENGTH / longest, true):
					_bk_add(occupied, parked_at)
					placed += 1
					added += 1
					break
			if placed >= 2:
				break
	print("carros adicionais por bairro: ", added)


func _scatter_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 555
	var kk := ["res://assets/kaykit/gltf/bush.gltf", "res://assets/kaykit/gltf/firehydrant.gltf", "res://assets/kaykit/gltf/dumpster.gltf", "res://assets/kaykit/gltf/bench.gltf"]
	var parked := 0
	var props := 0
	for r in roads:
		var kind: String = r["k"]
		if kind == "footway" or kind == "motorway" or kind == "trunk":
			continue
		var rp: Array = r["p"]
		var wd: float = float(ROAD_W.get(kind, 5.0))
		for k in range(rp.size() - 1):
			var a := Vector2(float(rp[k][0]), float(rp[k][1]))
			var b := Vector2(float(rp[k + 1][0]), float(rp[k + 1][1]))
			var d := b - a
			var L := d.length()
			if L < 4.0:
				continue
			var dir := d / L
			var nrm := Vector2(-dir.y, dir.x)
			var t := rng.randf_range(0.0, 10.0)
			while t < L:
				var side := 1.0 if rng.randf() < 0.5 else -1.0
				var q := a + dir * t + nrm * side * (wd * 0.5 + 1.8)
				var roll := rng.randf()
				if not _blocked(q):
					if roll < 0.14 and not veh_paths.is_empty() and parked < 300:
						var path: String = veh_paths[rng.randi() % veh_paths.size()]
						var ab := _proto_aabb(path)
						var longest := maxf(ab.size.x, ab.size.z)
						var bay := q + nrm * side * 2.6
						if longest > 0.01 and _place_street_object(path, bay, dir, CAR_LENGTH / longest, true):
							parked += 1
					elif roll < 0.3 and props < 1500:
						var path: String = kk[rng.randi() % kk.size()]
						var ab := _proto_aabb(path)
						if ab.size.y > 0.01 and _place_street_object(path, q, dir, rng.randf_range(0.65, 1.1) / ab.size.y, false):
							props += 1
				t += rng.randf_range(10.0, 18.0)
	print("carros estacionados: ", parked, " objetos de rua: ", props)


# ---------- pedestres: população perto do jogador ----------

func _random_road_near_car() -> Vector2:
	# escolhe um ponto de rua entre 60 e PED_RANGE metros do carro
	for tries in range(40):
		var r: Array = roads[randi() % roads.size()]["p"]
		if r.size() < 2:
			continue
		var k := randi() % (r.size() - 1)
		var a := Vector2(float(r[k][0]), float(r[k][1]))
		var d := a.distance_to(car_pos)
		if d > 60.0 and d < PED_RANGE:
			return a
	return car_pos + Vector2(80.0, 0.0)


func _road_pts_at(p: Vector2) -> PackedVector2Array:
	# trecho de rua que passa por p, usado como caminho do pedestre
	var best := 1e9
	var pts := PackedVector2Array([p, p + Vector2(10.0, 0.0)])
	for r in roads:
		var rp: Array = r["p"]
		for k in range(rp.size()):
			var q := Vector2(float(rp[k][0]), float(rp[k][1]))
			var dd := q.distance_to(p)
			if dd < best:
				best = dd
				pts = PackedVector2Array()
				for m in range(rp.size()):
					pts.append(Vector2(float(rp[m][0]), float(rp[m][1])))
	return pts


func _car_hits_pedestrian(p: Vector2) -> bool:
	for n in npcs:
		var pos: Vector2 = n["pos"]
		if pos.distance_to(p) < CAR_HIT_DIST:
			return true
	return false


func _car_hits_traffic(p: Vector2) -> bool:
	for c in traffic:
		var pos: Vector2 = c["pos"]
		if pos.distance_to(p) < CAR_HIT_DIST + 1.2:
			return true
	return false


# ---------- caso 1: sistema de quest (individual, com pistas e acusação) ----------

func _setup_survival_places() -> void:
	for point in pois:
		if point.has("access_x"):
			continue
		var pos := Vector2(float(point["x"]), float(point["y"]))
		var road := _access_near(pos, str(point.get("address", ""))) if point.get("real_place", false) else _road_near(pos, true)
		if not road.is_empty():
			var access: Vector2 = road[0]
			point["access_x"] = access.x
			point["access_y"] = access.y
	case_label = Label.new()
	case_label.add_theme_color_override("font_color", Color("#eee0bc"))
	var layer := CanvasLayer.new()
	add_child(layer)
	layer.add_child(case_label)
	minimap = Control.new()
	minimap.custom_minimum_size = Vector2(230, 230)
	minimap.size = Vector2(230, 230)
	minimap.draw.connect(_draw_minimap)
	layer.add_child(minimap)


func _cur_steps() -> Array:
	return CASES[case_idx]["steps"]


func _build_fixed_people() -> void:
	for i in pois.size():
		var p: Dictionary = pois[i]
		var site := Vector2(float(p["x"]), float(p["y"]))
		var access := Vector2(float(p.get("access_x", p["x"])), float(p.get("access_y", p["y"])))
		var towards := access.direction_to(site)
		if towards.is_zero_approx():
			towards = Vector2.RIGHT
		var perch := access
		var found := false
		for lateral in [0.0, 3.5, -3.5, 7.0, -7.0]:
			for distance in [4.5, 5.5, 6.5, 7.5, 9.0]:
				var candidate := access + towards * float(distance) + towards.orthogonal() * float(lateral)
				if not _blocked(candidate) and not _in_water(candidate) and road_clearance.is_clear(_rectangle(candidate, towards, 0.6, 0.6)):
					perch = candidate
					found = true
					break
			if found:
				break
		if p.get("real_place", false):
			perch = _site_entrance(p, access, perch)
		p["npc_pos"] = perch
		if p.get("real_place", false):
			var closest := INF
			for building in building_polys:
				if str(building["site"]) != str(p["id"]):
					continue
				var box: Rect2 = building["bb"]
				var distance := box.get_center().distance_squared_to(perch)
				if distance < closest:
					p["footprint"] = building["pts"]
					closest = distance
		if str(p["id"]) == "central":
			var npc := _person_sprite(2)
			npc.position = Vector3(perch.x, 0.04, perch.y)
			static_people.append(npc)
		_register_sign(str(p["name"]), Vector3(perch.x, 3.1, perch.y))


func _site_entrance(place: Dictionary, from_street: Vector2, fallback: Vector2) -> Vector2:
	for building in city["buildings"]:
		if str(building.get("osm_way", building.get("osm_node", ""))) != str(place["osm_way"]):
			continue
		var shape := _poly(building["p"])
		var best := INF
		var entrance := fallback
		for i in shape.size():
			var a := shape[i]
			var b := shape[(i + 1) % shape.size()]
			var edge := Geometry2D.get_closest_point_to_segment(from_street, a, b)
			var normal := a.direction_to(b).orthogonal()
			for side in [-1.0, 1.0]:
				var candidate := edge + normal * float(side) * 2.2
				var score := from_street.distance_squared_to(candidate)
				if score < best and not _blocked(candidate) and not _in_water(candidate) and road_clearance.is_clear(_rectangle(candidate, normal, 0.65, 0.65)):
					best = score
					entrance = candidate
		return entrance
	return fallback


func _first_case_leads_active() -> bool:
	return case_idx == 0 and case_step > 0 and case_step < 4


func _first_case_lead_at(id: String) -> Dictionary:
	if _first_case_leads_active() and id not in lead_ids:
		for i in range(1, 4):
			var lead: Dictionary = _cur_steps()[i]
			if str(case_pois.get(lead["poi"], "")) == id:
				return lead
	return {}


func _case_text() -> String:
	if intro_state == 1:
		return ""
	if intro_state == 2:
		return "Primeiro dia: saia de casa e vá até a Central de Investigação."
	if case_done:
		return "Todos os casos concluídos"
	var steps := _cur_steps()
	if case_step >= steps.size():
		return ""
	if _first_case_leads_active():
		var pending := PackedStringArray()
		for i in range(1, 4):
			var place: String = steps[i]["poi"]
			if str(case_pois.get(place, "")) not in lead_ids:
				var id := str(case_pois.get(place, ""))
				var address := str(street_names.get(id, ""))
				pending.append(place if id != _target_id() or address.is_empty() else "%s (%s)" % [place, address])
		return "%s · %d/3 diligências\n%s" % [CASES[0]["name"], lead_ids.size(), " • ".join(pending)]
	var objective := str(steps[case_step]["obj"])
	var address := str(street_names.get(_target_id(), ""))
	if not address.is_empty() and address != street_label.text:
		objective += "\n" + address
	return "%s\n%s" % [str(CASES[case_idx]["name"]), objective]


func _target_id() -> String:
	return survival.objective_id()


func _interact() -> void:
	ui_panel.visible = true
	var p: Dictionary = pois[poi_index]
	var id := str(p["id"])
	ui_name.text = str(p.get("npc", ""))
	_set_portrait(p)
	if not case_done and case_step < _cur_steps().size():
		var st: Dictionary = _cur_steps()[case_step]
		if str(st["kind"]) == "accuse" and id == _target_id():
			_open_accuse_menu()
			return
	var lead := _first_case_lead_at(id)
	if not lead.is_empty():
		lead_ids.append(id)
		_talk_case(lead, p)
		return
	if id == _target_id() and not case_done:
		_talk_case(_cur_steps()[case_step], p)
		return
	if p.get("real_place", false):
		ui_name.text = str(p["name"])
		_say(str(p["line"]))
		return
	_open_menu()


func _talk_case(st: Dictionary, p: Dictionary) -> void:
	ui_name.text = str(st["npc"])
	var speaker := p.duplicate()
	speaker["npc"] = st["npc"]
	_set_portrait(speaker)
	_say(str(st["say"]))
	var clue := str(st["clue"])
	if clue != "":
		clues.append(clue)
	case_step += 1
	cached_target_frame = -1
	_save_case()


func _open_accuse_menu() -> void:
	menu_open = true
	ui_menu.visible = true
	for c in ui_menu.get_children():
		c.queue_free()
	_say("Quem levou a chave? Consulte o caderno com C antes de abrir a acusação." if _cur_steps()[case_step].has("proofs") else "Quem você acusa? Você tem uma tentativa.")
	var suspects: Array = _cur_steps()[case_step]["suspects"]
	for who in suspects:
		var b := Button.new()
		b.text = "Acusar " + str(who)
		b.custom_minimum_size = BTN_SZ
		b.pressed.connect(_choose_suspect.bind(str(who)))
		ui_menu.add_child(b)
	var sair := Button.new()
	sair.text = "Recuar"
	sair.custom_minimum_size = BTN_SZ
	sair.pressed.connect(_close_menu)
	ui_menu.add_child(sair)
	ui_panel.visible = true


func _choose_suspect(who: String) -> void:
	var step: Dictionary = _cur_steps()[case_step]
	if not step.has("proofs"):
		_accuse(who)
		return
	for child in ui_menu.get_children():
		ui_menu.remove_child(child)
		child.queue_free()
	_say("Que pista sustenta sua acusação contra %s?" % who)
	for i in step["proofs"].size():
		var button := Button.new()
		button.text = str(step["proofs"][i])
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(280, 52)
		button.pressed.connect(_accuse.bind(who, i))
		ui_menu.add_child(button)
	var back := Button.new()
	back.text = "Voltar aos suspeitos"
	back.pressed.connect(_open_accuse_menu)
	ui_menu.add_child(back)


func _accuse(who: String, proof := -1) -> void:
	var step: Dictionary = _cur_steps()[case_step]
	if step.has("proof") and proof != int(step["proof"]):
		_close_menu()
		_say("Essa pista não liga o suspeito à retirada da chave. Reveja o caderno e volte a falar comigo.")
		return
	_close_menu()
	var culprit := str(_cur_steps()[case_step]["culprit"])
	var msg := ""
	if who == culprit:
		money += 300
		home.money_now = money
		home._save()
		msg = "Caso resolvido. %s foi preso. Recompensa: R$ 300." % who
	else:
		msg = "Acusação errada. %s não tinha ligação com o caso. Você não tem outra tentativa neste caso." % who
	clues.clear()
	lead_ids.clear()
	if case_idx + 1 < CASES.size():
		case_idx += 1
		case_step = 0
		msg += " Novo caso: %s. Fale com o Sargento Lima." % str(CASES[case_idx]["name"])
	else:
		case_done = true
		msg += " Você concluiu todos os casos disponíveis."
	cached_target_frame = -1
	_say(msg)
	_save_case()


func _show_notebook() -> void:
	ui_panel.visible = true
	ui_name.text = "Caderno de anotações"
	if clues.is_empty():
		_say("Nenhuma pista ainda. Fale com as pessoas da cidade.")
	else:
		var txt := ""
		for c in clues:
			txt += "- " + str(c) + "\n"
		_say(txt)
	typed = 9999.0
	ui_text.text = full_line


func _save_case() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"edition": 2, "idx": case_idx, "step": case_step, "done": case_done, "clues": clues, "lead_ids": lead_ids}))


func _load_case() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) == TYPE_DICTIONARY:
		case_idx = clampi(int(data.get("idx", 0)), 0, CASES.size() - 1)
		case_step = clampi(int(data.get("step", 0)), 0, _cur_steps().size())
		case_done = bool(data.get("done", false))
		clues = data.get("clues", [])
		lead_ids = data.get("lead_ids", [])
		if int(data.get("edition", 0)) < 2 and case_idx == 0 and not case_done:
			case_step = 0
			clues = []
			lead_ids = []


# ---------- minimapa: ruas, lugares e a direção do objetivo ----------

func _mm_pos(p: Vector2) -> Vector2:
	var d := p - _actor_pos()
	return minimap.size * 0.5 + Vector2(-d.x + d.y, -(d.x + d.y)) * 0.70710678 * mm_scale


func _draw_minimap() -> void:
	var sz := minimap.size
	var half := sz * 0.5
	minimap.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.10, 0.14, 0.11, 0.92), true)
	var rad := (sz.x * 0.75) / mm_scale
	var view := Rect2(_actor_pos() - Vector2.ONE * rad, Vector2.ONE * rad * 2.0)
	var major := ["motorway", "trunk", "primary", "secondary", "tertiary"]
	for pass_i in 2:
		for ri in roads.size():
			if not view.intersects(road_bb[ri]):
				continue
			var r: Dictionary = roads[ri]
			var kind: String = r["k"]
			if kind == "footway":
				continue
			var big := major.has(kind)
			if (pass_i == 0) == big:
				continue
			var rp: Array = r["p"]
			var col := Color(0.93, 0.86, 0.62) if big else Color(0.72, 0.72, 0.74)
			var w := 6.0 if big else 3.5
			for k in range(rp.size() - 1):
				var a := _mm_pos(Vector2(float(rp[k][0]), float(rp[k][1])))
				var b := _mm_pos(Vector2(float(rp[k + 1][0]), float(rp[k + 1][1])))
				minimap.draw_line(a, b, col, w, true)
	var target_id := _target_id()
	var pulse := 1.0 + 0.25 * sin(Time.get_ticks_msec() / 250.0)
	var previous := half
	for point in route_points:
		var current := _mm_pos(point)
		minimap.draw_line(previous, current, Color("#e7b569"), 4.0)
		previous = current
	for p in pois:
		var pid := str(p["id"])
		var is_t := pid == target_id and not case_done
		var q := _mm_pos(Vector2(float(p.get("access_x", p["x"])), float(p.get("access_y", p["y"]))))
		var inside := Rect2(Vector2(8, 8), sz - Vector2(16, 16)).has_point(q)
		if is_t:
			if not inside:
				var dv := q - half
				var sc := minf((half.x - 14.0) / maxf(absf(dv.x), 0.01), (half.y - 14.0) / maxf(absf(dv.y), 0.01))
				q = half + dv * sc
			minimap.draw_circle(q, 11.0 * pulse, Color(0.1, 0.08, 0.02))
			minimap.draw_circle(q, 8.5 * pulse, Color(1.0, 0.85, 0.2))
		elif inside and not _first_case_lead_at(pid).is_empty():
			minimap.draw_circle(q, 6.5, Color("#edc27d"))
		elif inside:
			minimap.draw_circle(q, 5.0, Color(0.05, 0.1, 0.18))
			minimap.draw_circle(q, 3.5, Color(0.45, 0.75, 1.0))
	var h := Vector2(cos(car_heading), sin(car_heading))
	if on_foot:
		for index in _nearby_cars(walk_pos, 90.0):
			var v: Dictionary = parked_vehicles[index]
			if v["index"] == survival.active_vehicle or walk_pos.distance_squared_to(v["pos"]) > 90.0 * 90.0:
				continue
			var point := _mm_pos(v["pos"])
			if Rect2(Vector2(4, 4), sz - Vector2(8, 8)).has_point(point):
				minimap.draw_rect(Rect2(point - Vector2(3.5, 2.5), Vector2(7, 5)), Color("#7cdfb5"))
	if on_foot and survival.active_vehicle >= 0:
		minimap.draw_circle(_mm_pos(car_pos), 4.0, Color("#ffd284"))
	var sx := (-h.x + h.y) * 0.70710678
	var sy := -(h.x + h.y) * 0.70710678
	var u := Vector2(sx, sy).normalized()
	var n := Vector2(-u.y, u.x)
	var pl := PackedVector2Array([half + u * 13.0, half - u * 9.0 + n * 9.0, half - u * 4.0, half - u * 9.0 - n * 9.0])
	minimap.draw_colored_polygon(pl, Color(1.0, 0.25, 0.2))
	minimap.draw_polyline(PackedVector2Array([pl[0], pl[1], pl[2], pl[3], pl[0]]), Color(1, 1, 1), 1.5)
	minimap.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.92, 0.76, 0.42), false, 3.0)


# ---------- retratos, texturas e sinalização ----------

func _set_portrait(p: Dictionary) -> void:
	ui_portrait.texture = _portrait_tex(str(p.get("npc", "")))
	ui_portrait.self_modulate = Color.WHITE


func _is_female(nm: String) -> bool:
	var first := nm.get_slice(" ", 0).get_slice(",", 0)
	if first in ["Dona", "Vendedora", "Guardiã", "Bióloga", "Guia", "Funcionária", "Atendente"]:
		return true
	if first in ["Seu", "Sargento", "Chefe", "Zelador", "Vendedor", "Relojoeiro", "Guarda-parque", "Guarda", "Curador", "Diácono", "Sacristão", "Servidor", "Funcionário", "Organista", "Padre"]:
		return false
	if first in ["Ivone", "Inês", "Raquel", "Isabel", "Carmen", "Beatriz", "Alice", "Irene", "Ester", "Lurdes", "Liz", "Ruth", "Miriam"]:
		return true
	return first.ends_with("a")


# retrato em pixel-art gerado em código, coerente com o nome e a função do personagem
func _portrait_tex(nm: String) -> Texture2D:
	if portrait_cache.has(nm):
		return portrait_cache[nm]
	var hsh: int = absi(nm.hash())
	var female := _is_female(nm)
	var skins := [Color(0.96, 0.8, 0.66), Color(0.87, 0.67, 0.5), Color(0.72, 0.5, 0.36), Color(0.5, 0.34, 0.24), Color(0.93, 0.76, 0.6)]
	var hairs := [Color(0.12, 0.09, 0.07), Color(0.3, 0.18, 0.1), Color(0.5, 0.32, 0.15), Color(0.2, 0.2, 0.22), Color(0.62, 0.45, 0.2)]
	var skin: Color = skins[hsh % skins.size()]
	var hair: Color = hairs[(hsh / 7) % hairs.size()]
	var cloth := Color.from_hsv(fposmod(float(hsh % 360) / 360.0, 1.0), 0.45, 0.65)
	var old := nm.begins_with("Dona") or nm.begins_with("Seu") or nm.begins_with("Relojoeiro") or nm.begins_with("Zelador")
	if old:
		hair = Color(0.75, 0.75, 0.76)
	var dark := Color(0.1, 0.08, 0.08)
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# ombros e roupa
	var police := nm.begins_with("Sargento")
	var ranger := nm.begins_with("Guarda")
	var cleric := nm.begins_with("Diácono") or nm.begins_with("Sacristão") or nm.begins_with("Padre")
	var lab := nm.begins_with("Bióloga")
	var apron := nm.begins_with("Vendedor") or nm.contains("sobá")
	if police:
		cloth = Color(0.14, 0.2, 0.38)
	elif ranger:
		cloth = Color(0.3, 0.42, 0.22)
	elif cleric:
		cloth = Color(0.1, 0.1, 0.12)
	elif lab:
		cloth = Color(0.93, 0.94, 0.95)
	img.fill_rect(Rect2i(6, 25, 20, 7), cloth)
	img.fill_rect(Rect2i(8, 24, 16, 1), cloth)
	if apron:
		img.fill_rect(Rect2i(11, 26, 10, 6), Color(0.94, 0.93, 0.9))
	if cleric:
		img.fill_rect(Rect2i(14, 24, 4, 2), Color(0.95, 0.95, 0.95))
	if police:
		img.fill_rect(Rect2i(7, 25, 4, 2), Color(0.85, 0.7, 0.2))
		img.fill_rect(Rect2i(21, 25, 4, 2), Color(0.85, 0.7, 0.2))
		img.fill_rect(Rect2i(19, 28, 3, 3), Color(0.85, 0.7, 0.2))
	# pescoço e cabeça
	img.fill_rect(Rect2i(14, 21, 4, 4), skin.darkened(0.12))
	img.fill_rect(Rect2i(10, 9, 12, 13), skin)
	img.fill_rect(Rect2i(11, 22, 10, 1), skin)
	img.fill_rect(Rect2i(9, 14, 1, 4), skin)
	img.fill_rect(Rect2i(22, 14, 1, 4), skin)
	# cabelo
	if female:
		img.fill_rect(Rect2i(9, 6, 14, 5), hair)
		img.fill_rect(Rect2i(8, 8, 3, 16), hair)
		img.fill_rect(Rect2i(21, 8, 3, 16), hair)
		img.fill_rect(Rect2i(10, 10, 5, 2), hair)
		if old:
			img.fill_rect(Rect2i(13, 3, 6, 4), hair)
	else:
		img.fill_rect(Rect2i(10, 7, 12, 3), hair)
		img.fill_rect(Rect2i(9, 8, 2, 5), hair)
		img.fill_rect(Rect2i(21, 8, 2, 5), hair)
	# rosto
	img.fill_rect(Rect2i(12, 14, 2, 2), dark)
	img.fill_rect(Rect2i(18, 14, 2, 2), dark)
	img.fill_rect(Rect2i(12, 12, 3, 1), hair.darkened(0.2))
	img.fill_rect(Rect2i(17, 12, 3, 1), hair.darkened(0.2))
	img.fill_rect(Rect2i(15, 16, 2, 2), skin.darkened(0.15))
	if female:
		img.fill_rect(Rect2i(14, 19, 4, 1), Color(0.75, 0.22, 0.25))
		img.fill_rect(Rect2i(9, 17, 1, 2), Color(0.9, 0.8, 0.3))
		img.fill_rect(Rect2i(22, 17, 1, 2), Color(0.9, 0.8, 0.3))
	else:
		img.fill_rect(Rect2i(14, 20, 4, 1), Color(0.5, 0.25, 0.22))
		if police or hsh % 3 == 0:
			img.fill_rect(Rect2i(13, 18, 6, 1), hair.darkened(0.1))
		if not police and hsh % 5 == 0:
			img.fill_rect(Rect2i(11, 19, 10, 3), hair.darkened(0.1))
			img.fill_rect(Rect2i(14, 20, 4, 1), Color(0.5, 0.25, 0.22))
	if hsh % 4 == 1 or nm.begins_with("Curador") or nm.begins_with("Relojoeiro") or lab:
		img.fill_rect(Rect2i(11, 13, 4, 1), dark)
		img.fill_rect(Rect2i(17, 13, 4, 1), dark)
		img.fill_rect(Rect2i(11, 16, 4, 1), dark)
		img.fill_rect(Rect2i(17, 16, 4, 1), dark)
		img.fill_rect(Rect2i(15, 14, 2, 1), dark)
	# chapéus
	if police:
		img.fill_rect(Rect2i(9, 4, 14, 5), Color(0.12, 0.17, 0.33))
		img.fill_rect(Rect2i(8, 9, 16, 1), dark)
		img.fill_rect(Rect2i(15, 5, 2, 3), Color(0.9, 0.75, 0.2))
	elif ranger:
		img.fill_rect(Rect2i(10, 4, 12, 5), Color(0.42, 0.34, 0.2))
		img.fill_rect(Rect2i(6, 9, 20, 1), Color(0.36, 0.28, 0.16))
	var tex := ImageTexture.create_from_image(img)
	portrait_cache[nm] = tex
	return tex


func _noise_tex(base: Color, amp: float, freq: float) -> ImageTexture:
	var nz := FastNoiseLite.new()
	nz.frequency = freq
	nz.seed = 7
	var img := Image.create(128, 128, false, Image.FORMAT_RGB8)
	for x in 128:
		for y in 128:
			var v := 1.0 + nz.get_noise_2d(float(x), float(y)) * amp
			img.set_pixel(x, y, Color(base.r * v, base.g * v, base.b * v))
	return ImageTexture.create_from_image(img)


func _tex_mat(t: Texture2D) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = t
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _quad_w(st: SurfaceTool, a: Vector2, b: Vector2, w: float, y: float) -> void:
	var d := b - a
	if d.length() < 0.01:
		return
	var pp := Vector2(-d.y, d.x).normalized() * w * 0.5
	for q in [a + pp, a - pp, b + pp, a - pp, b - pp, b + pp]:
		st.set_color(Color.WHITE)
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(q.x, y, q.y))


func _quad_c(st: SurfaceTool, a: Vector2, b: Vector2, w: float, y: float, col: Color) -> void:
	var d := b - a
	if d.length() < 0.01:
		return
	var pp := Vector2(-d.y, d.x).normalized() * w * 0.5
	for q in [a + pp, a - pp, b + pp, a - pp, b - pp, b + pp]:
		st.set_color(col)
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(q.x, y, q.y))


func _face_c(st: SurfaceTool, c: Vector3, u: Vector3, v: Vector3, col: Color) -> void:
	var nrm := u.cross(v).normalized()
	for q in [c - u - v, c + u - v, c + u + v, c - u - v, c + u + v, c - u + v]:
		st.set_color(col)
		st.set_normal(nrm)
		st.add_vertex(q)


# caixa colorida dentro de um SurfaceTool (yaw: o eixo z local aponta para (sin, cos))
func _box_c(st: SurfaceTool, c: Vector3, s: Vector3, col: Color, yaw: float) -> void:
	var bx := Vector3(cos(yaw), 0.0, -sin(yaw)) * s.x * 0.5
	var bz := Vector3(sin(yaw), 0.0, cos(yaw)) * s.z * 0.5
	var by := Vector3(0.0, s.y * 0.5, 0.0)
	_face_c(st, c + bx, by, bz, col)
	_face_c(st, c - bx, bz, by, col)
	_face_c(st, c + bz, bx, by, col)
	_face_c(st, c - bz, by, bx, col)
	_face_c(st, c + by, bz, bx, col)


func _dashes(st: SurfaceTool, a: Vector2, sdir: Vector2, t0: float, t1: float, on: float, gap: float, w: float, col: Color) -> void:
	var t := t0
	while t < t1 - 0.5:
		_quad_c(st, a + sdir * t, a + sdir * minf(t + on, t1), w, 0.07, col)
		t += on + gap


# sinalização viária: eixos, bordas, faixas de pedestre, linhas de retenção, placas PARE e semáforos
func _build_markings() -> void:
	var mst := SurfaceTool.new()
	mst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sst := SurfaceTool.new()
	sst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hst := SurfaceTool.new()
	hst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var gst := SurfaceTool.new()
	gst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n_posts := 0
	var lst: Array = []
	for li in range(6):
		var l := SurfaceTool.new()
		l.begin(Mesh.PRIMITIVE_TRIANGLES)
		lst.append(l)
	var white := Color(0.9, 0.9, 0.88)
	var yellow := Color(0.92, 0.72, 0.1)
	var major_k := ["primary", "secondary", "trunk", "motorway", "primary_link", "secondary_link"]
	var skip_k := ["footway", "pedestrian"]
	# 1) nós da malha: cada ponto guarda os braços de rua que saem dele
	var nodes := {}
	for r in roads:
		var kind: String = r["k"]
		if kind in skip_k:
			continue
		var rp: Array = r["p"]
		var n := rp.size()
		for k in range(n):
			var q := Vector2(float(rp[k][0]), float(rp[k][1]))
			var key := Vector2i(roundi(q.x), roundi(q.y))
			if not nodes.has(key):
				nodes[key] = {"p": q, "arms": []}
			var arms: Array = nodes[key]["arms"]
			for kk in [k - 1, k + 1]:
				if kk < 0 or kk >= n:
					continue
				var o := Vector2(float(rp[kk][0]), float(rp[kk][1]))
				if (o - q).length() > 0.5:
					arms.append({"d": (o - q).normalized(), "k": kind, "l": (o - q).length()})
	# 2) linhas ao longo das ruas (param antes dos cruzamentos)
	for r in roads:
		var kind: String = r["k"]
		if kind in skip_k or kind == "service":
			continue
		var rp: Array = r["p"]
		var wd: float = float(ROAD_W.get(kind, 5.0))
		var major: bool = kind in major_k
		var lamp_d := 14.0
		var lamp_side := 1.0
		for k in range(rp.size() - 1):
			var a := Vector2(float(rp[k][0]), float(rp[k][1]))
			var b := Vector2(float(rp[k + 1][0]), float(rp[k + 1][1]))
			var seg_len := (b - a).length()
			if seg_len < 2.0:
				continue
			var sdir := (b - a) / seg_len
			var perp := Vector2(-sdir.y, sdir.x)
			var t0 := 0.0
			var t1 := seg_len
			var ka := Vector2i(roundi(a.x), roundi(a.y))
			var kb := Vector2i(roundi(b.x), roundi(b.y))
			if nodes.has(ka) and (nodes[ka]["arms"] as Array).size() >= 3:
				t0 = 9.0
			if nodes.has(kb) and (nodes[kb]["arms"] as Array).size() >= 3:
				t1 = seg_len - 9.0
			if t1 - t0 < 2.0:
				continue
			while lamp_d < seg_len:
				if lamp_d > t0 + 2.0 and lamp_d < t1 - 2.0:
					var arm := -perp * lamp_side
					var lp := a + sdir * lamp_d - arm * (wd * 0.5 + 0.9)
					if not road_clearance.is_clear(_rectangle(lp, sdir, 0.42, 0.42)):
						lamp_d += 36.0
						continue
					var ly := atan2(arm.x, arm.y)
					_box_c(sst, Vector3(lp.x, 3.2, lp.y), Vector3(0.16, 6.4, 0.16), Color(0.3, 0.31, 0.33), ly)
					_box_c(sst, Vector3(lp.x + arm.x * 0.9, 6.3, lp.y + arm.y * 0.9), Vector3(0.12, 0.12, 1.8), Color(0.3, 0.31, 0.33), ly)
					_box_c(hst, Vector3(lp.x + arm.x * 1.7, 6.2, lp.y + arm.y * 1.7), Vector3(0.5, 0.18, 0.8), Color.WHITE, ly)
					var pc := lp + arm * 2.4
					for f in range(10):
						var a0 := TAU * float(f) / 10.0
						var a1 := TAU * float(f + 1) / 10.0
						gst.set_color(Color(1, 1, 1, 1))
						gst.set_normal(Vector3.UP)
						gst.add_vertex(Vector3(pc.x, 0.0, pc.y))
						gst.set_color(Color(1, 1, 1, 0))
						gst.set_normal(Vector3.UP)
						gst.add_vertex(Vector3(pc.x + cos(a0) * 9.0, 0.0, pc.y + sin(a0) * 9.0))
						gst.set_color(Color(1, 1, 1, 0))
						gst.set_normal(Vector3.UP)
						gst.add_vertex(Vector3(pc.x + cos(a1) * 9.0, 0.0, pc.y + sin(a1) * 9.0))
					lamp_side = -lamp_side
					n_posts += 1
				lamp_d += 36.0
			lamp_d -= seg_len
			var pa := a + sdir * t0
			var pb := a + sdir * t1
			if major:
				_quad_c(mst, pa + perp * 0.17, pb + perp * 0.17, 0.13, 0.07, yellow)
				_quad_c(mst, pa - perp * 0.17, pb - perp * 0.17, 0.13, 0.07, yellow)
				for sd in [-1.0, 1.0]:
					_quad_c(mst, pa + perp * sd * (wd * 0.5 - 0.3), pb + perp * sd * (wd * 0.5 - 0.3), 0.13, 0.07, white)
					_dashes(mst, a + perp * sd * (wd * 0.25), sdir, t0, t1, 3.0, 6.0, 0.13, white)
			else:
				_dashes(mst, a, sdir, t0, t1, 2.5, 5.0, 0.15, yellow)
	# 3) cruzamentos: faixa de pedestre, linha de retenção, placa PARE ou semáforo
	var n_lights := 0
	var n_signs := 0
	for key in nodes.keys():
		var e: Dictionary = nodes[key]
		var arms: Array = e["arms"]
		if arms.size() < 3:
			continue
		var node: Vector2 = e["p"]
		var n_major := 0
		var maxw := 0.0
		for a in arms:
			if str(a["k"]) in major_k:
				n_major += 1
			maxw = maxf(maxw, float(ROAD_W.get(str(a["k"]), 5.0)))
		var lights := n_major >= 3
		var ref := Vector2.ZERO
		if lights:
			ref = arms[0]["d"]
			var sk := Vector2i(floori(node.x / 50.0), floori(node.y / 50.0))
			if not sig_bk.has(sk):
				sig_bk[sk] = []
			sig_bk[sk].append([node, ref])
		var idx := 0
		for a in arms:
			idx += 1
			var dir: Vector2 = a["d"]
			var kind2: String = a["k"]
			if kind2 == "service":
				continue
			var half: float = float(ROAD_W.get(kind2, 5.0)) * 0.5
			var off: float = maxw * 0.5 + 1.2
			if float(a["l"]) < off + 5.5:
				continue
			var perp := Vector2(-dir.y, dir.x)
			# faixa de pedestre: listras no sentido da rua
			var o := -half + 0.6
			while o <= half - 0.6:
				_quad_c(mst, node + dir * off + perp * o, node + dir * (off + 2.6) + perp * o, 0.45, 0.07, white)
				o += 0.9
			# linha de retenção na pista de quem chega ao cruzamento
			var sl := node + dir * (off + 3.5)
			_quad_c(mst, sl - perp * 0.1, sl - perp * (half - 0.3), 0.4, 0.07, white)
			var sp := node + dir * (off + 4.0) - perp * (half + 1.1)
			var yaw := atan2(dir.x, dir.y)
			if not road_clearance.is_clear(_rectangle(sp, dir, 0.45, 0.45)):
				continue
			if lights:
				n_lights += 1
				_box_c(sst, Vector3(sp.x, 2.2, sp.y), Vector3(0.16, 4.4, 0.16), Color(0.2, 0.2, 0.22), yaw)
				_box_c(sst, Vector3(sp.x, 4.3, sp.y), Vector3(0.5, 1.4, 0.5), Color(0.1, 0.1, 0.11), yaw)
				var grp := 0 if absf(dir.dot(ref)) > 0.7 else 1
				_box_c(sst, Vector3(sp.x + dir.x * 0.65, 5.05, sp.y + dir.y * 0.65), Vector3(0.5, 0.1, 1.6), Color(0.1, 0.1, 0.11), yaw)
				for li in range(3):
					var fp := sp + dir * 0.28
					_box_c(lst[grp * 3 + li], Vector3(fp.x, 4.78 - float(li) * 0.46, fp.y), Vector3(0.38, 0.38, 0.06), Color.WHITE, yaw)
					var tp := sp + dir * (0.2 + float(li) * 0.46)
					_box_c(lst[grp * 3 + li], Vector3(tp.x, 5.14, tp.y), Vector3(0.38, 0.08, 0.38), Color.WHITE, yaw)
			elif float(ROAD_W.get(kind2, 5.0)) < maxw or (n_major == 0 and idx > 2):
				n_signs += 1
				_box_c(sst, Vector3(sp.x, 1.3, sp.y), Vector3(0.1, 2.6, 0.1), Color(0.6, 0.6, 0.62), yaw)
				_box_c(sst, Vector3(sp.x, 2.75, sp.y), Vector3(1.0, 1.0, 0.06), Color(0.92, 0.92, 0.9), yaw)
				var fq := sp + dir * 0.04
				_box_c(sst, Vector3(fq.x, 2.75, fq.y), Vector3(0.86, 0.86, 0.06), Color(0.8, 0.1, 0.1), yaw)
				var fr := sp + dir * 0.08
				_box_c(sst, Vector3(fr.x, 2.75, fr.y), Vector3(0.62, 0.16, 0.04), Color(0.95, 0.95, 0.93), yaw)
	_add_mesh(mst, _mat(Color.WHITE, true), 0.0)
	_add_mesh(sst, _mat(Color.WHITE, true), 0.0)
	lamp_mats.clear()
	for li in range(6):
		var lmat := StandardMaterial3D.new()
		lmat.cull_mode = BaseMaterial3D.CULL_DISABLED
		lamp_mats.append(lmat)
		_add_mesh(lst[li], lmat, 0.0)
	sig_state = -1
	lamp_head_mat = StandardMaterial3D.new()
	lamp_head_mat.albedo_color = Color(0.85, 0.85, 0.8)
	lamp_head_mat.emission = Color(1.0, 0.82, 0.5)
	lamp_head_mat.emission_energy_multiplier = 2.0
	lamp_head_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_add_mesh(hst, lamp_head_mat, 0.0)
	pool_mat = StandardMaterial3D.new()
	pool_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pool_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pool_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	pool_mat.vertex_color_use_as_albedo = true
	pool_mat.albedo_color = Color(1.0, 0.74, 0.38, 0.5)
	pool_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	night_root = Node3D.new()
	night_root.visible = false
	add_child(night_root)
	_add_mesh(gst, pool_mat, 0.09, night_root)
	# farol do carro do jogador (só aparece à noite)
	var fgs := SurfaceTool.new()
	fgs.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sdx in [-0.7, 0.7]:
		var pts3 := [Vector3(sdx, 0.0, -2.0), Vector3(sdx - 4.5, 0.0, -18.0), Vector3(sdx + 4.5, 0.0, -18.0)]
		var als := [0.9, 0.0, 0.0]
		for k in range(3):
			fgs.set_color(Color(1, 1, 1, als[k]))
			fgs.set_normal(Vector3.UP)
			fgs.add_vertex(pts3[k])
	head_glow = MeshInstance3D.new()
	head_glow.mesh = fgs.commit()
	var hgm := pool_mat.duplicate() as StandardMaterial3D
	hgm.albedo_color = Color(1.0, 0.95, 0.75, 0.55)
	head_glow.material_override = hgm
	head_glow.visible = false
	add_child(head_glow)
	print("postes: ", n_posts)
	print("sinalizacao: semaforos ", n_lights, " placas PARE ", n_signs)


# tecla T: leva o carro até o próximo marco da cidade (passeio turístico)
func _tour_next() -> void:
	var lm: Dictionary = LANDMARKS[tour_i % LANDMARKS.size()]
	tour_i += 1
	var target := Vector2(float(lm["x"]), float(lm["y"]))
	var best := 1e9
	var bp := target
	for r in roads:
		if str(r["k"]) in ["footway", "pedestrian", "service"]:
			continue
		for q in r["p"]:
			var v := Vector2(float(q[0]), float(q[1]))
			var d := v.distance_to(target)
			if d > 16.0 and d < best:
				best = d
				bp = v
	car_pos = bp
	car_root.position = Vector3(car_pos.x, 0.0, car_pos.y)
	cam_focus = car_root.position


# ---------- marcos da cidade modelados em código ----------

func _landmark_spot(c: Vector2) -> bool:
	for lm in LANDMARKS:
		var cl := float(lm.get("clear", 0.0))
		if cl > 0.0 and c.distance_to(Vector2(float(lm.get("mx", lm["x"])), float(lm.get("my", lm["y"])))) < cl:
			return true
	return false


func _lb(_st: SurfaceTool, _base: Vector2, _yaw: float, off: Vector3, size: Vector3, col: Color) -> void:
	landmark_parts.append({"offset": off, "size": size, "color": col})


func _lm_roof(st: SurfaceTool, base: Vector2, yaw: float, c: Vector3, w: float, l: float, col: Color) -> void:
	var steps := 6
	for i in range(steps):
		var f := 1.0 - float(i) / float(steps)
		_lb(st, base, yaw, Vector3(c.x, c.y + 0.25 + float(i) * 0.5, c.z), Vector3(maxf(w * f, 0.5), 0.5, l), col)


func _cross(st: SurfaceTool, b: Vector2, yaw: float, at: Vector3, s: float) -> void:
	var dark := Color(0.16, 0.14, 0.13)
	_lb(st, b, yaw, at + Vector3(0, 1.2 * s, 0), Vector3(0.26 * s, 2.4 * s, 0.26 * s), dark)
	_lb(st, b, yaw, at + Vector3(0, 1.6 * s, 0), Vector3(1.3 * s, 0.26 * s, 0.26 * s), dark)


# igrejas com silhuetas diferentes (frente no +z local)
func _church(st: SurfaceTool, b: Vector2, yaw: float, style: String) -> void:
	var white := Color(0.9, 0.89, 0.84)
	var stone := Color(0.62, 0.6, 0.55)
	var tile := Color(0.62, 0.26, 0.16)
	var glass := Color(0.25, 0.4, 0.58)
	var wood := Color(0.3, 0.18, 0.1)
	var dark := Color(0.16, 0.14, 0.13)
	if style == "batista":
		_lb(st, b, yaw, Vector3(0, 0.3, 0), Vector3(16.0, 0.6, 26.0), stone)
		_lb(st, b, yaw, Vector3(0, 4.6, -1.0), Vector3(13.0, 8.0, 20.0), white)
		_lm_roof(st, b, yaw, Vector3(0, 8.6, -1.0), 14.0, 21.0, Color(0.45, 0.2, 0.14))
		for i in range(4):
			_lb(st, b, yaw, Vector3(-4.5 + float(i) * 3.0, 4.1, 10.6), Vector3(0.9, 7.0, 0.9), white)
		_lb(st, b, yaw, Vector3(0, 7.9, 10.6), Vector3(12.0, 0.8, 1.6), white)
		for i in range(4):
			_lb(st, b, yaw, Vector3(0, 8.55 + float(i) * 0.5, 10.6), Vector3(11.0 - float(i) * 2.8, 0.5, 1.4), white)
		_lb(st, b, yaw, Vector3(0, 0.75, 12.2), Vector3(11.0, 0.3, 1.6), stone)
		_lb(st, b, yaw, Vector3(0, 2.2, 9.06), Vector3(2.2, 3.2, 0.12), wood)
		for i in range(5):
			for sd in [-1.0, 1.0]:
				_lb(st, b, yaw, Vector3(sd * 6.55, 4.6, -8.0 + float(i) * 3.6), Vector3(0.12, 3.4, 1.0), glass)
		_cross(st, b, yaw, Vector3(0, 10.5, 10.6), 0.8)
	elif style == "presbiteriana":
		var brick := Color(0.62, 0.3, 0.22)
		var slate := Color(0.25, 0.25, 0.28)
		_lb(st, b, yaw, Vector3(0, 4.0, 0), Vector3(9.0, 8.0, 18.0), brick)
		for i in range(8):
			_lb(st, b, yaw, Vector3(0, 8.3 + float(i) * 0.6, 0), Vector3(9.6 * (1.0 - float(i) / 8.0) + 0.4, 0.6, 18.6), slate)
		_lb(st, b, yaw, Vector3(0, 8.0, 10.5), Vector3(4.0, 16.0, 4.0), brick)
		_lb(st, b, yaw, Vector3(0, 13.5, 12.53), Vector3(1.2, 2.4, 0.1), dark)
		for i in range(7):
			var sw := 4.2 * (1.0 - float(i) / 7.0) + 0.3
			_lb(st, b, yaw, Vector3(0, 16.55 + float(i) * 1.1, 10.5), Vector3(sw, 1.1, sw), slate)
		_cross(st, b, yaw, Vector3(0, 24.0, 10.5), 0.8)
		_lb(st, b, yaw, Vector3(0, 1.7, 12.55), Vector3(1.8, 3.4, 0.12), wood)
		_lb(st, b, yaw, Vector3(0, 3.7, 12.55), Vector3(1.0, 0.6, 0.12), wood)
		for i in range(5):
			for sd in [-1.0, 1.0]:
				_lb(st, b, yaw, Vector3(sd * 4.55, 4.2, -7.0 + float(i) * 3.2), Vector3(0.12, 3.6, 0.8), glass)
	elif style == "adventista":
		var beige := Color(0.88, 0.84, 0.74)
		_lb(st, b, yaw, Vector3(0, 3.2, 0), Vector3(14.0, 6.4, 20.0), beige)
		_lb(st, b, yaw, Vector3(0, 6.6, 0), Vector3(14.8, 0.4, 20.8), Color(0.3, 0.3, 0.32))
		for i in range(9):
			_lb(st, b, yaw, Vector3(0, 0.6 + float(i) * 1.2, 10.3), Vector3(13.0 * (1.0 - float(i) / 9.0) + 1.0, 1.2, 0.8), Color(0.95, 0.95, 0.93))
		_lb(st, b, yaw, Vector3(0, 3.6, 10.75), Vector3(3.0, 7.0, 0.1), glass)
		_lb(st, b, yaw, Vector3(8.6, 7.0, 9.5), Vector3(0.7, 14.0, 0.7), white)
		_lb(st, b, yaw, Vector3(8.6, 11.5, 9.5), Vector3(2.8, 0.6, 0.7), white)
		for i in range(5):
			for sd in [-1.0, 1.0]:
				_lb(st, b, yaw, Vector3(sd * 7.05, 3.6, -7.6 + float(i) * 3.6), Vector3(0.12, 2.6, 1.6), glass)
	elif style == "catedral":
		var conc := Color(0.84, 0.82, 0.78)
		_lb(st, b, yaw, Vector3(0, 0.2, 4.0), Vector3(30.0, 0.4, 44.0), Color(0.72, 0.7, 0.66))
		_lb(st, b, yaw, Vector3(0, 6.0, -4.0), Vector3(20.0, 12.0, 30.0), conc)
		_lm_roof(st, b, yaw, Vector3(0, 12.0, -4.0), 21.0, 30.6, Color(0.5, 0.3, 0.22))
		for i in range(5):
			_lb(st, b, yaw, Vector3(0, 1.6 + float(i) * 3.2, 11.6), Vector3(20.0 - float(i) * 2.4, 3.2, 1.2), white)
		_lb(st, b, yaw, Vector3(0, 7.2, 12.25), Vector3(5.0, 9.0, 0.12), glass)
		_lb(st, b, yaw, Vector3(0, 1.9, 12.3), Vector3(3.2, 3.6, 0.14), wood)
		_cross(st, b, yaw, Vector3(0, 17.4, 11.6), 1.2)
		_lb(st, b, yaw, Vector3(14.0, 11.0, 10.0), Vector3(3.6, 22.0, 3.6), conc)
		_lb(st, b, yaw, Vector3(14.0, 18.5, 11.83), Vector3(1.4, 3.0, 0.1), dark)
		_lb(st, b, yaw, Vector3(14.0, 22.3, 10.0), Vector3(4.2, 0.6, 4.2), white)
		_cross(st, b, yaw, Vector3(14.0, 22.6, 10.0), 1.2)
		for i in range(6):
			for sd in [-1.0, 1.0]:
				_lb(st, b, yaw, Vector3(sd * 10.05, 6.5, -16.0 + float(i) * 4.6), Vector3(0.12, 7.0, 1.4), glass)
		# estátua de Santo Antônio na praça em frente
		_lb(st, b, yaw, Vector3(0, 1.2, 20.0), Vector3(1.8, 1.6, 1.8), stone)
		_lb(st, b, yaw, Vector3(0, 3.1, 20.0), Vector3(0.8, 2.2, 0.6), Color(0.42, 0.28, 0.18))
		_lb(st, b, yaw, Vector3(0, 4.5, 20.0), Vector3(0.5, 0.5, 0.5), Color(0.8, 0.65, 0.5))
	else:
		var yellow := Color(0.92, 0.82, 0.55)
		_lb(st, b, yaw, Vector3(0, 4.5, 0), Vector3(11.0, 9.0, 22.0), yellow)
		_lm_roof(st, b, yaw, Vector3(0, 9.0, 0), 11.8, 22.6, tile)
		for sd in [-1.0, 1.0]:
			_lb(st, b, yaw, Vector3(sd * 4.2, 7.5, 11.2), Vector3(3.4, 15.0, 3.4), yellow)
			_lb(st, b, yaw, Vector3(sd * 4.2, 11.5, 12.93), Vector3(1.0, 2.0, 0.1), dark)
			_lb(st, b, yaw, Vector3(sd * 4.2, 15.25, 11.2), Vector3(3.9, 0.5, 3.9), white)
			for i in range(4):
				var pw := 3.4 - float(i) * 0.8
				_lb(st, b, yaw, Vector3(sd * 4.2, 15.9 + float(i) * 0.8, 11.2), Vector3(pw, 0.8, pw), tile)
			_cross(st, b, yaw, Vector3(sd * 4.2, 18.7, 11.2), 0.7)
		_lb(st, b, yaw, Vector3(0, 5.5, 11.6), Vector3(5.0, 11.0, 1.0), yellow)
		for i in range(3):
			_lb(st, b, yaw, Vector3(0, 11.4 + float(i) * 0.8, 11.6), Vector3(5.0 - float(i) * 1.6, 0.8, 1.0), white)
		_lb(st, b, yaw, Vector3(0, 8.2, 12.15), Vector3(1.8, 1.8, 0.1), glass)
		_lb(st, b, yaw, Vector3(0, 1.8, 12.15), Vector3(2.2, 3.6, 0.12), wood)
		for i in range(5):
			for sd in [-1.0, 1.0]:
				_lb(st, b, yaw, Vector3(sd * 5.55, 5.0, -8.0 + float(i) * 4.0), Vector3(0.12, 3.4, 1.0), glass)


func _build_landmarks() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cream := Color(0.86, 0.8, 0.66)
	var stone := Color(0.62, 0.6, 0.55)
	var dark := Color(0.16, 0.14, 0.13)
	var tile := Color(0.62, 0.26, 0.16)
	var glass := Color(0.3, 0.45, 0.6)
	var n := 0
	for lm in LANDMARKS:
		var kind := str(lm["model"])
		if kind == "":
			continue
		landmark_parts.clear()
		var b := Vector2(float(lm.get("mx", lm["x"])), float(lm.get("my", lm["y"])))
		var rd := _road_dir_at(b)
		var yaw := atan2(rd.x, rd.y) if rd.length() > 0.1 else 0.0
		if lm.has("yaw"):
			yaw = float(lm["yaw"])
		elif kind in ["igreja", "casarao", "portal"]:
			var info := _road_near(b)
			if not info.is_empty():
				var to_road: Vector2 = (info[0] as Vector2) - b
				if to_road.length() > 1.0:
					var fd := to_road.normalized()
					yaw = atan2(fd.x, fd.y)
					b = (info[0] as Vector2) - fd * float(lm.get("back", 24.0))
		if kind == "relogio":
			_lb(st, b, yaw, Vector3(0, 0.25, 0), Vector3(4.4, 0.5, 4.4), stone)
			_lb(st, b, yaw, Vector3(0, 0.75, 0), Vector3(3.2, 0.5, 3.2), stone)
			_lb(st, b, yaw, Vector3(0, 5.0, 0), Vector3(1.9, 8.0, 1.9), cream)
			_lb(st, b, yaw, Vector3(0, 2.2, 0), Vector3(2.2, 0.3, 2.2), stone)
			_lb(st, b, yaw, Vector3(0, 8.9, 0), Vector3(2.3, 0.3, 2.3), stone)
			_lb(st, b, yaw, Vector3(0, 10.3, 0), Vector3(2.6, 2.6, 2.6), cream)
			for sd in [-1.0, 1.0]:
				_lb(st, b, yaw, Vector3(0, 10.3, sd * 1.32), Vector3(1.9, 1.9, 0.08), Color(0.96, 0.96, 0.92))
				_lb(st, b, yaw, Vector3(0, 10.6, sd * 1.38), Vector3(0.12, 0.8, 0.06), dark)
				_lb(st, b, yaw, Vector3(0.25, 10.3, sd * 1.38), Vector3(0.6, 0.12, 0.06), dark)
				_lb(st, b, yaw, Vector3(sd * 1.32, 10.3, 0), Vector3(0.08, 1.9, 1.9), Color(0.96, 0.96, 0.92))
				_lb(st, b, yaw, Vector3(sd * 1.38, 10.6, 0), Vector3(0.06, 0.8, 0.12), dark)
				_lb(st, b, yaw, Vector3(sd * 1.38, 10.3, 0.25), Vector3(0.06, 0.12, 0.6), dark)
			_lb(st, b, yaw, Vector3(0, 11.75, 0), Vector3(3.0, 0.3, 3.0), stone)
			_lb(st, b, yaw, Vector3(0, 12.3, 0), Vector3(2.0, 0.8, 2.0), cream)
			_lb(st, b, yaw, Vector3(0, 13.0, 0), Vector3(1.1, 0.6, 1.1), tile)
			_lb(st, b, yaw, Vector3(0, 13.9, 0), Vector3(0.2, 1.2, 0.2), dark)
		elif kind == "obelisco":
			_lb(st, b, yaw, Vector3(0, 0.2, 0), Vector3(6.0, 0.4, 6.0), stone)
			_lb(st, b, yaw, Vector3(0, 0.6, 0), Vector3(4.4, 0.4, 4.4), stone)
			_lb(st, b, yaw, Vector3(0, 1.7, 0), Vector3(2.6, 1.8, 2.6), Color(0.7, 0.68, 0.62))
			_lb(st, b, yaw, Vector3(0, 1.7, 1.33), Vector3(1.4, 0.9, 0.06), Color(0.35, 0.25, 0.12))
			for i in range(9):
				var wd := lerpf(1.7, 0.75, float(i) / 8.0)
				_lb(st, b, yaw, Vector3(0, 3.3 + float(i) * 1.4, 0), Vector3(wd, 1.4, wd), Color(0.74, 0.72, 0.66))
			_lb(st, b, yaw, Vector3(0, 15.5, 0), Vector3(0.5, 0.6, 0.5), Color(0.74, 0.72, 0.66))
			_lb(st, b, yaw, Vector3(0, 16.0, 0), Vector3(0.22, 0.5, 0.22), Color(0.74, 0.72, 0.66))
		elif kind == "igreja":
			_church(st, b, yaw, str(lm.get("style", "saojose")))
		elif kind == "bioparque":
			var silver := Color(0.74, 0.77, 0.8)
			_lb(st, b, yaw, Vector3(0, 0.3, 0), Vector3(126.0, 0.6, 72.0), Color(0.7, 0.69, 0.66))
			for i in range(-9, 10):
				var t := float(i) / 9.6
				var wv := sqrt(1.0 - t * t)
				var hh := 15.0 * wv + 3.0
				var dd := 38.0 * wv + 8.0
				var sc := silver if i % 2 == 0 else Color(0.67, 0.7, 0.74)
				var ox := float(i) * 6.2
				_lb(st, b, yaw, Vector3(ox, 0.6 + hh * 0.5, -4.0), Vector3(6.25, hh, dd), sc)
				_lb(st, b, yaw, Vector3(ox, 0.6 + hh + 0.8, -4.0), Vector3(6.25, 1.6, dd * 0.72), sc)
				_lb(st, b, yaw, Vector3(ox, 0.6 + hh + 2.2, -4.0), Vector3(6.25, 1.2, dd * 0.42), sc)
				if absi(i) <= 5:
					_lb(st, b, yaw, Vector3(ox, 4.2, -4.0 + dd * 0.5 + 0.1), Vector3(6.25, 5.6, 0.2), Color(0.16, 0.3, 0.44))
			_lb(st, b, yaw, Vector3(0, 6.0, 25.0), Vector3(20.0, 0.5, 10.0), Color(0.93, 0.93, 0.9))
			for sx in [-1.0, 1.0]:
				_lb(st, b, yaw, Vector3(sx * 9.0, 3.2, 29.0), Vector3(0.6, 5.4, 0.6), Color(0.93, 0.93, 0.9))
				_lb(st, b, yaw, Vector3(sx * 38.0, 0.66, 28.0), Vector3(30.0, 0.12, 11.0), Color(0.2, 0.45, 0.62))
		elif kind == "portal":
			var wood := Color(0.36, 0.22, 0.12)
			for sx in [-1.0, 1.0]:
				_lb(st, b, yaw, Vector3(sx * 5.0, 3.0, 0), Vector3(0.8, 6.0, 0.8), wood)
			_lb(st, b, yaw, Vector3(0, 6.3, 0), Vector3(12.4, 0.7, 1.0), wood)
			_lb(st, b, yaw, Vector3(0, 5.0, 0.1), Vector3(8.4, 1.5, 0.2), Color(0.13, 0.36, 0.22))
			_lb(st, b, yaw, Vector3(0, 5.0, 0.24), Vector3(6.6, 0.3, 0.06), Color(0.95, 0.95, 0.9))
			var tcols := [Color(0.7, 0.16, 0.1), Color(0.85, 0.62, 0.15), Color(0.12, 0.1, 0.1)]
			for i in range(3):
				var tx := -9.0 - float(i) * 2.2
				_lb(st, b, yaw, Vector3(tx, 2.3, -3.0), Vector3(0.8, 4.6, 0.8), tcols[i])
				_lb(st, b, yaw, Vector3(tx, 3.2, -3.0), Vector3(0.95, 0.4, 0.95), tcols[(i + 1) % 3])
				_lb(st, b, yaw, Vector3(tx, 4.8, -3.0), Vector3(1.1, 0.4, 1.1), tcols[(i + 2) % 3])
			_lb(st, b, yaw, Vector3(11.0, 1.5, -5.0), Vector3(5.0, 3.0, 4.0), cream)
			for i in range(4):
				var kw := 7.0 - float(i) * 1.6
				_lb(st, b, yaw, Vector3(11.0, 3.3 + float(i) * 0.6, -5.0), Vector3(kw, 0.6, kw), Color(0.55, 0.42, 0.2))
		elif kind == "casarao":
			var ochre := Color(0.85, 0.7, 0.42)
			_lb(st, b, yaw, Vector3(0, 3.8, 0), Vector3(16.0, 7.6, 10.0), ochre)
			_lb(st, b, yaw, Vector3(0, 7.75, 0), Vector3(16.8, 0.3, 10.8), Color(0.93, 0.9, 0.82))
			_lm_roof(st, b, yaw, Vector3(0, 7.9, 0), 10.6, 16.6, tile)
			for i in range(6):
				var ox := -6.25 + float(i) * 2.5
				_lb(st, b, yaw, Vector3(ox, 5.6, 5.05), Vector3(1.0, 1.9, 0.12), Color(0.2, 0.3, 0.38))
				_lb(st, b, yaw, Vector3(ox, 6.7, 5.05), Vector3(1.3, 0.2, 0.16), Color(0.93, 0.9, 0.82))
				if i != 2 and i != 3:
					_lb(st, b, yaw, Vector3(ox, 2.0, 5.05), Vector3(1.0, 1.9, 0.12), Color(0.2, 0.3, 0.38))
			_lb(st, b, yaw, Vector3(0, 1.6, 5.05), Vector3(2.2, 3.2, 0.14), Color(0.3, 0.18, 0.1))
			_lb(st, b, yaw, Vector3(0, 4.1, 5.5), Vector3(15.0, 0.2, 1.0), Color(0.93, 0.9, 0.82))
			_lb(st, b, yaw, Vector3(0, 4.7, 5.95), Vector3(15.0, 0.1, 0.1), dark)
		elif kind == "coreto":
			_lb(st, b, yaw, Vector3(0, 0.4, 0), Vector3(7.0, 0.8, 7.0), stone)
			_lb(st, b, yaw, Vector3(0, 0.9, 0), Vector3(6.0, 0.2, 6.0), Color(0.75, 0.73, 0.68))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					_lb(st, b, yaw, Vector3(sx * 2.6, 2.6, sz * 2.6), Vector3(0.3, 3.4, 0.3), Color(0.92, 0.92, 0.9))
			_lb(st, b, yaw, Vector3(0, 4.4, 0), Vector3(6.6, 0.3, 6.6), Color(0.92, 0.92, 0.9))
			for i in range(4):
				var wr := 6.0 - float(i) * 1.5
				_lb(st, b, yaw, Vector3(0, 4.8 + float(i) * 0.5, 0), Vector3(wr, 0.5, wr), tile)
			# chafariz ao lado
			_lb(st, b, yaw, Vector3(14.0, 0.3, 0), Vector3(6.0, 0.6, 6.0), stone)
			_lb(st, b, yaw, Vector3(14.0, 0.62, 0), Vector3(5.2, 0.1, 5.2), Color(0.3, 0.55, 0.75))
			_lb(st, b, yaw, Vector3(14.0, 1.2, 0), Vector3(0.6, 1.8, 0.6), stone)
			_lb(st, b, yaw, Vector3(14.0, 2.1, 0), Vector3(1.8, 0.2, 1.8), stone)
		elif kind == "feira":
			var red := Color(0.75, 0.12, 0.1)
			_lb(st, b, yaw, Vector3(0, 0.1, 0), Vector3(16.0, 0.2, 60.0), Color(0.5, 0.48, 0.45))
			for i in range(6):
				var oz := -25.0 + float(i) * 10.0
				for sx in [-1.0, 1.0]:
					_lb(st, b, yaw, Vector3(sx * 6.5, 2.0, oz - 4.0), Vector3(0.3, 4.0, 0.3), Color(0.85, 0.85, 0.82))
					_lb(st, b, yaw, Vector3(sx * 4.6, 0.6, oz), Vector3(2.4, 1.2, 6.0), Color(0.55, 0.38, 0.22))
					_lb(st, b, yaw, Vector3(sx * 4.6, 2.9, oz), Vector3(3.2, 0.2, 7.0), [red, Color(0.95, 0.8, 0.2), Color(0.2, 0.5, 0.3)][i % 3])
				_lm_roof(st, b, yaw, Vector3(0, 4.0, oz), 14.0, 9.6, Color(0.7, 0.2, 0.15))
			# portal de entrada
			for sx in [-1.0, 1.0]:
				_lb(st, b, yaw, Vector3(sx * 5.0, 3.5, 32.0), Vector3(0.7, 7.0, 0.7), red)
			_lb(st, b, yaw, Vector3(0, 6.6, 32.0), Vector3(13.0, 0.6, 0.9), red)
			_lb(st, b, yaw, Vector3(0, 7.4, 32.0), Vector3(15.0, 0.5, 1.2), dark)
			_lb(st, b, yaw, Vector3(0, 5.5, 32.0), Vector3(10.6, 0.4, 0.5), red)
		if _place_landmark(st, b, yaw, str(lm["id"])):
			n += 1
	_add_mesh(st, _mat(Color.WHITE, true), 0.0)
	print("marcos modelados fora da pista: ", n)


func _place_landmark(st: SurfaceTool, desired: Vector2, yaw: float, id: String) -> bool:
	if landmark_parts.is_empty():
		return false
	var local := Rect2()
	var tallest := 0.0
	for part in landmark_parts:
		var off: Vector3 = part["offset"]
		var size: Vector3 = part["size"]
		local = local.merge(Rect2(Vector2(off.x - size.x * 0.5, off.z - size.z * 0.5), Vector2(size.x, size.z)))
		tallest = maxf(tallest, off.y + size.y * 0.5)
	var facing := Vector2(sin(yaw), cos(yaw))
	var tangent := facing.orthogonal()
	var mid := local.get_center()
	var base := desired
	var shape := PackedVector2Array()
	for radius in range(0, 105, 4):
		var samples := 1 if radius == 0 else 16
		for i in samples:
			base = desired + Vector2.RIGHT.rotated(TAU * float(i) / float(samples)) * float(radius)
			shape = _rectangle(base + tangent * mid.x + facing * mid.y, facing, local.size.x, local.size.y)
			if road_clearance.is_clear(shape) and _buildings_clear(shape) and not _in_water(base):
				for part in landmark_parts:
					var off: Vector3 = part["offset"]
					var world := base + tangent * off.x + facing * off.z
					_box_c(st, Vector3(world.x, off.y, world.y), part["size"], part["color"], yaw)
				_add_bpoly(shape, tallest, "", id)
				_bk_add(bld_bk, base)
				for poi in pois:
					if str(poi["id"]) == id:
						poi["mx"] = base.x
						poi["my"] = base.y
						break
				return true
	push_warning("Sem espaço livre para o modelo de %s." % id)
	return false


# ---------- texturas de chão sem emenda (asfalto, grama, calçada) ----------

func _tile_noise(nz: FastNoiseLite, x: float, y: float, w: float) -> float:
	var fx := x / w
	var fy := y / w
	return (nz.get_noise_2d(x, y) * (1.0 - fx) * (1.0 - fy) + nz.get_noise_2d(x - w, y) * fx * (1.0 - fy)
		+ nz.get_noise_2d(x, y - w) * (1.0 - fx) * fy + nz.get_noise_2d(x - w, y - w) * fx * fy)


func _surface_tex(kind: String) -> ImageTexture:
	var sz := 64
	var big := FastNoiseLite.new()
	big.seed = 11
	big.frequency = 0.012
	var mid := FastNoiseLite.new()
	mid.seed = 23
	mid.frequency = 0.06
	var fine := FastNoiseLite.new()
	fine.seed = 37
	fine.frequency = 0.45
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var img := Image.create(sz, sz, false, Image.FORMAT_RGB8)
	for x in sz:
		for y in sz:
			var fx := float(x)
			var fy := float(y)
			var nb := _tile_noise(big, fx, fy, float(sz))
			var nm := _tile_noise(mid, fx, fy, float(sz))
			var nf := _tile_noise(fine, fx, fy, float(sz))
			var c := Color.WHITE
			if kind == "asfalto":
				var v := 0.235 + nb * 0.035 + nm * 0.02 + nf * 0.03
				var sp := rng.randf()
				if sp < 0.019:
					v += 0.055
				elif sp > 0.975:
					v -= 0.06
				c = Color(v * 0.94, v * 0.98, v * 1.14)
			elif kind == "calcada":
				var v2 := 0.56 + nb * 0.04 + nf * 0.035
				if x % 16 == 0 or y % 16 == 0:
					v2 -= 0.13
				c = Color(v2 * 1.03, v2 * 0.94, v2 * 0.83)
			else:
				var g := 0.31 + nb * 0.08 + nm * 0.035 + nf * 0.025
				var dry := clampf(0.5 + nb * 1.6, 0.0, 1.0)
				c = Color(g * lerpf(0.94, 1.23, dry), g * 0.95, g * 0.76)
				if kind == "parque":
					c = Color(g * 0.78, g * 1.16, g * 0.82)
				if rng.randf() < 0.045:
					c = c.darkened(0.12)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _smooth_mat(t: Texture2D) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = t
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


# ---------- objetos sempre encostados no chão ----------

func _ground(inst: Node3D) -> void:
	var box := _aabb_of(inst)
	inst.position.y -= box.position.y


# ---------- materiais e texturas gerados em código (Godot nativo, sem download) ----------

func _flat_mat(c: Color) -> StandardMaterial3D:
	var key := str(c)
	if not flat_cache.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		flat_cache[key] = m
	return flat_cache[key]


func _glass_mat() -> StandardMaterial3D:
	if not flat_cache.has("glass"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.55, 0.75, 0.85)
		m.emission_enabled = true
		m.emission = Color(1.0, 0.85, 0.55)
		m.emission_energy_multiplier = 0.5
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		flat_cache["glass"] = m
	return flat_cache["glass"]


func _box_node(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	return mi


# ---------- fachada de loja: toldo, vitrine iluminada e placa com o nome ----------

func _shop_front(c: Vector2, footprint: PackedVector2Array, t: Dictionary) -> void:
	var rd := _road_near(c, true)
	if rd.is_empty():
		return
	var target: Vector2 = rd[0]
	var front := Vector2.ZERO
	var n := Vector2.ZERO
	var span := 0.0
	var best := INF
	for i in footprint.size():
		var a := footprint[i]
		var b := footprint[(i + 1) % footprint.size()]
		if a.distance_to(b) < 4.8:
			continue
		var middle := (a + b) * 0.5
		var face := a.direction_to(b).orthogonal()
		if face.dot(target - middle) < 0.0:
			face = -face
		var distance := middle.distance_squared_to(target)
		if distance < best:
			best = distance
			n = face
			front = middle + face * 0.035
			span = minf(a.distance_to(b) - 0.2, 4.6)
	if n == Vector2.ZERO or not road_clearance.is_clear(_rectangle(front + n * 0.89, n, span, 1.82)):
		return
	var root := Node3D.new()
	root.position = Vector3(front.x, 0.0, front.y)
	root.rotation.y = atan2(n.x, n.y)
	add_child(root)
	root.add_child(_box_node(Vector3(4.6, 0.25, 1.8), Vector3(0.0, 3.1, 0.9), _flat_mat(t["awn"])))
	root.add_child(_box_node(Vector3(4.0, 1.8, 0.12), Vector3(0.0, 1.4, 0.06), _glass_mat()))
	root.add_child(_box_node(Vector3(4.4, 0.8, 0.15), Vector3(0.0, 4.1, 0.08), _flat_mat(t["sign"])))
	root.set_meta("interior", str(t["n"]))


# ---------- seta de direcionamento até o objetivo da quest ----------

func _update_goal_arrow() -> void:
	var tid := _target_id()
	var found := false
	var tp := Vector2.ZERO
	if tid != "":
		for p in pois:
			if str(p["id"]) == tid:
				tp = Vector2(float(p.get("access_x", p["x"])), float(p.get("access_y", p["y"])))
				if on_foot:
					tp = p.get("npc_pos", tp)
				found = true
				break
	var here := _actor_pos()
	if tid != route_target or here.distance_squared_to(route_origin) > 30.0 * 30.0:
		route_target = tid
		route_origin = here
		route_points = road_route.route(here, tp) if found and not on_foot else PackedVector2Array()
	if on_foot:
		route_points.clear()
	while route_points.size() > 1 and here.distance_to(route_points[0]) < 9.0:
		route_points.remove_at(0)
	var next := route_points[0] if not route_points.is_empty() else tp
	var d := next - here
	nav_has = found and tp.distance_to(here) > 7.0
	nav_dir = d.normalized() if nav_has else Vector2.ZERO


# ---------- trilha sonora: loop noir gerado em código (acordes menores, baixo e chiado de vinil) ----------

func _start_music() -> void:
	var rate := 22050
	var n := rate * 16
	var data := PackedByteArray()
	data.resize(n * 2)
	var chords := [[57, 60, 64, 67], [50, 53, 57, 60], [52, 56, 59, 62], [57, 60, 64, 67]]
	for i in n:
		var t := float(i) / float(rate)
		var bar := int(t / 4.0) % 4
		var s := 0.0
		for note in chords[bar]:
			var f := 440.0 * pow(2.0, (float(note) - 69.0) / 12.0)
			s += sin(TAU * f * t) * 0.05
		var root := 440.0 * pow(2.0, (float(chords[bar][0]) - 12.0 - 69.0) / 12.0)
		s += sin(TAU * root * t) * 0.25 * exp(-fmod(t, 1.0) * 3.0)
		s += (randf() * 2.0 - 1.0) * 0.01
		data.encode_s16(i * 2, int(clampf(s * 0.8, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = n
	wav.data = data
	var player := AudioStreamPlayer.new()
	player.stream = wav
	player.volume_db = -14.0
	add_child(player)
	player.play()
