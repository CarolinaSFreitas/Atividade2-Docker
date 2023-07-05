# 🖥️ Atividade 2 do PB da Compass UOL

<div align="center">
  <img src="/src/logo-compass.png" width="340px">
</div>

### 👥 Integrantes do Grupo 2

- Carolina Freitas
- Gabriel Matiolla
- Gabriel Torino

### 📝 Sobre a Atividade

1. Instalação e configuração do DOCKER ou CONTAINERD no host EC2.
  * Ponto adicional para o trabalho que utilizar a instalação via script de Start Instance (user_data.sh)

2. Efetuar Deploy de uma aplicação Wordpress com: 
  * Container de aplicação
  * RDS database MySQL

3. Configuração da utilização do serviço EFS AWS para estáticos do container de aplicação WordPress

4. Configuração do serviço de Load Balancer AWS para a aplicação Wordpress

<div align="center">
  <img src="/src/arq.jpg" alt="Arquitetura" width="625px">
   <p><em>Arquitetura</em></p>
</div>


## 🔐 Security Groups - Criação

Antes de iniciarmos a criação da EC2, do RDS e do EFS, devemos criar os Security Groups para cada um no console AWS.

+ O SG da EC2 deve conter as seguintes Inbound Rules:

| Type         | Protocol | Port Range | Source Type | Source      |
|--------------|----------|------------|-------------|-------------|
| SSH          | TCP      | 22         | Anywhere    | 0.0.0.0/0   |
| HTTP         | TCP      | 80         | Anywhere    | 0.0.0.0/0   |
##

<div align="center">
  <img src="/src/ec2-sg.jpeg" alt="Security Group para a EC2" width="765px">
   <p><em>Security Group para a EC2</em></p>
</div>

##

+ O SG do RDS deve conter a seguinte Inbound Rule:

| Type         | Protocol | Port Range | Source Type | Source      |
|--------------|----------|------------|-------------|-------------|
| MYSQL/Aurora | TCP      | 3306       | Anywhere    | 0.0.0.0/0   |
##

<div align="center">
  <img src="/src/rds-sg.jpeg" alt="Security Group para o RDS" width="765px">
   <p><em>Security Group para o RDS</em></p>
</div>

##

+ O SG do EFS deve conter a seguinte Inbound Rule:

| Type         | Protocol | Port Range | Source Type | Source      |
|--------------|----------|------------|-------------|-------------|
| NFS          | TCP      | 2049       | Anywhere    | 0.0.0.0/0   |
##

<div align="center">
  <img src="/src/efs-sg.jpeg" alt="Security Group para o EFS" width="765px">
   <p><em>Security Group para o EFS</em></p>
</div>

##


## ☁️ EC2 - Criando a instância

Abra o menu de criação de EC2 no seu console AWS e vá em Launch Instance, feito isso siga os passos de criação da sua EC2 (nome, KeyPair, tipo, sistema operacional, storage) e selecione o Security Group criado para a EC2.

### 📄 User data

No fim das etapas de criação da EC2 terá um campo para você inserir o User data, coloque o seguinte shellscript:

```
#!/bin/bash

sudo yum update -y
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
sudo chkconfig docker on
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo mv /usr/local/bin/docker-compose /bin/docker-compose
sudo yum install nfs-utils -y
sudo mkdir /mnt/efs/
sudo chmod +rwx /mnt/efs/
```

Esse shellscript (user_data.sh) nos auxiliará em:

+ Atualização do sistema operacional

+ Instalação do Docker e do Docker Compose 

+ Configuração de permissões

+ Preparação do ambiente para trabalhar com um sistema de arquivos NFS que armazenará os arquivos do WordPress

Com todos esses passos feitos, basta criar sua instância EC2.


## 🎲 RDS - Criando o Amazon Relational Database Service

O RDS armazenará os arquivos do container de WordPress, então antes de partirmos para o acesso na EC2, devemos criar o banco de dados corretamente.

+ Busque pelo serviço de RDS no console AWS e vá em "Create database"

+ Escolha o Engine type como MySQL

+ Em "Templates" selecione a opção "Free Tier"

+ Dê um nome para a sua instância RDS 

+ **Escolha suas credenciais do banco de dados e guarde essas informações (Master username e Master password), pois são informações necessárias para a criação do container de WordPress**

+ Na etapa de "Connectivity", escolha o Security Group criado especialmente para o RDS, selecione a mesma AZ que sua EC2 criada está e em "Public access" escolha a opção de sim.

+ **Ao fim da criação do RDS, haverá uma etapa chamada "Additional configuration" e nela existe um campo chamado "Initial database name", esse nome também será necessário na criação do container de WordPress**

+ Vá em "Create Database"

<div align="center">
  <img src="/src/db-rds.jpeg" alt="Banco de Dados Criado" width="765px">
   <p><em>Banco de Dados Criado</em></p>
</div>


## 📂 EFS - Criando o Amazon Elastic File System

O EFS armazenará os arquivos estáticos do WordPress. Portanto, para criá-lo corretamente e, em seguida, fazer a montagem no terminal, devemos seguir os seguintes passos:

+ Busque pelo serviço EFS ainda no console AWS e vá em "Create file system"

+ Na janela que se abre, escolha o nome do seu volume EFS

+ Na lista de "File systems" clique no nome do seu EFS e vá na seção "Network". Nessa parte vá no botão "Manage" e altere o SG para o que criamos no início especificamente para o EFS

<div align="center">
  <img src="/src/netw-efs.jpeg" alt="Seção de Network do EFS" width="765px">
   <p><em>Seção de Network do EFS</em></p>
</div>

<div align="center">
  <img src="/src/netw2-efs.jpeg" alt="Janela de Mount targets do EFS" width="765px">
   <p><em>Janela de Mount targets do EFS</em></p>
</div>


## 🗝️ Acessando a EC2 e fazendo configurações

Para fazermos as configurações necessárias na instância EC2 via terminal, devemos seguir os seguintes passos:

1. Confirme que o Docker e o Docker Compose foram instalados com sucessos usando os comandos `` docker ps `` e `` docker-compose --version ``. Apesar desses comandos estarem no shellscript, é sempre bom verificar que as ferramentas estão instaladas corretamente.  

2. O "nfs-utils" também foi instalado durante a inicialização da EC2 através do shellscript de user data, junto a isso foi criado também o caminho para a montagem do seu volume EFS (/mnt/efs/) com as permissões de rwx (leitura, escrita e execução). 

Esse caminho é muito importante e você pode conferir se ele foi criado com sucesso indo até ele com o comando `` cd /mnt/efs/ ``. Com essa confirmação, agora você deve ir novamente no seu console AWS, acessar o serviço de EFS e seguir os seguintes passos:

+ Selecione o seu volume EFS e clique em "Attach" para atachar o volume na sua EC2

+ Na janela aberta selecione "Mount via DNS" e copie o comando de montagem usando o NFS client e cole no terminal da EC2: 

<div align="center">
  <img src="/src/attach-efs.jpeg" alt="Janela de Attach do EFS" width="855px">
   <p><em>Janela de Attach do EFS</em></p>
</div>

**Não se esqueça de alterar o caminho no final do comando para /mnt/efs/**

+ Para confirmar a montagem do EFS execute `` df -h `` 

<div align="center">
  <img src="/src/df-h.jpeg" alt="Saída do comando df -h" width="785px">
   <p><em>Saída do comando df -h</em></p>
</div>

3. Para automatizar a montagem do volume EFS na sua instância EC2 faça o seguinte:

+ Edite o "fstab" com o comando `` nano /etc/fstab ``

+ Não exclua a linha que está no arquivo, apenas adicione: `` fs-0e220829bf4606496.efs.us-east-1.amazonaws.com:/    /mnt/efs    nfs4    defaults,_netdev,rw    0   0 ``, mas não se esqueça de alterar o DNS name para o do seu EFS

<div align="center">
  <img src="/src/fstab.jpeg" alt="Arquivo fstab" width="735px">
   <p><em>Arquivo fstab</em></p>
</div>

+ Feito isso, salve o arquivo e executa os comandos `` sudo umount /mnt/efs `` e depois `` sudo mount -a `` no terminal

+ Para confirmar novamente a montagem do EFS execute `` df -h ``

## 📄 Docker Compose - Criação do docker-compose.yml

Para subirmos o container do WordPress devemos criar um arquivo .yml/.yaml com as seguintes instruções:

1. Execute o comando `` nano docker-compose.yml `` e adicione:

```
version: '3.3'
services:
  wordpress:
    image: wordpress:latest
    volumes:
      - /mnt/efs/wordpress:/var/www/html
    ports:
      - 80:80
    restart: always
    environment:
      WORDPRESS_DB_HOST: endpoint do seu RDS
      WORDPRESS_DB_USER: seu master username (ex: admin)
      WORDPRESS_DB_PASSWORD: sua master password
      WORDPRESS_DB_NAME: nome do banco de dados (não o da instância RDS)
      WORDPRESS_TABLE_CONFIG: wp_
```

2. Dessa forma o arquivo YAML está pronto para inicializar o container de WordPress, então execute o comando: `` docker-compose up -d `` 

<div align="center">
  <img src="/src/docker-compose-d.jpeg" alt="Subindo o container com o 'docker-compose up -d'" width="755px">
   <p><em>Subindo o container com o 'docker-compose up -d'</em></p>
</div>

3. Para confirmar o armazenamento no EFS dos arquivos do WordPress gerados pelo Compose vá até o "/mnt/efs/":

<div align="center">
  <img src="/src/efs-wp.jpeg" alt="Arquivos do WP armazenados no EFS" width="755px">
   <p><em>Arquivos do WP armazenados no EFS</em></p>
</div>

4. Se quiser confirmar o RDS no container WordPress execute o container e acesse o MySQL com os seguintes passos:

+ `` docker exec -it <ID_DO_CONTAINER_WORDPRESS> /bin/bash `` 

+ Dentro do container WordPress execute: ``apt-get update`` e depois `` apt-get install default-mysql-client``.

+ Agora use o comando: `` mysql -h <ENDPOINT_DO_SEU_RDS> -P 3306 -u admin -p `` para entrar no banco de dados MySQL com as mesmas credenciais do seu RDS.

<div align="center">
  <img src="/src/mysql.jpeg" alt="Banco de Dados MySQL" width="600px">
   <p><em>Banco de Dados MySQL</em></p>
</div>
