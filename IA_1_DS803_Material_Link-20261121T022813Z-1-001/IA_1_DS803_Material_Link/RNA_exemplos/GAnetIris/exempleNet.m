% Parâmetros GA
gaopt.PopulationSize = 200;       %
gaopt.Generations = 500;          %
gaopt.InitialPopulation  = [];    %    Inicializaçoes de parâmetros
gaopt.MutationFcn = 0.15;         %
gaopt.EliteCount = 4;             %
%
load Wiris.dat
load CLiris.dat
%
% Treina rede com GA


x = gaGo(@(arg) fitnet(arg,Wiris,CLiris),14*8,gaopt);        %    Chamada do AG



%
% Verificação no conjunto de treinamento
[Err clout Cout3 bytes C1 C2] = fitnet(x,Wiris,CLiris)
% Teste em conjunto diferente Classes esperadas = {1, 1, 2, 2, 3, 3,}
load d:\afan\exemplos\iris4feat_noclas.dat
[Err clout cout3 bytes C1 C2] = fitnet(x,iris4feat_noclas(:,1:4),zeros(6,3))
%%%%%%%%
% Err - Avaliação da fitness
% clout - Classe
% cout - camada de saída
% v - Parametros otimizados
% C1 - Primeira camada
% C2 - Segunda camada
%%%%%%%%