# Companion Banco Imobiliário

Aplicativo web para acompanhar uma partida de Banco Imobiliário no tabuleiro:
saldos, pagamentos, posses, construções, prisão e histórico da mesa em um só lugar.
A interface roda em Godot Web e usa temas de bancos fictícios para dar personalidade
à experiência de cada jogador.

**[Abrir e testar o aplicativo](https://igorgabrielserrano.github.io/COMPANION_BANCO_IMOBILIARIO/)**

## Experimente em poucos minutos

1. Abra o aplicativo, escolha um tema e informe seu nome.
2. Clique em **Criar mesa**. O saldo inicial sugerido é R$ 25.000.
3. Abra o mesmo link em outro celular ou navegador. Informe outro nome e o PIN
   exibido na mesa para entrar como jogador.
4. Experimente pagar outro jogador, comprar uma posse e construir casas.
   Informe os preços e aluguéis conforme o título do seu tabuleiro.
5. No histórico, o banqueiro pode selecionar transações e desfazê-las,
   restaurando os saldos e as posses envolvidos.

Para experimentar a interface sozinho, basta criar uma mesa. Para testar a
sincronização, use dois navegadores ou aparelhos e mantenha aberta a mesa do
banqueiro. A conexão entre aparelhos utiliza PeerJS/WebRTC; a rede precisa
permitir essa conexão.

O **Pix da mesa** usa QR para identificar jogadores e abrir o pagamento dentro
do jogo. Todo dinheiro é fictício: não há integração com bancos nem Pix real.
O leitor de QR solicita acesso à câmera quando você toca em escanear.

## O que o projeto demonstra

- Interface em Godot exportada para a web, com navegação por abas e rolagem por toque.
- Cinco temas por jogador: C4 Bank, MuBank, Intel Bank, NeoBank e Nexus Bank.
- Animação contínua das moedas, contagem progressiva do saldo e áudio de ganhos/perdas.
- Mesas com PIN, sincronização de jogadores e recuperação da partida pelo mesmo nome.
- Compra e venda de posses, construção paga ao banco, hipoteca e resgate.
- Histórico com reversão individual ou em lote, exclusiva do banqueiro.
- QR por jogador, pagamento com destinatário preenchido e seleção de aluguel.
- Guia de regras pesquisável, com referências ao manual oficial da Estrela.

## Tecnologias e organização

| Parte | Implementação |
| --- | --- |
| Interface e animações | Godot 4.7.2, GDScript e exportação Web |
| Estado e operações da mesa | JavaScript, HTML e formulários acessíveis |
| Comunicação | PeerJS/WebRTC; BroadcastChannel entre abas locais |
| QR | qrcode-generator e jsQR, executados no navegador |
| Publicação | GitHub Pages e GitHub Actions |
| Verificação | Node.js e Playwright com Microsoft Edge |

O projeto `godot-web/` renderiza a interface. A página `build/index.html`
mantém o estado e valida as operações na sessão do banqueiro. As duas partes se
comunicam pelo JavaScriptBridge. A versão publicada fica em `build/`.

## Executar e verificar localmente

Na raiz do repositório, com Python disponível:

```powershell
python -m http.server 8000 --directory build
```

Abra `http://localhost:8000`. Os arquivos da exportação já estão versionados;
não é necessário instalar Godot para experimentar a aplicação pronta.

Para validar a lógica e a interface, com Node.js, Python, Playwright e Edge:

```powershell
node tests/sync.test.cjs
python tests/web_smoke.py
```

Para editar a interface, abra `godot-web/project.godot` no Godot 4.7.2.
Com os templates Web instalados, exporte usando:

```powershell
./tools/export-godot.ps1 -GodotPath "C:/caminho/Godot_v4.7.2-stable_win64_console.exe"
```

A verificação da interface usa perfis de viewport e toque de iPhone 11–17,
nos cinco temas. Ela não substitui testes em aparelhos físicos ou no Safari.

## Regras e escopo

Este é um companion para o jogo físico. Preços e aluguéis são informados pela
mesa; o catálogo completo de títulos desta edição ainda não foi cadastrado.
Grupo de cor, vez do jogador, distribuição equilibrada e estoque físico de
construções são conferidos no tabuleiro. Hotéis não têm um fluxo próprio.

Veja [as regras conferidas e os limites da automação](godot-web/REGRAS-CONFERIDAS.md)
e [como editar as cenas](godot-web/layouts/COMO-EDITAR.md).

Os nomes dos bancos são fictícios. Fontes e bibliotecas incluem seus arquivos
de licença nos diretórios de assets correspondentes.
