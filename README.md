# BotDex

**Repositório:** [https://github.com/LuizGup/PokedexBotElixir](https://github.com/LuizGup/PokedexBotElixir)

Bot do Discord temático de Pokémon, escrito em **Elixir** com a biblioteca **Nostrum**.

> Trabalho da disciplina **T300 — Programação Funcional** (UNIFOR), Prof. Bruno Lopes.
> Demonstra os pilares da programação funcional: pipe operator, pattern matching, imutabilidade e concorrência.

---

## Pré-requisitos

- **Elixir** 1.19+ (e Erlang/OTP 28+)
- **Mix** (vem junto com Elixir)
- Uma conta no [Discord Developer Portal](https://discord.com/developers/applications) para criar o bot
- Uma chave de API gratuita do [Giphy Developers](https://developers.giphy.com/) (apenas para o comando `!pika`)

---

## Instalação e configuração

### 1. Clone o repositório e baixe as dependências

```powershell
git clone https://github.com/LuizGup/PokedexBotElixir.git
cd "PokedexBotElixir/bot_dex"
mix deps.get
```

### 2. Configure o bot no Discord

No [Developer Portal](https://discord.com/developers/applications):

1. Crie uma **New Application** → aba **Bot** → **Reset Token** e copie.
2. Ainda em **Bot**, role até **Privileged Gateway Intents** e ative:
   - **MESSAGE CONTENT INTENT** (sem isso o bot não lê o conteúdo das mensagens)
3. Vá em **OAuth2 → URL Generator**:
   - **Scopes:** `bot` + `applications.commands`
   - **Bot Permissions:** View Channels, Send Messages, Embed Links, Read Message History
   - Copie a URL gerada, abra no navegador e adicione o bot ao seu servidor de teste.

### 3. Configure as variáveis de ambiente

No PowerShell, na mesma janela onde vai rodar o bot:

```powershell
$env:DISCORD_TOKEN = "seu_token_do_discord_aqui"
$env:GIPHY_API_KEY = "sua_chave_do_giphy_aqui"
```

> **Dica:** crie um arquivo `.env` na raiz do `bot_dex/` com essas variáveis (ele está no `.gitignore` e não será comitado).

### 4. Inicie o bot

```powershell
iex.bat -S mix
```

Você deve ver `[info] READY` no terminal — o bot está online.

---

## Comandos disponíveis

### Comandos obrigatórios (7 — cumprem o requisito do edital)

| Comando | API utilizada | Exemplo |
|---------|---------------|---------|
| `!pika` | Giphy — `gifs/random` | `!pika` |
| `!dex <nome>` | PokéAPI — `pokemon/{nome}` | `!dex pikachu` |
| `!carta <nome>` | Pokémon TCG API — `cards?q=name:` | `!carta charizard` |
| `!ep <temporada> <episodio>` | TVMaze — `shows/590/episodebynumber` | `!ep 1 25` |
| `!comparar <p1> <p2>` | Jikan (MyAnimeList) — `characters?q=` (paralelo via `Task.async`) | `!comparar pikachu charizard` |
| `!capturar <nome>` | PokéAPI — `pokemon-form/{nome}` + persistência JSON local | `!capturar bulbasaur` |
| `!habitat <cidade>` | Open-Meteo (`geocoding` + `forecast`) + PokéAPI — `type/{tipo}` (`with`) | `!habitat fortaleza` |

### Comandos bônus (extras de usabilidade)

| Comando | Descrição | Exemplo |
|---------|-----------|---------|
| `!help` | Lista todos os comandos disponíveis | `!help` |
| `!bag` | Lista a bag com info de cada Pokémon (PokéAPI) | `!bag` |
| `!soltar <nome>` | Remove um Pokémon da bag local | `!soltar pikachu` |

---

## Arquitetura

```
lib/bot_dex/
├── application.ex      # Supervisor OTP — ponto de entrada
├── consumer.ex         # Receptor de eventos do Discord (GenServer via Nostrum)
├── store.ex            # Persistência em treinador.json
└── commands/           # Um arquivo por comando
    ├── pika.ex
    ├── dex.ex
    ├── carta.ex
    ├── ep.ex
    ├── comparar.ex
    ├── capturar.ex
    ├── habitat.ex
    ├── bag.ex
    ├── soltar.ex
    └── help.ex
```

**Fluxo de uma mensagem:**
1. Usuário digita `!comando` no Discord.
2. Nostrum entrega o evento para `BotDex.Consumer.handle_event/1`.
3. Pattern matching no `msg.content` despacha para o módulo apropriado em `commands/`.
4. O módulo executa o pipeline (validação → API → formatação) e envia a resposta.

---

## Conceitos funcionais demonstrados

- **Pipe Operator (`|>`)** — toda função `run/N` é uma cadeia de transformações.
- **Pattern Matching** — em strings (`"!dex " <> nome`), tuplas (`{:ok, ...}`), mapas (`%{"name" => n}`), listas (`[head | tail]`).
- **Imutabilidade** — `Map.update`, `Enum.map`, listas com prepend (`[novo | lista]`).
- **Guards (`when`)** — condições adicionais ao pattern matching (`when qtd > 0`).
- **Concorrência funcional** — `Task.async`/`Task.await` no `!comparar` (duas chamadas à Jikan API em paralelo).
- **`with`** — pipeline com short-circuit no `!habitat` (3 APIs encadeadas sem `case` aninhado).

---

## Segurança

- **Nunca commitar tokens.** O `DISCORD_TOKEN` e o `GIPHY_API_KEY` são lidos de variáveis de ambiente em runtime via `System.get_env/1`. Arquivos `.env` estão no `.gitignore`.
- **Persistência local apenas.** O `treinador.json` é gerado em runtime no diretório do bot e também está no `.gitignore` — nada do estado dos usuários é versionado.

---

## Estrutura de testes manual

| Caso | Comando | Resultado esperado |
|------|---------|---------------------|
| Smoke test | `!help` | Lista completa de comandos |
| API simples | `!dex pikachu` | Ficha do Pikachu |
| API com lista | `!carta charizard` | Imagem grande + nome do set |
| Dois parâmetros + guards | `!ep 0 1` | Erro: número inválido (guard `> 0`) |
| Concorrência | `!comparar pikachu charizard` | Tabela comparativa (2 chamadas paralelas) |
| Persistência | `!capturar pikachu` → fechar → reabrir → `!bag` | Pokémon persistiu entre execuções |
| Combinação de APIs | `!habitat fortaleza` | Cidade + temperatura + Pokémon |
| Concorrência variável | `!bag` (com 5+ capturas) | Lista carrega rápido (paralelismo limitado) |
| CRUD completo | `!soltar pikachu` → `!bag` | Pokémon removido |

---

## 🤖 Declaração de uso de IA

Conforme as instruções do trabalho, o uso de ferramentas de inteligência artificial é permitido desde que declarado. Esta seção registra os principais prompts utilizados e as respostas obtidas durante o desenvolvimento do projeto. **O aluno é integralmente responsável pelo código entregue e é capaz de explicar qualquer linha durante a arguição.**

### Registro de Prompts e Respostas

#### Módulo 1 — Segurança e Repositório

**Prompt:**
> "quero tirar uma duvida em relação a esse trabalho, posso usar .env no repositorio?"

**Resposta:**
> "Com base nas instruções do documento, a resposta curta é: não coloque o arquivo `.env` no seu repositório público. Embora o trabalho exija o uso de variáveis de ambiente para que o token do bot não fique exposto no código, existem diretrizes específicas sobre o que deve e o que não deve ser enviado para o repositório. [...] Utilize o `README.md` para explicar como o professor deve configurar o token e executar o projeto."

---

#### Módulo 2 — Planejamento de APIs e Comandos

**Prompt:**
> "me ajude a me dar ideias de APIs que posso programar? [...] Queria fazer um bot estilo pokemon pokedex"

**Resposta:**
> "Transformar o bot em uma Pokédex funcional se encaixa perfeitamente nos requisitos do professor Bruno. Sugestão de estrutura:
>
> 1. **Sem parâmetro:** `!pika` (Giphy API).
> 2. **Um parâmetro:** `!dex <nome>` (PokéAPI).
> 3. **Um parâmetro:** `!carta <nome>` (Pokémon TCG API).
> 4. **Dois+ parâmetros:** `!item <nome> <id>` (PokéAPI Items).
> 5. **Dois+ parâmetros:** `!comparar <p1> <p2>` (PokeBase).
> 6. **Com persistência:** `!capturar <nome>` (JSON local).
> 7. **Combinando APIs:** `!habitat <cidade>` (Open-Meteo + PokéAPI)."

---

#### Módulo 3 — Arquitetura e Configuração Técnica

**Prompt:**
> "beleza, podemos trocar apenas a lib? quero usar httpoison por ser mais simples"

**Resposta:**
> "O professor Bruno Lopes deixou explícito que você pode escolher entre Tesla ou HTTPoison. O HTTPoison é popular por ser direto ao ponto. [...] No seu `mix.exs`, adicione `{:httpoison, \"~> 2.0\"}` e mantenha o `{:jason, \"~> 1.4\"}`. Lembre-se que a leitura e escrita do JSON devem estar no módulo `BotDex.Store`."

---

#### Módulo 4 — Resolução de Ambiente (Windows 11)

**Prompt:**
> "nao consigo rodar o source, estou no windows 11: `source : O termo 'source' não é reconhecido [...]`"

**Resposta:**
> "No PowerShell do Windows, o comando `source` não existe. Para configurar o token sem deixá-lo no código, use o comando: `$env:DISCORD_TOKEN = \"seu_token_aqui\"`. Depois, execute o bot com `iex.bat -S mix`."