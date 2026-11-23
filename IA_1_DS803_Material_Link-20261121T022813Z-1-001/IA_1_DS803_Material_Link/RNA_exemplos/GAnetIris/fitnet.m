function [Err clout Cout v C1 C2] = fitnet(arg, Wiris, CLiris)
%
% Definições da rede
m = 4;  % Quatro atributos de entrada do conjunto da Iris de Fisher
n1 = 2; % Camada intermediárias com 2 neurônios (arbitrária)
n2 = 3; % Tres neurônios de saída, um para cada classe possível
%%%
%                                                    % Agora recebe pelo GA 
%                                                    % arg = randi(2,1,((4*2)+(2*3))*8)-1;    % Bits aleatórios para simular a rede 
%%%                                                  % 14 = n1*m + n2*n1, *8 bits para pesos em bytes
% Bits -> Bytes
v = bits2bytes(arg);
%
% Monta matrizes vazias / camadas da rede
C1 = zeros(m, n1); % 4 X 2
C2 = zeros(n1,n2); % 2 X 3
%
% Gera camadas - Preenche por colunas
l1 = m*n1; % Tamanho de C1
C1(1:l1)  = v(1:l1);       % 4x2
C2(1:end) = v(1+l1:end);   % 2x3 % Elementos restantes
%
%
% Propagação 
Cout = Wiris*C1*C2;        % saída kx3 (k=número de linhas em Wiris)
%
% Verifica erro total
clout = maxi(Cout')';         % Assumo o maior valor por linha como classe
CLiri = maxi(CLiris')';       % Mesmo com o conjunto de supervisão
Err = sum(abs(clout-CLiri));  % Desvio total em relação ao obetivo
