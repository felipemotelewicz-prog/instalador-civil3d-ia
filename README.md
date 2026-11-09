# AutoCivil: Claude + Civil 3D (beta)

## ⬇️ Baixar
**[Baixar AutoCivil.exe](https://github.com/felipemotelewicz-prog/instalador-civil3d-ia/releases/download/v2.1.0/AutoCivil.exe)**

Sem login e sem precisar de administrador.

1. Salve seus desenhos e **feche o Civil 3D**.
2. Abra o **AutoCivil.exe**. Se o Windows mostrar um aviso azul, clique em **Mais informações → Executar assim mesmo**. Se o navegador avisar do download, clique em **Manter**.
3. Escolha **Completo** (recomendado) ou **Simples** e clique em **Instalar**.
4. Quando ele pedir, abra o Civil 3D com um desenho e clique em OK. Ele abre o Claude.

---

## Versões em .bat (alternativa)

## 1. Completo (recomendado): Civil 3D de verdade
Liga o Claude nos **objetos do Civil 3D**: superfícies, alinhamentos, perfis, corredores, seções, superelevação, redes de tubo (gravidade e pressão), pontos COGO, lotes, terraplenagem, hidrologia, quantitativos, pranchas e checagens de qualidade (180+ ações).

**[Baixar Instalar-Civil3D-IA-Completo.bat](https://github.com/felipemotelewicz-prog/instalador-civil3d-ia/releases/download/v2.0.0/Instalar-Civil3D-IA-Completo.bat)**

- Precisa do **Civil 3D 2025, 2026 ou 2027** (validado pelo autor no 2026).
- Feche o Civil 3D, dê dois cliques no instalador e siga a tela.
- Ele baixa o que faltar (Node.js e .NET SDK, só para esta conexão), monta o plugin para o seu Civil 3D e configura o Claude.
- Ao abrir o Civil 3D, se aparecer aviso de segurança do `Civil3DMcpPlugin`, clique em **Sempre carregar**.
- Teste no Claude: `use o civil3d_health`. No Civil 3D: comando `C3DMCPSTATUS`.

## 2. Simples: só desenho comum
Linhas, layers, cotas, textos, pranchas e PDF (funciona em qualquer AutoCAD completo ou Civil 3D).

**[Baixar Instalar-Civil3D-IA.bat](https://github.com/felipemotelewicz-prog/instalador-civil3d-ia/releases/download/v1.0.0/Instalar-Civil3D-IA.bat)**

## Deu erro?
Mande o arquivo `%TEMP%\instalador-civil3d-ia.log` para o suporte.

## Créditos
A conexão completa usa o [Civil3D-mcp](https://github.com/SimsUDS/Civil3D-mcp) de Steven Bouldin (licença MIT, incluída no pacote). O modo simples usa o [autocad-mcp-pro](https://pypi.org/project/autocad-mcp-pro/).
