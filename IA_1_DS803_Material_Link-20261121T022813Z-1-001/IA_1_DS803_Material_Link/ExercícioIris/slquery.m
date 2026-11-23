function m_ret = slquery( query, FAN_RNA_FILE, varargin )
% query - conjunto de vetor de caracteristicas a ser classificado
% FAN_RNA_FILE - arquivo da rede treinada no EasyFAN
% opcionais
%  parametros para o classificador... uso futuro
%
warning off
%
if( isempty(query) )
    m_ret = struct();
    m_ret.nome = 'Query is empty';
    return
end
if( exist( FAN_RNA_FILE , 'file' ) == 0 )
    m_ret = struct();
    m_ret.nome = 'FAN File not found';
    return
end

tmpNom = [ 'slq' num2str(ceil(rand(1,1)*100)) '.txt' ];
arq2 = [ 'res' num2str(ceil(rand(1,1)*100)) '.txt' ];

m_txt = vet2str( query );

fid = fopen( tmpNom , 'w+t');
n = length( m_txt(:,1) );
for i=1:n
    fprintf(fid, '%s\n', m_txt(i,:) );
end
fclose(fid);

m_ret = struct();
m_ret.Query = query;
m_ret.FAN = FAN_RNA_FILE;

%   IMPORTANTE:::cmd = ['java -jar c:/...rota_completa/SLQuery.jar -i ' tmpNom ' -f ' FAN_RNA_FILE ' -o ' arq2];
%   Ao colocar o programa em outro diretorio cuidar para indicar a rota para
%   SLQuery.jar (como abaixo)
if 1
    %        rota = mfilename('fullpath');
    %        s = strfind(rota,'/slquery');
    %        rota = rota(1:s(length(s)));
    %        cmd = ['java -jar ' rota 'SLQuery.jar -i ' tmpNom ' -f ' FAN_RNA_FILE ' -o ' arq2];
    %cd
    umfn = mfilename('fullpath');
    %disp(umfn)
    ps = find(umfn=='\');
    umfn(ps) = '/';
    umfn(ps(end):end) = [];
    %disp(umfn)
    %
    if(exist([pwd '/SLQuery.jar']))
    %    'if'
        cmd = ['java -jar SLQuery.jar -i ' tmpNom ' -f ' FAN_RNA_FILE ' -o ' arq2];
    else
    %    'else'
        wherenet = [umfn '/' FAN_RNA_FILE];
        if ~exist(wherenet,'file')
            wherenet = [pwd '/' FAN_RNA_FILE];
        end
        cmd = ['java -jar ' umfn '/SLQuery.jar -i ' tmpNom ' -f ' wherenet ' -o ' arq2];
    end
    % disp(cmd)
    %        cmd
    %
    %working        cmd = ['java -jar C:/Robmatlabfunc/SLQuery.jar -i ' tmpNom ' -f ' FAN_RNA_FILE ' -o ' arq2];
    
    %        cmd = ['java -jar C:/Users/Roberto/Documents/MATLAB/SLQuery.jar -i ' tmpNom ' -f ' FAN_RNA_FILE ' -o ' arq2];
    %        C:\Users\Roberto\Documents\MATLAB
    %        cmd = ['java -jar c:/"Program Files"/Matlab/r2008a/work/SLQuery.jar -i ' tmpNom ' -f ' FAN_RNA_FILE ' -o ' arq2];
else
    'É importante colocar a caminho completo do diretório em que está o programa ''SLQuery.jar'' na linha 37 no codigo da função slquery.m'
end
[blastStatus, blastResult] = system(cmd);
%delete( tmpNom );

%disp( cmd );

if( exist( arq2 , 'file' ) ~= 0 )
    fid = fopen(arq2, 'rt' );
    fseek(fid, 0, 'eof');
    qde = ftell(fid);
    fseek(fid, 0 , 'bof');
    result = fread(fid, qde, '*char' )';
    fclose(fid);
    s = regexp( result , [ '<nome>(?<nome>[^<]*)</nome><valor>(?<valor>[^<]*)</valor>'  ], 'names' );
    if ~isempty(s)
        m_ret.S = s;
        k = (([m_ret.S.valor]));
        if ~iscell(k)
            k(k==',') = '.';
            k = str2num(k);
            k = k';
        else
            k = (cell2mat(k'));
            k(k==',')='.';
            str2num(k);
        end
        m_ret.Result = k;
        %           m_ret.valor = [s.valor]';
        %m_ret.Result = str2num(cell2mat(m_ret.S.valor'));
        %s(s==',') ='.';
        %m_ret.Result = str2num(s)';
    else
        m_ret.nome = 'vazio';
        m_ret.valor = -1;
    end
    %m_ret.Result = result;
    %m_ret.Result = xml2struct( arq2 );
    delete( arq2 );
end
end

function mret = vet2str(t)
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
end