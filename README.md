# AutoCivil: Claude + Civil 3D (beta)

## Baixar
**[Baixar AutoCivil.exe](https://github.com/felipemotelewicz-prog/instalador-civil3d-ia/releases/latest/download/AutoCivil.exe)**

Adicional do curso **Revit com IA**: entre com o **mesmo e-mail e senha do AutoRevit** (quem ja entrou no AutoRevit neste computador entra direto). Nao precisa de administrador.

1. Salve seus desenhos e **feche o Civil 3D**.
2. 2. Abra o **AutoCivil.exe**. Se o Windows mostrar um aviso azul, clique em **Mais informacoes, Executar assim mesmo**. Se o navegador avisar do download, clique em **Manter**.
   3. 3. Entre com a conta do curso (ou use **Primeiro acesso** se ainda nao criou a senha). Confira a lista "Neste computador" e clique em **Instalar** (leva de 3 a 6 minutos na primeira vez).
      4. 4. Na tela final: abra o Civil 3D, clique em **Reiniciar o Claude** e cole o pedido de teste.
         5. 5. Clique em **Vault do Obsidian** para instalar as 94 notas do Civil 3D, ligar a conexao `vault-civil3d` no Claude e abrir o Obsidian (ele instala o Obsidian se faltar). O vault fica em `Documentos\AutoCivil\Vault Civil 3D com IA`.
            6. 6. Deu erro? Abra o AutoCivil pelo menu Iniciar e clique em **Esta dando erro?**: ele confere cada peca e conserta sozinho.
              
               7. ---
              
               8. ## Versoes em .bat (alternativa)
              
               9. ## 1. Completo (recomendado): Civil 3D de verdade
               10. Liga o Claude nos **objetos do Civil 3D**: superficies, alinhamentos, perfis, corredores, secoes, superelevacao, redes de tubo (gravidade e pressao), pontos COGO, lotes, terraplenagem, hidrologia, quantitativos, pranchas e checagens de qualidade (180+ acoes).
              
               11. **[Baixar Instalar-Civil3D-IA-Completo.bat](https://github.com/felipemotelewicz-prog/instalador-civil3d-ia/releases/download/v2.0.0/Instalar-Civil3D-IA-Completo.bat)**
              
               12. - Precisa do **Civil 3D 2025, 2026 ou 2027** (validado pelo autor no 2026).
                   - - Feche o Civil 3D, de dois cliques no instalador e siga a tela.
                     - - Ele baixa o que faltar (Node.js e .NET SDK, so para esta conexao), monta o plugin para o seu Civil 3D e configura o Claude.
                       - - Ao abrir o Civil 3D, se aparecer aviso de seguranca do `Civil3DMcpPlugin`, clique em **Sempre carregar**.
                         - - Teste no Claude: `use o civil3d_health`. No Civil 3D: comando `C3DMCPSTATUS`.
                          
                           - ## 2. Simples: so desenho comum
                           - Linhas, layers, cotas, textos, pranchas e PDF (funciona em qualquer AutoCAD completo ou Civil 3D).
                          
                           - **[Baixar Instalar-Civil3D-IA.bat](https://github.com/felipemotelewicz-prog/instalador-civil3d-ia/releases/download/v1.0.0/Instalar-Civil3D-IA.bat)**
                          
                           - ## Deu erro?
                           - Mande o arquivo `%TEMP%\instalador-civil3d-ia.log` para o suporte.
                          
                           - ## Creditos
                           - A conexao completa usa o [Civil3D-mcp](https://github.com/SimsUDS/Civil3D-mcp) de Steven Bouldin (licenca MIT, incluida no pacote). O modo simples usa o [autocad-mcp-pro](https://pypi.org/project/autocad-mcp-pro/).
                           - 
