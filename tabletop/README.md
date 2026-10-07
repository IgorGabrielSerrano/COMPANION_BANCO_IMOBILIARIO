# Companion no Tabletop Simulator

Mesa com 40 casas confirmadas pelo usuário, oito peões coloridos, dois dados físicos, pontos de encaixe e avanço opcional pelo resultado dos dados. O visual foi redesenhado para leitura; nomes, preços e grupos de cores seguem a referência. Não é reprodução da arte da Estrela.

## Abrir

O arquivo `Companion-Tabuleiro.json` e sua miniatura `Companion-Tabuleiro.png` devem ficar em `Documentos/My Games/Tabletop Simulator/Saves`. A cópia inicial já foi instalada nesse diretório no computador de Igor. No Tabletop: **Games → Save & Load → Companion Banco Imobiliário — Tabuleiro**. Se não aparecer, feche o menu e abra novamente; se necessário, reinicie o jogo.

Os arquivos de imagem e malha são carregados por HTTPS do GitHub Pages para que os convidados consigam vê-los. É necessária conexão para o primeiro carregamento. Não mova os arquivos publicados em `build/tabletop` sem reconstruir o save.

## Jogar com amigos

1. Crie uma sala multiplayer no Tabletop e carregue a mesa. Os participantes precisam do Tabletop Simulator.
2. Cada jogador escolhe a cor correspondente ao seu peão: branco, vermelho, azul, verde, amarelo, laranja, roxo ou rosa.
3. Abra o [Companion](https://igorgabrielserrano.github.io/COMPANION_BANCO_IMOBILIARIO/) no celular ou navegador. O banqueiro cria a mesa e compartilha o PIN.
4. Clique em **Rolar dados**, aguarde o resultado no chat e clique em **Avançar peão**. Só a cor que rolou pode usar esse resultado; ele é consumido uma vez. O posicionamento atual do peão define a casa de partida, inclusive depois de movimento manual.
5. Você também pode pegar os dados e pressionar **R**, e mover os peões manualmente. Essa rolagem manual não alimenta o botão de avanço.
6. Registre pagamentos, duplas e prisão no Companion. A mesa mostra lembretes para Início, Receita Federal e restituição, mas não altera saldos.

**Prisão:** para ir à prisão, mova o peão à casa 11 e marque no Companion. Para tentativas de saída, role e use **Descartar resultado** quando não houver movimento. Antes de avançar após dados iguais, confira no Companion se a terceira dupla exige prisão. Turnos e regras são controlados pelos jogadores; o script não decide automaticamente quem pode jogar.

**Cartas:** use suas cartas físicas de Notícias e títulos de posse. Aluguéis, custos de casas, hotéis e conteúdo das cartas não foram inventados. Esta versão entrega tabuleiro, dados e peões; não inclui baralhos digitais ou peças de construção.

## Desenvolvimento e validação

Gerador: `tools/build-tabletop.py` (Python e Pillow). Fonte dos nomes/valores: `docs/tabuleiro-referencia.json`. Script: `tabletop/mesa.lua`. A malha tem UV explícita e dimensões de 40 × 40, com origem e pontos de encaixe gerados da mesma geometria da imagem.

Validação automática verifica as 40 casas, ordem, IDs e comportamento do script com uma simulação da API Lua. A importação, física, câmera e orientação precisam ser confirmadas em uma partida real no Tabletop; testes simulados não substituem essa etapa.

Referências técnicas: [formato do save](https://kb.tabletopsimulator.com/custom-content/save-file-format/) e [API de objetos](https://api.tabletopsimulator.com/object/).
