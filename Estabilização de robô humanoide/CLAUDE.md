# Estabilização de robô humanoide — instruções do projeto

## 1. Objetivo

Desenvolver, em MATLAB, um **algoritmo de equilíbrio** para um robô humanoide.
O robô é aproximado por um **mecanismo plano (plano sagital)** com **4 corpos** e
**3 juntas de revolução**: tornozelo, joelho e quadril.

- O **pé é base fixa** (engastada no solo) — a cadeia é aberta e serial, tipo
  **pêndulo invertido triplo**.
- O **centro de massa (CM)** é aproximado como concentrado na **extremidade** do
  mecanismo (topo do tronco), no mesmo ponto onde está a **IMU**.
- **Entrada:** dados da IMU. **Saída:** os três ângulos de junta (referência para
  os motores) que trazem a coordenada **x do CM** de volta a um valor
  **x_ref** especificado.

Meta primária: **regulação quase-estática** de x_CM. Extensões dinâmicas (LIPM,
capture point) são etapa posterior, não o alvo inicial.

## 2. Convenção de modelagem (usar sempre esta — não redefinir)

### 2.1 Referencial

- Plano sagital. Origem no **eixo fixo, no nível do solo**.
- **x** horizontal, positivo no sentido da ponta do pé (frente).
- **z** vertical, positivo para cima. Gravidade = −z.
- Ângulos em **radianos** internamente; graus **apenas** em exibição/gráficos.
- **Ângulo positivo = elo se inclina para a FRENTE (para +x).** Não usar
  "horário/anti-horário": depende de que lado se olha o plano.

### 2.2 Elos e juntas

| Símbolo | Elo | De → Para | Junta na base do elo |
|---|---|---|---|
| `l1` | **base fixa** | eixo fixo (solo) → tornozelo | — (engaste, vertical) |
| `l2` | canela (tíbia) | tornozelo → joelho | `q1` tornozelo |
| `l3` | coxa (fêmur)   | joelho → quadril  | `q2` joelho |
| `l4` | tronco         | quadril → CM/IMU  | `q3` quadril |

São **4 barras**, das quais **3 são móveis**. `l1` é vertical e não depende
de `q`.

Vetor de configuração: `q = [q1; q2; q3]` — **ângulos relativos** (de junta,
o que os motores comandam).

Sinais das juntas: `q1 > 0` leva o corpo para a frente; `q2 ≤ 0` sempre
(o joelho só flexiona, nunca hiperextende); `q3 > 0` é flexão do quadril
(tronco à frente da coxa).

Ângulos **absolutos** medidos a partir da **vertical**:

```
phi1 = q1
phi2 = q1 + q2
phi3 = q1 + q2 + q3      % <- é ESTE que a IMU do topo mede
```

Postura ereta ideal: `q = [0; 0; 0]` ⇒ todos os elos alinhados com +z.

### 2.3 Cinemática direta da ponta (onde estão CM e IMU)

Implementada em `pontos_mecanismo.m`, que devolve **todos** os nós.

```
x(q) =        l2*sin(phi1) + l3*sin(phi2) + l4*sin(phi3)
z(q) = l1  +  l2*cos(phi1) + l3*cos(phi2) + l4*cos(phi3)
```

O `l1` entra só como offset constante em `z` — a barra fixa não contribui
para `x`.

### 2.4 Jacobiano da ponta (2×3) — referência, não rederivar

```
dx/dq1 =  l2*cos(phi1) + l3*cos(phi2) + l4*cos(phi3)
dx/dq2 =                 l3*cos(phi2) + l4*cos(phi3)
dx/dq3 =                                l4*cos(phi3)

dz/dq1 = -( l2*sin(phi1) + l3*sin(phi2) + l4*sin(phi3) )
dz/dq2 = -(                l3*sin(phi2) + l4*sin(phi3) )
dz/dq3 = -(                               l4*sin(phi3) )
```

Para a tarefa de equilíbrio, a linha de interesse é `Jx = [dx/dq1 dx/dq2 dx/dq3]`
(1×3).

### 2.5 CM: aproximação e caminho de refino

Implementado em `cm_posicao.m`, que devolve **os dois** modelos e escolhe
entre eles por `P.modelo_cm`:

- `'ponta'` — massa pontual na ponta de `l4` ⇒ `x_CM = x(q)`. É a aproximação
  do enunciado.
- `'ponderado'` — `x_CM = sum(m_i * x_ci) / sum(m_i)` sobre as 4 barras.

**Atenção — a diferença não é pequena.** Na postura ereta, com os parâmetros
estimados: `'ponta'` põe o CM a **43 cm** (72 % de H) e `'ponderado'` a
**31 cm** (52 % de H). Os 12 cm vêm das pernas, que pesam ~43 % do robô e
ficam ignoradas lá embaixo no modelo `'ponta'`.
Consequência dinâmica: `omega = sqrt(g/z_CM)` erra em ~18 %, então qualquer
resultado de LIPM/capture point tirado do modelo `'ponta'` é otimista.
Rodar sempre as duas versões antes de concluir.

## 3. Uso dos dados da IMU

A IMU está fixa no último elo, na ponta. No plano sagital ela fornece
`a_x`, `a_z` (acelerômetro) e `omega_y` (giroscópio).

- **Inclinação absoluta do tronco** (estática): `phi3_acc = atan2(a_x, a_z)`.
- **Fusão obrigatória** (o acelerômetro sozinho é corrompido por movimento; o
  giroscópio sozinho deriva). Usar filtro complementar como padrão:
  `phi3 = alpha*(phi3_ant + omega_y*dt) + (1-alpha)*phi3_acc`, com `alpha ≈ 0.98`.
  Kalman só se o complementar se mostrar insuficiente — documentar o motivo.
- **Limitação estrutural, atenção:** uma IMU na ponta mede **uma** grandeza
  absoluta (`phi3`), mas a postura tem **três** graus de liberdade. Só com a IMU
  a configuração **não é observável**. O projeto assume:
  - `q1, q2, q3` vêm dos **encoders dos motores** (postura conhecida);
  - a IMU fornece a **referência absoluta** — corrige a inclinação real do
    conjunto (pé deformável, solo inclinado, folga) e detecta a perturbação.
  - Ou seja: `phi3_medido - (q1+q2+q3)` = erro absoluto a ser injetado na
    estimativa. **Registrar explicitamente essa hipótese em qualquer relatório.**

## 4. Lei de controle

Erro da tarefa: `e = x_ref - x_CM`.

O sistema é **redundante**: 3 juntas para 1 objetivo escalar ⇒ 2 GDL livres.
Resolver por Jacobiano com pseudo-inversa amortecida e usar o espaço nulo para
tarefas secundárias:

```
dq = J_x' * (J_x*J_x' + lambda^2)^-1 * (Kp*e)        % tarefa primária
   + (I - J_x^+ * J_x) * dq_sec                       % espaço nulo
```

Tarefas secundárias sugeridas para `dq_sec` (nesta ordem de prioridade):

1. manter a **altura** `z(q)` próxima da nominal (não agachar ao corrigir);
2. atrair a postura para a configuração nominal `q_nom` (evita deriva);
3. afastar-se dos **limites de junta**.

Ganho `Kp` proporcional; adicionar termo derivativo sobre `x_CM` estimado se
houver oscilação. Amortecimento `lambda` protege as singularidades
(`Jx → 0` quando os elos ficam horizontais).

### Estratégias de equilíbrio a implementar/comparar

- **Tornozelo**: perturbação pequena, corrige quase só com `q1`.
- **Quadril**: perturbação grande, usa `q3` para gerar momento angular.
- **Coordenada**: pesos variáveis no espaço nulo em função de `|e|`.

## 5. Restrições que o algoritmo deve respeitar

- **Limites de junta** (definir em `parametros.m`, valores fisiológicos).
- **Joelho não hiperextende**: `q2` com sinal restrito a um lado.
- **ZMP dentro do pé**: `x_ZMP ∈ [-d_calcanhar, +d_ponta]`.
  Quase-estático: `x_ZMP ≈ x_CM`.
  Dinâmico (LIPM): `x_ZMP = x_CM - (z_CM/g) * ddx_CM`.
  Sair desse intervalo = o pé descola ⇒ a hipótese de base fixa quebra.
  **Verificar isso a cada passo e avisar.**
- Saturação de velocidade/aceleração das juntas.

## 6. Estrutura de arquivos (alvo)

Já existe:

```
parametros.m                % l1..l4, massas, limites, x_ref  <- ÚNICO lugar com números
pontos_mecanismo.m          % q -> pts [2x5] de todos os nós, e phi absolutos
cm_posicao.m                % q -> CM nos dois modelos ('ponta' e 'ponderado')
desenha_mecanismo.m         % desenha uma postura num eixo
demo_mecanismo.m            % confere geometria em 4 posturas + varredura do tornozelo
```

A fazer:

```
main.mlx                    % script vivo: monta, simula, plota
jacobiano.m                 % q -> J (2x3), fórmulas da seção 2.4
imu_estima_inclinacao.m     % (a_x, a_z, omega_y, dt) -> phi3 filtrado
controlador_equilibrio.m    % (estado, x_ref) -> q_ref dos motores
verifica_zmp.m              % checagem de restrição de apoio
anima_robo.m                % animação temporal (reusa desenha_mecanismo)
```

Uma função por arquivo. `main.mlx` só orquestra — **sem lógica de controle
enterrada no script vivo**.

## 7. Convenções de código

- MATLAB **R2026a**. Robotics System Toolbox disponível (pode ser usado para
  `rigidBodyTree`/visualização, mas a cinemática do modelo plano é analítica —
  fórmulas da seção 2 — e não deve depender do toolbox).
- **Comentários e nomes em português**, como no projeto irmão `Braço mecâmico`.
- Cabeçalho de função no estilo do repositório: descrição, entradas com
  unidade e dimensão, saídas, notas.
- **SI em tudo**: metros, quilogramas, segundos, radianos.
- Nada de números mágicos no meio do código — tudo em `parametros.m`.
- Evitar `.asv` versionados (autosave do MATLAB); se aparecerem, sugerir
  `.gitignore`.

## 8. Regras de trabalho com o Claude

- **Não alterar nem criar código no repositório sem pedido explícito.**
  O padrão é **propor, explicar e testar**; escrever arquivo só quando pedido.
- Ao mudar convenção de sinal, referencial ou definição de ângulo,
  **atualizar a seção 2 deste arquivo na mesma ação** — divergência entre o
  documento e o código é a maior fonte de erro neste projeto.
- Ao entregar equações, manter a nomenclatura desta seção 2 (`q1..q3`,
  `phi1..phi3`, `L1..L3`) — não introduzir símbolos novos sem registrar aqui.

## 9. Validação mínima

1. **Cinemática**: `q = 0` ⇒ `x = 0`, `z = L1+L2+L3`. Comparar Jacobiano
   analítico com diferenças finitas (erro < 1e-6).
2. **Regulação**: partir de `q` perturbado, verificar `x_CM → x_ref` sem
   violar limites nem ZMP.
3. **Rejeição de perturbação**: aplicar degrau/impulso em `x_CM` e medir tempo
   de acomodação e sobressinal.
4. **Estratégias**: comparar tornozelo × quadril × coordenada no mesmo distúrbio.
5. **Animação**: `anima_robo.m` mostrando elos, CM, x_ref e a base de apoio.

## 10. Pontos em aberto

**Resolvido em 2026-08-31:** "4 barras" = `l1` fixa + `l2`, `l3`, `l4` móveis,
cadeia **aberta** serial 3R. Não é quadrilátero fechado.

Ainda em aberto:

- Os valores em `parametros.m` são **estimativa** para um KidSize de
  H = 0,60 m e M = 5,0 kg (escala de ROBOTIS OP3), **não** medidas do robô real
  do usuário. Substituir assim que houver CAD ou balança.
- Existe modelo de atuador (saturação de torque, dinâmica do servo) ou os
  ângulos comandados são seguidos idealmente?
- A validação será só simulação em MATLAB, ou haverá Simulink / hardware?
- Modelo de IMU: qual sensor, qual taxa de amostragem, quanto de ruído e bias?
