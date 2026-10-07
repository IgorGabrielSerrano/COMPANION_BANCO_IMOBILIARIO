# Companion no Tabletop Simulator

Mesa v2 com 40 casas confirmadas pelo usuário, até oito peões nomeados, dois dados físicos, pontos de encaixe, 100 Notícias originais e 28 títulos de posse. Casas azuis, cabeçalhos e faixas de preço seguem a disposição e os grupos de cores da foto. Texto maior e malha corrigida para compensar o espelhamento do importador OBJ. O centro mantém o visual do Companion.

## Abrir

O arquivo `Companion-Tabuleiro.json` e sua miniatura `Companion-Tabuleiro.png` devem ficar em `Documentos/My Games/Tabletop Simulator/Saves`. A cópia atualizada já foi instalada nesse diretório no computador de Igor, preservando backup da versão anterior. No Tabletop: **Games → Save & Load → Companion Banco Imobiliário — Mesa v2**. Recarregue o save para aplicar a atualização à mesa aberta; salvar a mesa antiga não instala o novo conteúdo. Se não aparecer, feche o menu e abra novamente; se necessário, reinicie o jogo.

Os arquivos de imagem e malha são carregados por HTTPS do GitHub Pages para que os convidados consigam vê-los. É necessária conexão para o primeiro carregamento. Não mova os arquivos publicados em `build/tabletop` sem reconstruir o save.

## Jogar com amigos

**Mesa espelhada / um único computador:** o anfitrião pode abrir uma partida single player no Tabletop e compartilhar a tela com os amigos. Configure os nomes normalmente. **Rolar dados**, **Avançar**, **Descartar** e **Notícias**, quando usados pelo anfitrião, controlam o jogador da vez sem trocar de assento. A tecla **R** usada pelo anfitrião também registra os dados para o jogador atual. O anfitrião continua podendo **Passar vez**. O painel mostra o nome do participante representado; os amigos podem acessar apenas o Companion para administrar o banco.

1. Crie uma sala multiplayer no Tabletop e carregue a mesa. Os participantes precisam do Tabletop Simulator.
2. No painel inicial, o anfitrião escolhe de 2 a 8 participantes e preenche nomes diferentes para cada cor. Clique em **Iniciar partida**. Cada pessoa escolhe essa mesma cor no seletor de assento do Tabletop. Os peões recebem os nomes; os reservas ficam bloqueados fora do percurso. Os nomes e a configuração são preservados ao salvar a partida. Durante a partida, **Jogadores** mostra a lista; nomes e quantidade ficam bloqueados para preservar as posses.
3. Abra o [Companion](https://igorgabrielserrano.github.io/COMPANION_BANCO_IMOBILIARIO/) no celular ou navegador. O banqueiro cria a mesa e compartilha o PIN.
4. O painel fixo mostra **nome, dado 1 + dado 2 = soma** e destaca **DADOS IGUAIS — marque no Companion** quando necessário. Clique em **Rolar dados**, aguarde e use **Avançar**. Só a cor que rolou usa o resultado, consumido uma vez. O posicionamento atual do peão define a casa de partida, inclusive depois de movimento manual. O último resultado permanece visível.
5. Você também pode selecionar os dois dados e pressionar **R**. Essa rolagem atualiza o painel e alimenta o avanço. Não role enquanto outra pessoa tiver um resultado pendente. **Visão de cima** ajusta sua câmera para leitura. O tabuleiro permanece fixo para preservar o alinhamento dos peões e encaixes; use a câmera para mudar o ângulo.
6. Registre pagamentos, duplas e prisão no Companion. A mesa mostra lembretes para Início, Receita Federal e restituição, mas não altera saldos.

**Passar vez:** o painel indica o jogador atual. A partida começa no primeiro jogador configurado e segue a lista, retornando ao primeiro após o último. Só o jogador da vez ou o anfitrião pode passar; é preciso aguardar os dados pararem. Passar limpa o resultado pendente e o aviso de Notícias. Rolagem e compra de Notícias ficam disponíveis ao jogador da vez. A vez atual é preservada ao salvar/carregar. Duplas e prisão ainda são conferidas no Companion; passe a vez quando as regras exigirem.

**Peões:** usam uma malha própria com material branco e oito cores sólidas (branco, vermelho, azul, verde, amarelo, laranja, roxo e rosa), correspondentes aos assentos. O nome aparece ao apontar para o peão e na configuração dos jogadores.

**Prisão:** para ir à prisão, mova o peão à casa 11 e marque no Companion. Para tentativas de saída, role e use **Descartar resultado** quando não houver movimento. Antes de avançar após dados iguais, confira no Companion se a terceira dupla exige prisão. Turnos e regras são controlados pelos jogadores; o script não decide automaticamente quem pode jogar.

## Notícias e títulos

**Notícias:** o baralho no centro tem 100 cartas originais, criadas para esta mesa a pedido do usuário. Não são as cartas oficiais da Estrela. Há 50 recebimentos e 50 pagamentos, de R$ 300 a R$ 2.000, com total líquido zero no conjunto completo; isso não garante equilíbrio em cada partida. O anfitrião embaralha automaticamente ao iniciar. Clique em **Notícias** para revelar a próxima carta e seu aviso na tela. Registre o valor manualmente no Companion. As cartas ficam em um descarte junto do baralho; após esgotá-lo, junte os descartes, vire o baralho e embaralhe. O painel reconhece o novo baralho pelos IDs das cartas.

**Títulos:** o baralho de posses contém 22 propriedades e seis ações, com nomes, cores e preços confirmados. No baralho, **botão direito → Search**, busque pelo nome e retire a carta. Após registrar a compra no Companion, arraste o título para sua mão ou use **Guardar posse (host: jogador da vez)** no menu da carta. Cada uma das oito cores tem uma área de mão. Na venda, mova o título para a mão do comprador e registre a transferência no Companion; a movimentação da carta não movimenta dinheiro nem cadastra a posse automaticamente.

Aluguéis, casas, hotéis e hipoteca estão marcados **a definir** nos títulos, aguardando as fotos/valores oficiais. Não há peças de construção nesta versão. O Companion publicado continua com o cadastro manual existente.

## Desenvolvimento e validação

Gerador: `tools/build-tabletop.py` (Python e Pillow). Cartas: `tabletop/assets.py` e `tabletop/noticias.py`. Fonte dos nomes/valores: `docs/tabuleiro-referencia.json`. Script: `tabletop/mesa.lua`. A malha tem UV explícita, U invertido para o importador e dimensões de 40 × 40; pontos de encaixe e peões usam a mesma geometria. URLs de texturas e malha têm hash para evitar reutilização do conteúdo antigo no cache.

`tests/tabletop_test.py` (Python + lupa) verifica 40 casas, 100 Notícias, 28 títulos, IDs, mãos, configuração restrita ao anfitrião, persistência, rolagem manual/botão, soma, duplas e avanço único em uma simulação da API Lua. A importação, física, câmera e correção do espelhamento precisam ser confirmadas em uma partida real no Tabletop; testes simulados não substituem essa etapa.

Referências técnicas: [formato do save](https://kb.tabletopsimulator.com/custom-content/save-file-format/) e [API de objetos](https://api.tabletopsimulator.com/object/).
