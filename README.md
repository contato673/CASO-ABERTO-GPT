# Campo Grande · Zona de Quarentena

Sobrevivência isométrica nas ruas de Campo Grande, Mato Grosso do Sul.

[**Jogar no navegador ou no celular**](https://contato673.github.io/CASO-ABERTO-GPT/) · [Versão Windows](versoes/Caso-Aberto-Windows.zip) · [Capturas de teste](testes-visuais/sobrevivencia/)

Em um jogo novo, crie seu sobrevivente e leia o bilhete de Bia. Esta atualização de interiores conserva o save da publicação anterior. Em um jogo novo, a história começa perto do Posto Barão, na Rua Barão do Rio Branco. A primeira missão pede um kit de primeiros socorros na Pague Menos da Rua 13 de Maio. O minimapa marca o destino. Em locais trancados, quebrar um vidro libera a busca e alerta infectados próximos.

| Controle | Ação |
| --- | --- |
| WASD, setas ou joystick | Caminhar ou dirigir |
| Enter ou botão Entrar | Entrar em uma edificação próxima |
| E ou botão de interação | Interagir com móveis, falar ou investigar |
| F ou botão do veículo | Inspecionar, roubar, entrar ou descer do carro parado |
| Espaço ou botão de ataque | Golpear ou disparar |
| T, botão direito ou Mirar | Exibir a trajetória da arma de fogo. Toque no cenário para ajustar a direção |
| R ou Carregar na mochila | Usar uma caixa do calibre da arma |
| I ou ícone da mochila | Abrir a grade e tocar num item para usá-lo, equipá-lo ou vesti-lo |
| Esc ou Fechar | Fechar a janela |

Saúde, fome, sede e energia afetam recuperação e movimento. A mochila tem 18 espaços. O saque varia por categoria de construção e volta entre 2 e 6 horas reais depois que o estoque é esvaziado. A contagem continua com o jogo fechado. Os carros consomem combustível. Estacione e chegue perto do carro em uso para abastecer. O motor e a quebra de vidro podem chamar infectados.

Na mochila, escolha **Equipar** ou **Guardar arma · Usar punhos**. A faca aparece no Mercadão, e a pistola e a munição podem ser encontradas no Pátio Central Shopping. Cada disparo gasta uma munição e pode atrair infectados de longe.

Nos interiores, o saque aparece no cenário e a mochila continua disponível. As roupas vêm do saque e aparecem no personagem, inclusive depois de recarregar o jogo.

Os quadradinhos verdes no minimapa indicam carros próximos. Os encontros com sobreviventes são raros. Alguns fogem dos infectados e conversam com você, enquanto outros atacam. O minimapa mostra vias, carros e o objetivo ativo. Os infectados têm animações de caminhada e sons que vêm da posição deles na rua.

Ao interagir com o **Posto Barão**, escolha **Entrar em casa** no mesmo menu das missões. Cada conta do Big Field tem seu próprio interior, com móveis e baú separados. Ao sair, você volta ao posto. No menu **Mobiliar**, use duas peças da mochila para montar um móvel e escolher onde colocá-lo. A casa é salva neste navegador ou aparelho.

A campanha **A última transmissão** tem 16 missões de busca, entrega e reconhecimento. Os quatro contratos de abastecimento depois da campanha podem ser repetidos após 20 minutos. O diário está disponível na mochila, no Posto Barão e em casa. Mochila, necessidades, estoque, carros e reputação são salvos no dispositivo. A rede do abrigo é uma progressão local para um jogador.

## Editar

1. Com a cópia original em mãos, copie **assets/pack/** para o mesmo caminho deste projeto.
2. Importe **project.godot** no Godot 4.7.2.
3. Os recursos opcionais de sobrevivência ficam em **assets/survival_local/**, ignorados pelo Git. Os créditos e a origem de cada pack estão na [revisão](REVISAO.md).
4. Use os presets **Windows** e **Web** nos templates da mesma versão. Para publicar o Web, atualize os arquivos da pasta **docs/** e o ZIP em **versoes/**.

Dados cartográficos © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright), sob ODbL.

## Alpha cooperativo

A versão do GitHub Pages inicia a campanha individual. O serviço do alpha abre o jogo em **/alpha/** e exige conta. Só há dez convites de uso único. Um WebSocket autenticado compartilha posição, infectados, dano e distrações sonoras entre os jogadores. Senhas com salt e hash scrypt e sessões com expiração ficam no PostgreSQL privado da infraestrutura. Inventário, casa e campanha são locais, separados por conta e por publicação. O saque, munição, memória dos NPCs e veículos têm estado individual neste alpha.

Entre no servidor [Big Field](https://campo-grande-quarentena-alpha-uza6.onrender.com/alpha/) com um convite de uso único. Os losangos azuis no minimapa indicam outros jogadores na rua.

A pistola usa 9 mm, a escopeta usa calibre 12 e o fuzil usa 5,56 mm. As armas de fogo e as caixas aparecem separadamente no saque. Perto do baú físico, use **Abrir baú**. Morrer reinicia mochila, baú e campanha e volta à criação do sobrevivente.

No celular, o botão pontilhado abre a roda de itens. No teclado, use **Q**. As habilidades têm XP por prática e por estudo, com vantagem inicial da profissão. A fabricação mostra materiais, ferramenta, bancada e nível exigidos em cada receita. A bancada fica na casa.

O arquivo `render.yaml` define o serviço com WebSocket e seu PostgreSQL. O caminho de saúde é `/health`. Em desenvolvimento local, `ALPHA_LOCAL_DEV=1` permite usar um banco isolado apontado por `ALPHA_SQLITE`. A implantação externa exige `DATABASE_URL` e os hashes de convites. Para criar outros convites, use códigos aleatórios de alta entropia e inclua apenas seus hashes SHA-256 em `ALPHA_INVITE_HASHES`. Na implantação use a mesma origem para a página, o login e o WebSocket.

## Explorar edificações

Aproxime-se da fachada e escolha **Entrar**. Se a porta estiver trancada, é possível quebrar o vidro. A entrada permanece aberta nas próximas visitas. Dentro do prédio, caminhe até o móvel e toque no objeto para coletar ou use **E**. A geladeira, o armário e o gabinete de remédios guardam itens diferentes. Alguns locais estão vazios. As escadas dão acesso aos pisos disponíveis, e as pias, sofás e camas têm ações ao se aproximar.

O mapa usa plantas internas reutilizáveis, selecionadas pelo identificador do imóvel, com contornos e divisões por tipologia. A cidade também recebeu adereços do Urban Ruins e peças voxel de rua do HVNBNN, posicionados fora das faixas de rodagem. A distribuição dos itens respeita a categoria do edifício e o ciclo de reposição. As escolas correspondem a etiquetas existentes nos arquivos do OpenStreetMap fornecidos. O botão **Missão** recolhe ou expande o objetivo.

Os sprites internos usam as animações CC0 de Hormelz e os móveis CC0 de PtDesigns. A edição de jogo inclui peças de ThirdAngle, Classroom & School, Urban Ruins e HVNBNN nos termos dos respectivos packs. Para reconstruir o export com os packs licenciados somente para uso em jogo, execute `python scripts/importar_interiores.py` com Pillow instalado e os arquivos ZIP originais em Downloads. As texturas restritas ficam em `assets/interiores_locais/` e têm alternativas internas caso os arquivos não estejam disponíveis.

Os sobreviventes de rua usam quadros animados a partir do pacote [HCG Low Poly Law Enforcement](https://hcg-digital-arts.itch.io/hcg-low-poly-law-enforcement), de HCG_BurgessSimcraft. Os seis modelos também podem ser selecionados na criação ou em **Sua casa → Aparência do sobrevivente**.
