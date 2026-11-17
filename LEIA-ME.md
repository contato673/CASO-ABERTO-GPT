# Caso Aberto · Campo Grande

## Jogar

No Windows, abra **Caso Aberto - Campo Grande.exe**. Crie o detetive e selecione **Começar investigação**. A Central é o primeiro destino.

| Controle | Ação |
| --- | --- |
| W/A/S/D ou setas | Dirigir |
| E | Conversar ou investigar no local indicado |
| C | Abrir o caderno de pistas |
| Esc | Fechar o diálogo |
| N | Avançar três horas na iluminação, para teste |

O ponto dourado marca o destino. A linha dourada mostra o caminho calculado pelas ruas e a seta aponta para a próxima direção. A primeira ocorrência permite investigar os três locais em qualquer ordem. Ao voltar à Central, escolha o suspeito e a evidência que sustenta a acusação. O jogo grava as diligências concluídas no perfil da edição Campo Grande.

## O que a revisão encontrou e corrigiu

| Área | Problema encontrado | Alteração |
| --- | --- | --- |
| Visibilidade | O carro era renderizado somente em profundidade normal e podia sumir atrás de construções ou veículos. | Câmera mais elevada, carro remodelado, marcadores na posição do jogador e silhueta dourada nos pixels encobertos. |
| Prédios e escala | Modelos genéricos eram esticados para ocupar lotes. Em alguns casos, o volume visível e a colisão ficavam em lugares diferentes. | Edifícios do mapa usam a mesma implantação para a malha e a colisão. Alturas e janelas foram ajustadas. As casas e comércios autorais usam dimensões próximas às dos lotes. |
| Pista e calçada | Prédios, fachadas, tendas, postes e veículos estacionados tinham regras de posição independentes. Em cruzamentos, testar apenas o centro de um objeto deixava a borda entrar na pista. | O gerador testa a área inteira contra os segmentos e larguras das vias. Recorta pegadas que atravessam a pista, alinha fachadas pelo contorno e procura espaço livre para cada marco. |
| Densidade | O preenchimento produzia volumes repetitivos, alguns muito altos para quadras residenciais. | 5.005 lotes procedurais com alturas menores e mais variedade de telhados. A Central, duas casas e o comércio com toldo foram modelados no Blender e exportados para Godot. |
| Direção de arte | Materiais, modelos e iluminação seguiam estilos visuais diferentes. | Paleta comum em tons de terracota, ardósia e verde, vegetação modelada para o jogo e renderização 3D pixelada, com texto e minimapa legíveis. |
| Investigação | Os casos avançavam numa sequência fixa de conversas e o primeiro usava um prédio escolhido por proximidade como estação. | O primeiro caso passa pelo Museu dos Trabalhadores Ferroviários, Feira Central e Relógio da 14 de Julho. O jogador escolhe a ordem das diligências, reúne pistas e precisa fundamentar a acusação. |
| Navegação | A indicação apontava em linha reta para o local, inclusive através de prédios. | O destino tem um ponto de parada junto à rua. O minimapa calcula a rota pelo grafo viário e indica o próximo trecho. Trechos desconectados usam a direção geral do destino. |

A história, a Central e os personagens do caso são ficcionais. Os marcos foram estilizados, e a posição de algumas maquetes recebeu ajustes locais para manter as pistas livres. O mapa inclui 1.444 trechos de rua e caminho, e 1.016 implantações de origem antes do tratamento geométrico. Dados de mapa © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright), sob ODbL.

## Validação

- Verificação geométrica de 6.033 estruturas e 1.800 objetos posicionados. Nenhuma interseção com as faixas de circulação no conjunto auditado.
- Verificação visual no Godot com o carro em vista, atrás de uma construção alta e atrás de um veículo alto de teste.
- Teste do primeiro caso com as diligências em ordem alternativa, rotas válidas entre os destinos, recuperação do progresso salvo e duas tentativas de apresentar evidência: uma insuficiente e outra aceita.
- A versão exportada iniciou no Windows. No navegador local, criei o detetive, dirigi até a Central e recebi as três diligências do Sargento Lima.
- Os demais casos continuam com a estrutura linear original. A presença dos destinos foi verificada. O teste de ponta a ponta cobriu o primeiro caso.

## Abrir e editar

1. Extraia o ZIP do projeto.
2. Importe **project.godot** no Godot 4.7.2 e pressione **F5**.
3. Os modelos autorais ficam em **assets/cidade/**. Para regenerá-los, execute o Blender 5.2 em segundo plano a partir da pasta do projeto.

    blender --background --factory-startup --python scripts/blender/cidade_cg.py -- assets/cidade

Para exportar, instale os templates da mesma versão do Godot e use os presets **Windows** ou **Web**. O export web precisa ser servido por HTTP em localhost ou HTTPS em hospedagem. O repositório do GitHub contém o export anterior. Esta edição foi entregue em arquivos locais.

As licenças dos modelos herdados ficam em **assets/LICENSES/**. Consulte os termos ao compartilhar o projeto editável. Os quatro modelos em **assets/cidade/** são gerados pelo script desta edição.

Referência histórica da ambientação. [IPHAN · Complexo da Esplanada Ferroviária](https://www.gov.br/iphan/pt-br/assuntos/noticias/iphan-realiza-1a-fiscalizacao-integrada-em-imoveis-de-campo-grande-ms)
