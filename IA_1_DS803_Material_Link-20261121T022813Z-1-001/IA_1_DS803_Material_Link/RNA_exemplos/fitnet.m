function [Err clout Cout v C1 C2] = fitnet(arg, Wiris, CLiris)
%
m = 4;  % Quatro atributos de entrada do conjunto da Iris de Fisher
n1 = 2; % Camada intermediárias com 2 neurônios (arbitrária)
n2 = 3; % Tres neurônios de saída, um para cada classe possível
%%%
% Agora recebe pelo GA 
% arg = randi(2,1,((4*2)+(2*3))*8)-1;    % Bits aleatórios para simular a rede 
%%%                                      % 14 = n1*m + n2*n1, *8 bits para pesos embytes
% Bits -. matrizes
v = bits2bytes(arg);
l1 = m*n1;
C1 = zeros(m, n1);
C2 = zeros(n1,n2);
% Gera camadas
C1(1:l1)  = v(1:l1);       % 4x2
C2(1:end) = v(1+l1:end);   % 2x3
% Propagação
Cout = Wiris*C1*C2;        % saída kx3 (k=número de linhas em Wiris)
% Erro total
clout = maxi(Cout')';         % Assumo o maio valor por linha como classe
CLiri = maxi(CLiris')';       % Mesmo com o conjunto de supervisão
Err = sum(abs(clout-CLiri));  % Desvio total em relação ao obetivo
