FROM mcr.microsoft.com/dotnet/sdk:8.0

# Definir diretório de trabalho
WORKDIR /workspace

# Argumentos para UID e GID
ARG USER_ID
ARG GROUP_ID

# Criar um usuário não-root com UID e GID do host
RUN addgroup --gid ${GROUP_ID} devgroup && \
    adduser --disabled-password --gecos '' --uid ${USER_ID} --gid ${GROUP_ID} devuser

# Copiar o script para o contêiner
COPY docker/project_manager.sh /workspace/project_manager.sh

# Instalar ferramentas adicionais, se necessário
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Permitir execução do script
RUN chmod +x /workspace/project_manager.sh

# Configurar o alias para o usuário devuser
RUN echo "alias net='/workspace/project_manager.sh'" >> /home/devuser/.bashrc

# Definir o usuário atual como devuser
USER devuser

# Expor as portas para acessar o servidor web
EXPOSE 5000
EXPOSE 5001

# Comando padrão do contêiner
CMD ["sleep", "infinity"]
