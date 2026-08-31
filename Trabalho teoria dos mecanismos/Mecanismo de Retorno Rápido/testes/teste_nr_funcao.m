clc; clear;

%% ================= TESTE 1: exemplo simples com solucao conhecida =========
% circulo de raio 5 cruzando a reta x = y  ->  x = y = 5/sqrt(2) = 3.5355339
fprintf('===== TESTE 1: circulo + reta =====\n');
syms x y
q1   = [x; y];
phi1 = [x^2 + y^2 - 25;
        x - y];

[sol1, info1] = newton_raphson_sym(phi1, q1, [1; 1], verbose=true);

fprintf('\nsolucao  = [%.7f, %.7f]\n', sol1(1), sol1(2));
fprintf('esperado = [%.7f, %.7f]\n', 5/sqrt(2), 5/sqrt(2));
fprintf('erro     = %.2e\n', norm(sol1 - [5/sqrt(2); 5/sqrt(2)]));
fprintf('convergiu=%d, iteracoes=%d, residuo=%.2e\n', ...
        info1.convergiu, info1.iteracoes, info1.residuo);

%% ================= TESTE 2: o mecanismo (6 coordenadas) ==================
fprintf('\n\n===== TESTE 2: mecanismo, 6 coordenadas =====\n');
syms x_1 y_1 theta_1 x_2 y_2 theta_2 l_2 d

q = [x_1; y_1; theta_1; x_2; y_2; theta_2];

phi = [ x_1;
        y_1;
        theta_1 - atan((l_2*sin(theta_2) + d) / (l_2*cos(theta_2)));
        x_2;
        y_2 - d;
        theta_2 ];

% atribui os parametros ANTES de chamar
phi_num = subs(phi, [l_2, d], [5, 3]);

[sol2, info2] = newton_raphson_sym(phi_num, q, zeros(6,1), verbose=true);

nomes = {'x_1','y_1','theta_1','x_2','y_2','theta_2'};
fprintf('\n');
for k = 1:6
    fprintf('%-8s = %12.9f\n', nomes{k}, sol2(k));
end
fprintf('\ntheta_1 exato = atan(3/5) = %.9f  (erro %.2e)\n', ...
        atan(3/5), sol2(3) - atan(3/5));
fprintf('convergiu=%d, iteracoes=%d, residuo=%.2e\n', ...
        info2.convergiu, info2.iteracoes, info2.residuo);

%% ================= TESTE 3: erro de parametro esquecido ==================
fprintf('\n\n===== TESTE 3: deve dar erro (l_2 e d sem valor) =====\n');
try
    newton_raphson_sym(phi, q, zeros(6,1));
    fprintf('ERRO: deveria ter falhado!\n');
catch ME
    fprintf('capturou corretamente:\n  %s\n', ME.message);
end

%% ================= TESTE 4: dimensao errada de q0 ========================
fprintf('\n===== TESTE 4: deve dar erro (q0 com tamanho errado) =====\n');
try
    newton_raphson_sym(phi_num, q, zeros(3,1));
    fprintf('ERRO: deveria ter falhado!\n');
catch ME
    fprintf('capturou corretamente:\n  %s\n', ME.message);
end

%% ================= TESTE 5: nao convergencia (sem singularidade) =========
fprintf('\n===== TESTE 5: deve AVISAR que nao convergiu =====\n');
syms z
% z^3 - 2z + 2 a partir de z=0 entra em ciclo 0 -> 1 -> 0 -> 1 ...
% (derivada nunca zera nesses pontos: -2 e 1, entao nao ha singularidade)
[~, info5] = newton_raphson_sym(z^3 - 2*z + 2, z, 0, max_iter=5);
fprintf('convergiu = %d (esperado 0)\n', info5.convergiu);
fprintf('iteracoes = %d (esperado 5)\n', info5.iteracoes);

%% ================= TESTE 6: Jacobiana singular ===========================
fprintf('\n===== TESTE 6: deve dar ERRO (Jacobiana singular) =====\n');
% z^2 + 1 = 0 nao tem raiz real e leva a derivada 2z -> 0
try
    newton_raphson_sym(z^2 + 1, z, 1, max_iter=5);
    fprintf('ERRO: deveria ter falhado!\n');
catch ME
    fprintf('capturou corretamente:\n  %s\n', ME.message);
end

fprintf('\n===== TODOS OS TESTES CONCLUIDOS =====\n');
