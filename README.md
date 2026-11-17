# Campo Grande · Zona de Quarentena

Sobrevivência isométrica nas ruas de Campo Grande, Mato Grosso do Sul.

[**Jogar no navegador ou no celular**](https://contato673.github.io/CASO-ABERTO-GPT/) · [Versão Windows](versoes/Caso-Aberto-Windows.zip) · [Capturas de teste](testes-visuais/sobrevivencia/)

Você começa a pé no abrigo da Rua Barão do Rio Branco. A primeira missão pede um kit de primeiros socorros na Pague Menos da Rua 13 de Maio. O minimapa marca o destino. Em locais trancados, quebrar um vidro libera a busca e alerta infectados próximos.

| Controle | Ação |
| --- | --- |
| WASD, setas ou joystick | Caminhar ou dirigir |
| E, tocar na construção próxima ou botão de interação | Ver o estoque externo ou falar no abrigo |
| F ou Roubar / Entrar / Descer | Assumir um carro próximo ou sair dele com o veículo parado |
| Espaço ou mira na tela | Atacar com o equipamento disponível |
| I ou ícone da mochila | Ver suprimentos, usar itens e trocar a arma na mão |
| Esc ou Fechar | Fechar a janela |

Saúde, fome, sede e energia afetam recuperação e movimento. A mochila tem 18 espaços. O saque varia por categoria de construção e volta entre 2 e 6 horas reais depois que o estoque é esvaziado. A contagem continua com o jogo fechado. Os carros consomem combustível. Estacione e chegue perto do carro em uso para abastecer. O motor e a quebra de vidro podem chamar infectados.

Na mochila, escolha **Equipar** ou **Guardar arma · Usar punhos**. A faca aparece no Mercadão, e a pistola e a munição podem ser encontradas no Pátio Central Shopping. Cada disparo gasta uma munição e pode atrair infectados de longe.

Para vasculhar uma casa, aproxime-se da fachada e use o botão de interação. Se estiver trancada, quebrar o vidro chama a atenção dos infectados. Dentro do menu de esconderijo você pode descansar, lavar as mãos, trocar de roupa e sair por uma janela quando houver espaço livre. As roupas vêm do saque e aparecem no personagem, inclusive depois de recarregar o jogo.

Os quadradinhos verdes no minimapa indicam carros próximos. Os encontros com sobreviventes são raros. Alguns fogem dos infectados e conversam com você, enquanto outros atacam. O minimapa mostra vias, carros e o objetivo ativo. Os infectados têm animações de caminhada e sons que vêm da posição deles na rua.

No Posto Barão, abra **Baú pessoal** a pé para guardar ou retirar até 60 itens. O conteúdo do baú é salvo no dispositivo e permanece após a derrota do personagem.

Há três entregas para o abrigo. Depois da sequência, novos contratos ficam disponíveis após 20 minutos. Mochila, necessidades, estoque, carros e reputação são salvos no dispositivo. A rede do abrigo é uma progressão local para um jogador.

## Editar

1. Com a cópia original em mãos, copie **assets/pack/** para o mesmo caminho deste projeto.
2. Importe **project.godot** no Godot 4.7.2.
3. Os recursos opcionais de sobrevivência ficam em **assets/survival_local/**, ignorados pelo Git. Os créditos e a origem de cada pack estão na [revisão](REVISAO.md).
4. Use os presets **Windows** e **Web** nos templates da mesma versão. Para publicar o Web, atualize os arquivos da pasta **docs/** e o ZIP em **versoes/**.

Dados cartográficos © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright), sob ODbL.
