# Mecanismo de Retorno Rápido — Análise Cinemática em MATLAB

## Objetivo

Desenvolver um código em MATLAB para a análise e simulação da cinemática de um
mecanismo de retorno rápido (quick-return mechanism).

## Entregáveis

1. **Arquivo `.mlx`** (MATLAB Live Script) contendo o código da análise, que ao
   ser executado gere os resultados da simulação em forma de gráficos
   (posição, velocidade, aceleração, trajetória, etc., conforme o que fizer
   sentido para a cinemática do mecanismo).
2. **Arquivo `.pdf`** gerado pela exportação do `.mlx` diretamente do MATLAB
   (Live Editor → Export to PDF), refletindo o conteúdo e os gráficos do
   Live Script.

## Requisitos de implementação

- Os **parâmetros da simulação devem poder ser atribuídos individualmente**
  (ex.: comprimentos das barras, posição do pivô, velocidade angular de
  entrada, etc.) — ou seja, o código deve ser parametrizado e não ter valores
  fixos "hardcoded" sem possibilidade de ajuste pelo usuário.

- **O Newton-Raphson é sempre implementado à mão**, com o laço iterativo
  explícito (resíduo, Jacobiana, `Phi_q \ (-Phi)`, atualização e teste de
  convergência). **Não usar** `fsolve`, `vpasolve`, `solve` ou qualquer
  solucionador pronto para a análise de posição — o método é justamente o
  que o trabalho precisa demonstrar (Haug, seção 6).
  - Solucionadores prontos podem ser usados **apenas** como verificação
    independente em bloco separado, quando o usuário pedir.

## Regra de trabalho (importante)

- **Não modificar nem criar o(s) arquivo(s) oficial(is) da entrega
  (`.mlx` principal e o `.pdf` exportado) sem pedido ou permissão explícita
  do usuário.**
- É permitido rodar códigos e criar arquivos/scripts **de teste** livremente
  para validar ideias, fórmulas ou trechos de código.
- Arquivos de teste devem ficar separados do arquivo principal (ex.: em uma
  subpasta como `testes/` ou com nomes claramente distintos, como
  `teste_*.m`), para não haver risco de confundir rascunho com entrega
  oficial.
- Só editar o arquivo principal quando o usuário pedir explicitamente
  (ex.: "atualize o `.mlx` principal", "pode aplicar isso na entrega").
