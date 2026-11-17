# Caso Aberto

Use a branch principal deste repositório como destino das atualizações do jogo pedidas pelo proprietário. Antes de enviar uma alteração, verifique o diff e teste o fluxo afetado no Godot. Ao terminar uma atualização solicitada, faça commit e envie para a branch main de origin.

Mantenha os modelos e sprites herdados em assets/pack/ e assets/chars/ somente na cópia local. O README explica como obtê-los. Os modelos autorais em assets/cidade/ e o script Python que os gera fazem parte do projeto.

Ao mudar uma versão jogável, gere os exports correspondentes no Godot e atualize os ZIPs em versoes/.
O GitHub Pages publica a pasta docs/ na branch main. Ao atualizar o ZIP da versão web, copie os mesmos arquivos index.* do export para docs/ e preserve .nojekyll e .gdignore.

Em cada publicação jogável, execute `python scripts/release.py prepare` uma vez antes de exportar para Web e Windows. Depois do export Web e antes de copiar os arquivos para `docs/` e para o ZIP, execute `python scripts/release.py web CAMINHO_DO_EXPORT/index.html`. Isso dá à publicação seu próprio arquivo de progresso e sua própria URL de carregamento do pacote. Inclua `project.godot` no commit. Teste criação de personagem, introdução e caminhada inicial antes do push, além da retomada do progresso ao recarregar a mesma versão.
