# Conferência das regras de propriedade

Edição: Super Banco Imobiliário da Estrela. Referência oficial:
https://estrela.vteximg.com.br/arquivos/Manual-Super-Banco-Imobili%C3%A1rio.pdf

O usuário escolheu seguir o manual em vez da regra personalizada anterior.

Implementado:

- A compra ao banco conserva seu preço original, separado do preço negociado.
- A construção é paga ao banco e o aluguel é registrado conforme a carta.
- Casas são vendidas ao banco por metade do custo registrado. O aplicativo
  guarda o custo de cada construção; retirada parcial começa pelas últimas
  casas construídas. Custos antigos sem detalhamento usam o investimento
  registrado dividido pela quantidade de casas.
- A venda entre jogadores e a hipoteca exigem a retirada das casas primeiro.
- Hipoteca mantém o título com o proprietário e suspende o aluguel. O valor
  informado na carta é registrado como base de hipoteca; o resgate paga essa
  base ao banco mais 20%. O preço negociado numa venda não redefine essa base.
- Uma posse hipotecada não é oferecida para aluguel, inclusive pelo Pix.
- Desfazer restaura saldos e estado das posses nas operações novas, inclusive
  construção, venda de casas, transferência, hipoteca e resgate.

Conferência manual no tabuleiro, sem alegação de automação completa:

- Propriedades do grupo de cor completo para construir e distribuição
  equilibrada das casas entre terrenos.
- Vez do jogador, estoque físico de casas e hotéis.
- Valores exatos de compra, construção, hipoteca e aluguel de cada título.
  O catálogo desta edição ainda não foi fornecido/verificado integralmente.
- Hotel e regras de companhias por soma dos dados ainda não possuem um fluxo
  próprio neste companion; o registro de aluguel é manual.

O manual usa “valor indicado no Título +20%” no resgate. O aplicativo exibe
explicitamente a base de hipoteca registrada e o total do resgate para que a
mesa confira os valores com o título antes de confirmar.

Assim, compra/venda/hipoteca seguem o fluxo conferido, mas não é correto afirmar
que todas as regras do tabuleiro foram automatizadas ou que os valores de todas
as cartas estão certificados.
