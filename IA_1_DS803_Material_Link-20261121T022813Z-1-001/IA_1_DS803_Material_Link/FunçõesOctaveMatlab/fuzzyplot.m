function mret = fuzzyplot(xa, xb, xcor, varargin)
% Função do grupo de gerar gráficos de variáveis linguísticas
% fplot inic - cria escala do grafico, abre figura e hold on - xo é y
% fplot ones
% fplot zeros
% fplot Up - Linha ascendente
% fplot cai
V = varargin;
xmethod = 1;
xinic = varginfind(V,'Inic',0);
xones = varginfind(V,'Ones',0);
xzeros = varginfind(V,'Zeros',0);
xup = varginfind(V,'Up',0);
xdown = varginfind(V,'Down',0);
%
if xinic
    figure
    icor = {'r','g','b','c','m','y','k'};
    hold on 
    for ii=1:length(icor)
        plot([xa; xa],[xb; xb],icor{ii})
    end
elseif xones
    X = (xa:xb)';
    Y = ones(length(X),1);
    plot(X,Y,xcor);
elseif xzeros
    X = (xa:xb)';
    Y = zeros(length(X),1);
    plot(X,Y,xcor);
elseif xup
    X = [xa 0];
    Y = [xb 1];
    XY = linspace2(X,Y,abs(xa-xb)+1);
    plot(XY(:,1),XY(:,2),xcor);
elseif xdown
    X = [xa 1];
    Y = [xb 0];
    XY = linspace2(X,Y,abs(xa-xb)+1);
    plot(XY(:,1),XY(:,2),xcor);
end
    

    