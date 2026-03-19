# noctalia-syncthing-status

Plugin de status do Syncthing para Noctalia Niri, baseado na estrutura do plugin `auto_tile`.

Desenvolvido por Pir0c0pter0 (`pir0c0pter0000@gmail.com`).

## O que mostra

- sincronizado
- sincronizando
- pausado
- desconectado
- offline
- erro/autorizacao

## Como funciona

O plugin usa um helper Python (`syncthing-status.py`) para consultar a API REST do Syncthing e consolidar um snapshot simples em JSON. O `Main.qml` faz polling periodico e compartilha o estado com o widget da barra, painel e tela de configuracao.

## Configuracao

Por padrao o plugin tenta autodetectar:

- `config.xml` em `~/.local/state/syncthing/config.xml` ou `~/.config/syncthing/config.xml`
- GUI URL
- API key

Campos manuais continuam disponiveis se voce quiser apontar para outra instancia do Syncthing.

O idioma fica em modo automatico por padrao e acompanha o locale do sistema enquanto a opcao `Auto` estiver selecionada.

## Observacoes

- `verifyTls` fica desligado por padrao para nao quebrar com certificados locais/self-signed.
- se nenhuma pasta for selecionada nas configuracoes, o plugin monitora todas as pastas do Syncthing.
