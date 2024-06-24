# Projeto .NET no Docker WSL
Este repositório contém o script project_manager.sh que facilita a criação, gerenciamento e execução de projetos .NET dentro de um ambiente Docker. O script oferece vários comandos para inicializar soluções, adicionar projetos, restaurar dependências, compilar, executar, aplicar migrações, gerenciar pacotes NuGet, entre outros.

### Pré-requisitos
- Docker
- Docker Compose
- Visual Studio Code com a extensão Remote - Containers

## Alias para o script
Para facilitar o uso do script project_manager.sh, você pode criar um alias no seu arquivo de configuração de shell (.bashrc, .zshrc, etc.). Adicione a linha abaixo ao final do seu arquivo de configuração:
```sh
alias net="docker/project_manager.sh"

#Substitua caminho/para/seu pelo caminho real onde o script project_manager.sh está localizado.

#D`epois de adicionar a linha, recarregue o arquivo de configuração`:

source ~/.bashrc # ou source ~/.zshrc, dependendo do seu shell

#A`gora você pode usar o alias pm para chamar o script project_manager.sh de qualquer lugar`:

net init --solution TesteDocker --type webapi --path src/app/td.api.test
net add-project --type classlib --path src/domain/td.domain.test
net migrate --path src/app/td.api.test
```

## Requisitos

- Docker e Docker Compose instalados
- Bash shell (para executar os scripts de inicialização e atualização)
Torne o script executável:
```sh
chmod +x "$(pwd)/docker/project_manager.sh"
```

## Definir o Caminho Padrão do Projeto

Para definir o caminho padrão do projeto, use o comando set-default-path:
```sh
net set-default-path src/app/td.api.test
```
O comando acima gera um arquivo .project_manager_config, onde fica salvo o path base. 
Importante esse caminho será usado como base para as comandos que usam variavel --path.
Mas isso não impede que possa passar o path para criar um novo projeto por exemplo.

## Comandos Disponíveis - Resumo
O script project_manager.sh oferece os seguintes comandos:

- `set-default-path`: Define o caminho padrão do projeto.
- `set-default-dotnet-version`: Define a versão do .net a usar no projeto.
- `set-default-port`: Define a porta padrão para abertura do run ou debugs do projeto.
- `init`: Inicializa o ambiente de desenvolvimento.
- `add-project`: Adiciona um novo projeto à solução existente.
- `create`: Cria um novo projeto e adiciona à solução existente.
- `restore`: Restaura as dependências do projeto.
- `build`: Compila o projeto.
- `run`: Executa o projeto.
- `migrate`: Aplica migrações ao banco de dados.
- `add-migration`: Cria uma nova migração.
- `remove-migration`: Remove a última migração.
- `rollback-migration`: Reverte para uma migração específica.
- `add-nuget`: Adiciona um pacote NuGet ao projeto.
- `list-nuget`: Lista os pacotes NuGet do projeto.
- `remove-nuget`: Remove um pacote NuGet do projeto.
- `watch`: Assiste mudanças no projeto e recompila automaticamente.
- `help`: Mostra a ajuda do script.
- `up`: Sobe o docker compose do projeto
- `down`: Finalizar o docker compose do projeto

## Exemplo Instruções de Uso

### Inicialização do Projeto

Inicializar o Ambiente de Desenvolvimentodeseja e cria um novo projeto:
```sh
- net init --solution TesteDocker --type webapi --path src/app/td.api.test
```
### Adicionar um Novo Projeto à Solução Existente

Para adicionar uma nova camada (Application, Domain, Infrastructure), execute o comando:
```sh
net add-project --type classlib --path src/domain/td.domain.test
```
### Restaurar Dependências
```sh
net restore --path src/app/td.api.test
```
### Compilar o Projeto
```sh
net build --path src/app/td.api.test
```

### Executar o Projeto
```sh
net run --path src/app/td.api.test --port 5000
```
### Criar e Aplicar Migrações
```sh
net add-migration --path src/app/td.api.test --name InitialCreate
net migrate --path src/app/td.api.test
```
### Adicionar, Listar e Remover Pacotes NuGet
#### Adicionar um pacote NuGet:
```sh
net add-nuget --path src/app/td.api.test --package Newtonsoft.Json --version 13.0.1
```
#### Listar pacotes NuGet:
```sh
net list-nuget --path src/app/td.api.test
```

#### Remover um pacote NuGet:
```sh
net remove-nuget --path src/app/td.api.test --package Newtonsoft.Json
```

## Para Desenvolvimento
### Assistir Mudanças no Projeto e Recompilar Automaticamente
```sh
net watch --path src/app/td.api.test --port 5000
```

## Commandos e Instruções

### set-default-path

Define o caminho padrão do projeto que será utilizado quando um caminho não for explicitamente fornecido em outros comandos.

```sh
net set-default-path [caminho_do_projeto]
```
Exemplo:
```sh
net set-default-path src/app/td.api.test
```

### set-default-dotnet-version
Define a versão padrão do .NET que será utilizada quando uma versão não for explicitamente fornecida em outros comandos.

```sh
net set-default-dotnet-version [versao_do_dotnet]
```

Exemplo:
```sh
net set-default-dotnet-version 8.0
```

### set-default-port
Define a porta padrão que será utilizada quando uma porta não for explicitamente fornecida em outros comandos.

```sh
net set-default-port [porta]
```
Exemplo:
```sh
net set-default-port 5000
```

### init
Inicializa o ambiente de desenvolvimento, criando uma solução e adicionando um projeto.

```sh
net init --solution [nome_da_solucao] --type [tipo_do_projeto] [--path caminho_do_projeto] [--version versao_do_dotnet]
```

Variáveis:
* `--solution [nome_da_solucao]`: Obrigatório. Nome da solução a ser criada.
* `--type [tipo_do_projeto]`: Obrigatório. Tipo do projeto a ser criado (ex`: console, webapi, classlib, etc.).
* `--path [caminho_do_projeto]`: Opcional. Caminho onde o projeto será criado. Se não fornecido, usará o caminho padrão definido.
* `--version [versao_do_dotnet]`: Opcional. Versão do .NET a ser utilizada (ex`: 7.0, 8.0). Padrão é 8.0.

Exemplo:
```sh
net init --solution TesteDocker --type webapi --path src/app/td.api.test
```

### add-project
Adiciona um novo projeto à solução existente.

```sh
net add-project --type [tipo_do_projeto] [--path caminho_do_projeto] [--version versao_do_dotnet]
```

Variáveis:
* `--type [tipo_do_projeto]`: Obrigatório. Tipo do projeto a ser criado (ex`: console, webapi, classlib, etc.).
* `--path [caminho_do_projeto]`: Opcional. Caminho onde o projeto será criado. Se não fornecido, usará o caminho padrão definido.
* `--version [versao_do_dotnet]`: Opcional. Versão do .NET a ser utilizada (ex`: 7.0, 8.0). Padrão é 8.0.

Exemplo:
```sh
net add-project --type classlib --path src/domain/td.domain.test
```

### create
Cria um novo projeto e o adiciona à solução existente.

```sh
net create [--path caminho_do_projeto] --type [tipo_do_projeto] [--version versao_do_dotnet]
```

Variáveis:
* `--path [caminho_do_projeto]`: Opcional. Caminho onde o projeto será criado. Se não fornecido, usará o caminho padrão definido.
* `--type [tipo_do_projeto]`: Obrigatório. Tipo do projeto a ser criado (ex`: console, webapi, classlib, etc.).
* `--version [versao_do_dotnet]`: Opcional. Versão do .NET a ser utilizada (ex`: 7.0, 8.0). Padrão é 8.0.

Exemplo:
```sh
net create --path src/app/td.api.test --type webapi
```

### restore
Restaura as dependências do projeto.

```sh
net restore [--path caminho_do_projeto] [--version versao_do_dotnet]
```

Variáveis:
* `--path [caminho_do_projeto]`: Opcional. Caminho do projeto para restaurar as dependências. Se não fornecido, usará o caminho padrão definido.
* `--version [versao_do_dotnet]`: Opcional. Versão do .NET a ser utilizada (ex`: 7.0, 8.0). Padrão é 8.0.

Exemplo:
```sh
net restore --path src/app/td.api.test
```

### build
Compila o projeto.

```sh
net build [--path caminho_do_projeto] [--version versao_do_dotnet]
```

Variáveis:
* `--path [caminho_do_projeto]`: Opcional. Caminho do projeto para compilar. Se não fornecido, usará o caminho padrão definido.
* `--version [versao_do_dotnet]`: Opcional. Versão do .NET a ser utilizada (ex`: 7.0, 8.0). Padrão é 8.0.

Exemplo:
```sh
net build --path src/app/td.api.test
```

### run
Executa o projeto.

```sh
net run [--path caminho_do_projeto] [--version versao_do_dotnet] [--port porta] [--debug]
```

Variáveis:
* `--path [caminho_do_projeto]`: Opcional. Caminho do projeto para executar. Se não fornecido, usará o caminho padrão definido.
* `--version [versao_do_dotnet]`: Opcional. Versão do .NET a ser utilizada (ex`: 7.0, 8.0). Padrão é 8.0.
* `--port [porta]`: Opcional. Porta a ser utilizada pelo projeto. Padrão é 5000.
* `--debug`: Opcional. Executa o projeto em modo debug (sem recompilar).

Exemplo:
```sh
net run --path src/app/td.api.test --port 5000
```

### migrate
Aplica migrações ao banco de dados.

```sh
net migrate [--path caminho_do_projeto] [--version versao_do_dotnet]
```

Variáveis:
* `--path [caminho_do_projeto]`: Opcional. Caminho do projeto para aplicar migrações. Se não fornecido, usará o caminho padrão definido.
* `--version [versao_do_dotnet]`: Opcional. Versão do .NET a ser utilizada (ex`: 7.0, 8.0). Padrão é 8.0.

Exemplo:
```sh
net migrate --path src/app/td.api.test
```

### add-migration
Cria uma nova migração.

```sh
net add-migration --name [nome_da_migracao] [--path caminho_do_projeto] [--version versao_do_dotnet]
```

Variáveis:
* `--name [nome_da_migracao]`: Obrigatório. Nome da migração a ser criada.
* `--path [caminho_do_projeto]`: Opcional. Caminho do projeto para criar a migração. Se não fornecido, usará o caminho padrão definido.
* `--version [versao_do_dotnet]`: Opcional. Versão do .NET a ser utilizada (ex`: 7.0, 8.0). Padrão é 8.0.

Exemplo:
```sh
net add-migration --name InitialCreate --path src/app/td.api.test
```

### remove-migration
Remove a última migração.

```sh
net remove-migration [--path caminho_do_projeto] [--version versao_do_dotnet]
```
Variáveis:
* `--path [caminho_do_projeto]`: Opcional. Caminho do projeto para remover a migração. Se não fornecido, usará o caminho padrão definido.
* `--version [versao_do_dotnet]`: Opcional. Versão do .NET a ser utilizada (ex`: 7.0, 8.0). Padrão é 8.0.

Exemplo:
```sh
net remove-migration --path src/app/td.api.test
```

### rollback-migration
Reverte para uma migração específica.

```sh
net rollback-migration --name [nome_da_migracao] [--path caminho_do_projeto] [--version versao_do_dotnet]
```

Variáveis:
* `--name [nome_da_migracao]`: Obrigatório. Nome da migração para a qual reverter.
* `--path [caminho_do_projeto]`: Opcional. Caminho do projeto para reverter a migração. Se não fornecido, usará o caminho padrão definido.
* `--version [versao_do_dotnet]`: Opcional. Versão do .NET a ser utilizada (ex`: 7.0, 8.0). Padrão é 8.0.

Exemplo:
```sh
net rollback-migration --name InitialCreate --path src/app/td.api.test
```

### add-nuget
Adiciona um pacote NuGet ao projeto.

```sh
net add-nuget --package [nome_do_pacote] [--path caminho_do_projeto] [--version versao_do_pacote] [--dotnet-version versao_do_dotnet]
```

Variáveis:
* `--package [nome_do_pacote]`: Obrigatório. Nome do pacote NuGet a ser adicionado.
* `--path [caminho_do_projeto]`: Opcional. Caminho do projeto para adicionar o pacote. Se não fornecido, usará o caminho padrão definido.
* `--version [versao_do_pacote]`: Opcional. Versão do pacote NuGet a ser adicionada. Se não fornecido, adiciona a última versão disponível.
* `--dotnet-version [versao_do_dotnet]`: Opcional. Versão do .NET a ser utilizada (ex`: 7.0, 8.0). Padrão é 8.0.

Exemplo:
```sh
net add-nuget --package Newtonsoft.Json --path src/app/td.api.test --version 13.0.1
```

### list-nuget
Lista os pacotes NuGet do projeto.

```sh
net list-nuget [--path caminho_do_projeto] [--version versao_do_dotnet]
```

Variáveis:
* `--path [caminho_do_projeto]`: Opcional. Caminho do projeto para listar os pacotes. Se não fornecido, usará o caminho padrão definido.
* `--version [versao_do_dotnet]`: Opcional. Versão do .NET a ser utilizada (ex`: 7.0, 8.0). Padrão é 8.0.
Exemplo:
```sh
net list-nuget --path src/app/td.api.test
```

### remove-nuget
Remove um pacote NuGet do projeto.

```sh
net remove-nuget --package [nome_do_pacote] [--path caminho_do_projeto] [--version versao_do_dotnet]
```

Variáveis:
* `--package [nome_do_pacote]`: Obrigatório. Nome do pacote NuGet a ser removido.
* `--path [caminho_do_projeto]`: Opcional. Caminho do projeto para remover o pacote. Se não fornecido, usará o caminho padrão definido.
* `--version [versao_do_dotnet]`: Opcional. Versão do .NET a ser utilizada (ex`: 7.0, 8.0). Padrão é 8.0.

Exemplo:
```sh
net remove-nuget --package Newtonsoft.Json --path src/app/td.api.test
```

### watch
Assiste mudanças no projeto e recompila automaticamente.

```sh
net watch [--path caminho_do_projeto] [--version versao_do_dotnet] [--port porta] [--debug]
```

Variáveis:
* `--path [caminho_do_projeto]`: Opcional. Caminho do projeto para assistir as mudanças. Se não fornecido, usará o caminho padrão definido.
* `--version [versao_do_dotnet]`: Opcional. Versão do .NET a ser utilizada (ex`: 7.0, 8.0). Padrão é 8.0.
* `--port [porta]`: Opcional. Porta a ser utilizada pelo projeto. Padrão é 5000.
* `--debug`: Opcional. Executa o projeto em modo debug (sem hot reload).

Exemplo:
```sh
net watch --path src/app/td.api.test --port 5000
```

### help
Mostra a ajuda detalhada do script.

```sh
net help
```

### up
Sobe o ambiente Docker.

```sh
net up
```

Exemplo:
```sh
net up
```

### down
Finalizar o ambiente Docker.

```sh
net down
```

Exemplo:
```sh
net down
```

## Licença

Este projeto está licenciado sob os termos da licença MIT.
