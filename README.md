# .NET Project in Docker WSL / React
This repository contains the project_manager.sh script that makes it easy to create, manage, and run .NET projects within a Docker environment. The script offers several commands to initialize solutions, add projects, restore dependencies, compile, run, apply migrations, manage NuGet packages, and more.
In addition to the backend.
net it is also possible to start a frontend project in React. The environment also has a MYSQL database version 8, mailpit for email testing and minio to simulate the AWS environment. And to facilitate an nginx server for React, mailpit and minio applications.

### Prerequisites
- Docker
- Docker Compose
- Visual Studio Code with the Remote - Containers extension

## Alias for the Script
To make using the project_manager.sh script easier, you can create an alias in your shell configuration file (.bashrc, .zshrc, etc.). Add the line below to the end of your configuration file:
```sh
alias net="docker/project_manager.sh"

# Replace path/to/your with the actual path where the project_manager.sh script is located.

# After adding the line, reload the configuration file:

source ~/.bashrc # or source ~/.zshrc, depending on your shell

# Now you can use the alias net to call the project_manager.sh script from anywhere:

net init --solution TestDocker --type webapi --path src/app/td.api.test
net add-project --type classlib --path src/domain/td.domain.test
net migrate --path src/app/td.api.test
```

## Requirements

* Docker and Docker Compose installed
* Bash shell (to run the initialization and update scripts)

Make the script executable:
```sh
chmod +x "$(pwd)/docker/project_manager.sh"
```

## Set Default Project Path

To set the default project path, use the set-default-path command:
```sh
net set-default-path src/app/td.api.test
```
The command above generates a .project_manager_config file where the base path is saved. This path will be used as the base for commands that use the --path variable. However, this does not prevent you from specifying a path to create a new project, for example.

## Available Commands - Summary
The project_manager.sh script offers the following commands:

* `set-default-path`: Sets the default project path.
* `set-default-dotnet-version`: Sets the .NET version to use in the project.
* `set-default-port`: Sets the default port for running or debugging the project.
* `init`: Initializes the development environment.
* `add-project`: Adds a new project to the existing solution.
* `create`: Creates a new project and adds it to the existing solution.
* `restore`: Restores project dependencies.
* `build`: Builds the project.
* `run`: Runs the project.
* `migrate`: Applies migrations to the database.
* `add-migration`: Creates a new migration.
* `remove-migration`: Removes the last migration.
* `rollback-migration`: Rolls back to a specific migration.
* `add-nuget`: Adds a NuGet package to the project.
* `list-nuget`: Lists the project's NuGet packages.
* `remove-nuget`: Removes a NuGet package from the project.
* `watch`: Watches for changes in the project and recompiles automatically.
* `help`: Shows the script help.
* `up`: Brings up the project's Docker compose.
* `down`: Brings down the project's Docker compose.

## Example Usage Instructions

### Project Initialization

Initialize the development environment and create a new project:
```sh
- net init --solution TestDocker --type webapi --path src/app/td.api.test
```
### Add a New Project to the Existing Solution

To add a new layer (Application, Domain, Infrastructure), run the command:
```sh
net add-project --type classlib --path src/domain/td.domain.test
```
### Restore Dependencies
```sh
net restore --path src/app/td.api.test
```
### Build the Project
```sh
net build --path src/app/td.api.test
```

### Run the Project
```sh
net run --path src/app/td.api.test --port 5000
```
### Create and Apply Migrations
```sh
net add-migration --path src/app/td.api.test --name InitialCreate
net migrate --path src/app/td.api.test
```
### Add, List, and Remove NuGet Packages
#### Add a NuGet package:
```sh
net add-nuget --path src/app/td.api.test --package Newtonsoft.Json --version 13.0.1
```
#### List NuGet packages:
```sh
net list-nuget --path src/app/td.api.test
```

#### Remove a NuGet package:
```sh
net remove-nuget --path src/app/td.api.test --package Newtonsoft.Json
```

## For Development
### Watch for Changes and Recompile Automatically
```sh
net watch --path src/app/td.api.test --port 5000
```

## Commands and Instructions

### set-default-path

Sets the default project path to be used when a path is not explicitly provided in other commands

```sh
net set-default-path [caminho_do_projeto]
```
Example:
```sh
net set-default-path src/app/td.api.test
```

### set-default-dotnet-version
Sets the default .NET version to be used when a version is not explicitly provided in other commands.

```sh
net set-default-dotnet-version [versao_do_dotnet]
```

Example:
```sh
net set-default-dotnet-version 8.0
```

### set-default-port
Sets the default port to be used when a port is not explicitly provided in other commands.

```sh
net set-default-port [porta]
```
Example:
```sh
net set-default-port 5000
```

### init
Initializes the development environment, creating a solution and adding a project.

```sh
net init --solution [nome_da_solucao] --type [tipo_do_projeto] [--path caminho_do_projeto] [--version versao_do_dotnet]
```

Variables:
* `--solution [solution_name]`: Required. Name of the solution to be created.
* `--type [project_type]`: Required. Type of the project to be created (e.g., console, webapi, classlib, etc.).
* `--path [project_path]`: Optional. Path where the project will be created. If not provided, the default path will be used.
* `--version [dotnet_version]`: Optional. .NET version to be used (e.g., 7.0, 8.0). Default is 8.0.

Example:
```sh
net init --solution TesteDocker --type webapi --path src/app/td.api.test
```

### add-project
Adds a new project to the existing solution.

```sh
net add-project --type [project_type] [--path project_path] [--version dotnet_version]
```

Variables:
* `--type [project_type]`: Required. Type of the project to be created (e.g., console, webapi, classlib, etc.).
* `--path [project_path]`: Optional. Path where the project will be created. If not provided, the default path will be used.
* `--version [dotnet_version]`: Optional. .NET version to be used (e.g., 7.0, 8.0). Default is 8.0.

Example:
```sh
net add-project --type classlib --path src/domain/td.domain.test
```

### create
Creates a new project and adds it to the existing solution.

```sh
net create [--path project_path] --type [project_type] [--version dotnet_version]
```

Variables:
* `--path [project_path]`: Optional. Path where the project will be created. If not provided, the default path will be used.
* `--type [project_type]`: Required. Type of the project to be created (e.g., console, webapi, classlib, etc.).
* `--version [dotnet_version]`: Optional. .NET version to be used (e.g., 7.0, 8.0). Default is 8.0.

Example:
```sh
net create --path src/app/td.api.test --type webapi
```

### restore
Restores project dependencies.

```sh
net restore [--path project_path] [--version dotnet_version]
```

Variables:
* `--path [project_path]`: Optional. Path of the project to restore dependencies. If not provided, the default path will be used.
* `--version [dotnet_version]`: Optional. .NET version to be used (e.g., 7.0, 8.0). Default is 8.0.

Example:
```sh
net restore --path src/app/td.api.test
```

### build
Builds the project.

```sh
net build [--path project_path] [--version dotnet_version]
```

Variables:
* `--path [project_path]`: Optional. Path of the project to build. If not provided, the default path will be used.
* `--version [dotnet_version]`: Optional. .NET version to be used (e.g., 7.0, 8.0). Default is 8.0.

Example:
```sh
net build --path src/app/td.api.test
```

### run
Runs the project.

```sh
net run [--path project_path] [--version dotnet_version] [--port port] [--debug]
```

Variables:
* `--path [project_path]`: Optional. Path of the project to run. If not provided, the default path will be used.
* `--version [dotnet_version]`: Optional. .NET version to be used (e.g., 7.0, 8.0). Default is 8.0.
* `--port [port]`: Optional. Port to be used by the project. Default is 5000.
* `--debug`: Optional. Runs the project in debug mode (without recompiling).

Example:
```sh
net run --path src/app/td.api.test --port 5000
```

### migrate
Applies migrations to the database.

```sh
net migrate [--path project_path] [--version dotnet_version]
```

Variables:
* `--path [project_path]`: Optional. Path of the project to apply migrations. If not provided, the default path will be used.
* `--version [dotnet_version]`: Optional. .NET version to be used (e.g., 7.0, 8.0). Default is 8.0.

Example:
```sh
net migrate --path src/app/td.api.test
```

### add-migration
Creates a new migration.

```sh
net add-migration --name [migration_name] [--path project_path] [--version dotnet_version]
```

Variables:
* `--name [migration_name]`: Required. Name of the migration to be created.
* `--path [project_path]`: Optional. Path of the project to create the migration. If not provided, the default path will be used.
* `--version [dotnet_version]`: Optional. .NET version to be used (e.g., 7.0, 8.0). Default is 8.0.

Example:
```sh
net add-migration --name InitialCreate --path src/app/td.api.test
```

### remove-migration
Removes the last migration.

```sh
net remove-migration [--path project_path] [--version dotnet_version]
```
Variables:
* `--path [project_path]`: Optional. Path of the project to remove the migration. If not provided, the default path will be used.
* `--version [dotnet_version]`: Optional. .NET version to be used (e.g., 7.0, 8.0). Default is 8.0.

Example:
```sh
net remove-migration --path src/app/td.api.test
```

### rollback-migration
Rolls back to a specific migration.

```sh
net rollback-migration --name [migration_name] [--path project_path] [--version dotnet_version]
```

Variables:
* `--name [migration_name]`: Required. Name of the migration to roll back to.
* `--path [project_path]`: Optional. Path of the project to roll back the migration. If not provided, the default path will be used.
* `--version [dotnet_version]`: Optional. .NET version to be used (e.g., 7.0, 8.0). Default is 8.0.

Example:
```sh
net rollback-migration --name InitialCreate --path src/app/td.api.test
```

### add-nuget
Adds a NuGet package to the project.

```sh
net add-nuget --package [package_name] [--path project_path] [--version package_version] [--dotnet-version dotnet_version]
```

Variables:
* `--package [package_name]`: Required. Name of the NuGet package to be added.
* `--path [project_path]`: Optional. Path of the project to add the package. If not provided, the default path will be used.
* `--version [package_version]`: Optional. Version of the NuGet package to be added. If not provided, the latest available version is added.
* `--dotnet-version [dotnet_version]`: Optional. .NET version to be used (e.g., 7.0, 8.0). Default is 8.0.

Example:
```sh
net add-nuget --package Newtonsoft.Json --path src/app/td.api.test --version 13.0.1
```

### list-nuget
Lists the project's NuGet packages.

```sh
net list-nuget [--path project_path] [--version dotnet_version]
```

Variables:
* `--path [project_path]`: Optional. Path of the project to list the packages. If not provided, the default path will be used.
* `--version [dotnet_version]`: Optional. .NET version to be used (e.g., 7.0, 8.0). Default is 8.0.
Example:
```sh
net list-nuget --path src/app/td.api.test
```

### remove-nuget
Removes a NuGet package from the project.

```sh
net remove-nuget --package [package_name] [--path project_path] [--version dotnet_version]
```

Variables:
* `--package [package_name]`: Required. Name of the NuGet package to be removed.
* `--path [project_path]`: Optional. Path of the project to remove the package. If not provided, the default path will be used.
* `--version [dotnet_version]`: Optional. .NET version to be used (e.g., 7.0, 8.0). Default is 8.0.

Example:
```sh
net remove-nuget --package Newtonsoft.Json --path src/app/td.api.test
```

### watch
Watches for changes in the project and recompiles automatically.

```sh
net watch [--path project_path] [--version dotnet_version] [--port port] [--debug]
```

Variables:
* `--path [project_path]`: Optional. Path of the project to watch for changes. If not provided, the default path will be used.
* `--version [dotnet_version]`: Optional. .NET version to be used (e.g., 7.0, 8.0). Default is 8.0.
* `--port [port]`: Optional. Port to be used by the project. Default is 5000.
* `--debug`: Optional. Runs the project in debug mode (without hot reload).

Example:
```sh
net watch --path src/app/td.api.test --port 5000
```

### help
Shows detailed help for the script.

```sh
net help
```

### up
Brings up the Docker environment.

```sh
net up
```

Example:
```sh
net up
```

### down
Brings down the Docker environment.

```sh
net down
```

Example:
```sh
net down
```

## Licença

This project is licensed under the terms of the MIT license.
