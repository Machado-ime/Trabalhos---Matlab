function [config, pos_atual] = cinematica_inversa_generica(UR5e, pos, chute, peso_pos, peso_ori, angulo)

% Cria o resolvedor GIK com restrições específicas
gik = generalizedInverseKinematics("RigidBodyTree", UR5e, "ConstraintInputs", {"position","orientation"});
gik.SolverParameters.MaxIterations = 500;
gik.SolverParameters.SolutionTolerance = 1e-4;
gik.SolverParameters.GradientTolerance = 1e-8;

% Cria a restrição de posição
posTarget = constraintPositionTarget("tool0");
posTarget.TargetPosition = pos;
posTarget.Weights = peso_pos;  % peso total para X Y Z

% Cria a restrição de orientação
oriTarget = constraintOrientationTarget("tool0");
oriTarget.TargetOrientation = eul2quat([angulo -pi 0]);oriTarget.Weights = peso_ori;  % zero se quiser ignorar a orientação

% Chute inicial
initialGuess = homeConfiguration(UR5e);
for i = 1:numel(chute)
    initialGuess(i).JointPosition = chute(i);
end

% Resolve a cinemática inversa
[configSoln, solnInfo] = gik(initialGuess, posTarget, oriTarget);

% Extrai resultado
config = [configSoln(1).JointPosition configSoln(2).JointPosition configSoln(3).JointPosition configSoln(4).JointPosition -pi/2 configSoln(5).JointPosition];

% Diagnóstico de Posição e Orientação
T = getTransform(UR5e, configSoln, "tool0");
pos_atual = tform2trvec(T);
quat_atual = tform2quat(T);

% Converte para Euler (Z-Y-X) em graus para facilitar a leitura humana
euler_atual = rad2deg(quat2eul(quat_atual)); 

fprintf("\n--- Diagnóstico Tool0 ---\n");
disp("Status do Solver: " + solnInfo.Status);
fprintf("Posição:    X = %.4f | Y = %.4f | Z = %.4f (m)\n", pos_atual(1), pos_atual(2), pos_atual(3));
fprintf("Orientação: Z = %.2f°   | Y = %.2f°   | X = %.2f° (Euler)\n", euler_atual(1), euler_atual(2), euler_atual(3));
disp("Configuração de Juntas (rad):");
disp(config); 

end




