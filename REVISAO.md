# Campo Grande · Zona de Quarentena

## Mundo e jogabilidade

O mapa, o traçado viário e os 26 locais reais cadastrados foram reaproveitados, inclusive as referências de fachada da Casa do Artesão, da Morada dos Baís e do Grande Hotel Gaspar. Nas lacunas cartográficas, o preenchimento é procedural. Duas novas variantes voxel foram usadas em lotes residenciais e comerciais desse preenchimento.

- O abrigo da Rua Barão do Rio Branco recebe as missões de abastecimento. As primeiras entregas levam à Pague Menos, ao Mercadão e ao Pátio Central Shopping.
- O saque fica na interface de cada prédio. Farmácias, mercados e centros comerciais têm reservas diferentes. Há locais vazios e portas trancadas.
- Vidros quebrados e carros em movimento produzem ruído. Os infectados podem patrulhar, investigar o som, perseguir por visão, buscar o último ponto conhecido e morder. Se encontram uma barreira, tentam usar a malha viária. O pátio do abrigo é seguro.
- Os carros ficam estacionados. Roubar, dirigir, sair e voltar ao veículo funcionam com combustível persistente. Há um carro a cerca de 22 m do abrigo inicial.
- O relógio real controla a reposição de suprimentos de 2 a 6 horas e os contratos repetíveis. A progressão, a mochila e o baú de 60 itens do Posto Barão pertencem ao perfil local.

## Verificação

Fluxo testado no Godot em tela vertical. Foram exercitados roubo e reentrada no carro, estoque trancado, alerta ao quebrar vidro, reposição só após o prazo, uso de água, mordida, combate corpo a corpo, as três entregas e restauração do progresso. As capturas ficam em [testes-visuais](testes-visuais/sobrevivencia/).

## Créditos de recursos

- Sprites selecionados de **ZombiePack** e ícones selecionados de **Free Pixel Survival Items Pack** e **Free Pixel Melee Weapon Pack** integrados aos exports. [Domin Dev](https://domin-dev.itch.io/)
- Dois modelos de **Voxel Buildings** adaptados para lotes genéricos. [mehrasaur](https://mehrasaur.itch.io/voxel-buildings)
- Referências de combate isométrico e lógica de estados dos infectados. A implementação do jogo é em GDScript. [Zombusters](https://github.com/retrowax/Zombusters) · [zombie-ai](https://github.com/baponkar/zombie-ai)
- Pacotes **Package**, **Pleasant Park Pack** e **actionVoxels** ficam disponíveis como material de origem local. Os arquivos recebidos não trouxeram condições de uso identificáveis.

A revisão em tela vertical também cobriu colisão a pé e de carro, busca em uma casa, vidro quebrado, descanso, higiene, saída pela janela, persistência da roupa, fuga de um sobrevivente e quadros e reprodução sonora dos infectados. A distribuição adicionou 812 carros mantendo os IDs existentes.

Na Rua Barão do Rio Branco, o teste confirmou a colisão no carro estacionado e na base do poste. Também foram verificadas a janela de aparição dos sobreviventes, a aproximação hostil, o dano e a defesa do jogador.

A revisão em tela vertical cobriu criação de personagem, introdução, entrada na casa, transferência para o baú, descanso, montagem e posicionamento de móveis, as 16 missões e a retomada de uma campanha antiga a partir da quarta missão. O recorte da planta do Mercadão foi verificado contra as vias. As referências da cobertura do Mercadão e dos balcões do Grande Hotel Gaspar estão nas fotografias 182 e 80 da [Revista ARCA 15](https://cdn.campogrande.ms.gov.br/portal/prod/uploads/sites/47/2021/08/revista-arca-15-2011-1629935562.pdf).

Os testes em tela vertical verificaram plantas recortadas, colisões, coleta por toque, aparecimento individual de itens, tranca persistente, escadas do Grande Hotel Gaspar, ações de sofá, cama e pia e os caminhos de acesso às 20 missões. O mapa gerou 258 adereços de rua após a geração de carros.
