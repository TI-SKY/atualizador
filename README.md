# atualizador
Scripts para automatizar atualizações dos sistemas sky


Os arquivos atualizador.ps1 e atualizador.sh devem ser salvos dentro do diretório `atualizador`, colocado no diretório sky do servidor de arquivos.
Não importa a estrutura de diretórios até chegar na pasta sky (/sky, /home/sky, /dados/sky, D:\sky\, F:\sky), o diretório `atualizador` deve ficar no mesmo diretório da executaveis, NÃO dentro dele.
Principal atenção quando o servidor de executaveis for diferente do de dados.
Não deve-se colocar os scripts dentro da executaveis, pois ela está na rede e deixaria disponíveis scripts que devem rodar como admin.
Para Servidores windows o arquivo handle64.exe deve ser copiado junto.

Os scripts devem ser invocados por um serviço rodando com privilégios de administrador.

Em conjunto, esperasse a possibilidade de um programa atualizador que rodaria numa estação windows, para que o cliente posa acompanhar o processo de atualização, e também o qual deveria disparar o processo de atualização no servidor.

## LINUX

- /sky/atualizador/atualizador.sh

## WINDOWS

- C:\sky\atualizador\atualizador.ps1
- C:\sky\atualizador\handle64.exe

## FUNCIONAMENTO

Ambos scripts operam pela mesma lógica.

Antes de iniciar são realizados alguns testes para verificar se é possível continuar rodando o script, ou não.


O próximo passo é encerrar todos os arquivos abertos no compartilhamento.
Embora seja feito um filtro para buscar apenas arquivos do sistema em atuailzação, pids de processos do `smbstatus` podem ser iguais para o mesmo cliente em vários arquivos.
No windows, como seria possível a execução de sistemas sky, é buscado também por processos do sitema para que sejam encerrados.


Após, é feita uma busca por processos utilizando arquivos da pasta do sistema localmente. No linux com `lsof`, no windows com `handle`.
No linux serão encerrados todos os processos operando dentro da pasta de executável do sistema.
No windows serão encerrados os handles vinculados aos processos operando dentro da pasta do sistema.

Após a liberação da pasta, ela será renomeada para a extração da nova versão, e após a conclusão da extração, renomeada novamente para o original.
A função de renomear a pasta serve para garantir que todos os arquivos dentro dela estão liberados, principalmente no windows.

No linux, ao final é usado o comando `chmod` para dar permissão aos novos arquivos.

## REQUISITOS

O script deve ser executado NO SERVIDOR.

Os scripts devem ser salvos dentro da pasta atualizador, no mesmo diretorio da executaveis, mas não dentro dela.

É preciso passar como parâmetros o nome do sistema e o nome do zip com nova versão (sem o .zip).
O zip da nova versão deve estar dentro da pasta do sistema.

```
C:\sky\atualizador\atualizador.ps1 -sistema sistema -namezip sistema2024.01.01.0
```

```
/sky/atualizador/atualizador.sh sistema sistema2024.01.01.0
```

Os scripts devem ser invocados com privilégios de administrador.
No linux, como root. No windows, com um usuário (e terminal) abertos por um admin.


É extremamente importante que todos os sistemas sejam encerrados nas estações.
Embora os scripts tentam forçadamente encerrar todos os vículos com arquivos abertos e processos locais, o sistema em uso ainda poderia dificultar a liberação dos arquivos e pastas.
E mesmo liberando o vínculo com todos os arquivos, caso o sistema permaneça em execução na estação, a versão antiga pode ficar presa no cache do windows, sendo necessário reiniciá-la.
