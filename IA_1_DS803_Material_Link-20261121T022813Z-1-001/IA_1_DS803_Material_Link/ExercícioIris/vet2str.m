function mret = vet2str(t)
%Converte o vetor de padroes para o formato do Sibila (elimina a ultima
%coluna)
n = length(t(:,1));
m = length(t(1,:));
virgulas = char(ones(1,n)*44)';
mret = [];
for j=1:m-1
    s = num2str(t(:,j));
    mret = [mret s virgulas];
end
s = num2str(t(:,j+1));
mret = [mret s];
    