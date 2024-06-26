#!/bin/bash

# Diretório do projeto
PROJECT_DIR=$(pwd)

# Arquivo de configuração para armazenar as configurações padrão
CONFIG_FILE="$PROJECT_DIR/.project_manager_config"

# Função para carregar a configuração do arquivo de configuração
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        DEFAULT_DOTNET_VERSION="8.0"
        DEFAULT_PORT=5000
        DEFAULT_ROOT_PROJECT_PATH="backend/src/"
        DEFAULT_PROJECT_PATH="app/td.api.test"
        DEFAULT_DOCKER_NETWORK="app-network"
        DEFAULT_NODE_VERSION="latest"
    fi
}


# Função para definir a versão padrão do .NET
set_default_dotnet_version() {
    local dotnet_version="$1"
    echo "DEFAULT_DOTNET_VERSION=\"$dotnet_version\"" >> "$CONFIG_FILE"
    echo "Versão padrão do .NET definida como: $dotnet_version"
}

# Função para definir a porta padrão
set_default_port() {
    local port="$1"
    echo "DEFAULT_PORT=\"$port\"" >> "$CONFIG_FILE"
    echo "Porta padrão definida como: $port"
}

# Função para definir o caminho padrão do projeto
set_default_project_path() {
    local project_path="$1"
    echo "DEFAULT_PROJECT_PATH=\"$project_path\"" >> "$CONFIG_FILE"
    echo "Caminho padrão do projeto definido como: $project_path"
}

# Função para definir a rede padrão do Docker
set_default_docker_network() {
    local network_name="$1"
    echo "DEFAULT_DOCKER_NETWORK=\"$network_name\"" >> "$CONFIG_FILE"
    echo "Rede Docker padrão definida como: $network_name"
}

# Função para obter o ID do usuário e grupo atual
get_user_group_ids() {
    USER_ID=$(id -u)
    GROUP_ID=$(id -g)
}

# Função para obter o nome da solução existente
get_solution_name() {
    SOLUTION_NAME=$(ls *.sln 2>/dev/null | head -n 1)
    if [ -z "$SOLUTION_NAME" ]; then
        echo "Nenhuma solução encontrada na pasta raiz."
        exit 1
    fi
    SOLUTION_NAME=${SOLUTION_NAME%.sln}
}

# Função para criar diretórios se não existirem
create_directories() {
    local project_path=$1

    if [ ! -d "$PROJECT_DIR/$project_path" ]; then
        mkdir -p "$PROJECT_DIR/$project_path"
        chown $USER_ID:$GROUP_ID "$PROJECT_DIR/$project_path"
    fi
}

# Função para criar e inicializar o projeto
create_project() {
    load_config

    local project_path="$DEFAULT_PROJECT_PATH"
    local project_type
    local dotnet_version="$DEFAULT_DOTNET_VERSION"
    local solution_path

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --path) project_path="$2"; shift ;;
            --type) project_type="$2"; shift ;;
            --version) dotnet_version="$2"; shift ;;
            --solution) solution_path="$2"; shift ;;
            *) echo "Parâmetro desconhecido: $1"; exit 1 ;;
        esac
        shift
    done

    local root_project_path="$DEFAULT_ROOT_PROJECT_PATH"
    local docker_image="mcr.microsoft.com/dotnet/sdk:${dotnet_version}"
    local project_name=$(basename $project_path)
    local project_dir=$(dirname $project_path)

    create_directories "$root_project_path/$project_path"

    # Cria o projeto no caminho especificado
    docker run --rm -v "$(pwd):/workspace" -w "/workspace/$root_project_path/$project_dir" -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet new $project_type -n $project_name

    # Verifica se o tipo de projeto é webapi e adiciona um controlador padrão se necessário
    if [ "$project_type" == "webapi" ]; then
        docker run --rm -v "$(pwd):/workspace" -w "/workspace/$root_project_path/$project_path" -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet new controller -name WeatherForecastController
    fi

    # Adiciona o projeto à solução se especificado
    if [ ! -z "$solution_path" ]; then
        docker run --rm -v "$(pwd):/workspace" -w "/workspace" -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet sln $solution_path add "$root_project_path/$project_path/$project_name.csproj"
    fi

    echo "Novo projeto $project_name criado e adicionado à solução com sucesso."
}

# Comando para restaurar dependências
restore_project() {
    load_config

    local project_path="$DEFAULT_PROJECT_PATH"
    local dotnet_version="$DEFAULT_DOTNET_VERSION"

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --path) project_path="$2"; shift ;;
            --version) dotnet_version="$2"; shift ;;
            *) echo "Parâmetro desconhecido: $1"; exit 1 ;;
        esac
        shift
    done

    local docker_image="mcr.microsoft.com/dotnet/sdk:${dotnet_version}"

    docker run --rm -v $PROJECT_DIR:/workspace -w /workspace/$project_path -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet restore
}

# Comando para compilar o projeto
build_project() {
    load_config

    local project_path="$DEFAULT_PROJECT_PATH"
    local dotnet_version="$DEFAULT_DOTNET_VERSION"

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --path) project_path="$2"; shift ;;
            --version) dotnet_version="$2"; shift ;;
            *) echo "Parâmetro desconhecido: $1"; exit 1 ;;
        esac
        shift
    done

    local docker_image="mcr.microsoft.com/dotnet/sdk:${dotnet_version}"

    docker run --rm -v $PROJECT_DIR:/workspace -w /workspace/$project_path -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet build
}

# Função para executar o projeto
run_project() {
    load_config

    local project_path="$DEFAULT_PROJECT_PATH"
    local dotnet_version="$DEFAULT_DOTNET_VERSION"
    local port="$DEFAULT_PORT"
    local debug=""
    local network="$DEFAULT_DOCKER_NETWORK"
    local container_name="dotnet_run_container"

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --path) project_path="$2"; shift ;;
            --version) dotnet_version="$2"; shift ;;
            --port) port="$2"; shift ;;
            --debug) debug="--configuration Debug"; ;;
            --network) network="$2"; shift ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done

    create_network_if_not_exists "$network"
    export ASPNETCORE_URLS="http://0.0.0.0:$port"
    local root_project_path="$DEFAULT_ROOT_PROJECT_PATH"
    local docker_image="mcr.microsoft.com/dotnet/sdk:${dotnet_version}"

    docker run -d --name $container_name -v "$(pwd):/workspace" -w "/workspace/$root_project_path/$project_path" --network $network -p $port:$port -e ASPNETCORE_URLS -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet run --urls "http://0.0.0.0:$port" $debug
}

# Função para assistir mudanças no projeto e recompilar automaticamente
watch_project() {
    load_config

    local project_path="$DEFAULT_PROJECT_PATH"
    local dotnet_version="$DEFAULT_DOTNET_VERSION"
    local port="$DEFAULT_PORT"
    local debug=""
    local network="$DEFAULT_DOCKER_NETWORK"
    local container_name="dotnet_watch_container"

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --path) project_path="$2"; shift ;;
            --version) dotnet_version="$2"; shift ;;
            --port) port="$2"; shift ;;
            --debug) debug="--configuration Debug"; ;;
            --network) network="$2"; shift ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done

    create_network_if_not_exists "$network"
    export ASPNETCORE_URLS="http://0.0.0.0:$port"
    local root_project_path="$DEFAULT_ROOT_PROJECT_PATH"
    local docker_image="mcr.microsoft.com/dotnet/sdk:${dotnet_version}"

    docker run -d --name $container_name -v "$(pwd):/workspace" -w "/workspace/$root_project_path/$project_path" --network $network -p $port:$port -e ASPNETCORE_URLS -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet watch run --urls "http://0.0.0.0:$port" $debug
}

# Função para publicar o projeto
publish_project() {
    load_config

    local project_path="$DEFAULT_PROJECT_PATH"
    local dotnet_version="$DEFAULT_DOTNET_VERSION"
    local publish_path="$DEFAULT_PUBLISH_PATH"
    local runtime="linux-x64"
    local root_project_path="$DEFAULT_ROOT_PROJECT_PATH"
    local docker_image="mcr.microsoft.com/dotnet/sdk:${dotnet_version}"

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --path) project_path="$2"; shift ;;
            --version) dotnet_version="$2"; shift ;;
            --publish-path) publish_path="$2"; shift ;;
            --runtime) runtime="$2"; shift ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done

    create_directories "$publish_path"

    echo "Publishing project at $root_project_path/$project_path to $publish_path..."

    docker run --rm -v "$(pwd):/workspace" -w "/workspace/$root_project_path/$project_path" -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet publish -c Release -r $runtime --self-contained -o "/workspace/$publish_path"

    echo "Project published to $publish_path"
}

# Comando para aplicar migrações
migrate_database() {
    load_config

    local project_path="$DEFAULT_PROJECT_PATH"
    local dotnet_version="$DEFAULT_DOTNET_VERSION"

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --path) project_path="$2"; shift ;;
            --version) dotnet_version="$2"; shift ;;
            *) echo "Parâmetro desconhecido: $1"; exit 1 ;;
        esac
        shift
    done

    local docker_image="mcr.microsoft.com/dotnet/sdk:${dotnet_version}"

    docker run --rm -v $PROJECT_DIR:/workspace -w /workspace/$project_path -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet ef database update
}

# Comando para criar uma migração
create_migration() {
    load_config

    local project_path="$DEFAULT_PROJECT_PATH"
    local migration_name
    local dotnet_version="$DEFAULT_DOTNET_VERSION"

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --path) project_path="$2"; shift ;;
            --name) migration_name="$2"; shift ;;
            --version) dotnet_version="$2"; shift ;;
            *) echo "Parâmetro desconhecido: $1"; exit 1 ;;
        esac
        shift
    done

    if [ -z "$migration_name" ]; then
        echo "Por favor, forneça um nome para a migração."
        exit 1
    fi

    local docker_image="mcr.microsoft.com/dotnet/sdk:${dotnet_version}"

    docker run --rm -v $PROJECT_DIR:/workspace -w /workspace/$project_path -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet ef migrations add $migration_name
}

# Comando para remover uma migração
remove_migration() {
    load_config

    local project_path="$DEFAULT_PROJECT_PATH"
    local dotnet_version="$DEFAULT_DOTNET_VERSION"

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --path) project_path="$2"; shift ;;
            --version) dotnet_version="$2"; shift ;;
            *) echo "Parâmetro desconhecido: $1"; exit 1 ;;
        esac
        shift
    done

    local docker_image="mcr.microsoft.com/dotnet/sdk:${dotnet_version}"

    docker run --rm -v $PROJECT_DIR:/workspace -w /workspace/$project_path -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet ef migrations remove
}

# Comando para reverter uma migração
rollback_migration() {
    load_config

    local project_path="$DEFAULT_PROJECT_PATH"
    local migration_name
    local dotnet_version="$DEFAULT_DOTNET_VERSION"

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --path) project_path="$2"; shift ;;
            --name) migration_name="$2"; shift ;;
            --version) dotnet_version="$2"; shift ;;
            *) echo "Parâmetro desconhecido: $1"; exit 1 ;;
        esac
        shift
    done

    if [ -z "$migration_name" ]; then
        echo "Por favor, forneça o nome da migração para a qual reverter."
        exit 1
    fi

    local docker_image="mcr.microsoft.com/dotnet/sdk:${dotnet_version}"

    docker run --rm -v $PROJECT_DIR:/workspace -w /workspace/$project_path -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet ef database update $migration_name
}

# Comando para adicionar um pacote NuGet
add_nuget_package() {
    load_config

    local project_path="$DEFAULT_PROJECT_PATH"
    local package_name
    local package_version
    local dotnet_version="$DEFAULT_DOTNET_VERSION"

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --path) project_path="$2"; shift ;;
            --package) package_name="$2"; shift ;;
            --version) package_version="$2"; shift ;;
            --dotnet-version) dotnet_version="$2"; shift ;;
            *) echo "Parâmetro desconhecido: $1"; exit 1 ;;
        esac
        shift
    done

    if [ -z "$package_name" ]; then
        echo "Por favor, forneça o nome do pacote NuGet."
        exit 1
    fi

    local docker_image="mcr.microsoft.com/dotnet/sdk:${dotnet_version}"

    if [ -z "$package_version" ]; then
        docker run --rm -v $PROJECT_DIR:/workspace -w /workspace/$project_path -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet add package $package_name
    else
        docker run --rm -v $PROJECT_DIR:/workspace -w /workspace/$project_path -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet add package $package_name --version $package_version
    fi
}

# Comando para listar pacotes NuGet
list_nuget_packages() {
    load_config

    local project_path="$DEFAULT_PROJECT_PATH"
    local dotnet_version="$DEFAULT_DOTNET_VERSION"

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --path) project_path="$2"; shift ;;
            --version) dotnet_version="$2"; shift ;;
            *) echo "Parâmetro desconhecido: $1"; exit 1 ;;
        esac
        shift
    done

    local docker_image="mcr.microsoft.com/dotnet/sdk:${dotnet_version}"

    docker run --rm -v $PROJECT_DIR:/workspace -w /workspace/$project_path -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet list package
}

# Comando para remover um pacote NuGet
remove_nuget_package() {
    load_config

    local project_path="$DEFAULT_PROJECT_PATH"
    local package_name
    local dotnet_version="$DEFAULT_DOTNET_VERSION"

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --path) project_path="$2"; shift ;;
            --package) package_name="$2"; shift ;;
            --version) dotnet_version="$2"; shift ;;
            *) echo "Parâmetro desconhecido: $1"; exit 1 ;;
        esac
        shift
    done

    if [ -z "$package_name" ]; then
        echo "Por favor, forneça o nome do pacote NuGet."
        exit 1
    fi

    local docker_image="mcr.microsoft.com/dotnet/sdk:${dotnet_version}"

    docker run --rm -v $PROJECT_DIR:/workspace -w /workspace/$project_path -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet remove package $package_name
}

# Função para adicionar um novo projeto à solução existente
add_project() {
    load_config

    local project_path="$DEFAULT_PROJECT_PATH"
    local project_type
    local dotnet_version="$DEFAULT_DOTNET_VERSION"

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --path) project_path="$2"; shift ;;
            --type) project_type="$2"; shift ;;
            --version) dotnet_version="$2"; shift ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done

    get_solution_name

    local root_project_path="$DEFAULT_ROOT_PROJECT_PATH"
    local docker_image="mcr.microsoft.com/dotnet/sdk:${dotnet_version}"
    local project_name=$(basename $project_path)
    local project_dir=$(dirname $project_path)

    create_directories "$root_project_path/$project_path"

    echo "Adding new project $project_name to solution $SOLUTION_NAME..."
    
    # Create the project in the specified path
    docker run --rm -v "$(pwd):/workspace" -w "/workspace/$root_project_path/$project_dir" -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet new $project_type -n $project_name

    # Add a default controller if the project type is webapi
    if [ "$project_type" == "webapi" ]; then
        docker run --rm -v "$(pwd):/workspace" -w "/workspace/$root_project_path/$project_path" -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet new controller -name WeatherForecastController
    fi

    # Add the project to the solution
    docker run --rm -v "$(pwd):/workspace" -w "/workspace" -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet sln "$root_project_path/$SOLUTION_NAME.sln" add "$root_project_path/$project_path/$project_name.csproj"

    echo "New project $project_name added to solution $SOLUTION_NAME successfully."
}

# Função para inicializar o ambiente de desenvolvimento
init_environment() {
    load_config

    local solution_name
    local project_path="$DEFAULT_PROJECT_PATH"
    local root_project_path="$DEFAULT_ROOT_PROJECT_PATH"
    local project_type
    local dotnet_version="$DEFAULT_DOTNET_VERSION"

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --solution) solution_name="$2"; shift ;;
            --path) project_path="$2"; shift ;;
            --type) project_type="$2"; shift ;;
            --version) dotnet_version="$2"; shift ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done

    if [ -z "$solution_name" ] || [ -z "$project_type" ]; then
        echo "Usage: ./project_manager.sh init --solution [solution_name] --type [project_type] [--path project_path] [--version dotnet_version]"
        echo "Example: ./project_manager.sh init --solution TesteDocker --type webapi --path app/td.api.test"
        exit 1
    fi

    echo "Initializing development environment for solution $solution_name and project at $project_path..."

    local docker_image="mcr.microsoft.com/dotnet/sdk:${dotnet_version}"

    # Create directories with correct permissions
    create_directories "$root_project_path/$project_path"

    # Create the solution in the root project directory
    docker run --rm -v "$(pwd):/workspace" -w "/workspace/$root_project_path" -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet new sln -n $solution_name

    create_project --path $project_path --type $project_type --version $dotnet_version --solution "$root_project_path/$solution_name.sln"
    restore_project --path "$root_project_path/$project_path" --version $dotnet_version
    build_project --path "$root_project_path/$project_path" --version $dotnet_version
    echo "Development environment initialized successfully."
}

# Função para criar e inicializar o projeto
create_project() {
    load_config

    local project_path="$DEFAULT_PROJECT_PATH"
    local project_type
    local dotnet_version="$DEFAULT_DOTNET_VERSION"
    local solution_path

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --path) project_path="$2"; shift ;;
            --type) project_type="$2"; shift ;;
            --version) dotnet_version="$2"; shift ;;
            --solution) solution_path="$2"; shift ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done

    local root_project_path="$DEFAULT_ROOT_PROJECT_PATH"
    local docker_image="mcr.microsoft.com/dotnet/sdk:${dotnet_version}"
    local project_name=$(basename $project_path)
    local project_dir=$(dirname $project_path)

    create_directories "$root_project_path/$project_path"

    # Create the project in the specified path
    docker run --rm -v "$(pwd):/workspace" -w "/workspace/$root_project_path/$project_dir" -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet new $project_type -n $project_name

    # Add a default controller if the project type is webapi
    if [ "$project_type" == "webapi" ]; then
        docker run --rm -v "$(pwd):/workspace" -w "/workspace/$root_project_path/$project_path" -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet new controller -name WeatherForecastController
    fi

    # Add the project to the solution if specified
    if [ ! -z "$solution_path" ]; then
        docker run --rm -v "$(pwd):/workspace" -w "/workspace" -e DOTNET_CLI_HOME=/tmp --user "$(id -u):$(id -g)" $docker_image dotnet sln $solution_path add "$root_project_path/$project_path/$project_name.csproj"
    fi

    echo "New project $project_name created and added to the solution successfully."
}

# Função para verificar e criar a rede Docker
create_network_if_not_exists() {
    local network_name="$1"
    if ! docker network inspect "$network_name" > /dev/null 2>&1; then
        echo "Creating Docker network: $network_name"
        docker network create "$network_name"
    else
        echo "Docker network $network_name already exists"
    fi
}

# Função para parar o contêiner de run
stop_run_container() {
    local container_name="dotnet_run_container"
    echo "Stopping container $container_name..."
    docker stop $container_name && docker rm $container_name
}

# Função para parar o contêiner de watch
stop_watch_container() {
    local container_name="dotnet_watch_container"
    echo "Stopping container $container_name..."
    docker stop $container_name && docker rm $container_name
}

# Comando para subir o ambiente Docker
up_environment() {
    if command -v docker-compose &> /dev/null; then
        docker-compose -f ./.docker/docker-compose.yml up
    else
        docker compose -f ./.docker/docker-compose.yml up
    fi
}

# Comando para derrubar o ambiente Docker
down_environment() {
    if command -v docker-compose &> /dev/null; then
        docker-compose -f ./.docker/docker-compose.yml down
    else
        docker compose -f ./.docker/docker-compose.yml down
    fi
}

# Comando para criar um projeto React
create_react_app() {
    load_config

    local node_version="$DEFAULT_NODE_VERSION"
    local project_name="frontend"

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --version) node_version="$2"; shift ;;
            --name) project_name="$2"; shift ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done

    docker run --rm -v "$(pwd):/workspace" -w /workspace "node:$node_version" sh -c "npx create-react-app $project_name --template typescript"
}

# Comando para criar um projeto Next.js
create_next_app() {
    load_config

    local node_version="$DEFAULT_NODE_VERSION"

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --version) node_version="$2"; shift ;;
            --name) project_name="$2"; shift ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
        shift
    done

    docker run --rm -v "$(pwd):/workspace" -w /workspace "node:$node_version" sh -c "npx create-next-app"
} 

# Comando para executar um comando Docker arbitrário
run_custom_command() {
    local custom_command="$1"

    if [ -z "$custom_command" ]; then
        echo "Uso: ./project_manager.sh run-custom-command '[comando]'"
        echo "Exemplo: ./project_manager.sh run-custom-command 'npx create-react-app frontend --template typescript'"
        exit 1
    fi

    if command -v docker-compose &> /dev/null; then
        docker-compose -f docker-compose.create-project.yml run --rm create-project sh -c "$custom_command"
    else
        docker compose -f docker-compose.create-project.yml run --rm create-project sh -c "$custom_command"
    fi
}

# Function to display help organized in three columns with proper formatting
show_help() {
    printf "%-30s %-60s %s\n" "Command" "Parameters" "Description"
    printf "%-30s %-60s %s\n" "-------" "----------" "-----------"
    printf "%-30s %-60s %s\n" \
        "set-default-path" "[project_path]" "Set the default project path" \
        "set-default-dotnet-version" "[dotnet_version]" "Set the default .NET version" \
        "set-default-port" "[port]" "Set the default port" \
        "set-default-network" "[network_name]" "Set the default Docker network" \
        "set-default-node-version" "[node_version]" "Set the default Node.js version" \
        "set-default-publish-path" "[publish_path]" "Set the default publish path" \
        "init" "--solution [solution_name] --type [project_type] [--path project_path] \n%28s [--version dotnet_version]" "Initialize the development environment" \
        "add-project" "--type [project_type] [--path project_path] \n%28s [--version dotnet_version]" "Add a new project to the existing solution" \
        "create" "[--path project_path] --type [project_type] \n%28s [--version dotnet_version]" "Create a new project and add it to the existing solution" \
        "restore" "[--path project_path] [--version dotnet_version]" "Restore project dependencies" \
        "build" "[--path project_path] [--version dotnet_version]" "Build the project" \
        "run" "[--path project_path] [--version dotnet_version] \n%28s [--port port] [--debug] [--network network_name]" "Run the project in detached mode" \
        "stop-run" "" "Stop the running project container" \
        "watch" "[--path project_path] [--version dotnet_version] \n%28s [--port port] [--debug] [--network network_name]" "Watch for changes and rebuild the project in detached mode" \
        "stop-watch" "" "Stop the watching project container" \
        "migrate" "[--path project_path] [--version dotnet_version]" "Apply database migrations" \
        "add-migration" "--name [migration_name] [--path project_path] \n%28s [--version dotnet_version]" "Create a new migration" \
        "remove-migration" "[--path project_path] [--version dotnet_version]" "Remove the last migration" \
        "rollback-migration" "--name [migration_name] [--path project_path] \n%28s [--version dotnet_version]" "Revert to a specific migration" \
        "add-nuget" "--package [package_name] [--path project_path] \n%28s [--version package_version] [--dotnet-version dotnet_version]" "Add a NuGet package to the project" \
        "list-nuget" "[--path project_path] [--version dotnet_version]" "List NuGet packages in the project" \
        "remove-nuget" "--package [package_name] [--path project_path] \n%28s [--version dotnet_version]" "Remove a NuGet package from the project" \
        "up" "[-d] [--build]" "Start the Docker environment" \
        "down" "[-d] [--build]" "Stop the Docker environment" \
        "create-next-app" "[--version node_version] [--name project_name]" "Create a React project using create-next-app" \
        "create-react-app" "[--version node_version] [--name project_name]" "Create a React project using create-react-app with TypeScript" \
        "run-custom-command" "'[command]'" "Run a custom command in the Docker container" \
        "publish" "[--path project_path] [--version dotnet_version] \n%28s [--publish-path publish_path] [--runtime runtime]" "Publish the project as self-contained for Nginx" \
        "help" "" "Show this help message"
}

# Check the provided command
case "$1" in
    set-default-path)
        shift
        set_default_project_path "$@"
        ;;
    set-default-dotnet-version)
        shift
        set_default_dotnet_version "$@"
        ;;
    set-default-port)
        shift
        set_default_port "$@"
        ;;
    set-default-network)
        shift
        set_default_docker_network "$@"
        ;;
    set-default-node-version)
        shift
        set_default_node_version "$@"
        ;;
    set-default-publish-path)
        shift
        set_default_publish_path "$@"
        ;;
    init)
        get_user_group_ids
        shift
        init_environment "$@"
        ;;
    add-project)
        get_user_group_ids
        shift
        add_project "$@"
        ;;
    create)
        get_user_group_ids
        shift
        create_project "$@"
        ;;
    restore)
        get_user_group_ids
        shift
        restore_project "$@"
        ;;
    build)
        get_user_group_ids
        shift
        build_project "$@"
        ;;
    run)
        get_user_group_ids
        shift
        run_project "$@"
        ;;
    stop-run)
        stop_run_container
        ;;
    watch)
        get_user_group_ids
        shift
        watch_project "$@"
        ;;
    stop-watch)
        stop_watch_container
        ;;
    migrate)
        get_user_group_ids
        shift
        migrate_database "$@"
        ;;
    add-migration)
        get_user_group_ids
        shift
        create_migration "$@"
        ;;
    remove-migration)
        get_user_group_ids
        shift
        remove_migration "$@"
        ;;
    rollback-migration)
        get_user_group_ids
        shift
        rollback_migration "$@"
        ;;
    add-nuget)
        get_user_group_ids
        shift
        add_nuget_package "$@"
        ;;
    list-nuget)
        get_user_group_ids
        shift
        list_nuget_packages "$@"
        ;;
    remove-nuget)
        get_user_group_ids
        shift
        remove_nuget_package "$@"
        ;;
    up)
        shift
        up_environment "$@"
        ;;
    down)
        shift
        down_environment "$@"
        ;;
    create-next-app)
        shift
        create_next_app "$@"
        ;;
    create-react-app)
        shift
        create_react_app "$@"
        ;;
    run-custom-command)
        shift
        run_custom_command "$@"
        ;;
    publish)
        shift
        publish_project "$@"
        ;;
    help | *)
        show_help
        ;;
esac
