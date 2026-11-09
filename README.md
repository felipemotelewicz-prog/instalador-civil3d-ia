# Instalador: Claude + AutoCAD / Civil 3D

Liga o **Claude Desktop** no **AutoCAD completo ou Civil 3D** (não funciona no AutoCAD LT).

## Como instalar

1. Baixe o instalador: **[Instalar-Civil3D-IA.bat](https://github.com/felipemotelewicz-prog/instalador-civil3d-ia/releases/latest/download/Instalar-Civil3D-IA.bat)**
2. Dê dois cliques no arquivo. Se o Windows mostrar um aviso azul, clique em **Mais informações → Executar assim mesmo**.
3. Siga a tela. Quando ele pedir, **abra o Civil 3D com um desenho** e aperte Enter.
4. No Claude, escreva: `use o system_status do autocad`. Tem que aparecer `connected: true`.

## O que ele faz

- Confere se o AutoCAD / Civil 3D está instalado
- Instala o Python se faltar
- Instala a conexão (`autocad-mcp-pro`)
- Grava a configuração do Claude (faz cópia de segurança e mantém as outras conexões)
- Reabre o Claude

Deu erro? Mande o arquivo `%TEMP%\instalador-civil3d-ia.log` para o suporte.
