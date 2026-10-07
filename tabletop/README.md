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

## Casa atual e compra de posse

Após **Avançar**, o painel da casa mostra nome, preço e disponibilidade. Se a posse tiver dono registrado, mostra o nome dele e bloqueia a compra. Casas de Notícias, impostos, prisão e outros espaços especiais mostram sua instrução em vez de preço de compra. Soltar um peão manualmente sobre uma casa também atualiza esse painel.

**Comprar posse** retira o título correspondente do baralho e coloca a carta aberta em uma área do centro da mesa, associada ao jogador da vez. O host opera o comprador atual sem mudar de assento. Você pode arrastar a carta para outro lugar ou para a mão do jogador. A posse fica registrada no save do Tabletop e não pode ser comprada novamente enquanto estiver com dono. Um título fora do banco sem dono registrado aparece como pendente de confirmação, evitando tratar uma carta retirada manualmente como disponível.

A compra no Tabletop **não debita o saldo do Companion**: registre a compra e o pagamento no aplicativo. O preço é o da referência confirmada; aluguéis, casas e hipoteca continuam a definir. O menu **Guardar / atribuir posse (host: jogador da vez)** registra o dono de uma carta retirada manualmente. Usado pelo host em uma carta já comprada, permite atribuí-la ao jogador atual; registre a transferência no Companion também.

## Ajustar os controles

Os botões ficam em uma faixa compacta na parte inferior, e o resumo de vez/dados fica menor no canto superior esquerdo. O botão **Layout**, no canto superior direito, abre o editor do host. Use as setas para escolher cada botão ou painel e altere:

- **X/Y em porcentagem:** posição do centro na tela. X cresce da esquerda para a direita; Y cresce de baixo para cima.
- **Largura, altura e fonte:** tamanho individual de cada controle.

Clique em **Aplicar** para ver o resultado. **Restaurar tudo** recupera os padrões caso um painel fique fora da área desejada. Os ajustes ficam no save da partida; salve no Tabletop para mantê-los na próxima abertura. Este editor posiciona pelos campos, sem depender do arraste nativo, cuja posição o Tabletop não permite salvar de forma confiável. O botão Layout permanece acessível mesmo que você reposicione os outros controles.

**Prisão:** para ir à prisão, mova o peão à casa 11 e marque no Companion. Para tentativas de saída, role e use **Descartar resultado** quando não houver movimento. Antes de avançar após dados iguais, confira no Companion se a terceira dupla exige prisão. Turnos e regras são controlados pelos jogadores; o script não decide automaticamente quem pode jogar.

## Notícias e títulos

**Notícias:** o baralho no centro tem 100 cartas originais, criadas para esta mesa a pedido do usuário. Não são as cartas oficiais da Estrela. Há 50 recebimentos e 50 pagamentos, de R$ 300 a R$ 2.000, com total líquido zero no conjunto completo; isso não garante equilíbrio em cada partida. O anfitrião embaralha automaticamente ao iniciar. Clique em **Notícias** para revelar a próxima carta e seu aviso na tela. Registre o valor manualmente no Companion. As cartas ficam em um descarte junto do baralho; após esgotá-lo, junte os descartes, vire o baralho e embaralhe. O painel reconhece o novo baralho pelos IDs das cartas.

**Títulos:** o baralho de posses contém 22 propriedades e seis ações, com nomes, cores e preços confirmados. Prefira **Comprar posse** após cair na casa. Também é possível usar **botão direito → Search**, retirar a carta e usar **Guardar / atribuir posse (host: jogador da vez)**. Cada uma das oito cores tem uma área de mão. Arrastar uma carta sozinho não muda seu dono registrado: na venda, o host deve atribuí-la ao jogador atual pelo menu e registrar a transferência no Companion.

Aluguéis, casas, hotéis e hipoteca estão marcados **a definir** nos títulos, aguardando as fotos/valores oficiais. Não há peças de construção nesta versão. O Companion publicado continua com o cadastro manual existente.

## Desenvolvimento e validação

Gerador: `tools/build-tabletop.py` (Python e Pillow). Cartas: `tabletop/assets.py` e `tabletop/noticias.py`. Fonte dos nomes/valores: `docs/tabuleiro-referencia.json`. Script: `tabletop/mesa.lua`. A malha tem UV explícita, U invertido para o importador e dimensões de 40 × 40; pontos de encaixe e peões usam a mesma geometria. URLs de texturas e malha têm hash para evitar reutilização do conteúdo antigo no cache.

`tests/tabletop_test.py` (Python + lupa) verifica 40 casas, 100 Notícias, 28 títulos, IDs, mãos, configuração restrita ao anfitrião, persistência, rolagem manual/botão, soma, duplas e avanço único em uma simulação da API Lua. A importação, física, câmera e correção do espelhamento precisam ser confirmadas em uma partida real no Tabletop; testes simulados não substituem essa etapa.

Referências técnicas: [formato do save](https://kb.tabletopsimulator.com/custom-content/save-file-format/) e [API de objetos](https://api.tabletopsimulator.com/object/).
