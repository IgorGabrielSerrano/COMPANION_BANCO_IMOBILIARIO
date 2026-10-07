# Guia de suporte e diagnóstico

Este documento reúne orientações para quem testa o Companion Banco Imobiliário
e um caso de diagnóstico realizado no próprio projeto.

## Informações para iniciar um atendimento

Registre o navegador e sua versão, o aparelho, a ação realizada, o resultado
esperado e o resultado observado. Informe se o problema ocorre com todos os
jogadores ou apenas com um. Use uma mesa de teste para reproduzir o cenário.
Screenshots e registros compartilhados devem conter apenas os dados necessários
para entender a falha, sem senhas, códigos de autenticação ou dados de clientes.

## Problemas frequentes durante o teste

| Sintoma | Conferência inicial | Próximo passo |
| --- | --- | --- |
| Outro jogador não entra | Conferir nome e PIN, sessão do banqueiro aberta e status de conexão | Testar em dois navegadores/aparelhos; registrar mensagens e ambiente se continuar |
| A mesa não sincroniza | Verificar se a sessão do banqueiro continua conectada | Em rede gerenciada, encaminhar a análise de conectividade à equipe responsável |
| Retorno não recupera o jogador | Conferir o mesmo PIN e nome; a partida precisa estar ativa | A recuperação do banqueiro depende do mesmo navegador e dos dados locais preservados |
| O QR não abre a câmera | Conferir permissão de câmera e acesso por HTTPS ou localhost | Usar o pagamento manual pela aba Conta e registrar a falha de câmera |
| O QR não identifica o destinatário | Confirmar que é QR deste jogo, de outro jogador ativo na mesma mesa | Gerar o QR da mesa atual e tentar novamente |
| Não consegue construir ou hipotecar | Conferir saldo, quantidade de casas e estado da posse | Construção paga ao banco; venda e hipoteca exigem vender as casas antes |
| Não consegue desfazer uma transação | Conferir se está na sessão do banqueiro | Consultar a mensagem; operações posteriores relacionadas ou saldo insuficiente podem bloquear a reversão |

## Caso do projeto: tema muda ao entrar na mesa

**Sintoma:** o usuário escolhia um tema no lobby, mas via outro ao entrar.

**Como reproduzir:** usar um nome com preferência antiga salva, selecionar outro
tema antes de entrar e criar ou acessar uma mesa com esse mesmo nome.

**Causa identificada:** a preferência antiga associada ao nome prevalecia sobre
a escolha explícita feita no lobby.

**Correção:** conservar a escolha do lobby até a entrada e então salvá-la como
preferência do nome normalizado, sem modificar o estado financeiro da mesa.

**Validação:** testes de criação e entrada nos cinco temas; teste de interface
com uma preferência antiga e conferência da persistência ao retornar.
Os cenários estão em `tests/sync.test.cjs` e `tests/web_smoke.py`.

## Exemplo de registro de chamado

```text
Título: Tema escolhido no lobby não é mantido ao entrar
Ambiente: navegador e versão / aparelho / versão publicada
Impacto: preferência visual do jogador; sem alteração de saldo
Reprodução: preferência antiga por nome + escolha diferente antes de entrar
Resultado esperado: manter a escolha atual
Resultado observado: carregar a preferência antiga
Diagnóstico: prioridade incorreta entre preferência antiga e escolha atual
Tratativa: registrar a escolha do lobby ao entrar na mesa
Validação: criação, entrada e retorno nos cinco temas
Encerramento: explicar a correção ao usuário após a validação
```

Esse registro descreve o projeto pessoal. Não representa atendimento prestado
a um cliente empresarial, uso de uma ferramenta de chamados específica ou
certificação em suporte.
