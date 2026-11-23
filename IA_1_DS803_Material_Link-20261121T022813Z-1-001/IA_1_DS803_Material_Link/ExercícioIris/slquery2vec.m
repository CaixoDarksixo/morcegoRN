function [ resultado ] = slquery2vec( q )
%
n = length(q.Result);
vetor = [];

for i=1:n
%slquery old    vetor = [ vetor; q.Result(i).valor ];
    vetor = [ vetor; q.Result(i) ];
end

resultado = vetor;

end

