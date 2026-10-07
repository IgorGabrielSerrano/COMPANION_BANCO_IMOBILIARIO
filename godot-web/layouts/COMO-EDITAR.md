# Ajustar o layout na Godot

## Conta: saldo, botões e labels

Abra `conta.tscn` e use a visualização **2D**. Os elementos são Controls
posicionados diretamente, sem um Container que recoloque automaticamente os
botões quando você tentar movê-los.

- Selecione um nó na árvore à esquerda ou clique nele na tela 2D.
- Mova o elemento com a ferramenta de seleção; use as alças para mudar o tamanho.
- No **Inspector**, altere **Text** para mudar a escrita de um botão ou label.
- Em **Theme Overrides → Font Sizes → Font Size**, ajuste o tamanho da fonte.
- Em **Layout → Transform**, ajuste a posição e o tamanho com valores precisos.
- Salve com **Ctrl+S**. Pressione **F5** para ver o aplicativo com dados de exemplo.

O botão **Tema** na prévia nativa permite ver C4 Bank, MuBank, Intel Bank,
NeoBank e Nexus Bank. A prévia usa dados de exemplo; a sincronização de mesas
continua na versão web.

Os nomes dos nós, como `Patrimonio/Valor` e `Acoes/Receber`, ligam os componentes
às funções do jogo. Mantenha esses nomes e altere o campo **Text** para mudar a
escrita que o jogador vê.

Labels dinâmicos usam campos entre chaves:

- `{nome}`: nome do jogador;
- `{saldo}`: saldo, com animação;
- `{conexao}`: situação da conexão;
- `{prisao}`: prisão e sequência de duplas;
- `{jogadores}` e `{posses}`: contagens;
- `{papel}`: indicação de banqueiro.

Você pode mudar a frase em volta desses campos: por exemplo,
`Olá, {nome}` pode virar `Conta de {nome}`.

Se aumentar a altura da tela ou mover elementos para abaixo do limite atual,
aumente **Custom Minimum Size → Y** do nó raiz `Conta`. Esse valor define a
altura rolável da aba.

## Cabeçalho e navegação

Abra `estrutura.tscn` para ajustar o nome do banco, o PIN, Tema, Sair e as cinco
abas. O nó `AreaMovel` define a região de rolagem. Seus offsets superior e
inferior reservam espaço para o cabeçalho e as abas.

Abra `prisao.tscn` para ajustar os controles de prisão. Eles foram movidos da
Conta para a aba Prisão, preservando os textos que você editou.

Os anchors dos elementos que se estendem para a direita mantêm a interface
responsiva. Prefira alterar os offsets/posição sem remover os anchors existentes.

## Depois do ajuste

Salve os arquivos e envie a captura ou avise que terminou. As cenas já são
usadas pelo aplicativo; a próxima exportação incorpora suas alterações.
A publicação acontece após revisão e validação das alterações salvas.
